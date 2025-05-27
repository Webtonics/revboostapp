// lib/features/subscription/widgets/subscription_plans_section.dart - Updated with trial eligibility

import 'package:flutter/material.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
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
        _buildSectionHeader(context),
        const SizedBox(height: 24),
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
  
  Widget _buildSectionHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEligible = provider.isEligibleForTrial;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEligible 
              ? 'Start with a 14-day free trial'
              : 'Choose Your Plan',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isEligible) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.getTrialUnavailableReason(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final isEligibleForTrial = provider.isEligibleForTrial;
    
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
            if (isEligibleForTrial)
              Text(
                'Start with a 14-day free trial',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                'No free trial available',
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
            
            // Action buttons
            _buildActionButtons(context, plan, provider, isEligibleForTrial),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionProvider provider,
    bool isEligibleForTrial,
  ) {
    return Column(
      children: [
        // Free trial button (conditional)
        if (isEligibleForTrial) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Start Free Trial',
              type: AppButtonType.primary,
              fullWidth: true,
              isLoading: provider.isProcessingTrial,
              onPressed: () {
                _showStartTrialDialog(context, plan, provider);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Subscribe button
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: isEligibleForTrial ? 'Subscribe Now' : 'Subscribe',
            type: isEligibleForTrial ? AppButtonType.secondary : AppButtonType.primary,
            fullWidth: true,
            isLoading: provider.isProcessingCheckout,
            onPressed: () {
              provider.selectPlan(plan.id);
              provider.redirectToCheckout();
            },
          ),
        ),
        
        // Disabled trial button with explanation (for ineligible users)
        if (!isEligibleForTrial) ...[
          const SizedBox(height: 12),
          const SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Free Trial Used',
              type: AppButtonType.text,
              fullWidth: true,
              onPressed: null, // Disabled
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.getTrialUnavailableReason(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
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
            const Text(
              'You\'re about to start a 14-day free trial with all Pro features.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Important:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• No credit card required to start\n'
                    '• Trial automatically expires after 14 days\n'
                    '• You can only use the free trial once\n'
                    '• Subscribe anytime during or after trial',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: provider.isProcessingTrial ? null : () async {
              Navigator.pop(context);
              
              final success = await provider.startFreeTrial();
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Your 14-day free trial has started!'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage ?? 'Failed to start trial',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: provider.isProcessingTrial
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Trial'),
          ),
        ],
      ),
    );
  }
}