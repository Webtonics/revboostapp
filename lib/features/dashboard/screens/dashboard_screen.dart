// // lib/features/dashboard/screens/dashboard_screen.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:revboostapp/models/dashboard_model.dart';
// import 'package:revboostapp/providers/dashboard_provider.dart';
// import 'package:revboostapp/widgets/layout/app_layout.dart';
// import 'package:intl/intl.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({Key? key}) : super(key: key);

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Load dashboard data when screen initializes
//     Future.microtask(() => 
//       Provider.of<DashboardProvider>(context, listen: false).loadDashboardData()
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       title: 'Dashboard',
//       child: Consumer<DashboardProvider>(
//         builder: (context, dashboardProvider, child) {
//           if (dashboardProvider.isLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
          
//           if (dashboardProvider.errorMessage != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     size: 64,
//                     color: Theme.of(context).colorScheme.error,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Error',
//                     style: Theme.of(context).textTheme.headlineMedium,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     dashboardProvider.errorMessage!,
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.bodyLarge,
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () => dashboardProvider.loadDashboardData(),
//                     child: const Text('Try Again'),
//                   ),
//                 ],
//               ),
//             );
//           }
          
//           final stats = dashboardProvider.stats;
//           return DashboardContent(stats: stats);
//         },
//       ),
//     );
//   }
// }

// class DashboardContent extends StatelessWidget {
//   final DashboardStats stats;
  
//   const DashboardContent({
//     Key? key,
//     required this.stats,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () => Provider.of<DashboardProvider>(context, listen: false).loadDashboardData(),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Welcome back!',
//               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Here\'s an overview of your reviews',
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//             const SizedBox(height: 24),
            
//             // Stats cards
//             _buildStatsCards(context),
            
//             const SizedBox(height: 32),
            
//             // Rating distribution
//             _buildRatingDistribution(context),
            
//             const SizedBox(height: 32),
            
//             // Platform distribution
//             _buildPlatformDistribution(context),
            
//             const SizedBox(height: 32),
            
//             // Recent activity
//             _buildRecentActivity(context),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildStatsCards(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: _getColumnCount(context),
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       childAspectRatio: 1.5,
//       children: [
//         _buildStatCard(
//           context, 
//           'Review Requests', 
//           stats.totalReviewRequests.toString(),
//           Icons.outgoing_mail,
//           Colors.blue,
//         ),
//         _buildStatCard(
//           context, 
//           'Reviews Received', 
//           stats.reviewsReceived.toString(),
//           Icons.star_outline,
//           Colors.green,
//         ),
//         _buildStatCard(
//           context, 
//           'QR Code Scans', 
//           stats.qrCodeScans.toString(),
//           Icons.qr_code_scanner_outlined,
//           Colors.purple,
//         ),
//         _buildStatCard(
//           context, 
//           'Click-Through Rate', 
//           '${(stats.clickThroughRate * 100).toInt()}%',
//           Icons.touch_app_outlined,
//           Colors.orange,
//         ),
//       ],
//     );
//   }
  
//   Widget _buildRatingDistribution(BuildContext context) {
//     if (stats.ratingDistribution.isEmpty) {
//       return const SizedBox.shrink();
//     }
    
//     return Card(
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.star, color: Colors.amber[700], size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Rating Distribution',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
            
