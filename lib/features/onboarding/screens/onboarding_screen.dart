// lib/features/onboarding/screens/onboarding_screen.dart

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
      title: 'Collect Reviews Effectively',
      description: 'Redirect positive reviews to public platforms while collecting negative feedback privately',
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

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    if (mounted) {
      context.go(AppRoutes.businessSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Lottie animation
                      Lottie.asset(
                        page.lottieAsset,
                        controller: _lottieController,
                        onLoaded: (composition) {
                          _lottieController
                            ..duration = composition.duration
                            ..repeat();
                        },
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                      ),
                      const SizedBox(height: 40),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: page.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: page.textColor.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 80), // Space for navigation buttons
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Page indicator
          Positioned(
            bottom: 130,
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
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  _currentPage > 0
                      ? TextButton.icon(
                          onPressed: _onPreviousPage,
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          label: const Text(
                            'Previous',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : const SizedBox(width: 100),
                  
                  // Skip button or Next button
                  _currentPage < _pages.length - 1
                      ? Row(
                          children: [
                            TextButton(
                              onPressed: _completeOnboarding,
                              child: const Text(
                                'Skip',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _onNextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _pages[_currentPage].backgroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Text('Next'),
                              label: const Icon(Icons.arrow_forward_rounded),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].backgroundColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Text('Get Started'),
                          label: const Icon(Icons.arrow_forward_rounded),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}