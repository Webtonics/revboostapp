// lib/features/dashboard/screens/enhanced_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:revboostapp/routing/app_router.dart';

import '../../../providers/dashboard_provider.dart';
import 'widgets/dashboard_metric_card.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/rating_distribution_chart.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/traffic_sources_chart.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    Future.microtask(() => 
      Provider.of<EnhancedDashboardProvider>(context, listen: false).loadDashboardData()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedDashboardProvider>(
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
                
                // Charts and detailed analytics
                _buildChartsSection(context, stats),
                
                const SizedBox(height: 32),
                
                // Recent activity and quick actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent activity
                    Expanded(
                      flex: 2,
                      child: RecentActivityWidget(
                        activities: stats.recentActivity,
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Quick actions
                    Expanded(
                      flex: 1,
                      child: DashboardQuickActions(
                        businessId: business.id,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, business, EnhancedDashboardProvider provider) {
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

  Widget _buildMetricsGrid(BuildContext context, DashboardStats stats, EnhancedDashboardProvider provider) {
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
              growthPercentage: provider.getGrowthPercentage('requests'),
              onTap: () => context.go(AppRoutes.reviewRequests),
            ),
            
            DashboardMetricCard(
              title: 'Reviews Received',
              value: _formatNumber(stats.reviewsReceived),
              icon: Icons.star_outline,
              color: Colors.amber,
              growthPercentage: provider.getGrowthPercentage('reviews'),
            ),
            
            DashboardMetricCard(
              title: 'QR Code Scans',
              value: _formatNumber(stats.qrCodeScans),
              icon: Icons.qr_code_scanner,
              color: Colors.purple,
              onTap: () => context.go(AppRoutes.qrCode),
            ),
            
            DashboardMetricCard(
              title: 'Page Views',
              value: _formatNumber(stats.pageViews),
              icon: Icons.visibility_outlined,
              color: Colors.teal,
              growthPercentage: provider.getGrowthPercentage('pageViews'),
            ),
            
            RatingMetricCard(
              rating: stats.averageRating,
              totalReviews: stats.reviewsReceived,
              growthPercentage: provider.getGrowthPercentage('rating'),
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

  Widget _buildChartsSection(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Charts in a row for larger screens, column for mobile
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1000) {
              return Row(
                children: [
                  Expanded(
                    child: RatingDistributionChart(
                      ratingDistribution: stats.ratingDistribution,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TrafficSourcesChart(
                      sourceBreakdown: stats.sourceBreakdown,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  RatingDistributionChart(
                    ratingDistribution: stats.ratingDistribution,
                  ),
                  const SizedBox(height: 24),
                  TrafficSourcesChart(
                    sourceBreakdown: stats.sourceBreakdown,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorView(EnhancedDashboardProvider provider) {
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

  Future<void> _previewReviewPage(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review page URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
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

  int _getColumnCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 3; // Max 3 columns for better readability
  }
}