//             // Simple bar chart
//             ...stats.ratingDistribution.entries.map((entry) {
//               final totalReviews = stats.ratingDistribution.values
//                   .fold(0, (sum, count) => sum + count);
//               final percentage = totalReviews > 0 
//                   ? (int.parse(entry.value.toString()) / totalReviews * 100).toInt()
//                   : 0;
              
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           child: Text(
//                             '${entry.key}★',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Stack(
//                             children: [
//                               Container(
//                                 height: 20,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               FractionallySizedBox(
//                                 widthFactor: percentage / 100,
//                                 child: Container(
//                                   height: 20,
//                                   decoration: BoxDecoration(
//                                     color: _getRatingColor(int.parse(entry.key)),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         SizedBox(
//                           width: 40,
//                           child: Text(
//                             '${entry.value}',
//                             textAlign: TextAlign.end,
//                           ),
//                         ),
//                         SizedBox(
//                           width: 40,
//                           child: Text(
//                             '$percentage%',
//                             textAlign: TextAlign.end,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildPlatformDistribution(BuildContext context) {
//     if (stats.platformDistribution.isEmpty) {
//       return const SizedBox.shrink();
//     }
    
//     return Card(
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.pie_chart_outline, color: Colors.purple[700], size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Platform Distribution',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
            
//             ...stats.platformDistribution.entries.map((entry) {
//               final totalReviews = stats.platformDistribution.values
//                   .fold(0, (sum, count) => sum + count);
//               final percentage = totalReviews > 0 
//                   ? (entry.value / totalReviews * 100).toInt()
//                   : 0;
              
//               IconData icon;
//               Color color;
              
//               switch (entry.key) {
//                 case 'Google':
//                   icon = Icons.g_mobiledata;
//                   color = Colors.blue;
//                   break;
//                 case 'Facebook':
//                   icon = Icons.facebook;
//                   color = Colors.indigo;
//                   break;
//                 case 'Yelp':
//                   icon = Icons.restaurant_menu;
//                   color = Colors.red;
//                   break;
//                 case 'TripAdvisor':
//                   icon = Icons.travel_explore;
//                   color = Colors.green;
//                   break;
//                 default:
//                   icon = Icons.public;
//                   color = Colors.grey;
//               }
              
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Row(
//                   children: [
//                     Icon(icon, color: color, size: 20),
//                     const SizedBox(width: 8),
//                     Text(
//                       entry.key,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       '${entry.value} reviews',
//                       style: TextStyle(
//                         color: Theme.of(context).brightness == Brightness.dark
//                             ? Colors.grey[400]
//                             : Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '$percentage%',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildRecentActivity(BuildContext context) {
//     if (stats.recentActivity.isEmpty) {
//       return const SizedBox.shrink();
//     }
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Recent Activity',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
        
//         // Activity items
//         ...stats.recentActivity.map((activity) => _buildActivityItem(context, activity)).toList(),
//       ],
//     );
//   }
  
//   Widget _buildActivityItem(BuildContext context, ReviewActivity activity) {
//     IconData iconData;
//     Color iconColor;
    
//     switch (activity.type) {
//       case ActivityType.newReview:
//         iconData = Icons.star;
//         iconColor = Colors.amber;
//         break;
//       case ActivityType.feedback:
//         iconData = Icons.feedback;
//         iconColor = Colors.blue;
//         break;
//       case ActivityType.requestSent:
//         iconData = Icons.send;
//         iconColor = Colors.green;
//         break;
//       case ActivityType.qrScan:
//         iconData = Icons.qr_code_scanner;
//         iconColor = Colors.purple;
//         break;
//     }
    
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               CircleAvatar(
//                 radius: 20,
//                 backgroundColor: iconColor.withOpacity(0.1),
//                 child: Icon(iconData, color: iconColor, size: 20),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       activity.title,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       activity.subtitle,
//                       style: TextStyle(
//                         color: Theme.of(context).brightness == Brightness.dark
//                             ? Colors.grey[400]
//                             : Colors.grey[600],
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 _formatTimeAgo(activity.timestamp),
//                 style: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.dark
//                       ? Colors.grey[400]
//                       : Colors.grey[600],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Divider(),
//       ],
//     );
//   }
  
//   Widget _buildStatCard(
//     BuildContext context, 
//     String title, 
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Card(
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//               ],
//             ),
//             const Spacer(),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             const Spacer(),
//           ],
//         ),
//       ),
//     );
//   }
  
//   int _getColumnCount(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     if (width < 600) return 1;
//     if (width < 900) return 2;
//     if (width < 1200) return 3;
//     return 4;
//   }
  
//   Color _getRatingColor(int rating) {
//     switch (rating) {
//       case 1:
//         return Colors.red;
//       case 2:
//         return Colors.orange;
//       case 3:
//         return Colors.amber;
//       case 4:
//         return Colors.lightGreen;
//       case 5:
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }
  
//   String _formatTimeAgo(DateTime time) {
//     final now = DateTime.now();
//     final difference = now.difference(time);
    
//     if (difference.inSeconds < 60) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return DateFormat('MMM d, yyyy').format(time);
//     }
//   }
// }
// lib/features/dashboard/screens/dashboard_screen.dart - simplified
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/dashboard_provider.dart';
import 'package:revboostapp/routing/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    Future.microtask(() => 
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (dashboardProvider.errorMessage != null) {
          return Center(
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
                  'Error',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  dashboardProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => dashboardProvider.loadDashboardData(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        
        final business = dashboardProvider.businessData;
        if (business == null) {
          return const Center(
            child: Text('No business data available'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Text(
                'Welcome, ${business.name}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your online reviews and reputation',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              
              // Business card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (business.description != null && business.description!.isNotEmpty)
                                  Text(
                                    business.description!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (business.reviewLinks.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text(
                          'Connected Review Platforms',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: business.reviewLinks.entries.map((entry) {
                            IconData icon;
                            switch (entry.key) {
                              case 'Google Business Profile':
                                icon = Icons.business;
                                break;
                              case 'Yelp':
                                icon = Icons.restaurant_menu;
                                break;
                              case 'Facebook':
                                icon = Icons.facebook;
                                break;
                              default:
                                icon = Icons.link;
                            }
                            
                            return GestureDetector(
                              onTap: () => context.go(AppRoutes.settings),
                              child: Chip(
                                avatar: Icon(icon, size: 16),
                                label: Text(entry.key),
                                
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Quick actions section
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: _getColumnCount(context),
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.3,
                children: [
                  _buildActionCard(
                    context,
                    'View QR Code',
                    // 'Generate and print QR codes',
                    Icons.qr_code,
                    Colors.purple,
                    () => context.go(AppRoutes.qrCode),
                  ),
                  _buildActionCard(
                    context,
                    'Send Review Request',
                    // 'Email or SMS to customers',
                    Icons.send,
                    Colors.blue,
                    () => context.go(AppRoutes.reviewRequests),
                  ),
                  _buildActionCard(
                    context,
                    'Manage Account',
                    // 'Update business details',
                    Icons.people,
                    Colors.orange,
                    () =>context.go(AppRoutes.settings),
                  ),
                  _buildActionCard(
                    context,
                    'Manage Subscriptions',
                    // 'Manage your subscriptions',
                    Icons.subscriptions,
                    // Icons.description,
                    Colors.green,
                    () => context.go(AppRoutes.subscription),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Coming soon features
              _buildComingSoonSection(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildActionCard(
    BuildContext context,
    String title,
    // String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Text(
              //   subtitle,
              //   style: Theme.of(context).textTheme.bodySmall,
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildComingSoonSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upcoming,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coming Soon',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildComingSoonFeature(
              context,
              'Analytics Dashboard',
              'Track your reviews and ratings over time',
              Icons.bar_chart,
            ),
            const Divider(),
            _buildComingSoonFeature(
              context,
              'Automated Responses',
              'Quickly respond to customer reviews',
              Icons.chat,
            ),
            const Divider(),
            _buildComingSoonFeature(
              context,
              'Review Monitoring',
              'Get notified of new reviews across platforms',
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComingSoonFeature(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }
}