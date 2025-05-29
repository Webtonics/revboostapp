// lib/features/reviews/screens/public_review_screen.dart - Updated with Page View Tracking

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/core/services/page_view_service.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/feedback_provider.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class PublicReviewScreen extends StatefulWidget {
  final String businessId;

  const PublicReviewScreen({
    Key? key,
    required this.businessId,
  }) : super(key: key);

  @override
  State<PublicReviewScreen> createState() => _PublicReviewScreenState();
}

class _PublicReviewScreenState extends State<PublicReviewScreen> {
  BusinessModel? _business;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedRating = 0;
  final _feedbackController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  
  // Page view tracking
  final PageViewService _pageViewService = PageViewService();
  String? _trackingId;
  String _pageViewSource = 'direct';

  @override
  void initState() {
    super.initState();
    _extractTrackingInfo();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Extract tracking information from URL parameters
  void _extractTrackingInfo() {
    final uri = GoRouterState.of(context).uri;
    _trackingId = uri.queryParameters['tracking_id'];
    
    // Determine source based on URL parameters or referrer
    if (uri.queryParameters.containsKey('source')) {
      _pageViewSource = uri.queryParameters['source'] ?? 'direct';
    } else if (_trackingId != null) {
      _pageViewSource = 'email'; // Likely from email if tracking ID present
    } else {
      // Try to detect if it's from QR code vs direct link
      // QR codes typically don't have referrers, while direct links might
      try {
        if (kIsWeb) {
          final referrer = Uri.base.queryParameters['ref'] ?? '';
          if (referrer.isEmpty) {
            _pageViewSource = 'qr'; // Likely QR code scan
          } else {
            _pageViewSource = 'direct'; // Direct link with referrer
          }
        } else {
          _pageViewSource = 'qr'; // Mobile is likely QR scan
        }
      } catch (e) {
        _pageViewSource = 'direct'; // Fallback
      }
    }
    
    debugPrint('Page view source determined: $_pageViewSource, tracking ID: $_trackingId');
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

        // Track page view after business is loaded
        await _trackPageView();
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

  /// Track the page view
  Future<void> _trackPageView() async {
    if (_business == null) return;

    try {
      debugPrint('🔍 Tracking page view for business: ${widget.businessId}');
      debugPrint('🔍 Source: $_pageViewSource, Tracking ID: $_trackingId');
      
      await _pageViewService.trackPageView(
        businessId: widget.businessId,
        source: _pageViewSource,
        trackingId: _trackingId,
        metadata: {
          'businessName': _business!.name,
          'timestamp': DateTime.now().toIso8601String(),
          'userAgent': kIsWeb ? 'web' : 'mobile',
        },
      );
      
      debugPrint('✅ Page view tracked successfully');
    } catch (e) {
      debugPrint('❌ Error tracking page view: $e');
      // Don't show error to user - this is background tracking
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) {
      _showErrorDialog('Please select a rating');
      return;
    }

    if (_selectedRating <= 3 && _feedbackController.text.trim().isEmpty) {
      _showErrorDialog('Please provide feedback to help us improve');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get or create feedback provider
      final emailService = Provider.of<EmailService>(context, listen: false);
      final feedbackProvider = FeedbackProvider(
        emailService: emailService,
        businessId: widget.businessId,
        businessName: _business!.name,
        businessEmail: null, // We don't have business email in this context
      );

      // Submit feedback
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
        // Update page view completion
        await _pageViewService.updatePageViewCompletion(
          businessId: widget.businessId,
          trackingId: _trackingId,
          rating: _selectedRating.toDouble(),
          completed: true,
        );

        if (_selectedRating >= 4) {
          // Positive rating - redirect to review platforms
          _showPlatformSelection();
        } else {
          // Negative rating - show thank you message
          _showThankYouMessage();
        }
      } else {
        _showErrorDialog('Failed to submit feedback. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error submitting feedback: $e');
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
      builder: (context) => AlertDialog(
        title: Text('Thank you for the ${_selectedRating}-star rating! ⭐'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you mind sharing your experience publicly? '
              'It really helps other customers find us!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_business!.reviewLinks.isNotEmpty) ...[
              Text(
                'Choose where to leave your review:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._business!.reviewLinks.entries.map(
                (entry) => _buildPlatformButton(entry.key, entry.value),
              ).toList(),
            ] else ...[
              const Text('No review platforms configured for this business.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showThankYouMessage();
            },
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformButton(String platform, String url) {
    IconData icon;
    Color color;

    switch (platform.toLowerCase()) {
      case 'google':
      case 'google business profile':
        icon = Icons.business;
        color = Colors.blue;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.indigo;
        break;
      case 'yelp':
        icon = Icons.restaurant_menu;
        color = Colors.red;
        break;
      case 'tripadvisor':
        icon = Icons.travel_explore;
        color = Colors.green;
        break;
      default:
        icon = Icons.link;
        color = Colors.grey;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              Navigator.of(context).pop();
              _showThankYouMessage();
            } else {
              _showErrorDialog('Could not open $platform');
            }
          } catch (e) {
            _showErrorDialog('Error opening $platform: $e');
          }
        },
        icon: Icon(icon, color: Colors.white),
        label: Text('Review on $platform'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showThankYouMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thank You! 🙏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Your feedback has been submitted successfully.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We appreciate you taking the time to share your experience with us!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally navigate away or close the page
            },
            child: const Text('You\'re Welcome!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        message: 'Submitting your feedback...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Business logo/header
                _buildBusinessHeader(),
                
                const SizedBox(height: 32),
                
                // Rating section
                _buildRatingSection(),
                
                const SizedBox(height: 24),
                
                // Feedback section (shown for ratings <= 3)
                if (_selectedRating > 0 && _selectedRating <= 3) ...[
                  _buildFeedbackSection(),
                  const SizedBox(height: 24),
                ],
                
                // Optional contact info (for all ratings)
                if (_selectedRating > 0) ...[
                  _buildContactSection(),
                  const SizedBox(height: 32),
                ],
                
                // Submit button
                if (_selectedRating > 0) _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.business,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _business!.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'How was your experience?',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Rate your experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.star,
                      size: 48,
                      color: rating <= _selectedRating
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            if (_selectedRating > 0) ...[
              const SizedBox(height: 12),
              Text(
                _getRatingText(_selectedRating),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _getRatingColor(_selectedRating),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us improve',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'d love to hear your feedback so we can make things better.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us what we could do better...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact info (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave your contact details if you\'d like us to follow up.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : Text(
                _selectedRating >= 4 ? 'Submit & Leave Public Review' : 'Submit Feedback',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}