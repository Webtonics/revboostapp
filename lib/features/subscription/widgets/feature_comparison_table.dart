// lib/features/subscription/widgets/feature_comparison_table.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/core/theme/app_colors.dart';

class FeatureComparisonTable extends StatelessWidget {
  const FeatureComparisonTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildComparisonTable(context),
      ],
    );
  }
  
  Widget _buildComparisonTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          _buildTableRow(
            context,
            'Review Invitations',
            {'free': 'Up to 5/month', 'pro': 'Unlimited'},
          ),
          _buildTableRow(
            context,
            'Custom QR Codes',
            {'free': 'Limited', 'pro': 'Unlimited & Customizable'},
          ),
          _buildTableRow(
            context,
            'Email Invites',
            {'free': 'Basic Templates', 'pro': 'Custom Templates'},
          ),
          _buildTableRow(
            context,
            'SMS Invites',
            {'free': '❌', 'pro': '✅'},
          ),
          _buildTableRow(
            context,
            'Feedback Collection',
            {'free': 'Basic', 'pro': 'Advanced with Analytics'},
          ),
          _buildTableRow(
            context,
            'Dashboard Analytics',
            {'free': 'Limited', 'pro': 'Full Analytics Suite'},
          ),
          _buildTableRow(
            context,
            'Priority Support',
            {'free': '❌', 'pro': '✅'},
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Feature', style: headerStyle),
          ),
          Expanded(
            child: Center(child: Text('Free', style: headerStyle)),
          ),
          Expanded(
            child: Center(child: Text('Pro', style: headerStyle)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableRow(BuildContext context, String feature, Map<String, String> values) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                values['free'] ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  color: values['free'] == '❌' 
                      ? Colors.grey 
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                values['pro'] ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: values['pro'] == '✅' ? FontWeight.bold : null,
                  color: values['pro'] == '✅' 
                      ? AppColors.success 
                      : values['pro'] == '❌' 
                          ? Colors.grey 
                          : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}