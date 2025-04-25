// lib/features/reviews/screens/public_review_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late Animation<double> _scaleAnimation;
  
  // Background gradient colors - updated with more vibrant colors
  final List<Color> _gradientColors = [
    const Color(0xFF1A73E8), // Primary blue
    const Color(0xFF0D47A1), // Deep blue
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
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
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
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ));
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
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(28),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.blue[50]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success animation
                  Lottie.asset(
                    'assets/lottie/success.json',
                    width: 140,
                    height: 140,
                    repeat: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title and message
                  Text(
                    'Thank You!',
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We really appreciate your positive feedback. Please share your experience on your preferred platform:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Platform options
                  if (reviewLinks.isEmpty)
                    Text(
                      'No review platforms available. Please contact the business directly.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: reviewLinks.entries.map((entry) {
                        final platform = entry.key;
                        final link = entry.value;
                        
                        // Platform-specific styling
                        Color buttonColor;
                        IconData platformIcon;
                        String platformLabel;
                        
                        switch (platform) {
                          case 'Google Business Profile':
                            buttonColor = const Color(0xFF4285F4);
                            platformIcon = Icons.g_mobiledata_rounded;
                            platformLabel = 'Google';
                            break;
                          case 'Yelp':
                            buttonColor = const Color(0xFFD32323);
                            platformIcon = Icons.restaurant_menu;
                            platformLabel = 'Yelp';
                            break;
                          case 'Facebook':
                            buttonColor = const Color(0xFF3b5998);
                            platformIcon = Icons.facebook;
                            platformLabel = 'Facebook';
                            break;
                          case 'TripAdvisor':
                            buttonColor = const Color(0xFF00af87);
                            platformIcon = Icons.travel_explore;
                            platformLabel = 'TripAdvisor';
                            break;
                          default:
                            buttonColor = const Color(0xFF1A73E8);
                            platformIcon = Icons.star_rounded;
                            platformLabel = platform.split(' ')[0]; // Just the first word of platform name
                        }
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton.icon(
                            icon: Icon(platformIcon, size: 24),
                            label: Text(
                              platformLabel,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: buttonColor.withOpacity(0.5),
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
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Skip option
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _showThankYou = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Maybe later',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.feedback_outlined,
                      color: Color(0xFF1A73E8),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your Feedback Matters',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A73E8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Feedback message
              Text(
                'We appreciate your honesty. Please let us know how we can improve your experience:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              
              // Feedback form
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your experience and suggestions...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFF1A73E8), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitFeedback();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF1A73E8).withOpacity(0.3),
                    ),
                    child: Text(
                      'Submit Feedback',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red[700],
          ),
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
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _gradientColors,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
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
        image: const DecorationImage(
          image: AssetImage('assets/images/wave_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/splash_logo_light.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.headlineSmall,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _businessFuture = _loadBusiness();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
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
          image: AssetImage('assets/images/wave_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 42),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Image - Using your asset
                    Image.asset(
                      'assets/splash_logo_light.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    
                    // Business name with enhanced styling
                    Text(
                      business.name,
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A73E8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (business.description != null && business.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                        child: Text(
                          business.description!,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 36),
                    
                    // Decorative divider
                    Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Rating prompt with enhanced styling
                    Text(
                      'How was your experience?',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 24,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your feedback helps us improve our service',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    
                    // Enhanced Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: () => _handleRatingSelected(starValue),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 1.0,
                                end: _rating == starValue ? 1.2 : 1.0,
                              ),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Icon(
                                    _rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: _rating >= starValue ? Colors.amber[400] : Colors.grey[300],
                                    size: 35,
                                    shadows: _rating >= starValue ? [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    
                    // Enhanced rating text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<int>(_rating),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _rating > 0 
                            ? (_rating >= 4 ? Colors.green[50] : Colors.blue[50]) 
                            : Colors.grey[50],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _rating > 0 
                              ? (_rating >= 4 ? Colors.green[200]! : Colors.blue[200]!) 
                              : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          _getRatingText(),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: _rating > 0 
                              ? (_rating >= 4 ? Colors.green[700] : Colors.blue[700]) 
                              : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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

  Widget _buildThankYouView(BusinessModel business) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[600]!,
            Colors.green[800]!,
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/confetti_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/splash_logo_light.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                
                // Success animation
                Lottie.asset(
                  'assets/lottie/success.json',
                  width: 180,
                  height: 180,
                  repeat: true,
                ),
                const SizedBox(height: 24),
                
                // Thank you message with enhanced styling
                Text(
                  'Thank You!',
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  _rating >= 4
                      ? 'We appreciate your positive feedback! Thank you for taking the time to share your experience.'
                      : 'Thank you for your valuable feedback. We\'ll use it to improve our service.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                
                // Decorative confetti icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, color: Colors.green[300], size: 28),
                    const SizedBox(width: 12),
                    Icon(Icons.emoji_emotions, color: Colors.amber[400], size: 28),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite, color: Colors.red[300], size: 28),
                  ],
                ),
                const SizedBox(height: 36),
                
                // Back to business button with improved styling
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rating = 0;
                      _showThankYou = false;
                      _feedbackController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Rate Again',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.green[700]!, width: 2),
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
      return 'Tap a star to rate';
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