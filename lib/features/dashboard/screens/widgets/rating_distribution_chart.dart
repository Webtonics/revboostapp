// lib/features/dashboard/widgets/rating_distribution_chart.dart

import 'package:flutter/material.dart';

class RatingDistributionChart extends StatelessWidget {
  final Map<String, int> ratingDistribution;

  const RatingDistributionChart({
    Key? key,
    required this.ratingDistribution,
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
                  'Rating Distribution',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.bar_chart,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (ratingDistribution.isEmpty)
              _buildEmptyState(context)
            else
              _buildChart(context),
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
              Icons.star_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ratings yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rating distribution will appear here once customers start leaving reviews',
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

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate total for percentages
    final total = ratingDistribution.values.fold(0, (sum, count) => sum + count);
    
    // Ensure we have all ratings 1-5
    final completeDistribution = <String, int>{};
    for (int i = 5; i >= 1; i--) {
      completeDistribution[i.toString()] = ratingDistribution[i.toString()] ?? 0;
    }
    
    return Column(
      children: completeDistribution.entries.map((entry) {
        final rating = int.parse(entry.key);
        final count = entry.value;
        final percentage = total > 0 ? (count / total) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Rating with stars
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Text(
                      '$rating',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ],
                ),
              ),
              
              // Progress bar
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getRatingColor(rating),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Count and percentage
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${(percentage * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}