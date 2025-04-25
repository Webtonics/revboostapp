import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revboostapp/core/services/feedback_service.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/models/feedback_model.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

/// Displays only the current user's business 'blocked' or low-rating feedback
class BlockedFeedbackPage extends StatefulWidget {
  const BlockedFeedbackPage({Key? key}) : super(key: key);

  @override
  _BlockedFeedbackPageState createState() => _BlockedFeedbackPageState();
}

class _BlockedFeedbackPageState extends State<BlockedFeedbackPage> {
  late Future<List<FeedbackModel>> _feedbacksFuture;
  late final FeedbackService _feedbackService;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Initialize services
      final emailService = Provider.of<EmailService>(context, listen: false);
      _feedbackService = FeedbackService(emailService: emailService);

      // Chain retrieving the businessId then loading its feedbacks
      _feedbacksFuture = _getBusinessId()
          .then((businessId) => _loadBlockedFeedbacks(businessId));

      _initialized = true;
    }
  }

  /// Query Firestore 'businesses' to find the document owned by current user
  Future<String> _getBusinessId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('No business found for user');
    }
    // Document ID is the businessId used in feedback documents
    return snap.docs.first.id;
  }

  /// Load all feedbacks for this business, then filter blocked or rating <= 3
  Future<List<FeedbackModel>> _loadBlockedFeedbacks(String businessId) async {
    // Use existing service to fetch once
    final all = await _feedbackService.getFeedbackForBusinessOnce(businessId);
    // Filter for blocked status or low ratings
    return all.where((f) {
      return f.status == FeedbackStatus.blocked || f.rating <= 3;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Blocked Feedback',
      child: FutureBuilder<List<FeedbackModel>>(
        future: _feedbacksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          final feedbacks = snapshot.data ?? [];
          if (feedbacks.isEmpty) {
            return Center(
              child: Text(
                'No blocked feedback found.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) => _buildFeedbackCard(feedbacks[index], index),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel fb, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 100),
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            child: Text(
              fb.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          title: Text(
            fb.customerName ?? 'Anonymous',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(fb.feedback, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (fb.customerEmail != null)
                Text(fb.customerEmail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fb.status == FeedbackStatus.blocked
                  ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              fb.status.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
    );
  }
}

