// lib/features/subscription/widgets/subscription_plans_section.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/models/subscription_model.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/common/app_button.dart';

class SubscriptionPlansSection extends StatelessWidget {
  final SubscriptionProvider provider;
  
  const SubscriptionPlansSection({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plans = provider.availablePlans;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Start with a 14-day free trial',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout for subscription plans
            if (constraints.maxWidth < 800) {
              // Stacked layout for smaller screens
              return Column(
                children: [
                  _buildPlanCard(
                    context,
                    plan: plans.firstWhere((p) => p.id == 'monthly'),
                    isRecommended: true,
                    provider: provider,
                  ),
                  const SizedBox(height: 24),
                  _buildPlanCard(
                    context,
                    plan: plans.firstWhere((p) => p.id == 'yearly'),
                    isRecommended: false,
                    provider: provider,
                  ),
                ],
              );
            } else {
              // Side-by-side layout for larger screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      context,
                      plan: plans.firstWhere((p) => p.id == 'monthly'),
                      isRecommended: true,
                      provider: provider,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildPlanCard(
                      context,
                      plan: plans.firstWhere((p) => p.id == 'yearly'),
                      isRecommended: false,
                      provider: provider,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildPlanCard(
    BuildContext context, {
    required SubscriptionPlan plan,
    required bool isRecommended,
    required SubscriptionProvider provider,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: isRecommended
              ? Border.all(
                  color: colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              plan.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${plan.price}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    plan.interval == 'monthly' ? '/month' : '/year',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Start with a 14-day free trial',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981), // Success green
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Start Free Trial',
                type: AppButtonType.primary,
                fullWidth: true,
                onPressed: () {
                  _showStartTrialDialog(context, plan, provider);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Subscribe Now',
                type: AppButtonType.secondary,
                fullWidth: true,
                onPressed: () {
                  provider.selectPlan(plan.id);
                  provider.redirectToCheckout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showStartTrialDialog(
    BuildContext context, 
    SubscriptionPlan plan, 
    SubscriptionProvider provider
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Your Free Trial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to start a 14-day free trial with all Pro features. '
              'After your trial ends, you\'ll be automatically subscribed to the ${plan.name} plan '
              'at \$${plan.price}/${plan.interval == 'monthly' ? 'month' : 'year'} unless you cancel.',
            ),
            const SizedBox(height: 16),
            const Text(
              'No credit card required to start your trial.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.startFreeTrial();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your free trial has started!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Start Trial'),
          ),
        ],
      ),
    );
  }
}