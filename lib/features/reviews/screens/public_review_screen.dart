// lib/features/reviews/screens/public_review_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class PublicReviewScreen extends StatefulWidget {
  final String businessId;
  
  const PublicReviewScreen({
    Key? key, 
    required this.businessId,
  }) : super(key: key);

  @override
  State<PublicReviewScreen> createState() => _PublicReviewScreenState();
}

class _PublicReviewScreenState extends State<PublicReviewScreen> with SingleTickerProviderStateMixin {
  late Future<BusinessModel?> _businessFuture;
  int _rating = 0;
  bool _isSubmitting = false;
  bool _showThankYou = false;
  final TextEditingController _feedbackController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // Background gradient colors
  final List<Color> _gradientColors = [
    const Color(0xFF2563EB), // Primary blue
    const Color(0xFF1E40AF), // Darker blue
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    _businessFuture = _loadBusiness();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<BusinessModel?> _loadBusiness() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .get();
      
      if (doc.exists) {
        return BusinessModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error loading business: $e');
      return null;
    }
  }

  void _handleRatingSelected(int rating) {
    setState(() {
      _rating = rating;
    });

    // Animate transition to the next step
    _animationController.reset();
    _animationController.forward();

    // Handle different flows based on rating
    if (rating >= 4) {
      // For 4-5 star ratings, show platform selection
      _showPlatformSelectionDialog();
    } else {
      // For 1-3 star ratings, show feedback form
      _showFeedbackDialog();
    }
  }

  void _showPlatformSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<BusinessModel?>(
        future: _businessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final business = snapshot.data;
          if (business == null) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Business not found'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final reviewLinks = business.reviewLinks;
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success animation
                  Lottie.asset(
                    'assets/lottie/success.json',
                    width: 120,
                    height: 120,
                    repeat: false,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title and message
                  Text(
                    'Thank You!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We really appreciate your positive feedback. Please share your experience on your preferred platform:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Platform options
                  if (reviewLinks.isEmpty)
                    const Text(
                      'No review platforms available. Please contact the business directly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: reviewLinks.entries.map((entry) {
                        final platform = entry.key;
                        final link = entry.value;
                        
                        // Platform-specific styling
                        Color buttonColor;
                        IconData platformIcon;
                        
                        switch (platform) {
                          case 'Google Business Profile':
                            buttonColor = const Color(0xFF4285F4);
                            platformIcon = Icons.g_mobiledata_rounded;
                            break;
                          case 'Yelp':
                            buttonColor = const Color(0xFFD32323);
                            platformIcon = Icons.restaurant_menu;
                            break;
                          case 'Facebook':
                            buttonColor = const Color(0xFF3b5998);
                            platformIcon = Icons.facebook;
                            break;
                          case 'TripAdvisor':
                            buttonColor = const Color(0xFF00af87);
                            platformIcon = Icons.travel_explore;
                            break;
                          default:
                            buttonColor = Colors.grey[800]!;
                            platformIcon = Icons.star;
                        }
                        
                        return ElevatedButton.icon(
                          icon: Icon(platformIcon),
                          label: Text(platform.split(' ')[0]), // Just the first word of platform name
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            // Launch the review platform
                            _launchReviewPlatform(link);
                            Navigator.pop(context);
                            
                            // Show thank you
                            setState(() {
                              _showThankYou = true;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Skip option
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _showThankYou = true;
                      });
                    },
                    child: const Text('Maybe later'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchReviewPlatform(String url) async {
    try {
      final Uri reviewUri = Uri.parse(url);
      if (await canLaunchUrl(reviewUri)) {
        await launchUrl(reviewUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening review platform: $e')),
        );
      }
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.feedback_outlined,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your Feedback Matters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Feedback message
              Text(
                'We appreciate your honesty. Please let us know how we can improve your experience:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              
              // Feedback form
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share your experience and suggestions...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[400]!),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitFeedback();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Submit Feedback'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save the feedback to Firestore
      await FirebaseFirestore.instance.collection('feedback').add({
        'businessId': widget.businessId,
        'rating': _rating,
        'feedback': _feedbackController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
        _showThankYou = true;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: FutureBuilder<BusinessModel?>(
          future: _businessFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorView('Error loading business information');
            }

            final business = snapshot.data;
            if (business == null) {
              return _buildErrorView('Business not found');
            }

            return _showThankYou
                ? _buildThankYouView(business)
                : _buildReviewView(business);
          },
        ),
      ),
    );
  }
  
  Widget _buildErrorView(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _businessFuture = _loadBusiness();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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

  Widget _buildReviewView(BusinessModel business) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/review_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Business logo or initial
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: business.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              business.logoUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  business.name.isNotEmpty
                                      ? business.name[0].toUpperCase()
                                      : 'B',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            business.name.isNotEmpty
                                ? business.name[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Business name
                  Text(
                    business.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (business.description != null && business.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        business.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 32),
                  
                  // Rating prompt
                  Text(
                    'How was your experience?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve our service',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () => _handleRatingSelected(starValue),
                          child: Icon(
                            _rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _rating >= starValue ? Colors.amber : Colors.grey[400],
                            size: 48,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _getRatingText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _rating > 0 ? AppColors.primary : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouView(BusinessModel business) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[700]!,
            Colors.green[900]!,
          ],
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success animation
                Lottie.asset(
                  'assets/lottie/success.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                ),
                const SizedBox(height: 24),
                
                // Thank you message
                Text(
                  'Thank You!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _rating >= 4
                      ? 'We appreciate your positive feedback! Thank you for taking the time to share your experience.'
                      : 'Thank you for your valuable feedback. We\'ll use it to improve our service.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Back to business button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rating = 0;
                      _showThankYou = false;
                      _feedbackController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rate Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                   
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.green[700]!),
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    if (_rating == 0) {
      return 'Tap to rate';
    } else if (_rating == 1) {
      return 'Very disappointed';
    } else if (_rating == 2) {
      return 'Not satisfied';
    } else if (_rating == 3) {
      return 'It was okay';
    } else if (_rating == 4) {
      return 'Good experience';
    } else {
      return 'Excellent!';
    }
  }
}