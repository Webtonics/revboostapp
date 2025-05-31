// lib/features/dashboard/widgets/dashboard_quick_actions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revboostapp/routing/app_router.dart';

class DashboardQuickActions extends StatelessWidget {
  final String businessId;

  const DashboardQuickActions({
    Key? key,
    required this.businessId,
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
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.flash_on,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.send_outlined,
                  title: 'Send Review Request',
                  subtitle: 'Email a customer for review',
                  color: Colors.blue,
                  onTap: () => context.go(AppRoutes.reviewRequests),
                ),
                
                const SizedBox(height: 12),
                
                _buildActionButton(
                  context,
                  icon: Icons.qr_code,
                  title: 'View QR Code',
                  subtitle: 'Display or print QR code',
                  color: Colors.purple,
                  onTap: () => context.go(AppRoutes.qrCode),
                ),
                
                const SizedBox(height: 12),
                
                _buildActionButton(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'View Feedback',
                  subtitle: 'See customer feedback',
                  color: Colors.orange,
                  onTap: () => context.go(AppRoutes.feedback),
                ),
                
                const SizedBox(height: 12),
                
                _buildActionButton(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Business Settings',
                  subtitle: 'Update business info',
                  color: Colors.teal,
                  onTap: () => context.go(AppRoutes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}