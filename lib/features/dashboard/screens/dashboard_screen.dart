// lib/features/dashboard/screens/simplified_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/features/dashboard/screens/widgets/dashboard_metric_card.dart';
import 'package:revboostapp/features/dashboard/screens/widgets/dashboard_quick_actions.dart';

import '../../../providers/dashboard_provider.dart';

class SimplifiedDashboardScreen extends StatefulWidget {
  const SimplifiedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SimplifiedDashboardScreen> createState() => _SimplifiedDashboardScreenState();
}

class _SimplifiedDashboardScreenState extends State<SimplifiedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    Future.microtask(() => 
      Provider.of<SimplifiedDashboardProvider>(context, listen: false).loadDashboardData()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimplifiedDashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (dashboardProvider.errorMessage != null) {
          return _buildErrorView(dashboardProvider);
        }
        
        final business = dashboardProvider.businessData;
        final stats = dashboardProvider.stats;
        
        if (business == null) {
          return const Center(
            child: Text('No business data available'),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => dashboardProvider.refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with business info and preview button
                _buildHeader(context, business, dashboardProvider),
                
                const SizedBox(height: 32),
                
                // Key metrics cards
                _buildMetricsGrid(context, stats, dashboardProvider),
                
                const SizedBox(height: 32),
                
                // Charts section
                _buildChartsSection(context, stats),
                
                const SizedBox(height: 32),
                
                // Recent activity and quick actions
                _buildBottomSection(context, stats, business),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, business, SimplifiedDashboardProvider provider) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s how ${business.name} is performing',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last updated: ${_formatLastUpdated(provider.stats.lastUpdated)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Preview button and refresh
        Row(
          children: [
            IconButton(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            ),
            
            const SizedBox(width: 12),
            
            ElevatedButton.icon(
              onPressed: () => _previewReviewPage(provider.getReviewPageUrl()),
              icon: const Icon(Icons.open_in_new, color: Colors.white,),
              label: const Text('Preview Review Funnel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SimplifiedDashboardStats stats, SimplifiedDashboardProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _getColumnCount(constraints.maxWidth);
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 1.4,
          children: [
            DashboardMetricCard(
              title: 'Review Requests Sent',
              value: _formatNumber(stats.totalReviewRequests),
              icon: Icons.send_outlined,
              color: Colors.blue,
              // growthPercentage: provider.getGrowthPercentage('requests'),
              onTap: () => context.go(AppRoutes.reviewRequests),
            ),
            
            DashboardMetricCard(
              title: 'Reviews Received',
              value: _formatNumber(stats.reviewsReceived),
              icon: Icons.star_outline,
              color: Colors.amber,
              // growthPercentage: provider.getGrowthPercentage('reviews'),
              subtitle: 'from feedback submissions',
            ),
            
            DashboardMetricCard(
              title: 'Funnel Views',
              value: _formatNumber(stats.pageViews),
              icon: Icons.visibility_outlined,
              color: Colors.teal,
              // growthPercentage: provider.getGrowthPercentage('pageViews'),
              subtitle: 'total Funnel visits',
            ),
            
            DashboardMetricCard(
              title: 'QR Code Scans',
              value: _formatNumber(stats.qrCodeScans),
              icon: Icons.qr_code_scanner,
              color: Colors.purple,
              subtitle: 'via QR code',
              onTap: () => context.go(AppRoutes.qrCode),
            ),
            
            RatingMetricCard(
              rating: stats.averageRating,
              totalReviews: stats.reviewsReceived,
              // growthPercentage: provider.getGrowthPercentage('rating'),
            ),
            
            ConversionMetricCard(
              conversionRate: stats.conversionRate,
              totalViews: stats.pageViews,
              totalConversions: stats.reviewsReceived,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, SimplifiedDashboardStats stats) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Simple charts
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1000) {
              return Row(
                children: [
                  Expanded(child: _buildRatingChart(context, stats)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSourceChart(context, stats)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRatingChart(context, stats),
                  const SizedBox(height: 24),
                  _buildSourceChart(context, stats),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildRatingChart(BuildContext context, SimplifiedDashboardStats stats) {
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
            
            if (stats.ratingDistribution.isEmpty)
              _buildEmptyChart('No ratings yet')
            else
              _buildRatingBars(context, stats.ratingDistribution),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceChart(BuildContext context, SimplifiedDashboardStats stats) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Traffic Sources',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.pie_chart,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (stats.sourceBreakdown.isEmpty)
              _buildEmptyChart('No traffic data yet')
            else
              _buildSourceList(context, stats.sourceBreakdown),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBars(BuildContext context, Map<String, int> distribution) {
    final theme = Theme.of(context);
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: [5, 4, 3, 2, 1].map((rating) {
        final count = distribution[rating.toString()] ?? 0;
        final percentage = total > 0 ? (count / total) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Row(
                  children: [
                    Text('$rating'),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              ),
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
              SizedBox(
                width: 60,
                child: Text(
                  '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourceList(BuildContext context, Map<String, int> breakdown) {
    final theme = Theme.of(context);
    final total = breakdown.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: breakdown.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getSourceColor(entry.key),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_getSourceDisplayName(entry.key)),
              ),
              Text(
                '${entry.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection(BuildContext context, SimplifiedDashboardStats stats, business) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent activity
        // Expanded(
        //   flex: 2,
        //   child: _buildRecentActivity(context, stats),
        // ),
        
        // const SizedBox(width: 24),
        
        // Quick actions
        Expanded(
          flex: 1,
          child: DashboardQuickActions(
            businessId: business.id,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, SimplifiedDashboardStats stats) {
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
            
            if (stats.recentActivity.isEmpty)
              _buildEmptyChart('No recent activity')
            else
              Column(
                children: stats.recentActivity.take(5).map((activity) => 
                  _buildActivityItem(context, activity)
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, SimpleRecentActivity activity) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.type == 'review' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              activity.type == 'review' ? Icons.star : Icons.visibility,
              color: activity.type == 'review' ? Colors.green : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
                Text(
                  activity.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
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

  Widget _buildErrorView(SimplifiedDashboardProvider provider) {
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
              'Error Loading Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadDashboardData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5: return Colors.green;
      case 4: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 2: return Colors.deepOrange;
      case 1: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'qr': return Colors.purple;
      case 'email': return Colors.blue;
      case 'direct': return Colors.green;
      case 'link': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getSourceDisplayName(String source) {
    switch (source.toLowerCase()) {
      case 'qr': return 'QR Code Scans';
      case 'email': return 'Email Links';
      case 'direct': return 'Direct Access';
      case 'link': return 'Shared Links';
      default: return source.toUpperCase();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatLastUpdated(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
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
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  int _getColumnCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 3;
  }

  Future<void> _previewReviewPage(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review Funnel URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Add tracking parameter to show it came from dashboard preview
      final previewUrl = '$url?source=dashboard_preview';
      final uri = Uri.parse(previewUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open review page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}