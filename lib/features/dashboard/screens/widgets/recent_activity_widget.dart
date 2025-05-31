// lib/features/dashboard/widgets/recent_activity_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../providers/dashboard_provider.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivityWidget({
    Key? key,
    required this.activities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.timeline,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Activities list
            if (activities.isEmpty)
              _buildEmptyState(context)
            else
              Column(
                children: activities.map((activity) => 
                  _buildActivityItem(context, activity)
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity will appear here as customers interact with your review page',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, RecentActivity activity) {
    final theme = Theme.of(context);
    final isLast = activities.indexOf(activity) == activities.length - 1;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: _getActivityColor(activity.type),
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(activity.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.newReview:
        return Icons.star_rounded;
      case ActivityType.newFeedback:
        return Icons.feedback_rounded;
      case ActivityType.requestSent:
        return Icons.send_rounded;
      case ActivityType.pageView:
        return Icons.visibility_rounded;
      case ActivityType.qrScan:
        return Icons.qr_code_scanner_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.newReview:
        return Colors.amber;
      case ActivityType.newFeedback:
        return Colors.blue;
      case ActivityType.requestSent:
        return Colors.green;
      case ActivityType.pageView:
        return Colors.purple;
      case ActivityType.qrScan:
        return Colors.teal;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}