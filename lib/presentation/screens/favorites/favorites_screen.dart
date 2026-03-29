import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/unified_food_model.dart';
import '../../providers/food_provider.dart';
import '../../widgets/unified_food_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import '../my_foods/create_food_screen.dart';
import '../my_foods/edit_food_screen.dart';

/// Favorites Screen
/// 
/// Main screen for "Món Yêu Thích" feature
/// Contains 2 main tabs:
/// 1. Gợi ý - All favorites (mixed list)
/// 2. Món của tôi - Custom foods management
/// 
/// This screen is accessible from bottom navigation bar
/// 
/// Usage:
/// - Access via bottom nav tab
/// - View all favorite foods
/// - Manage custom foods (create/edit/delete)
/// - Quick add to meals
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    await Future.wait([
      provider.loadFavorites(),
      provider.loadMyFoods(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : const Text('⭐ Món Yêu Thích'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadData();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'Gợi ý'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Món của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildMyFoodsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'favorites_fab', // ✅ Unique hero tag to avoid conflicts
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateFoodScreen(),
            ),
          );
          
          if (result != null && mounted) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo món mới'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Build search field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Tìm kiếm...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (query) {
        if (_tabController.index == 0) {
          // Search in favorites
          final provider = Provider.of<FoodProvider>(context, listen: false);
          provider.loadFavorites(); // Reload with filter if needed
        } else {
          // Search in my foods
          final provider = Provider.of<FoodProvider>(context, listen: false);
          provider.loadMyFoods(searchQuery: query);
        }
      },
    );
  }

  /// Tab 1: All Favorites
  Widget _buildFavoritesTab() {
    return Consumer<FoodProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const ListLoadingSkeleton();
        }

        if (provider.error != null) {
          return ErrorDisplay(
            title: 'Lỗi tải dữ liệu',
            message: provider.error!,
            retryLabel: 'Thử lại',
            onRetry: _loadData,
          );
        }

        if (!provider.hasFavorites) {
          return NoFavoritesEmptyState(
            onAddPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFoodScreen(),
                ),
              );
              
              if (result != null && mounted) {
                _loadData();
              }
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              final food = provider.favorites[index];
              return UnifiedFoodCard(
                food: food,
                onTap: () {
                  // TODO: Quick add to meal dialog
                  _showAddToMealDialog(food);
                },
                onFavoriteToggle: () async {
                  await provider.toggleFavorite(food.id, food.foodSource);
                },
                onEdit: food.isEditable
                    ? () async {
                        // Navigate to edit screen
                        final userFood = food.asCustomFood;
                        if (userFood != null) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditFoodScreen(food: userFood),
                            ),
                          );
                          
                          if (result != null && mounted) {
                            _loadData();
                          }
                        }
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  /// Tab 2: My Foods
  Widget _buildMyFoodsTab() {
    return Consumer<FoodProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const ListLoadingSkeleton();
        }

        if (provider.error != null) {
          return ErrorDisplay(
            title: 'Lỗi tải dữ liệu',
            message: provider.error!,
            retryLabel: 'Thử lại',
            onRetry: _loadData,
          );
        }

        if (!provider.hasMyFoods) {
          return NoMyFoodsEmptyState(
            onCreatePressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFoodScreen(),
                ),
              );
              
              if (result != null && mounted) {
                _loadData();
              }
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            itemCount: provider.myFoods.length,
            itemBuilder: (context, index) {
              final food = provider.myFoods[index];
              
              // Convert to UnifiedFoodModel for display
              // Check if it's favorited
              final isFav = provider.favorites.any((f) => f.id == food.id);
              
              return UnifiedFoodCard(
                food: UnifiedFoodModel.fromCustom(food, isFavorite: isFav),
                onTap: () async {
                  // Navigate to edit
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFoodScreen(food: food),
                    ),
                  );
                  
                  if (result != null && mounted) {
                    _loadData();
                  }
                },
                onFavoriteToggle: () async {
                  await provider.toggleFavorite(food.id, 'custom');
                },
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFoodScreen(food: food),
                    ),
                  );
                  
                  if (result != null && mounted) {
                    _loadData();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Show dialog to quickly add food to a meal
  void _showAddToMealDialog(dynamic food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm vào bữa ăn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: AppColors.breakfast),
              title: const Text('Bữa Sáng'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to breakfast
              },
            ),
            ListTile(
              leading: const Icon(Icons.lunch_dining, color: AppColors.lunch),
              title: const Text('Bữa Trưa'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to lunch
              },
            ),
            ListTile(
              leading: const Icon(Icons.dinner_dining, color: AppColors.dinner),
              title: const Text('Bữa Tối'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to dinner
              },
            ),
            ListTile(
              leading: const Icon(Icons.cookie, color: AppColors.snack),
              title: const Text('Ăn Vặt'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to snack
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY STATES ====================

/// Empty state when no favorites
class NoFavoritesEmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const NoFavoritesEmptyState({
    super.key,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'Chưa có món yêu thích',
      message: 'Tap ⭐ ở các món ăn để thêm vào yêu thích\nvà truy cập nhanh hơn',
      actionLabel: 'Tạo món mới',
      onAction: onAddPressed,
    );
  }
}

/// Empty state when no custom foods
class NoMyFoodsEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const NoMyFoodsEmptyState({
    super.key,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.restaurant_menu,
      title: 'Chưa có món ăn nào',
      message: 'Tạo món ăn riêng của bạn với\nthông tin dinh dưỡng tùy chỉnh',
      actionLabel: 'Tạo món đầu tiên',
      onAction: onCreatePressed,
    );
  }
}

