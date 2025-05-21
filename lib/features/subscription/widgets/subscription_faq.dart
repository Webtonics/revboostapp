// lib/features/subscription/widgets/subscription_faq.dart

import 'package:flutter/material.dart';

class SubscriptionFAQ extends StatelessWidget {
  const SubscriptionFAQ({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildFAQItem(
          context,
          question: 'How does the free trial work?',
          answer: 'Your 14-day free trial gives you full access to all Pro features. '
                 'No credit card is required to start. Once your trial ends, you\'ll '
                 'need to subscribe to continue using premium features.',
        ),
        _buildFAQItem(
          context,
          question: 'Can I cancel my subscription anytime?',
          answer: 'Yes, you can cancel your subscription at any time from your '
                 'account settings. After cancellation, you\'ll continue to have '
                 'access to Pro features until the end of your current billing period.',
        ),
        _buildFAQItem(
          context,
          question: 'What payment methods do you accept?',
          answer: 'We accept all major credit cards, including Visa, Mastercard, '
                 'American Express, and Discover.',
        ),
        _buildFAQItem(
          context,
          question: 'Will I be charged automatically after my free trial?',
          answer: 'No, we won\'t automatically charge you after your free trial. '
                 'You\'ll need to manually subscribe to continue using Pro features.',
        ),
        _buildFAQItem(
          context,
          question: 'Can I switch plans later?',
          answer: 'Yes, you can switch between monthly and yearly plans at any time. '
                 'If you upgrade, the new plan will take effect immediately. If you '
                 'downgrade, the change will take effect at the end of your current '
                 'billing period.',
        ),
      ],
    );
  }
  
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final textTheme = Theme.of(context).textTheme;
    
    return ExpansionTile(
      title: Text(
        question,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Text(
            answer,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}