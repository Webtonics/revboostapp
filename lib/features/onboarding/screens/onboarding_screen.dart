import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:revboostapp/features/onboarding/models/onboarding_page_model.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/routing/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _lottieController;
  
  // Define onboarding pages - you can easily add or remove pages here
  final List<OnboardingPageModel> _pages = [
    const OnboardingPageModel(
      title: 'Welcome to RevBoost',
      description: 'Boost your online reputation with smart review management',
      lottieAsset: 'assets/lottie/welcome.json',
      backgroundColor: Color(0xFF2563EB),
      textColor: Colors.white,
    ),
    const OnboardingPageModel(
      title: 'Shield your business',
      description: ' Filter bad reviews before they go public.',
      lottieAsset: 'assets/lottie/reviews.json',
      backgroundColor: Color(0xFF0D9488),
      textColor: Colors.white,
    ),
    const OnboardingPageModel(
      title: 'QR Code Integration',
      description: 'Generate custom QR codes for customers to easily leave reviews',
      lottieAsset: 'assets/lottie/qr_code.json',
      backgroundColor: Color(0xFF7C3AED),
      textColor: Colors.white,
    ),
    const OnboardingPageModel(
      title: 'Insightful Analytics',
      description: 'Track your review performance with detailed analytics and reporting',
      lottieAsset: 'assets/lottie/analytics.json',
      backgroundColor: Color(0xFFEF4444),
      textColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
  await OnboardingService.setOnboardingCompleted();
  
  if (mounted) {
    // Navigate to business setup next
    context.go(AppRoutes.businessSetup);
  }
}

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              
              return Container(
                color: page.backgroundColor,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive sizes
                      final lottieSize = isSmallScreen ? constraints.maxWidth * 0.4 : constraints.maxWidth * 0.8;
                      final paddingHorizontal = constraints.maxWidth * 0.05;
                      
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isSmallScreen ? 20 : 40),
                              
                              // Lottie animation with responsive sizing
                              SizedBox(
                                height: isSmallScreen ? lottieSize * 0.8 : lottieSize ,
                                child: Container(
                                
                                  child: Lottie.asset(
                                    page.lottieAsset,
                                    controller: _lottieController,
                                    onLoaded: (composition) {
                                      _lottieController
                                        ..duration = composition.duration
                                        ..repeat();
                                    },
                                    width: lottieSize,
                                    height: lottieSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Title
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                                child: Text(
                                  page.title,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: page.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 24 : 28,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Description
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal + 10),
                                child: Text(
                                  page.description,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: page.textColor.withOpacity(0.9),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 60 : 100),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Page indicator
          Positioned(
            bottom: isSmallScreen ? 50 : 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ResponsiveNavigationButtons(
                  currentPage: _currentPage,
                  pagesLength: _pages.length,
                  backgroundColor: _pages[_currentPage].backgroundColor,
                  onPrevious: _onPreviousPage,
                  onNext: _onNextPage,
                  onComplete: _completeOnboarding,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted navigation buttons into a separate widget for better organization
class ResponsiveNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int pagesLength;
  final Color backgroundColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const ResponsiveNavigationButtons({
    Key? key,
    required this.currentPage,
    required this.pagesLength,
    required this.backgroundColor,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        currentPage > 0
            ? TextButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                label: isNarrow 
                    ? const SizedBox.shrink() 
                    : const Text(
                        'Previous',
                        style: TextStyle(color: Colors.white),
                      ),
              )
            : SizedBox(width: isNarrow ? 40 : 100),
        
        // Skip button or Next button
        currentPage < pagesLength - 1
            ? Row(
                children: [
                  TextButton(
                    onPressed: onComplete,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 12 : 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Text('Next'),
                    label: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24,
                    vertical: 12,
                  ),
                ),
                icon: const Text('Get Started'),
                label: const Icon(Icons.arrow_forward_rounded),
              ),
      ],
    );
  }
}

