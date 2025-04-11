// Fix for the RenderFlex overflow error in subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/features/subscription/widgets/lemon_squeezy_webview.dart';
import 'package:revboostapp/models/subscription_model.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _showWebView = false;
  String _selectedPlanId = '';
  
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Subscription',
      child: _showWebView
          ? LemonSqueezyWebView(
              planId: _selectedPlanId,
              onComplete: (success) {
                setState(() {
                  _showWebView = false;
                });
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription activated successfully!')),
                  );
                }
              },
            )
          : _buildSubscriptionContent(),
    );
  }
  
  Widget _buildSubscriptionContent() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        if (subscriptionProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (subscriptionProvider.errorMessage != null) {
          return SingleChildScrollView(
            child: Center(
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
                    subscriptionProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => subscriptionProvider.reloadSubscriptionStatus(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final isSubscribed = subscriptionProvider.isSubscribed;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 1200 ? 120 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            // Fix: Set mainAxisSize to min to prevent the unbounded height error
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heading
              Center(
                child: Column(
                  // Fix: Set mainAxisSize to min
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(
                      isSubscribed ? 'Your Subscription' : 'Upgrade to RevBoost Pro',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSubscribed 
                          ? 'Manage your active subscription'
                          : 'Unlock advanced features to boost your online reputation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Current subscription status
              if (isSubscribed) _buildCurrentSubscription(context, subscriptionProvider),
              
              // Value proposition banner
              if (!isSubscribed) _buildValuePropositionBanner(context),
              
              const SizedBox(height: 40),
              
              // Plans title
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isSubscribed ? 'Available Plans' : 'Choose Your Plan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Pricing toggle
              if (!isSubscribed) _buildPricingToggle(context),
              
              const SizedBox(height: 24),
              
              // Subscription plans
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 800;
                  
                  if (isSmallScreen) {
                    // Vertical layout for small screens
                    return Column(
                      // Fix: Set mainAxisSize to min
                      mainAxisSize: MainAxisSize.min,
                      children: subscriptionProvider.availablePlans.map((plan) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildPlanCard(context, plan, subscriptionProvider),
                        );
                      }).toList(),
                    );
                  } else {
                    // Side-by-side layout for larger screens
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Fix: Use IntrinsicHeight to ensure all cards have same height
                      children: subscriptionProvider.availablePlans.map((plan) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildPlanCard(context, plan, subscriptionProvider),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 48),
              
              // Testimonials
              if (!isSubscribed) _buildTestimonials(context),
              
              const SizedBox(height: 48),
              
              // Features comparison
              // if (!isSubscribed) _buildFeaturesComparison(context),
              
              const SizedBox(height: 48),
              
              // FAQs section
              _buildFaqSection(context),
              
              const SizedBox(height: 48),
              
              // Money-back guarantee
              if (!isSubscribed) _buildMoneyBackGuarantee(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildValuePropositionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Color.lerp(Theme.of(context).colorScheme.primary, Colors.purple, 0.7)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        // Fix: Set mainAxisSize to min
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Boost Your Online Reputation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Businesses with active review management see a 35% increase in customer engagement and an 18% boost in revenue.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildStatItem(context, '250%', 'More Reviews'),
              _buildStatItem(context, '4.8', 'Average Rating'),
              _buildStatItem(context, '68%', 'More Customers'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      // Fix: Set mainAxisSize to min
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPricingToggle(BuildContext context) {
    // This is just a visual representation - for a real implementation
    // you would track the state and update plan prices accordingly
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Monthly',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Switch(
          value: false, // default to monthly
          onChanged: (value) {
            // Toggle between monthly and yearly
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        Row(
          children: [
            Text(
              'Yearly',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Save 16%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCurrentSubscription(BuildContext context, SubscriptionProvider provider) {
    final status = provider.subscriptionStatus;
    final planId = status.planId;
    
    if (planId == null) return const SizedBox.shrink();
    
    // Find the plan
    final plan = provider.availablePlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => SubscriptionPlan(
        id: 'unknown',
        name: 'Unknown Plan',
        description: '',
        price: 0,
        interval: '',
        features: [],
        lemonSqueezyProductId: '',
      ),
    );
    
    final expiryDate = status.expiresAt != null
        ? DateFormat('MMMM d, yyyy').format(status.expiresAt!)
        : 'Unknown';
    
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          // Fix: Set mainAxisSize to min
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Active Subscription',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Plan details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Fix: Set mainAxisSize to min
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your subscription renews on $expiryDate',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have full access to all RevBoost Pro features',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Only show this in development
                // if (false) // Set to true for testing
                //   ElevatedButton.icon(
                //     onPressed: () {
                //       provider.cancelSubscription();
                //     },
                //     icon: const Icon(Icons.cancel),
                //     label: const Text('Cancel (Test)'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.red,
                //     ),
                //   ),
              ],
            ),
            
            const Divider(height: 40),
            
            // Manage subscription button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  final url = provider.getCustomerPortalUrl();
                  launchUrl(Uri.parse(url));
                },
                icon: const Icon(Icons.settings),
                label: const Text('Manage Subscription'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionProvider provider,
  ) {
    final isCurrentPlan = provider.subscriptionStatus.planId == plan.id;
    final isSubscribed = provider.isSubscribed;
    final isYearly = plan.id == 'yearly';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentPlan
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isYearly 
              ? LinearGradient(
                  colors: [Colors.white, Theme.of(context).colorScheme.primary.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        // Fix: Remove the Spacer and use SizedBox.height instead
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Fix: Set mainAxisSize to min
          mainAxisSize: MainAxisSize.min,
          children: [
            // Plan name and badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Fix: Set mainAxisSize to min
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isYearly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Best Value',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${plan.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/${plan.interval}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (isYearly)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Just \$${(plan.price / 12).toStringAsFixed(2)} per month',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Features list
            ...plan.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Fix: Replace Spacer with SizedBox
            const SizedBox(height: 24),
            
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () {
                        // Get user email
                        final email = Provider.of<AuthProvider>(context, listen: false).user?.email ?? '';
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please update your email address in your profile first')),
                          );
                          return;
                        }
                        
                        setState(() {
                          _selectedPlanId = plan.id;
                          _showWebView = true;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isYearly ? Colors.green[700] : Theme.of(context).colorScheme.primary,
                  disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  elevation: 2,
                ),
                child: Text(
                  isCurrentPlan 
                      ? 'Current Plan'
                      : isSubscribed
                          ? 'Change Plan'
                          : 'Subscribe Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestimonials(BuildContext context) {
    return Column(
      // Fix: Set mainAxisSize to min
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Trusted by Thousands of Businesses',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            
            if (isSmallScreen) {
              return Column(
                // Fix: Set mainAxisSize to min
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTestimonialCard(
                    context,
                    '"RevBoost helped us increase our Google rating from 3.2 to 4.8 stars in just 3 months. Our restaurant is now consistently booked on weekends!"',
                    'Maria L.',
                    'Restaurant Owner',
                  ),
                  const SizedBox(height: 16),
                  _buildTestimonialCard(
                    context,
                    '"The private feedback feature saved our reputation. We now fix issues before they become negative public reviews. Worth every penny."',
                    'James T.',
                    'Dental Practice Manager',
                  ),
                  const SizedBox(height: 16),
                  _buildTestimonialCard(
                    context,
                    '"Our QR code is now on every table. We\'ve collected more reviews in 1 month than we did in the entire previous year."',
                    'Sarah K.',
                    'Café Owner',
                  ),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTestimonialCard(
                      context,
                      '"RevBoost helped us increase our Google rating from 3.2 to 4.8 stars in just 3 months. Our restaurant is now consistently booked on weekends!"',
                      'Maria L.',
                      'Restaurant Owner',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTestimonialCard(
                      context,
                      '"The private feedback feature saved our reputation. We now fix issues before they become negative public reviews. Worth every penny."',
                      'James T.',
                      'Dental Practice Manager',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTestimonialCard(
                     context,
                      '"Our QR code is now on every table. We\'ve collected more reviews in 1 month than we did in the entire previous year."',
                      'Sarah K.',
                      'Café Owner',
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
  
  Widget _buildTestimonialCard(
    BuildContext context,
    String quote,
    String name,
    String position,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          // Fix: Set mainAxisSize to min
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote,
              color: Colors.grey,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              quote,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Fix: Set mainAxisSize to min
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      position,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  
  
  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey[300]!,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoneyBackGuarantee(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user,
            color: Colors.green[700],
            size: 48,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Fix: Set mainAxisSize to min
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '14-Day Money-Back Guarantee',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try RevBoost Pro risk-free. If you\'re not completely satisfied within the first 14 days, we\'ll refund your payment in full — no questions asked.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFaqSection(BuildContext context) {
    return Column(
      // Fix: Set mainAxisSize to min
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        
        // Two-column layout for wider screens
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;
            
            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      // Fix: Set mainAxisSize to min
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFaqItem(
                          context,
                          'What happens after I subscribe?',
                          'After subscribing, you\'ll immediately get access to all premium features. Your subscription will automatically renew at the end of your billing period unless you cancel.',
                        ),
                        _buildFaqItem(
                          context,
                          'Can I cancel anytime?',
                          'Yes, you can cancel your subscription at any time. You\'ll continue to have access until the end of your current billing period.',
                        ),
                        _buildFaqItem(
                          context,
                          'How do I change my plan?',
                          'You can change your plan at any time by selecting a new plan on this page. Changes will take effect at the start of your next billing cycle.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      // Fix: Set mainAxisSize to min
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFaqItem(
                          context,
                          'Is my payment secure?',
                          'Yes, all payments are processed securely through Lemon Squeezy. We never store your credit card information.',
                        ),
                        _buildFaqItem(
                          context,
                          'Do you offer refunds?',
                          'Yes, we offer a 14-day money-back guarantee. If you\'re not satisfied with RevBoost Pro for any reason, contact our support team within 14 days of your purchase for a full refund.',
                        ),
                        _buildFaqItem(
                          context,
                          'Is there a limit to how many reviews I can collect?',
                          'No, RevBoost Pro has no limits on the number of reviews you can collect. Collect as many as you want!',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                // Fix: Set mainAxisSize to min
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFaqItem(
                    context,
                    'What happens after I subscribe?',
                    'After subscribing, you\'ll immediately get access to all premium features. Your subscription will automatically renew at the end of your billing period unless you cancel.',
                  ),
                  _buildFaqItem(
                    context,
                    'Can I cancel anytime?',
                    'Yes, you can cancel your subscription at any time. You\'ll continue to have access until the end of your current billing period.',
                  ),
                  _buildFaqItem(
                    context,
                    'How do I change my plan?',
                    'You can change your plan at any time by selecting a new plan on this page. Changes will take effect at the start of your next billing cycle.',
                  ),
                  _buildFaqItem(
                    context,
                    'Is my payment secure?',
                    'Yes, all payments are processed securely through Lemon Squeezy. We never store your credit card information.',
                  ),
                  _buildFaqItem(
                    context,
                    'Do you offer refunds?',
                    'Yes, we offer a 14-day money-back guarantee. If you\'re not satisfied with RevBoost Pro for any reason, contact our support team within 14 days of your purchase for a full refund.',
                  ),
                  _buildFaqItem(
                    context,
                    'Is there a limit to how many reviews I can collect?',
                    'No, RevBoost Pro has no limits on the number of reviews you can collect. Collect as many as you want!',
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }}