// lib/features/subscription/widgets/current_subscription_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/common/app_button.dart';

class CurrentSubscriptionCard extends StatelessWidget {
  final SubscriptionProvider provider;
  
  const CurrentSubscriptionCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isFreeTrial = provider.isFreeTrial;
    final subscription = provider.subscriptionStatus;
    
    // Format expiration date
    String expiryText = 'N/A';
    if (subscription.expiresAt != null) {
      final formatter = DateFormat('MMMM d, yyyy');
      expiryText = formatter.format(subscription.expiresAt!);
    } else if (isFreeTrial && subscription.trialEndDate != null) {
      final formatter = DateFormat('MMMM d, yyyy');
      expiryText = formatter.format(subscription.trialEndDate!);
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isFreeTrial 
                        ? AppColors.info.withOpacity(0.1) 
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFreeTrial ? "FREE TRIAL" : "ACTIVE",
                    style: textTheme.labelSmall?.copyWith(
                      color: isFreeTrial ? AppColors.info : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isFreeTrial)
                  TextButton.icon(
                    onPressed: () async {
                      final url = await provider.getCustomerPortalUrl();
                      if (url != null) {
                         provider.openBillingPortal();
                      }
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text("Manage Billing"),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isFreeTrial 
                  ? "Free Trial - Full Access" 
                  : subscription.planId == 'monthly' 
                      ? "Pro Monthly" 
                      : "Pro Yearly",
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isFreeTrial 
                  ? "Your trial gives you full access to all features" 
                  : "Thank you for your subscription",
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Subscription details
            _buildSubscriptionDetailItem(
              context,
              icon: Icons.calendar_today_outlined,
              title: isFreeTrial ? "Trial Ends" : "Next Billing Date",
              value: expiryText,
            ),
            const SizedBox(height: 16),
            
            if (!isFreeTrial) ...[
              _buildSubscriptionDetailItem(
                context,
                icon: Icons.credit_card_outlined,
                title: "Payment Method",
                value: "••••••••••••4242",
              ),
              const SizedBox(height: 16),
            ],
            
            _buildSubscriptionDetailItem(
              context,
              icon: Icons.workspace_premium_outlined,
              title: "Plan",
              value: isFreeTrial 
                  ? "Free Trial" 
                  : subscription.planId == 'monthly' 
                      ? "Pro Monthly - \$29.99/month" 
                      : "Pro Yearly - \$299.99/year",
            ),
            
            const SizedBox(height: 32),
            
            if (isFreeTrial)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: "Upgrade Now",
                      type: AppButtonType.primary,
                      fullWidth: true,
                      onPressed: () {
                        provider.selectPlan('monthly');
                        provider.redirectToCheckout();
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: "Manage Subscription",
                      type: AppButtonType.secondary,
                      fullWidth: true,
                      onPressed: () async {
                        final url = await provider.getCustomerPortalUrl();
                        if (url != null) {
                           provider.openBillingPortal();
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionDetailItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}