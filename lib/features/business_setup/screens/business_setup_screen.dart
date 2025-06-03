// lib/features/business_setup/screens/business_setup_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/business_setup_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

// Import the widget files we'll create
import '../widgets/setup_progress_indicator.dart';
import '../widgets/business_info_step.dart';
import '../widgets/review_platforms_step.dart';
import '../widgets/final_step.dart';
import '../widgets/step_navigation.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({Key? key}) : super(key: key);

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _contentController;
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  
  // Platform links controllers
  final Map<String, TextEditingController> _reviewPlatformControllers = {
    'Google Business Profile': TextEditingController(),
    'Yelp': TextEditingController(),
    'Facebook': TextEditingController(),
    'TripAdvisor': TextEditingController(),
  };
  
  // Logo image data
  Uint8List? _logoImageBytes;
  String? _selectedCategory;
  bool _isLoading = false;

  // Step configuration
  final List<Map<String, String>> _steps = [
    {
      'title': 'Business Information',
      'subtitle': 'Tell customers who you are',
      'icon': '🏢',
    },
    {
      'title': 'Review Platform Links',
      'subtitle': 'Connect your existing profiles',
      'icon': '🔗',
    },
    {
      'title': 'Ready to Launch!',
      'subtitle': 'Complete your setup',
      'icon': '🚀',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Start initial animations
    _progressController.value = 1 / _steps.length;
    _contentController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  void _initializeFormData() {
    final provider = Provider.of<BusinessSetupProvider>(context, listen: false);
    
    if (provider.name.isNotEmpty) {
      _businessNameController.text = provider.name;
    }
    
    if (provider.description.isNotEmpty) {
      _businessDescriptionController.text = provider.description;
    }
    
    final reviewLinks = provider.reviewLinks;
    for (final platform in _reviewPlatformControllers.keys) {
      if (reviewLinks.containsKey(platform)) {
        _reviewPlatformControllers[platform]!.text = reviewLinks[platform]!;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    for (final controller in _reviewPlatformControllers.values) {
      controller.dispose();
    }
    _progressController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_validateBusinessInfo()) return;
      _saveBusinessInfo();
    } else if (_currentStep == 1) {
      _saveReviewLinks();
    }
    
    if (_currentStep < _steps.length - 1) {
      _animateToStep(_currentStep + 1);
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animateToStep(_currentStep - 1);
    }
  }

  void _animateToStep(int step) {
    setState(() => _currentStep = step);
    _contentController.reset();
    
    _progressController.animateTo(
      (step + 1) / _steps.length,
      curve: Curves.easeOut,
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
  }

  bool _validateBusinessInfo() {
    if (_businessNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Business name is required');
      return false;
    }
    return true;
  }

  void _saveBusinessInfo() {
    final provider = Provider.of<BusinessSetupProvider>(context, listen: false);
    provider.setBusinessInfo(
      name: _businessNameController.text.trim(),
      description: _businessDescriptionController.text.trim(),
    );
  }

  void _saveReviewLinks() {
    final provider = Provider.of<BusinessSetupProvider>(context, listen: false);
    for (final platform in _reviewPlatformControllers.keys) {
      final link = _reviewPlatformControllers[platform]!.text.trim();
      if (link.isNotEmpty) {
        provider.setReviewLink(platform, link);
      } else {
        provider.removeReviewLink(platform);
      }
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    
    try {
      final businessProvider = Provider.of<BusinessSetupProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      _saveBusinessInfo();
      _saveReviewLinks();
      
      await businessProvider.saveBusinessSetup();
      await OnboardingService.setBusinessSetupCompleted();
      await authProvider.updateUserSetupStatus(true);
      await authProvider.reloadUser();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _getCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return BusinessInfoStep(
          nameController: _businessNameController,
          descriptionController: _businessDescriptionController,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (value) {
            setState(() => _selectedCategory = value);
          },
          contentController: _contentController,
        );
      case 1:
        return ReviewPlatformsStep(
          platformControllers: _reviewPlatformControllers,
          contentController: _contentController,
        );
      case 2:
        return FinalStep(
          businessName: _businessNameController.text,
          businessDescription: _businessDescriptionController.text,
          selectedCategory: _selectedCategory,
          platformControllers: _reviewPlatformControllers,
          contentController: _contentController,
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isLargeScreen = screenWidth > 900;
            
            if (isLargeScreen) {
              // Desktop/Large screen layout with side-by-side design
              return _buildLargeScreenLayout();
            } else {
              // Mobile/Tablet layout with scrollable content
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Header with progress
          SetupProgressIndicator(
            currentStep: _currentStep,
            totalSteps: _steps.length,
            steps: _steps,
            progressController: _progressController,
          ),
          
          // Content - now scrollable
          Expanded(
            child: SingleChildScrollView(
              child: _getCurrentStepContent(),
            ),
          ),
          
          // Navigation
          StepNavigation(
            currentStep: _currentStep,
            totalSteps: _steps.length,
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return SafeArea(
      child: Row(
        children: [
          // Left side - Progress indicator (fixed width)
          // ignore: sized_box_for_whitespace
          Container(
            width: 400,
            child: SetupProgressIndicator(
              currentStep: _currentStep,
              totalSteps: _steps.length,
              steps: _steps,
              progressController: _progressController,
            ),
          ),
          
          // Right side - Content and navigation
          Expanded(
            child: Column(
              children: [
                // Content area - scrollable
                Expanded(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 800),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _getCurrentStepContent(),
                    ),
                  ),
                ),
                
                // Navigation - fixed at bottom
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 800),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: StepNavigation(
                    currentStep: _currentStep,
                    totalSteps: _steps.length,
                    onNext: _nextStep,
                    onPrevious: _previousStep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}