// lib/features/reviews/screens/public_review_screen.dart - Premium Design

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/core/services/page_view_service.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/feedback_provider.dart';
import 'package:revboostapp/features/reviews/widgets/premium_business_header.dart';
import 'package:revboostapp/features/reviews/widgets/premium_rating_widget.dart';
import 'package:revboostapp/features/reviews/widgets/premium_feedback_widget.dart';
import 'package:revboostapp/features/reviews/widgets/premium_contact_widget.dart';
import 'package:revboostapp/features/reviews/widgets/premium_submit_button.dart';
import 'package:revboostapp/features/reviews/widgets/premium_platform_selection.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

class PublicReviewScreen extends StatefulWidget {
  final String businessId;

  const PublicReviewScreen({
    Key? key,
    required this.businessId,
  }) : super(key: key);

  @override
  State<PublicReviewScreen> createState() => _PublicReviewScreenState();
}

class _PublicReviewScreenState extends State<PublicReviewScreen>
    with TickerProviderStateMixin {
  BusinessModel? _business;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedRating = 0;
  final _feedbackController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  final int _isSmallScreen = 900;

  // Page view tracking (silent)
  final PageViewService _pageViewService = PageViewService();
  String? _trackingId;
  String _pageViewSource = 'direct';

  // Animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _extractTrackingInfo();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _extractTrackingInfo() {
    try {
      Map<String, String> queryParams = {};
      
      if (kIsWeb) {
        final currentUrl = html.window.location.href;
        final uri = Uri.parse(currentUrl);
        queryParams = uri.queryParameters;
      }
      
      _trackingId = queryParams['tracking_id'];
      
      if (queryParams.containsKey('source')) {
        _pageViewSource = queryParams['source'] ?? 'direct';
      } else if (_trackingId != null && _trackingId!.isNotEmpty) {
        _pageViewSource = 'email';
      } else {
        _pageViewSource = 'qr';
      }
    } catch (e) {
      debugPrint('Error extracting tracking info: $e');
      _pageViewSource = 'direct';
    }
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestoreService = FirestoreService();
      final business = await firestoreService.getBusinessById(widget.businessId);

      if (business != null) {
        setState(() {
          _business = business;
          _isLoading = false;
        });

        // Start animations
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          _slideController.forward();
        });

        // Silently track page view
        _trackPageView();
      } else {
        setState(() {
          _errorMessage = 'Business not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading business: $e';
        _isLoading = false;
      });
    }
  }

  void _trackPageView() async {
    if (_business == null) return;

    try {
      await _pageViewService.trackPageView(
        businessId: widget.businessId,
        source: _pageViewSource,
        trackingId: _trackingId,
        metadata: {
          'businessName': _business!.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Page view tracking failed: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) {
      _showErrorSnackBar('Please select a rating');
      return;
    }

    if (_selectedRating <= 3 && _feedbackController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide feedback to help us improve');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final emailService = Provider.of<EmailService>(context, listen: false);
      final feedbackProvider = FeedbackProvider(
        emailService: emailService,
        businessId: widget.businessId,
        businessName: _business!.name,
        businessEmail: null,
      );

      final success = await feedbackProvider.submitFeedback(
        rating: _selectedRating.toDouble(),
        feedback: _feedbackController.text.trim(),
        customerName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        customerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        metadata: {
          'source': _pageViewSource,
          'trackingId': _trackingId,
          'submittedVia': 'public_review_page',
        },
      );

      if (success) {
        // Silently update page view completion
        try {
          await _pageViewService.updatePageViewCompletion(
            businessId: widget.businessId,
            trackingId: _trackingId,
            rating: _selectedRating.toDouble(),
            completed: true,
          );
        } catch (e) {
          debugPrint('Page view completion update failed: $e');
        }

        if (_selectedRating >= 4) {
          _showPlatformSelection();
        } else {
          _showThankYouMessage();
        }
      } else {
        _showErrorSnackBar('Failed to submit feedback. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error submitting feedback: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showPlatformSelection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PremiumPlatformSelection(
          rating: _selectedRating,
          reviewLinks: _business!.reviewLinks,
          onSkip: () {
            Navigator.of(context).pop();
            _showThankYouMessage();
          },
        ),
      ),
    );
  }

  void _showThankYouMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[600],
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Thank You!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your feedback has been submitted successfully. We appreciate you taking the time to share your experience!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'You\'re Welcome!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: MediaQuery.of(context).size.width >= _isSmallScreen ? const EdgeInsets.symmetric( horizontal: 150, ): const EdgeInsets.all(0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 800 ? 48 : 24,
              vertical: 24,
            ),
            child: Column(
              children: [
                // Business Header
                PremiumBusinessHeader(business: _business!),
                
                SizedBox(height: MediaQuery.of(context).size.width > 800 ? 48 : 32),
                
                // Rating Widget
                PremiumRatingWidget(
                  selectedRating: _selectedRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                ),
                
                SizedBox(height: MediaQuery.of(context).size.width > 800 ? 48 : 32),
                
                // Feedback Widget (only for ratings 1-3)
                if (_selectedRating > 0 && _selectedRating <= 3) ...[
                  PremiumFeedbackWidget(
                    feedbackController: _feedbackController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width > 800 ? 48 : 32),
                ],
                
                // Contact Widget (for all ratings)
                if (_selectedRating > 0) ...[
                  PremiumContactWidget(
                    nameController: _nameController,
                    emailController: _emailController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width > 800 ? 48 : 32),
                ],
                
                // Submit Button
                if (_selectedRating > 0) ...[
                  PremiumSubmitButton(
                    isSubmitting: _isSubmitting,
                    onPressed: _submitFeedback,
                    text: _selectedRating >= 4 
                        ? 'Submit & Leave Public Review' 
                        : 'Submit Feedback',
                  ),
                ],
                
                SizedBox(height: MediaQuery.of(context).size.width > 800 ? 64 : 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}