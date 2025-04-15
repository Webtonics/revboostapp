// lib/features/review_requests/widgets/review_request_stats_card.dart

import 'package:flutter/material.dart';

/// A widget that displays review request statistics
class ReviewRequestStatsCard extends StatelessWidget {
  /// The statistics data to display
  final Map<String, dynamic> statistics;
  
  /// Whether statistics are currently loading
  final bool isLoading;
  
  /// Creates a [ReviewRequestStatsCard]
  const ReviewRequestStatsCard({
    Key? key,
    required this.statistics,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if stats are loaded
    final hasStats = statistics.isNotEmpty && !isLoading;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (!hasStats && !isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No statistics available yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Total Requests
            _buildStatCard(
              context,
              title: 'Total Requests',
              value: _formatNumber(statistics['total'] ?? 0),
              icon: Icons.email_outlined,
              iconColor: Theme.of(context).primaryColor,
              width: cardWidth,
            ),
            
            // Sent
            _buildStatCard(
              context,
              title: 'Sent',
              value: _formatNumber(statistics['sent'] ?? 0),
              icon: Icons.send_outlined,
              iconColor: Colors.blue,
              width: cardWidth,
            ),
            
            // Completed
            // _buildStatCard(
            //   context,
            //   title: 'Completed',
            //   value: _formatNumber(statistics['completed'] ?? 0),
            //   icon: Icons.check_circle_outline,
            //   iconColor: Colors.green,
            //   width: cardWidth,
            // ),
            
            // // Click Rate
            // _buildStatCard(
            //   context,
            //   title: 'Click Rate',
            //   value: _formatPercent(statistics['clickRate'] ?? 0),
            //   icon: Icons.touch_app_outlined,
            //   iconColor: Colors.orange,
            //   width: cardWidth,
            // ),
            
            // // Completion Rate
            // _buildStatCard(
            //   context,
            //   title: 'Completion Rate',
            //   value: _formatPercent(statistics['completionRate'] ?? 0),
            //   icon: Icons.assignment_turned_in_outlined,
            //   iconColor: Colors.purple,
            //   width: cardWidth,
            // ),
            
            // // Positive Rate
            // _buildStatCard(
            //   context,
            //   title: 'Positive Feedback',
            //   value: _formatPercent(statistics['positiveRate'] ?? 0),
            //   icon: Icons.thumb_up_outlined,
            //   iconColor: Colors.green,
            //   width: cardWidth,
            // ),
          ],
        );
      }
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Formats a number for display
  String _formatNumber(dynamic value) {
    if (value is int || value is double) {
      return value.toString();
    } else {
      return '0';
    }
  }
  
  /// Formats a number as a percentage
  String _formatPercent(dynamic value) {
    if (value is double) {
      return '${(value * 100).toStringAsFixed(1)}%';
    } else if (value is int) {
      return '$value%';
    } else {
      return '0%';
    }
  }
}