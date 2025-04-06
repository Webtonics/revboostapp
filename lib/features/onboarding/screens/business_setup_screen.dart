// lib/features/business_setup/screens/business_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revboostapp/features/onboarding/services/onboarding_service.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({Key? key}) : super(key: key);

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  
  // Step titles
  final List<String> _stepTitles = [
    'Business Information',
    'Review Platform Links',
    'Almost Done!',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    // Here you would save all the collected data to Firestore
    // For now, we'll just mark setup as complete and navigate
    await OnboardingService.setBusinessSetupCompleted();
    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Your Business (${_currentStep + 1}/${_stepTitles.length})'),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _stepTitles.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          
          // Step title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _stepTitles[_currentStep],
              style: Theme.of(context).textTheme.headlineSmall,
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
                _buildBusinessInfoStep(),
                
                // Step 2: Review Platform Links
                _buildReviewPlatformsStep(),
                
                // Step 3: Final Step
                _buildFinalStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _currentStep > 0
                    ? TextButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      )
                    : const SizedBox(width: 100),
                
                // Next/Finish button
                AppButton(
                  text: _currentStep < _stepTitles.length - 1 ? 'Next' : 'Finish',
                  onPressed: _nextStep,
                  icon: Icons.arrow_forward,
                  type: AppButtonType.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your business',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          
          // Business name field
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name',
              hintText: 'Enter your business name',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          
          // Business description field
          TextField(
            controller: _businessDescriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Business Description',
              hintText: 'Tell your customers about your business...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          
          // Logo upload
          Center(
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    // Implement logo upload functionality
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Logo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPlatformsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your review platforms',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your business profile links to help customers leave reviews on your preferred platforms.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Google Business Profile
          _buildPlatformLinkField(
            platform: 'Google Business Profile',
            icon: Icons.g_mobiledata,
            hintText: 'https://g.page/r/example',
          ),
          const SizedBox(height: 16),
          
          // Yelp
          _buildPlatformLinkField(
            platform: 'Yelp',
            icon: Icons.restaurant_menu,
            hintText: 'https://www.yelp.com/biz/example',
          ),
          const SizedBox(height: 16),
          
          // Facebook
          _buildPlatformLinkField(
            platform: 'Facebook',
            icon: Icons.facebook,
            hintText: 'https://www.facebook.com/example',
          ),
          
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Add more platforms functionality
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Another Platform'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformLinkField({
    required String platform,
    required IconData icon,
    required String hintText,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: platform,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildFinalStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Almost there!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your business profile is ready to be created. Click "Finish" to complete the setup and start collecting reviews.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}