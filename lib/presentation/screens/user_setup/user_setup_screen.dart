import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import 'steps/basic_info_step.dart';
import 'steps/goal_selection_step.dart';
import 'steps/target_weight_step.dart';
import 'steps/activity_level_step.dart';
import 'steps/summary_step.dart';

/// User Setup Screen with multiple steps
class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5; // BasicInfo → Goal → Target → Activity → Summary

  // User data (name will be fetched from Firebase User)
  final Map<String, dynamic> _userData = {
    // 'name' removed - will be fetched from Firebase User displayName
    'gender': 'male',
    'age': 25,
    'height': 170.0,
    'weight': 70.0,
    'goalType': 'maintain',
    'targetWeight': null,
    'weeklyGoal': 0.5,
    'activityLevel': 'moderate',
  };

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateUserData(Map<String, dynamic> data) {
    setState(() {
      _userData.addAll(data);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupTitle),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Basic Info (Gender, Age, Height, Weight)
                  BasicInfoStep(
                    userData: _userData,
                    onNext: (data) {
                      _updateUserData(data);
                      _nextStep();
                    },
                  ),
                  // Step 2: Goal Selection
                  GoalSelectionStep(
                    userData: _userData,
                    onNext: (data) {
                      _updateUserData(data);
                      // Skip target weight if maintaining
                      if (data['goalType'] == 'maintain') {
                        setState(() {
                          _currentStep += 2; // Skip target weight step
                        });
                        _pageController.animateToPage(
                          3, // Go to activity level (index 3 now)
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _nextStep();
                      }
                    },
                  ),
                  // Step 3: Target Weight (conditional)
                  TargetWeightStep(
                    userData: _userData,
                    onNext: (data) {
                      _updateUserData(data);
                      _nextStep();
                    },
                  ),
                  // Step 4: Activity Level
                  ActivityLevelStep(
                    userData: _userData,
                    onNext: (data) {
                      _updateUserData(data);
                      _nextStep();
                    },
                  ),
                  // Step 5: Summary
                  SummaryStep(
                    userData: _userData,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Bước ${_currentStep + 1}/$_totalSteps',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

