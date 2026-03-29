/// User Model
class UserModel {
  final int? id;
  final String? firebaseUid; // Firebase UID for data isolation
  final String name;
  final String gender; // 'male' or 'female'
  final int age;
  final double heightCm;
  final double weightKg;
  final String goalType; // 'lose', 'maintain', 'gain'
  final double? targetWeightKg;
  final double weeklyGoalKg;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'extra_active'
  final double bmi;
  final double bmr;
  final double tdee;
  final double calorieGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    this.firebaseUid,
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goalType,
    this.targetWeightKg,
    required this.weeklyGoalKg,
    required this.activityLevel,
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'name': name,
      'gender': gender,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal_type': goalType,
      'target_weight_kg': targetWeightKg,
      'weekly_goal_kg': weeklyGoalKg,
      'activity_level': activityLevel,
      'bmi': bmi,
      'bmr': bmr,
      'tdee': tdee,
      'calorie_goal': calorieGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      firebaseUid: map['firebase_uid'] as String?,
      name: map['name'] as String,
      gender: map['gender'] as String,
      age: map['age'] as int,
      heightCm: map['height_cm'] as double,
      weightKg: map['weight_kg'] as double,
      goalType: map['goal_type'] as String,
      targetWeightKg: map['target_weight_kg'] as double?,
      weeklyGoalKg: map['weekly_goal_kg'] as double,
      activityLevel: map['activity_level'] as String,
      bmi: map['bmi'] as double,
      bmr: map['bmr'] as double,
      tdee: map['tdee'] as double,
      calorieGoal: map['calorie_goal'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Copy with
  UserModel copyWith({
    int? id,
    String? name,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? goalType,
    double? targetWeightKg,
    double? weeklyGoalKg,
    String? activityLevel,
    double? bmi,
    double? bmr,
    double? tdee,
    double? calorieGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weeklyGoalKg: weeklyGoalKg ?? this.weeklyGoalKg,
      activityLevel: activityLevel ?? this.activityLevel,
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, gender: $gender, age: $age, '
        'height: $heightCm cm, weight: $weightKg kg, goal: $goalType, '
        'calorieGoal: $calorieGoal kcal)';
  }
}

/// Weight History Model
class WeightHistoryModel {
  final int? id;
  final int userId;
  final double weightKg;
  final DateTime date;
  final String? note;

  WeightHistoryModel({
    this.id,
    required this.userId,
    required this.weightKg,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'weight_kg': weightKg,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory WeightHistoryModel.fromMap(Map<String, dynamic> map) {
    return WeightHistoryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      weightKg: map['weight_kg'] as double,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}

