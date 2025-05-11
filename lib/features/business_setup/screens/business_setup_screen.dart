// lib/features/business_setup/screens/business_setup_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/business_setup_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

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
  
  // Step titles and subtitles for more context
  final List<Map<String, String>> _steps = [
    {
      'title': 'Business Information',
      'subtitle': 'Tell customers who you are'
    },
    {
      'title': 'Review Platform Links',
      'subtitle': 'Connect your existing profiles'
    },
    {
      'title': 'Almost Done!',
      'subtitle': 'Just one click away'
    },
  ];

  // Platform icons
  final Map<String, IconData> _platformIcons = {
    'Google Business Profile': Icons.business_center,
    'Yelp': Icons.restaurant_menu,
    'Facebook': Icons.facebook,
    'TripAdvisor': Icons.travel_explore,
  };
  
  // Logo image data
  Uint8List? _logoImageBytes;
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Start initial animations
    _progressController.value = 1 / _steps.length;
    _contentController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the business setup provider data if available
      final provider = Provider.of<BusinessSetupProvider>(context, listen: false);
      
      // Set initial values if available
      if (provider.name.isNotEmpty) {
        _businessNameController.text = provider.name;
      }
      
      if (provider.description.isNotEmpty) {
        _businessDescriptionController.text = provider.description;
      }
      
      // Set initial values for review links
      final reviewLinks = provider.reviewLinks;
      for (final platform in _reviewPlatformControllers.keys) {
        if (reviewLinks.containsKey(platform)) {
          _reviewPlatformControllers[platform]!.text = reviewLinks[platform]!;
        }
      }
    });
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
      // Validate and save business info
      if (_businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business name is required'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Save business info to provider
      final provider = Provider.of<BusinessSetupProvider>(context, listen: false);
      provider.setBusinessInfo(
        name: _businessNameController.text.trim(),
        description: _businessDescriptionController.text.trim(),
      );
    } else if (_currentStep == 1) {
      // Save review links to provider
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
    
    // Proceed to next step or complete setup
    if (_currentStep < _steps.length - 1) {
      // Reset content animation for next page
      _contentController.reset();
      
      // Animate to next page
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      
      // Update progress bar
      _progressController.animateTo(
        (_currentStep + 2) / _steps.length,
        curve: Curves.easeOut,
      );
      
      // Start content animation after page transition
      Future.delayed(const Duration(milliseconds: 300), () {
        _contentController.forward();
      });
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Reset content animation for previous page
      _contentController.reset();
      
      // Animate to previous page
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      
      // Update progress bar
      _progressController.animateTo(
        (_currentStep) / _steps.length,
        curve: Curves.easeOut,
      );
      
      // Start content animation after page transition
      Future.delayed(const Duration(milliseconds: 300), () {
        _contentController.forward();
      });
    }
  }
// Future<void> _completeSetup() async {
//   // Show loading indicator
//   setState(() {
//     _isLoading = true;
//   });
  
//   try {
//     // Get providers
//     final businessProvider = Provider.of<BusinessSetupProvider>(context, listen: false);
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
//     // Ensure business info is set
//     businessProvider.setBusinessInfo(
//       name: _businessNameController.text.trim(),
//       description: _businessDescriptionController.text.trim(),
//     );
    
//     // Save review platform links
//     for (final platform in _reviewPlatformControllers.keys) {
//       final link = _reviewPlatformControllers[platform]!.text.trim();
//       if (link.isNotEmpty) {
//         businessProvider.setReviewLink(platform, link);
//       } else {
//         businessProvider.removeReviewLink(platform);
//       }
//     }
    
//     // Save business setup to Firebase (without logo)
//     await businessProvider.saveBusinessSetup();
    
//     // Mark setup as completed in OnboardingService
//     await OnboardingService.setBusinessSetupCompleted();
    
//     // Update the user's hasCompletedSetup flag in AuthProvider
//     await authProvider.updateUserSetupStatus(true);
    
//     // Force reload the user data to get updated status
//     await authProvider.reloadAuthState();
    
//     // Hide loading indicator
//     setState(() {
//       _isLoading = false;
//     });
    
//     // Navigation: check if mounted, then navigate
//     if (mounted) {
//       // Navigate directly to dashboard instead of splash
//       debugPrint('⚡ Business setup completed, navigating to dashboard');
//       context.go(AppRoutes.dashboard);
//     }
//   } catch (e) {
//     // Hide loading indicator
//     setState(() {
//       _isLoading = false;
//     });
    
