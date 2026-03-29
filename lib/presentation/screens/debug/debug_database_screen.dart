import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/database_helper.dart';

/// Debug Screen - For testing database operations
class DebugDatabaseScreen extends StatefulWidget {
  const DebugDatabaseScreen({super.key});

  @override
  State<DebugDatabaseScreen> createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  String _status = 'Ready';
  bool _isProcessing = false;

  Future<void> _deleteAndRebuildDatabase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Đang xóa database...';
    });

    try {
      // Delete database
      await DatabaseHelper.instance.deleteDB();
      setState(() => _status = 'Database đã xóa. Đang rebuild...');

      // Rebuild will happen automatically on next access
      await DatabaseHelper.instance.ensureFoodsSeeded();
      
      // Check count
      final foods = await DatabaseHelper.instance.getAllFoods();
      
      setState(() {
        _status = 'Hoàn thành! Database có ${foods.length} món ăn';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database đã được rebuild với ${foods.length} món ăn!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkDatabaseStatus() async {
    setState(() {
      _isProcessing = true;
      _status = 'Đang kiểm tra...';
    });

    try {
      final foods = await DatabaseHelper.instance.getAllFoods();
      final users = await DatabaseHelper.instance.getFirstUser();
      
      setState(() {
        _status = 'Foods: ${foods.length}\nUsers: ${users != null ? 1 : 0}';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Database'),
        backgroundColor: AppColors.error,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚠️ Debug Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Chỉ dùng khi cần fix database',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Check Status Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _checkDatabaseStatus,
              icon: const Icon(Icons.info_outline),
              label: const Text('Kiểm tra Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppColors.info,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delete & Rebuild Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _deleteAndRebuildDatabase,
              icon: const Icon(Icons.refresh),
              label: const Text('Xóa & Rebuild Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppColors.error,
              ),
            ),
            
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

