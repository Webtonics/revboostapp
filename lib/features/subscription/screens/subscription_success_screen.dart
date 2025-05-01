// lib/features/subscription/screens/subscription_success_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/models/subscription_model.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  final String? planId;

  const SubscriptionSuccessScreen({
    Key? key,
    this.planId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Subscription Activated',
      child: _buildSuccessContent(context),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        // Plan info
        final SubscriptionPlan plan = _getPlanInfo(subscriptionProvider);
        final subscription = subscriptionProvider.subscriptionStatus;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Success Title
                    Text(
                      'Subscription Activated!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Success Message
                    Text(
                      'You now have access to all ${plan.name} features',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Plan details card
                    _buildPlanDetailsCard(context, plan, subscription),
                    const SizedBox(height: 32),
                    
                    // What's next
                    _buildNextStepsCard(context),
                    const SizedBox(height: 48),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.go(AppRoutes.dashboard);
                          },
                          icon: const Icon(Icons.dashboard),
                          label: const Text('Go to Dashboard'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.go(AppRoutes.qrCode);
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Create QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanDetailsCard(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionStatus subscription,
  ) {
    final renewalDate = subscription.expiresAt != null 
        ? '${subscription.expiresAt!.month}/${subscription.expiresAt!.day}/${subscription.expiresAt!.year}'
        : 'Unknown';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Subscription Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Plan details
            _buildDetailRow(context, 'Plan', plan.name),
            _buildDetailRow(context, 'Billing Cycle', '${plan.interval}ly'),
            _buildDetailRow(context, 'Amount', '\$${plan.price.toStringAsFixed(2)} per ${plan.interval}'),
            _buildDetailRow(context, 'Next Renewal', renewalDate),
            
            const SizedBox(height: 16),
            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can manage your subscription at any time from the Subscription page.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s Next?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Steps
            _buildNextStep(
              context,
              '1',
              'Access your Review QR code',
              'Generate a QR code that customers can scan to leave reviews.',
              Icons.qr_code,
            ),
            const SizedBox(height: 20),
            _buildNextStep(
              context,
              '2',
              'Send review requests',
              'Email your customers asking for reviews with direct links.',
              Icons.email,
            ),
            const SizedBox(height: 20),
            // _buildNextStep(
            //   context,
            //   '3',
            //   'Monitor your dashboard',
            //   'Track your review performance and customer feedback.',
            //   Icons.analytics,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStep(
    BuildContext context,
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SubscriptionPlan _getPlanInfo(SubscriptionProvider provider) {
    // Try to get plan by ID passed in constructor
    if (planId != null) {
      try {
        return provider.availablePlans.firstWhere(
          (plan) => plan.id == planId,
        );
      } catch (_) {
        // If not found, fall through to current plan
      }
    }

    // Get current subscription plan
    final currentPlanId = provider.subscriptionStatus.planId;

    // Find the plan by ID
    if (currentPlanId != null) {
      try {
        return provider.availablePlans.firstWhere(
          (plan) => plan.id == currentPlanId,
        );
      } catch (_) {
        // Plan not found, return a default one
      }
    }

    // Fallback to a default plan if needed
    return SubscriptionPlan(
      id: 'unknown',
      name: 'RevBoost Pro',
      description: 'Premium subscription',
      price: 0,
      interval: 'month',
      features: [],
      lemonSqueezyProductId: '',
    );
  }
}