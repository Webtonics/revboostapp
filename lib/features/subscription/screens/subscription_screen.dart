// lib/features/subscription/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/features/subscription/widgets/current_subscription_card.dart';
import 'package:revboostapp/features/subscription/widgets/expert_services_section.dart';
import 'package:revboostapp/features/subscription/widgets/feature_comparison_table.dart';
import 'package:revboostapp/features/subscription/widgets/subscription_faq.dart';
import 'package:revboostapp/features/subscription/widgets/subscription_plans_section.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSubscriptionData();
    });
  }
  
  Future<void> _initSubscriptionData() async {
    if (!_isInitialized) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.refreshSubscriptionStatus();
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isSubscribed = subscriptionProvider.isSubscribed;
    final isFreeTrial = subscriptionProvider.isFreeTrial;
    
    return LoadingOverlay(
      isLoading: subscriptionProvider.status == SubscriptionProviderStatus.loading || 
                 subscriptionProvider.isProcessingCheckout,
      message: subscriptionProvider.isProcessingCheckout 
          ? "Processing your subscription..." 
          : "Loading subscription details...",
      child: AppLayout(
        title: "Subscription",
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(isSubscribed, isFreeTrial),
                    const SizedBox(height: 40),
                    if (isSubscribed || isFreeTrial)
                      CurrentSubscriptionCard(
                        provider: subscriptionProvider,
                      )
                    else
                      SubscriptionPlansSection(
                        provider: subscriptionProvider,
                      ),
                    const SizedBox(height: 60),
                    const ExpertServicesSection(),
                    const SizedBox(height: 60),
                    // const FeatureComparisonTable(),
                    const SizedBox(height: 40),
                    const SubscriptionFAQ(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isSubscribed, bool isFreeTrial) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSubscribed 
              ? "Your Pro Subscription" 
              : isFreeTrial 
                  ? "Your Free Trial" 
                  : "Choose Your Plan",
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isSubscribed 
              ? "Manage your subscription and billing details" 
              : isFreeTrial 
                  ? "Enjoy full access to all features during your trial period" 
                  : "Unlock powerful features to boost your online reviews",
          style: textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}




