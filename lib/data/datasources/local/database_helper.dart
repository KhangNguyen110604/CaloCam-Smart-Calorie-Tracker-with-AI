import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'food_seed_data.dart';
import '../../seed/vietnamese_nutrition_seed.dart';

/// Database Helper - SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calocount.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Version 5: Added nutrition_database table for AI food recognition nutrition lookup
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        goal_type TEXT NOT NULL,
        target_weight_kg REAL,
        weekly_goal_kg REAL NOT NULL,
        activity_level TEXT NOT NULL,
        bmi REAL NOT NULL,
        bmr REAL NOT NULL,
        tdee REAL NOT NULL,
        calorie_goal REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Weight history table
    await db.execute('''
      CREATE TABLE weight_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Foods table (catalog)
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        portion_size TEXT NOT NULL,
        image_url TEXT,
        description TEXT,
        ingredients TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Meal entries table
    await db.execute('''
      CREATE TABLE meal_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        food_id INTEGER,
        food_name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        portion_size TEXT NOT NULL,
        portion_multiplier REAL DEFAULT 1.0,
        serving_size REAL DEFAULT 100.0,
        servings REAL DEFAULT 1.0,
        source TEXT NOT NULL,
        image_path TEXT,
        confidence REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // Water intake table
    await db.execute('''
      CREATE TABLE water_intake (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        glasses INTEGER NOT NULL,
        milliliters INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      )
    ''');

    // ==================== NEW: USER CUSTOM FOODS ====================
    // User-created foods table (món ăn của tôi)
    // Stores custom foods created manually or from AI scans
    await db.execute('''
      CREATE TABLE user_foods (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        portion_size REAL DEFAULT 100,
        serving_size REAL,
        calories REAL NOT NULL,
        protein REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        image_path TEXT,
        source TEXT CHECK(source IN ('manual', 'ai_scan')) NOT NULL,
        ai_confidence REAL,
        is_editable INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        last_used_at TEXT,
        usage_count INTEGER DEFAULT 0
      )
    ''');

    // ==================== NEW: FAVORITES ====================
    // Favorite foods table (món yêu thích)
    // Links to both built-in foods and user_foods
    await db.execute('''
      CREATE TABLE favorite_foods (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        food_id TEXT NOT NULL,
        food_source TEXT NOT NULL CHECK(food_source IN ('builtin', 'custom')),
        added_at TEXT NOT NULL,
        last_used_at TEXT,
        usage_count INTEGER DEFAULT 0,
        UNIQUE(user_id, food_id, food_source)
      )
    ''');

    // ==================== NEW: NUTRITION DATABASE ====================
    // Nutrition database table (cơ sở dữ liệu dinh dưỡng)
    // Stores nutrition data for food lookup (local cache + pre-populated Vietnamese foods)
    // This is used for AI food recognition - lookup calories instead of asking GPT-4
    await db.execute('''
      CREATE TABLE nutrition_database (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_name TEXT NOT NULL UNIQUE,
        food_name_en TEXT,
        food_name_vi TEXT,
        
        -- Nutrition per 100g (standardized)
        calories_per_100g REAL NOT NULL,
        protein_per_100g REAL DEFAULT 0,
        carbs_per_100g REAL DEFAULT 0,
        fat_per_100g REAL DEFAULT 0,
        fiber_per_100g REAL DEFAULT 0,
        
        -- Serving sizes (JSON array)
        -- Example: [{"name": "Tô lớn", "grams": 500}, {"name": "Bát nhỏ", "grams": 300}]
        serving_sizes TEXT,
        
        -- Metadata
        source TEXT DEFAULT 'manual' CHECK(source IN ('manual', 'fatsecret', 'usda', 'user')),
        category TEXT,
        is_verified INTEGER DEFAULT 0,
        usage_count INTEGER DEFAULT 0,
        last_used TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_meal_entries_date ON meal_entries(date)');
    await db.execute('CREATE INDEX idx_meal_entries_user_date ON meal_entries(user_id, date)');
    await db.execute('CREATE INDEX idx_weight_history_user_date ON weight_history(user_id, date)');
    await db.execute('CREATE INDEX idx_water_intake_user_date ON water_intake(user_id, date)');
    
    // NEW: Indexes for user_foods and favorites
    await db.execute('CREATE INDEX idx_user_foods_user ON user_foods(user_id)');
    await db.execute('CREATE INDEX idx_user_foods_usage ON user_foods(user_id, usage_count DESC)');
    await db.execute('CREATE INDEX idx_user_foods_name ON user_foods(user_id, name)');
    await db.execute('CREATE INDEX idx_favorites_user ON favorite_foods(user_id, usage_count DESC)');
    await db.execute('CREATE INDEX idx_favorites_food ON favorite_foods(user_id, food_id, food_source)');
    
    // NEW: Indexes for nutrition_database (for fast food lookup)
    await db.execute('CREATE INDEX idx_nutrition_food_name ON nutrition_database(food_name)');
    await db.execute('CREATE INDEX idx_nutrition_category ON nutrition_database(category)');
    await db.execute('CREATE INDEX idx_nutrition_usage ON nutrition_database(usage_count DESC)');

    // Seed food database
    await _seedFoods(db);
    
    // Seed nutrition database (Vietnamese foods)
    await _seedNutritionDatabase(db);
  }

  /// Seed Vietnamese foods database
  Future<void> _seedFoods(Database db) async {
    // Check if foods already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM foods'),
    );
    
    if (count != null && count > 0) {
      debugPrint('Foods already seeded: $count items');
      return;
    }
    
    debugPrint('Seeding foods database...');
    final foods = FoodSeedData.getVietnameseFoods();
    for (final food in foods) {
      await db.insert('foods', food, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    debugPrint('Seeded ${foods.length} foods');
  }
  
  /// Force reseed foods (for testing/updates)
  Future<void> reseedFoods() async {
    final db = await database;
    await db.delete('foods'); // Clear existing
    await _seedFoods(db);
  }
  
  /// Ensure foods are seeded (call this on app start)
  Future<void> ensureFoodsSeeded() async {
    final db = await database;
    await _seedFoods(db);
  }

  /// Force reseed nutrition database (for testing/updates)
  Future<void> reseedNutritionDatabase() async {
    try {
      final db = await database;
      await db.delete('nutrition_database'); // Clear existing
      await _seedNutritionDatabase(db);
      debugPrint('✅ Nutrition database reseeded successfully');
    } catch (e) {
      debugPrint('❌ Error reseeding nutrition database: $e');
    }
  }

  /// Seed nutrition database with Vietnamese foods
  /// 
  /// Pre-populates nutrition_database table with common Vietnamese dishes.
  /// Only runs once on first database creation.
  Future<void> _seedNutritionDatabase(Database db) async {
    try {
      // Check if nutrition data already exists
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM nutrition_database'),
      );
      
      if (count != null && count > 0) {
        debugPrint('📊 Nutrition database already seeded: $count items');
        return;
      }
      
      debugPrint('📊 Seeding nutrition database with Vietnamese foods...');
      
      // Import seed data
      final seedData = await _getVietnameseNutritionSeedData();
      
      // Insert all nutrition data
      for (final nutrition in seedData) {
        await db.insert(
          'nutrition_database',
          nutrition.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      
      debugPrint('✅ Seeded ${seedData.length} Vietnamese foods to nutrition database');
    } catch (e) {
      debugPrint('❌ Error seeding nutrition database: $e');
      // Don't throw - app should still work without seed data
    }
  }

  /// Get Vietnamese nutrition seed data
  /// 
  /// Returns list of pre-defined Vietnamese foods with nutrition info.
  /// This is imported from seed file to keep database_helper clean.
  Future<List<dynamic>> _getVietnameseNutritionSeedData() async {
    try {
      // Get seed data from VietnameseNutritionSeed class
      return VietnameseNutritionSeed.getVietnameseFoods();
    } catch (e) {
      debugPrint('⚠️ Could not load nutrition seed data: $e');
      return [];
    }
  }

  /// Upgrade database (for future versions)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('📦 Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 2) {
      // Version 2: Add new columns to meal_entries table
      debugPrint('🔄 Migrating to v2: Adding new columns to meal_entries...');
      
      try {
        // Check if columns exist
        final result = await db.rawQuery('PRAGMA table_info(meal_entries)');
        final columnNames = result.map((col) => col['name'] as String).toList();
        
        // Add food_id if not exists
        if (!columnNames.contains('food_id')) {
          await db.execute('ALTER TABLE meal_entries ADD COLUMN food_id INTEGER');
          debugPrint('✅ Added food_id column');
        }
        
        // Add serving_size if not exists
        if (!columnNames.contains('serving_size')) {
          await db.execute('ALTER TABLE meal_entries ADD COLUMN serving_size REAL DEFAULT 100.0');
          debugPrint('✅ Added serving_size column');
        }
        
        // Add servings if not exists
        if (!columnNames.contains('servings')) {
          await db.execute('ALTER TABLE meal_entries ADD COLUMN servings REAL DEFAULT 1.0');
          debugPrint('✅ Added servings column');
        }
        
        // Note: SQLite doesn't support changing PRIMARY KEY type from INTEGER to TEXT
        // So we keep the old id as INTEGER for existing rows
        // New inserts will still work as TEXT (SQLite is flexible with types)
        
        debugPrint('✅ Migration to v2 completed successfully');
      } catch (e) {
        debugPrint('❌ Migration error: $e');
        // If migration fails, it's safer to just delete and recreate
        debugPrint('⚠️ Falling back to database recreation...');
        throw Exception('Migration failed. Please delete and rebuild database.');
      }
    }
    
    if (oldVersion < 3) {
      // Version 3: Add image_path column for AI-captured images
      debugPrint('🔄 Migrating to v3: Adding image_path column...');
      
      try {
        // Check if column exists
        final result = await db.rawQuery('PRAGMA table_info(meal_entries)');
        final columnNames = result.map((col) => col['name'] as String).toList();
        
        // Rename image_url to image_path if exists, or add image_path
        if (columnNames.contains('image_url') && !columnNames.contains('image_path')) {
          // SQLite doesn't support RENAME COLUMN directly in old versions
          // So we just add image_path and copy data
          await db.execute('ALTER TABLE meal_entries ADD COLUMN image_path TEXT');
          await db.execute('UPDATE meal_entries SET image_path = image_url WHERE image_url IS NOT NULL');
          debugPrint('✅ Migrated image_url to image_path');
        } else if (!columnNames.contains('image_path')) {
          await db.execute('ALTER TABLE meal_entries ADD COLUMN image_path TEXT');
          debugPrint('✅ Added image_path column');
        }
        
        debugPrint('✅ Migration to v3 completed successfully');
      } catch (e) {
        debugPrint('❌ Migration error: $e');
        debugPrint('⚠️ Falling back to database recreation...');
        throw Exception('Migration failed. Please delete and rebuild database.');
      }
    }
    
    if (oldVersion < 4) {
      // Version 4: Add user_foods and favorite_foods tables
      debugPrint('🔄 Migrating to v4: Adding user_foods and favorite_foods tables...');
      
      try {
        // Check if tables already exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('user_foods', 'favorite_foods')"
        );
        
        if (!tables.any((t) => t['name'] == 'user_foods')) {
          // Create user_foods table
          await db.execute('''
            CREATE TABLE user_foods (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              name TEXT NOT NULL,
              portion_size REAL DEFAULT 100,
              serving_size REAL,
              calories REAL NOT NULL,
              protein REAL DEFAULT 0,
              carbs REAL DEFAULT 0,
              fat REAL DEFAULT 0,
              image_path TEXT,
              source TEXT CHECK(source IN ('manual', 'ai_scan')) NOT NULL,
              ai_confidence REAL,
              is_editable INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT,
              last_used_at TEXT,
              usage_count INTEGER DEFAULT 0
            )
          ''');
          
          // Create indexes for user_foods
          await db.execute('CREATE INDEX idx_user_foods_user ON user_foods(user_id)');
          await db.execute('CREATE INDEX idx_user_foods_usage ON user_foods(user_id, usage_count DESC)');
          await db.execute('CREATE INDEX idx_user_foods_name ON user_foods(user_id, name)');
          
          debugPrint('✅ Created user_foods table with indexes');
        }
        
        if (!tables.any((t) => t['name'] == 'favorite_foods')) {
          // Create favorite_foods table
          await db.execute('''
            CREATE TABLE favorite_foods (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              food_id TEXT NOT NULL,
              food_source TEXT NOT NULL CHECK(food_source IN ('builtin', 'custom')),
              added_at TEXT NOT NULL,
              last_used_at TEXT,
              usage_count INTEGER DEFAULT 0,
              UNIQUE(user_id, food_id, food_source)
            )
          ''');
          
          // Create indexes for favorite_foods
          await db.execute('CREATE INDEX idx_favorites_user ON favorite_foods(user_id, usage_count DESC)');
          await db.execute('CREATE INDEX idx_favorites_food ON favorite_foods(user_id, food_id, food_source)');
          
          debugPrint('✅ Created favorite_foods table with indexes');
        }
        
        debugPrint('✅ Migration to v4 completed successfully');
      } catch (e) {
        debugPrint('❌ Migration v4 error: $e');
        // Log but don't throw - existing users should still work
        debugPrint('⚠️ Please check database integrity');
      }
    }
    
    if (oldVersion < 5) {
      // Version 5: Add nutrition_database table for AI food recognition
      debugPrint('🔄 Migrating to v5: Adding nutrition_database table...');
      
      try {
        // Check if table already exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='nutrition_database'"
        );
        
        if (tables.isEmpty) {
          // Create nutrition_database table
          await db.execute('''
            CREATE TABLE nutrition_database (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_name TEXT NOT NULL UNIQUE,
              food_name_en TEXT,
              food_name_vi TEXT,
              
              -- Nutrition per 100g (standardized)
              calories_per_100g REAL NOT NULL,
              protein_per_100g REAL DEFAULT 0,
              carbs_per_100g REAL DEFAULT 0,
              fat_per_100g REAL DEFAULT 0,
              fiber_per_100g REAL DEFAULT 0,
              
              -- Serving sizes (JSON array)
              serving_sizes TEXT,
              
              -- Metadata
              source TEXT DEFAULT 'manual' CHECK(source IN ('manual', 'fatsecret', 'usda', 'user')),
              category TEXT,
              is_verified INTEGER DEFAULT 0,
              usage_count INTEGER DEFAULT 0,
              last_used TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          
          // Create indexes for nutrition_database
          await db.execute('CREATE INDEX idx_nutrition_food_name ON nutrition_database(food_name)');
          await db.execute('CREATE INDEX idx_nutrition_category ON nutrition_database(category)');
          await db.execute('CREATE INDEX idx_nutrition_usage ON nutrition_database(usage_count DESC)');
          
          debugPrint('✅ Created nutrition_database table with indexes');
        }
        
        debugPrint('✅ Migration to v5 completed successfully');
      } catch (e) {
        debugPrint('❌ Migration v5 error: $e');
        debugPrint('⚠️ Please check database integrity');
      }
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calocount.db');
    await deleteDatabase(path);
    _database = null;
  }

  // ==================== USER OPERATIONS ====================

  /// Insert user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get user by Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );
    debugPrint('🔍 [DatabaseHelper] getUserByFirebaseUid: $firebaseUid → ${results.isNotEmpty ? "Found user ID ${results.first['id']}" : "Not found"}');
    return results.isNotEmpty ? results.first : null;
  }

  /// Get first user (assuming single user app)
  Future<Map<String, dynamic>?> getFirstUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Update user
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete user
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== WEIGHT HISTORY OPERATIONS ====================

  /// Insert weight history
  Future<int> insertWeightHistory(Map<String, dynamic> weightHistory) async {
    final db = await database;
    return await db.insert('weight_history', weightHistory);
  }

  /// Get weight history by user
  Future<List<Map<String, dynamic>>> getWeightHistory(int userId, {int? limit}) async {
    final db = await database;
    return await db.query(
      'weight_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  // ==================== FOOD OPERATIONS ====================

  /// Insert food
  Future<int> insertFood(Map<String, dynamic> food) async {
    final db = await database;
    return await db.insert('foods', food);
  }

  /// Get all foods
  Future<List<Map<String, dynamic>>> getAllFoods() async {
    final db = await database;
    return await db.query('foods', orderBy: 'name ASC');
  }

  /// Get a single food by ID
  Future<Map<String, dynamic>?> getFood(int id) async {
    final db = await database;
    final results = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get foods by category
  Future<List<Map<String, dynamic>>> getFoodsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
  }

  /// Search foods
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
  }

  /// Get favorite foods
  Future<List<Map<String, dynamic>>> getFavoriteFoods() async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
  }

  /// Update food favorite status
  Future<int> updateFoodFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'foods',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== MEAL ENTRY OPERATIONS ====================

  /// Insert meal entry
  Future<int> insertMealEntry(Map<String, dynamic> mealEntry) async {
    final db = await database;
    // Use INSERT OR REPLACE to handle duplicates from Firestore sync
    return await db.insert(
      'meal_entries',
      mealEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get meal entries by date
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<List<Map<String, dynamic>>> getMealEntriesByDate(int userId, String date) async {
    final db = await database;
    return await db.query(
      'meal_entries',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      orderBy: 'time ASC',
    );
  }

  /// Get meal entries by date range
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<List<Map<String, dynamic>>> getMealEntriesByDateRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.query(
      'meal_entries',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date DESC, time DESC',
    );
  }

  /// Get meal entries by type and date
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<List<Map<String, dynamic>>> getMealEntriesByTypeAndDate(
    int userId,
    String mealType,
    String date,
  ) async {
    final db = await database;
    return await db.query(
      'meal_entries',
      where: 'user_id = ? AND meal_type = ? AND date = ?',
      whereArgs: [userId, mealType, date],
      orderBy: 'time ASC',
    );
  }

  /// Get all meal entries (for history screen)
  /// 
  /// Returns all meal entries sorted by date and time (newest first)
  /// 
  /// ⚠️ WARNING: This loads ALL meals into memory. Use getMealsPaginated() instead
  /// for large datasets to avoid memory issues.
  @Deprecated('Use getMealsPaginated() for better performance')
  Future<List<Map<String, dynamic>>> getAllMeals() async {
    final db = await database;
    return await db.query(
      'meal_entries',
      orderBy: 'date DESC, time DESC',
    );
  }

  /// Get all meal entries (for sync purposes)
  /// 
  /// WARNING: This loads ALL meals into memory. Only use for:
  /// - Initial sync to cloud
  /// - Backup operations
  /// - Small datasets
  /// 
  /// For displaying meals in UI, use getMealsPaginated() instead.
  Future<List<Map<String, dynamic>>> getAllMealEntriesForSync() async {
    final db = await database;
    return await db.query(
      'meal_entries',
      orderBy: 'date DESC, time DESC',
    );
  }

  /// Get meals with pagination (RECOMMENDED for history screen)
  /// 
  /// Supports:
  /// - User isolation (REQUIRED)
  /// - Pagination with limit/offset
  /// - Date range filtering
  /// - Meal type filtering
  /// - Search by food name
  /// 
  /// Parameters:
  /// - [userId]: User ID to filter meals (REQUIRED for data isolation)
  /// - [limit]: Number of meals to return (default: 50)
  /// - [offset]: Number of meals to skip (default: 0)
  /// - [startDate]: Filter meals from this date onwards (optional)
  /// - [endDate]: Filter meals up to this date (optional)
  /// - [mealType]: Filter by meal type (breakfast, lunch, dinner, snack) (optional)
  /// - [searchQuery]: Search in food name (optional)
  /// 
  /// Returns: List of meal entry maps, sorted by date DESC, time DESC
  /// 
  /// Example:
  /// ```dart
  /// // Get first 50 meals for user
  /// final firstPage = await getMealsPaginated(userId: 1, limit: 50, offset: 0);
  /// 
  /// // Get next 50 meals
  /// final secondPage = await getMealsPaginated(userId: 1, limit: 50, offset: 50);
  /// 
  /// // Search with filter
  /// final results = await getMealsPaginated(
  ///   userId: 1,
  ///   limit: 50,
  ///   searchQuery: 'Phở',
  ///   mealType: 'breakfast',
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getMealsPaginated({
    required int userId,
    int limit = 50,
    int offset = 0,
    String? startDate,
    String? endDate,
    String? mealType,
    String? searchQuery,
  }) async {
    final db = await database;
    
    // Build WHERE clause dynamically
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    // ⚠️ CRITICAL: Always filter by userId for data isolation
    whereConditions.add('user_id = ?');
    whereArgs.add(userId);
    
    // Date range filter
    if (startDate != null && endDate != null) {
      whereConditions.add('date >= ? AND date <= ?');
      whereArgs.add(startDate);
      whereArgs.add(endDate);
    } else if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate);
    } else if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate);
    }
    
    // Meal type filter
    if (mealType != null && mealType.isNotEmpty) {
      whereConditions.add('LOWER(meal_type) = ?');
      whereArgs.add(mealType.toLowerCase());
    }
    
    // Search filter (case-insensitive)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('LOWER(food_name) LIKE ?');
      whereArgs.add('%${searchQuery.toLowerCase()}%');
    }
    
    // Combine WHERE conditions
    final whereClause = whereConditions.join(' AND ');
    
    // Execute query with pagination
    return await db.query(
      'meal_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, time DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get total count of meals (for pagination calculation)
  /// 
  /// Supports same filters as getMealsPaginated
  /// Useful for showing "X of Y meals" or calculating total pages
  Future<int> getMealsCount({
    String? startDate,
    String? endDate,
    String? mealType,
    String? searchQuery,
  }) async {
    final db = await database;
    
    // Build WHERE clause (same logic as getMealsPaginated)
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      whereConditions.add('date >= ? AND date <= ?');
      whereArgs.add(startDate);
      whereArgs.add(endDate);
    } else if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate);
    } else if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate);
    }
    
    if (mealType != null && mealType.isNotEmpty) {
      whereConditions.add('LOWER(meal_type) = ?');
      whereArgs.add(mealType.toLowerCase());
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('LOWER(food_name) LIKE ?');
      whereArgs.add('%${searchQuery.toLowerCase()}%');
    }
    
    final whereClause = whereConditions.isNotEmpty 
        ? whereConditions.join(' AND ')
        : null;
    
    // Count query
    final result = await db.query(
      'meal_entries',
      columns: ['COUNT(*) as count'],
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get meals by date (alias for getMealEntriesByDate for consistency)
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<List<Map<String, dynamic>>> getMealsByDate(int userId, String date) async {
    return await getMealEntriesByDate(userId, date);
  }

  /// Update meal entry
  Future<int> updateMealEntry(Map<String, dynamic> mealEntry) async {
    final db = await database;
    final id = mealEntry['id'];
    if (id == null) {
      throw ArgumentError('Meal entry must have an id to update');
    }
    return await db.update(
      'meal_entries',
      mealEntry,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete meal entry
  Future<int> deleteMealEntry(String id) async {
    final db = await database;
    return await db.delete(
      'meal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== WATER INTAKE OPERATIONS ====================

  /// Insert or update water intake
  Future<int> upsertWaterIntake(Map<String, dynamic> waterIntake) async {
    final db = await database;
    return await db.insert(
      'water_intake',
      waterIntake,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get water intake by date
  Future<Map<String, dynamic>?> getWaterIntakeByDate(int userId, String date) async {
    final db = await database;
    final results = await db.query(
      'water_intake',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ==================== STATISTICS ====================

  /// Get total calories for date
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<double> getTotalCaloriesByDate(int userId, String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(calories * portion_multiplier) as total
      FROM meal_entries
      WHERE user_id = ? AND date = ?
    ''', [userId, date]);

    return result.first['total'] as double? ?? 0.0;
  }

  /// Get daily summary
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<Map<String, dynamic>> getDailySummary(int userId, String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(calories * portion_multiplier) as total_calories,
        SUM(protein * portion_multiplier) as total_protein,
        SUM(carbs * portion_multiplier) as total_carbs,
        SUM(fat * portion_multiplier) as total_fat,
        COUNT(*) as meal_count
      FROM meal_entries
      WHERE user_id = ? AND date = ?
    ''', [userId, date]);

    return result.first;
  }

  // ==================== USER FOODS CRUD ====================
  // CRUD operations for user-created foods (món ăn của tôi)

  /// Insert a new user food
  /// 
  /// Creates a custom food entry that user can edit later
  /// Source can be 'manual' (user typed) or 'ai_scan' (from camera)
  /// 
  /// Example:
  /// ```dart
  /// await db.insertUserFood({
  ///   'id': uuid.v4(),
  ///   'user_id': 'user_1',
  ///   'name': 'Phở gà nhà tôi',
  ///   'calories': 150,
  ///   'protein': 12,
  ///   'carbs': 20,
  ///   'fat': 5,
  ///   'source': 'manual',
  ///   'created_at': DateTime.now().toIso8601String(),
  /// });
  /// ```
  Future<int> insertUserFood(Map<String, dynamic> food) async {
    final db = await database;
    return await db.insert(
      'user_foods',
      food,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all user foods for a specific user
  /// 
  /// Returns list sorted by usage count (most used first)
  /// Optionally filter by search query
  Future<List<Map<String, dynamic>>> getUserFoods(
    String userId, {
    String? searchQuery,
    String? orderBy,
  }) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'user_id = ? AND LOWER(name) LIKE ?';
      whereArgs = [userId, '%${searchQuery.toLowerCase()}%'];
    } else {
      whereClause = 'user_id = ?';
      whereArgs = [userId];
    }
    
    return await db.query(
      'user_foods',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'usage_count DESC, last_used_at DESC',
    );
  }

  /// Get a specific user food by ID
  Future<Map<String, dynamic>?> getUserFood(String foodId) async {
    final db = await database;
    final results = await db.query(
      'user_foods',
      where: 'id = ?',
      whereArgs: [foodId],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  /// Update user food
  /// 
  /// Only editable foods can be updated (is_editable = 1)
  Future<int> updateUserFood(Map<String, dynamic> food) async {
    final db = await database;
    final id = food['id'];
    if (id == null) {
      throw ArgumentError('Food must have an id to update');
    }
    
    // Add updated_at timestamp
    food['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      'user_foods',
      food,
      where: 'id = ? AND is_editable = 1', // Only update if editable
      whereArgs: [id],
    );
  }

  /// Delete user food
  /// 
  /// Also removes from favorites if exists
  Future<int> deleteUserFood(String foodId) async {
    final db = await database;
    
    // First, remove from favorites
    await db.delete(
      'favorite_foods',
      where: 'food_id = ? AND food_source = ?',
      whereArgs: [foodId, 'custom'],
    );
    
    // Then delete the food itself
    return await db.delete(
      'user_foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );
  }

  /// Increment usage count for user food
  /// 
  /// Called when user adds this food to a meal
  /// Updates usage_count and last_used_at automatically
  Future<void> incrementUserFoodUsage(String foodId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE user_foods 
      SET usage_count = usage_count + 1,
          last_used_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), foodId]);
  }

  // ==================== FAVORITES CRUD ====================
  // CRUD operations for favorite foods (món yêu thích)

  /// Add food to favorites
  /// 
  /// Can add both built-in foods and custom user foods
  /// foodSource: 'builtin' or 'custom'
  /// 
  /// Example:
  /// ```dart
  /// // Add built-in food
  /// await db.addFavorite('user_1', '123', 'builtin');
  /// 
  /// // Add custom food
  /// await db.addFavorite('user_1', 'uuid-abc', 'custom');
  /// ```
  Future<int> addFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final db = await database;
    
    return await db.insert(
      'favorite_foods',
      {
        'id': '${userId}_${foodId}_$foodSource', // Composite ID
        'user_id': userId,
        'food_id': foodId,
        'food_source': foodSource,
        'added_at': DateTime.now().toIso8601String(),
        'usage_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  /// Remove food from favorites
  Future<int> removeFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final db = await database;
    
    return await db.delete(
      'favorite_foods',
      where: 'user_id = ? AND food_id = ? AND food_source = ?',
      whereArgs: [userId, foodId, foodSource],
    );
  }

  /// Check if food is favorited
  Future<bool> isFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final db = await database;
    
    final results = await db.query(
      'favorite_foods',
      where: 'user_id = ? AND food_id = ? AND food_source = ?',
      whereArgs: [userId, foodId, foodSource],
      limit: 1,
    );
    
    return results.isNotEmpty;
  }

  /// Get all favorites for a user
  /// 
  /// Returns list of favorite records (not the actual foods)
  /// Join with foods/user_foods tables to get full details
  Future<List<Map<String, dynamic>>> getFavorites(
    String userId, {
    String? foodSource,
  }) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (foodSource != null) {
      whereClause = 'user_id = ? AND food_source = ?';
      whereArgs = [userId, foodSource];
    } else {
      whereClause = 'user_id = ?';
      whereArgs = [userId];
    }
    
    return await db.query(
      'favorite_foods',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'usage_count DESC, last_used_at DESC',
    );
  }

  /// Increment favorite usage count
  /// 
  /// Called when user adds a favorite food to a meal
  Future<void> incrementFavoriteUsage(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE favorite_foods 
      SET usage_count = usage_count + 1,
          last_used_at = ?
      WHERE user_id = ? AND food_id = ? AND food_source = ?
    ''', [
      DateTime.now().toIso8601String(),
      userId,
      foodId,
      foodSource,
    ]);
  }

  /// Get favorite foods with full details (JOIN query)
  /// 
  /// Returns combined data from favorites + foods/user_foods
  /// Useful for displaying favorite foods list with all info
  Future<List<Map<String, dynamic>>> getFavoriteFoodsWithDetails(
    String userId,
  ) async {
    final db = await database;
    
    // Get built-in favorites (join with foods table)
    final builtinFavorites = await db.rawQuery('''
      SELECT 
        f.id as food_id,
        f.name,
        f.calories,
        f.protein,
        f.carbs,
        f.fat,
        f.portion_size,
        f.image_url,
        'builtin' as source,
        fav.usage_count,
        fav.last_used_at,
        fav.added_at,
        0 as is_editable
      FROM favorite_foods fav
      INNER JOIN foods f ON f.id = CAST(fav.food_id AS INTEGER)
      WHERE fav.user_id = ? AND fav.food_source = 'builtin'
    ''', [userId]);
    
    // Get custom favorites (join with user_foods table)
    final customFavorites = await db.rawQuery('''
      SELECT 
        uf.id as food_id,
        uf.name,
        uf.calories,
        uf.protein,
        uf.carbs,
        uf.fat,
        uf.portion_size,
        uf.image_path as image_url,
        uf.source,
        fav.usage_count,
        fav.last_used_at,
        fav.added_at,
        uf.is_editable
      FROM favorite_foods fav
      INNER JOIN user_foods uf ON uf.id = fav.food_id
      WHERE fav.user_id = ? AND fav.food_source = 'custom'
    ''', [userId]);
    
    // Combine and sort by usage_count
    final combined = [...builtinFavorites, ...customFavorites];
    combined.sort((a, b) {
      final aCount = (a['usage_count'] as int?) ?? 0;
      final bCount = (b['usage_count'] as int?) ?? 0;
      return bCount.compareTo(aCount); // DESC
    });
    
    return combined;
  }

  /// Get favorite statistics
  /// 
  /// Returns summary data for favorites screen
  Future<Map<String, int>> getFavoriteStats(String userId) async {
    final db = await database;
    
    // Count total favorites
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM favorite_foods WHERE user_id = ?
    ''', [userId]);
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    // Count custom favorites
    final customResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM favorite_foods 
      WHERE user_id = ? AND food_source = 'custom'
    ''', [userId]);
    final custom = Sqflite.firstIntValue(customResult) ?? 0;
    
    // Count built-in favorites
    final builtin = total - custom;
    
    return {
      'total': total,
      'custom': custom,
      'builtin': builtin,
    };
  }

  // ==================== DATA MANAGEMENT ====================
  
  /// Clear all data from database (for current user only)
  /// 
  /// Deletes all records from all tables FOR THE SPECIFIED USER.
  /// Use this when user signs out to prevent data leakage between users.
  /// 
  /// Parameters:
  /// - [firebaseUid]: The Firebase UID of the user whose data should be cleared.
  ///                  If null, clears ALL data (use for emergency/debug only).
  /// 
  /// Tables cleared:
  /// - users: NOT CLEARED (kept for re-login) ⚠️
  /// - meal_entries: Cleared (filtered by user_id)
  /// - user_foods: Cleared (filtered by user_id)
  /// - favorite_foods: Cleared (filtered by user_id)
  /// - water_intake: Cleared (filtered by user_id)
  /// 
  /// Note: This does NOT delete the database file or tables structure,
  /// only the data inside them.
  Future<void> clearAllData({String? firebaseUid}) async {
    final db = await database;
    
    if (firebaseUid == null) {
      // ⚠️ WARNING: Clear ALL data (no filter)
      debugPrint('⚠️ [DatabaseHelper] Clearing ALL data (no user filter)...');
      
      await db.transaction((txn) async {
        // NOTE: We keep users table intact so users can sign back in
        // await txn.delete('users'); // DON'T delete users!
        await txn.delete('meal_entries');
        await txn.delete('user_foods');
        await txn.delete('favorite_foods');
        await txn.delete('water_intake');
      });
      
      debugPrint('✅ [DatabaseHelper] All data cleared (users table kept)');
      return;
    }
    
    // ✅ Clear data for specific Firebase UID
    debugPrint('🗑️ [DatabaseHelper] Clearing data for Firebase UID: $firebaseUid');
    
    // First, get the local userId from firebase_uid
    final userMap = await getUserByFirebaseUid(firebaseUid);
    if (userMap == null) {
      debugPrint('⚠️ [DatabaseHelper] No user found with firebase_uid: $firebaseUid');
      return;
    }
    
    final userId = userMap['id'] as int;
    debugPrint('🔍 [DatabaseHelper] Found local userId: $userId for firebase_uid: $firebaseUid');
    
    await db.transaction((txn) async {
      // IMPORTANT: DON'T delete from users table!
      // We need to keep user profile for re-login
      // await txn.delete('users', where: 'firebase_uid = ?', whereArgs: [firebaseUid]);
      debugPrint('  ℹ️ Keeping user profile (for re-login)');
      
      // Clear meal entries for this user
      // Note: meal_entries.user_id is TEXT (firebase_uid or local_id as string)
      await txn.delete('meal_entries', where: 'user_id = ?', whereArgs: [userId.toString()]);
      debugPrint('  ✅ Cleared meal_entries for user $userId');
      
      // Clear user foods for this user
      await txn.delete('user_foods', where: 'user_id = ?', whereArgs: [userId.toString()]);
      debugPrint('  ✅ Cleared user_foods for user $userId');
      
      // Clear favorites for this user
      await txn.delete('favorite_foods', where: 'user_id = ?', whereArgs: [userId.toString()]);
      debugPrint('  ✅ Cleared favorite_foods for user $userId');
      
      // Clear water intake for this user
      await txn.delete('water_intake', where: 'user_id = ?', whereArgs: [userId]);
      debugPrint('  ✅ Cleared water_intake for user $userId');
    });
    
    debugPrint('✅ [DatabaseHelper] All data cleared for user (profile kept for re-login)');
  }
}