//     // Show error message if mounted
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Colors.red.shade700,
//         ),
//       );
//     }
//   }
// }
Future<void> _completeSetup() async {
  // Show loading indicator
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Get providers
    final businessProvider = Provider.of<BusinessSetupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Ensure business info is set
    businessProvider.setBusinessInfo(
      name: _businessNameController.text.trim(),
      description: _businessDescriptionController.text.trim(),
    );
    
    // Save review platform links
    for (final platform in _reviewPlatformControllers.keys) {
      final link = _reviewPlatformControllers[platform]!.text.trim();
      if (link.isNotEmpty) {
        businessProvider.setReviewLink(platform, link);
      } else {
        businessProvider.removeReviewLink(platform);
      }
    }
    
    // Save business setup to Firebase (without logo)
    await businessProvider.saveBusinessSetup();
    
    // Mark setup as completed in both services
    await OnboardingService.setBusinessSetupCompleted();
    
    // This is critical: update the user object in auth provider
    await authProvider.updateUserSetupStatus(true);
    
    // Ensure the user data is fully reloaded to reflect the change
    await authProvider.reloadUser();
    
    // Add a small delay to ensure Firebase updates are registered
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Hide loading indicator
    setState(() {
      _isLoading = false;
    });
    
    // Navigation: check if mounted, then navigate
    if (mounted) {
      // Navigate to dashboard through splash for proper redirection
      debugPrint('⚡ Business setup completed, navigating to dashboard');
      context.go(AppRoutes.dashboard);
    }
  } catch (e) {
    // Hide loading indicator
    setState(() {
      _isLoading = false;
    });
    
    // Show error message if mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // Detect screen size for responsive layout
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTabScreen = size.width < 600;
    final isPortrait = size.height > size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        // Use a gradient app bar for a more modern look
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Setup Your Business',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: isDarkMode 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).primaryColor.withOpacity(0.03),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) => CircularProgressBar(
                    value: _progressController.value,
                    size: isSmallScreen ? 32 : 40,
                    strokeWidth: isSmallScreen ? 3 : 4,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          padding: EdgeInsets.symmetric( horizontal: isSmallScreen? 10: 250),
          // Add a subtle gradient background for polish
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode 
                  ? [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20.0 : 32.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linear progress indicator
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              minHeight: 6,
                            ),
                          );
                        }
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Step title
                      Text(
                        _steps[_currentStep]['title']!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Step subtitle
                      Text(
                        _steps[_currentStep]['subtitle']!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider for visual separation
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swiping
                    onPageChanged: (int page) {
                      setState(() {
                        _currentStep = page;
                      });
                    },
                    children: [
                      // Step 1: Business Information
                      _buildBusinessInfoStep(isSmallScreen, isDarkMode),
                      
                      // Step 2: Review Platform Links
                      _buildReviewPlatformsStep(isSmallScreen, isDarkMode),
                      
                      // Step 3: Final Step
                      _buildFinalStep(isSmallScreen, isDarkMode),
                    ],
                  ),
                ),
                
                // Bottom navigation bar with shadow
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: isSmallScreen ? 16.0 : 20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _currentStep > 0
                          ? TextButton.icon(
                              onPressed: _previousStep,
                              icon: const Icon(Icons.arrow_back),
                              label: Text(
                                isSmallScreen && isPortrait ? '' : 'Back',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 8 : 12,
                                ),
                              ),
                            )
                          : SizedBox(width: isSmallScreen ? 48 : 100),
                      
                      // Next/Finish button
                      AppButton(
                        text: _currentStep < _steps.length - 1 ? 'Next' : 'Finish',
                        onPressed: _nextStep,
                        icon: _currentStep < _steps.length - 1 
                            ? Icons.arrow_forward 
                            : Icons.check_circle_outline,
                        type: AppButtonType.primary,
                        size: isSmallScreen ? AppButtonSize.small : AppButtonSize.medium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep(bool isSmallScreen, bool isDarkMode) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : 32.0,
            vertical: 24.0,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business name field with animation
              _buildAnimatedField(
                controller: _businessNameController,
                label: 'Business Name',
                hint: 'Enter your business name',
                icon: Icons.business,
                delay: 100,
                required: true,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 24),
              
              // Business description field with animation
              _buildAnimatedField(
                controller: _businessDescriptionController,
                label: 'Business Description',
                hint: 'Tell your customers what makes your business special...',
                icon: Icons.description,
                maxLines: 4,
                delay: 200,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 32),
              
              // Business category with animation
              _buildAnimatedDropdown(
                label: 'Business Category',
                hint: 'Select a category',
                icon: Icons.category,
                items: const [
                  'Restaurant or Café',
                  'Home Services',
                  'Retail Store',
                  'Service Business',
                  'Professional Services',
                  'Healthcare',
                  'Other',
                ],
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                delay: 300,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 32),
              
              // Tips section with animation
              _buildAnimatedWidget(
                delay: 400,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.blue.shade900.withOpacity(0.2)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.blue.shade800.withOpacity(0.3)
                          : Colors.blue.shade100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pro Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Use a descriptive business name that\'s easy to remember',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Your description should highlight what makes your business unique',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Select the most specific category for your business type',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewPlatformsStep(bool isSmallScreen, bool isDarkMode) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : 32.0,
            vertical: 24.0,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card at the top
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.5)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connect Your Review Platforms',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add links to the platforms where your customers can leave reviews. These will be used to redirect customers when they leave positive feedback.',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Generate platform fields with animation
              ...List.generate(
                _platformIcons.length,
                (index) {
                  final platform = _platformIcons.keys.elementAt(index);
                  final icon = _platformIcons.values.elementAt(index);
                  
                  return Column(
                    children: [
                      _buildAnimatedPlatformField(
                        platform: platform,
                        controller: _reviewPlatformControllers[platform]!,
                        icon: icon,
                        delay: 100 * index,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              
              // Help text
              _buildAnimatedWidget(
                delay: 500,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.amber.shade900.withOpacity(0.2)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.amber.shade800.withOpacity(0.3)
                          : Colors.amber.shade100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'To find your review profile links:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Google: Search your business and copy the "Write a review" URL',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Yelp/TripAdvisor: Go to your business profile and copy the URL',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Facebook: Go to your page, click Reviews tab, and copy the URL',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalStep(bool isSmallScreen, bool isDarkMode) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Curves.easeOutCubic,
        )),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                _buildAnimatedWidget(
                  delay: 100,
                  child: Lottie.asset(
                    'assets/lottie/success.json',
                    width: isSmallScreen ? 180 : 200,
                    height: isSmallScreen ? 180 : 200,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                _buildAnimatedWidget(
                  delay: 300,
                  child: Text(
                    'You\'re all set!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: isSmallScreen ? 24 : 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                _buildAnimatedWidget(
                  delay: 400,
                  child: Text(
                    'Your business profile is ready. Click "Finish" to complete the setup and start collecting reviews right away.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontSize: isSmallScreen ? 15 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Business summary
                _buildAnimatedWidget(
                  delay: 500,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isDarkMode
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.business,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Business Summary',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Summary items with improved layout
                        _buildSummaryItem(
                          'Name',
                          _businessNameController.text.isEmpty 
                              ? 'Not provided' 
                              : _businessNameController.text,
                          isDarkMode,
                        ),
                        
                        if (_businessDescriptionController.text.isNotEmpty)
                          _buildSummaryItem(
                            'Description',
                            _businessDescriptionController.text,
                            isDarkMode,
                          ),
                          
                        if (_selectedCategory != null)
                          _buildSummaryItem('Category', _selectedCategory!, isDarkMode),
                          
                        _buildSummaryItem(
                          'Connected Review Platforms',
                          _reviewPlatformControllers.values
                              .where((controller) => controller.text.trim().isNotEmpty)
                              .length
                              .toString(),
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Benefits list with improved design
                _buildAnimatedWidget(
                  delay: 600,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                    color: isDarkMode
                          ? Theme.of(context).primaryColor.withOpacity(0.08)
                          : Theme.of(context).primaryColor.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What\'s Next?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitItem(
                          icon: Icons.star,
                          title: 'Collect positive reviews',
                          subtitle: 'Boost your online reputation',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitItem(
                          icon: Icons.filter_alt,
                          title: 'Filter negative feedback',
                          subtitle: 'Address issues before they go public',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitItem(
                          icon: Icons.qr_code,
                          title: 'QR code integration',
                          subtitle: 'Make it easy for customers to leave reviews',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Get started tip
                _buildAnimatedWidget(
                  delay: 700,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.green.shade900.withOpacity(0.2)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.green.shade800.withOpacity(0.3)
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green[600],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready to Launch!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Click "Finish" below to complete setup and start exploring your dashboard.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode 
                                        ? Colors.grey[300] 
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int delay = 0,
    bool required = false,
    required bool isDarkMode,
  }) {
    // Determine appropriate colors based on theme
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    
    return _buildAnimatedWidget(
      delay: delay,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          alignLabelWithHint: maxLines > 1,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
  
  Widget _buildAnimatedDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
    int delay = 0,
    required bool isDarkMode,
  }) {
    // Determine appropriate colors based on theme
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    
    return _buildAnimatedWidget(
      delay: delay,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        hint: Text(hint),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
        dropdownColor: isDarkMode ? Colors.grey[700] : Colors.white,
      ),
    );
  }

  Widget _buildAnimatedPlatformField({
    required String platform,
    required TextEditingController controller,
    required IconData icon,
    required int delay,
    required bool isDarkMode,
  }) {
    // Determine appropriate colors based on theme
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    
    return _buildAnimatedWidget(
      delay: delay,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$platform Link',
          hintText: 'Enter your $platform profile URL',
          prefixIcon: Icon(icon),
          suffixIcon: IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () {
              // Show info tooltip
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enter the URL where customers can review your business on $platform'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWidget({
    required Widget child,
    required int delay,
  }) {
    return FutureBuilder<void>(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        );
        
        if (snapshot.connectionState == ConnectionState.done) {
          controller.forward();
        }
        
        return FadeTransition(
          opacity: controller,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }
}

// Custom circular progress indicator
class CircularProgressBar extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;

  const CircularProgressBar({
    super.key,
    required this.value,
    required this.size,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Center text
          Center(
            child: Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}