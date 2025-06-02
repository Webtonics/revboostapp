// lib/features/dashboard/widgets/dashboard_metric_card.dart

import 'package:flutter/material.dart';

class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? growthPercentage;
  final bool? isPositiveGrowth;
  final String? subtitle;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.growthPercentage,
    this.isPositiveGrowth,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with icon and growth indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (growthPercentage != null) _buildGrowthIndicator(),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Main value
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 32,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Subtitle if provided
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthIndicator() {
    if (growthPercentage == null) return const SizedBox.shrink();
    
    final isPositive = isPositiveGrowth ?? (growthPercentage! > 0);
    final growthColor = isPositive ? Colors.green : Colors.red;
    final growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: growthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            growthIcon,
            size: 16,
            color: growthColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${growthPercentage!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: growthColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized metric cards for specific use cases

class RatingMetricCard extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double? growthPercentage;

  const RatingMetricCard({
    Key? key,
    required this.rating,
    required this.totalReviews,
    this.growthPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DashboardMetricCard(
      title: 'Average Rating',
      value: rating > 0 ? rating.toStringAsFixed(1) : '—',
      icon: Icons.star_rounded,
      color: _getRatingColor(rating),
      // growthPercentage: growthPercentage,
      subtitle: totalReviews > 0 ? 'from $totalReviews reviews' : 'No reviews yet',
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }
}

class ConversionMetricCard extends StatelessWidget {
  final double conversionRate;
  final int totalViews;
  final int totalConversions;

  const ConversionMetricCard({
    Key? key,
    required this.conversionRate,
    required this.totalViews,
    required this.totalConversions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardMetricCard(
      title: 'Conversion Rate',
      value: '${(conversionRate * 100).toStringAsFixed(1)}%',
      icon: Icons.trending_up_rounded,
      color: Colors.purple,
      subtitle: '$totalConversions of $totalViews visitors',
    );
  }
}