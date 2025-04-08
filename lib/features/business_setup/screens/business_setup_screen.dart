import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';

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
  final Map<String, dynamic> _platformIcons = {
    'Google Business Profile': Icons.business_center,
    'Yelp': Icons.restaurant_menu,
    'Facebook': Icons.facebook,
    'TripAdvisor': Icons.travel_explore,
    'Instagram': Icons.camera_alt_outlined,
  };

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _progressController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextStep() {
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

  Future<void> _completeSetup() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
    
    // Here you would save all the collected data to Firestore
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    await OnboardingService.setBusinessSetupCompleted();
    
    if (mounted) {
      Navigator.of(context).pop(); // Remove loading dialog
      
      // Show success animation before navigating
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Determine text color based on theme
          final textColor = Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.white;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/success.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                  onLoaded: (composition) {
                    // Ensure we navigate to dashboard after animation completes
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) {
                        Navigator.of(context).pop();
                        // Use GoRouter for navigation
                        context.go(AppRoutes.dashboard);
                      }
                    });
                  },
                ),
                Text(
                  'Setup Complete!',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isPortrait = size.height > size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Setup Your Business',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
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
      body: Padding(
         padding: isSmallScreen ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12) : const EdgeInsets.symmetric(horizontal: 100.0, vertical: 24),
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Linear progress indicator
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
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
                  _buildBusinessInfoStep(isSmallScreen),
                  
                  // Step 2: Review Platform Links
                  _buildReviewPlatformsStep(isSmallScreen),
                  
                  // Step 3: Final Step
                  _buildFinalStep(isSmallScreen),
                ],
              ),
            ),
            
            // Navigation buttons
            SafeArea(
              minimum: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: isSmallScreen ? 8.0 : 16.0
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
    );
  }

  Widget _buildBusinessInfoStep(bool isSmallScreen) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business name field with animation
              const SizedBox(height: 16),
              _buildAnimatedField(
                controller: _businessNameController,
                label: 'Business Name',
                hint: 'Enter your business name',
                icon: Icons.business,
                delay: 100,
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
              ),
              
              const SizedBox(height: 32),
              
              // Business category with animation
              _buildAnimatedDropdown(
                label: 'Business Category',
                hint: 'Select a category',
                icon: Icons.category,
                items: const [
                  'Restaurant or Café',
                  'Retail Store',
                  'Service Business',
                  'Professional Services',
                  'Healthcare',
                  'Other',
                ],
                delay: 300,
              ),
              
              const SizedBox(height: 32),
              
              // Logo upload with animation
              _buildAnimatedWidget(
                delay: 400,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          // Implement logo upload functionality
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Logo'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
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

  Widget _buildReviewPlatformsStep(bool isSmallScreen) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Connect the platforms where your customers can leave reviews.',
                style: TextStyle(color: Colors.grey),
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
                        icon: icon,
                        delay: 100 * index,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              
              // "Add platform" button
              Center(
                child: _buildAnimatedWidget(
                  delay: 100 * _platformIcons.length,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Add platform functionality
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Platform'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
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

  Widget _buildFinalStep(bool isSmallScreen) {
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
                      color: Colors.grey[700],
                      fontSize: isSmallScreen ? 15 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Benefits list
                _buildAnimatedWidget(
                  delay: 500,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitItem(
                          icon: Icons.star,
                          title: 'Collect positive reviews',
                          subtitle: 'Boost your online reputation',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitItem(
                          icon: Icons.filter_alt,
                          title: 'Filter negative feedback',
                          subtitle: 'Address issues before they go public',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitItem(
                          icon: Icons.qr_code,
                          title: 'QR code integration',
                          subtitle: 'Make it easy for customers to leave reviews',
                        ),
                      ],
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

  // Helper widgets with animations
  
  Widget _buildAnimatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int delay = 0,
  }) {
    // Determine appropriate colors based on theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    
    return _buildAnimatedWidget(
      delay: delay,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
  
  Widget _buildAnimatedDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    int delay = 0,
  }) {
    // Determine appropriate colors based on theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    
    return _buildAnimatedWidget(
      delay: delay,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        hint: Text(hint),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_) {},
      ),
    );
  }

  Widget _buildAnimatedPlatformField({
    required String platform,
    required IconData icon,
    required int delay,
  }) {
    // Determine appropriate colors based on theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    
    return _buildAnimatedWidget(
      delay: delay,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            platform,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect your $platform profile',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
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

