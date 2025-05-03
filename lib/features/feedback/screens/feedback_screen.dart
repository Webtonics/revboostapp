import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revboostapp/core/services/feedback_service.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/models/feedback_model.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

/// Displays the current user's business feedback from customers
class BusinessFeedbackPage extends StatefulWidget {
  const BusinessFeedbackPage({Key? key}) : super(key: key);

  @override
  _BusinessFeedbackPageState createState() => _BusinessFeedbackPageState();
}

class _BusinessFeedbackPageState extends State<BusinessFeedbackPage> {
  late Future<List<FeedbackModel>> _feedbacksFuture;
  late final FeedbackService _feedbackService;
  bool _initialized = false;
  String? _businessId;
  String? _businessName;
  String? _userEmail;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Initialize services
      final emailService = Provider.of<EmailService>(context, listen: false);
      _feedbackService = FeedbackService(emailService: emailService);

      // Load user's business information and feedback
      _feedbacksFuture = _loadBusinessDataAndFeedback();
      _initialized = true;
    }
  }

  /// Load business data and then load all feedback for that business
  Future<List<FeedbackModel>> _loadBusinessDataAndFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Store user email for later use
    _userEmail = user.email;
    
    // First get the user document to find business IDs
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists) {
      throw Exception('User document not found');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    
    // Get business IDs from user document
    final businessIds = List<String>.from(userData['businessIds'] ?? []);
    
    if (businessIds.isEmpty) {
      throw Exception('No businesses found for user');
    }
    
    // Use the first business ID (most apps have one business per user)
    _businessId = businessIds.first;
    
    // Get business details
    final businessDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .get();
    
    if (businessDoc.exists) {
      final businessData = businessDoc.data() as Map<String, dynamic>;
      _businessName = businessData['name'] as String?;
    }
    
    // Now load the feedback for this business
    return await _feedbackService.getFeedbackForBusinessOnce(_businessId!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedbackModel>>(
      future: _feedbacksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading feedback',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _feedbacksFuture = _loadBusinessDataAndFeedback();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final feedbacks = snapshot.data ?? [];
        
        if (feedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.feedback_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No feedback yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'When customers provide feedback, it will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Show business info at the top
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_businessName != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _businessName!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_userEmail != null)
                          Text(
                            _userEmail!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Feedback: ${feedbacks.length}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            Expanded(
              child: ListView.builder(
                itemCount: feedbacks.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) => _buildFeedbackCard(feedbacks[index], index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackModel fb, int index) {
    // Determine color based on rating
    Color ratingColor;
    if (fb.rating >= 4) {
      ratingColor = Colors.green;
    } else if (fb.rating >= 3) {
      ratingColor = Colors.orange;
    } else {
      ratingColor = Colors.red;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 100),
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rating and name
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratingColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: ratingColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          fb.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ratingColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fb.customerName ?? 'Anonymous Customer',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(fb.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Feedback content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fb.feedback,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (fb.customerEmail != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fb.customerEmail!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Status chip and action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(fb.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fb.status.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(fb.status),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Reply button
                      if (fb.customerEmail != null)
                        TextButton.icon(
                          icon: const Icon(Icons.reply, size: 18),
                          label: const Text('Reply'),
                          onPressed: () {
                            // Implement reply functionality
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      // Mark as reviewed or block button
                      if (fb.status == FeedbackStatus.submitted)
                        TextButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Mark Reviewed'),
                          onPressed: () {
                            _updateFeedbackStatus(fb.id, FeedbackStatus.reviewed);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format timestamp to readable date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // Get color based on feedback status
  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.submitted:
        return Colors.blue;
      case FeedbackStatus.reviewed:
        return Colors.green;
      case FeedbackStatus.blocked:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Update feedback status
  void _updateFeedbackStatus(String feedbackId, FeedbackStatus newStatus) async {
    try {
      await _feedbackService.updateFeedbackStatus(feedbackId, newStatus);
      
      // Refresh the feedback list
      setState(() {
        _feedbacksFuture = _loadBusinessDataAndFeedback();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback status updated to ${newStatus.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating feedback status: $e')),
      );
    }
  }
}

