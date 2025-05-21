// lib/features/subscription/screens/subscription_success_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String? planId;
  
  const SubscriptionSuccessScreen({
    Key? key,
    this.planId,
  }) : super(key: key);

  @override
  State<SubscriptionSuccessScreen> createState() => _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool _isProcessing = true;
  bool _isSuccess = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Process subscription after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processSubscription();
    });
  }
  
  Future<void> _processSubscription() async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    try {
      // Get query parameters
      final uri = Uri.parse(Uri.base.toString());
      
      // Check if this URL has success parameters
      if (provider.hasSubscriptionSuccessParams(uri)) {
        // Process subscription
        final success = await provider.handleCheckoutSuccess(uri.queryParameters);
        
        setState(() {
          _isProcessing = false;
          _isSuccess = success;
          _errorMessage = success ? null : 'Failed to verify subscription';
        });
      } else {
        // No success parameters, just show success based on planId
        await provider.refreshSubscriptionStatus();
        
        setState(() {
          _isProcessing = false;
          _isSuccess = provider.isSubscribed;
          _errorMessage = provider.isSubscribed ? null : 'Subscription not found';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _errorMessage = 'Error processing subscription: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: "Verifying your subscription...",
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _isProcessing
                    ? const SizedBox.shrink() // Don't show content while loading
                    : _isSuccess
                        ? _buildSuccessContent()
                        : _buildErrorContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuccessContent() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get plan name
    final planName = widget.planId == 'yearly' ? 'Pro Yearly' : 'Pro Monthly';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 80,
          ),
        ),
        const SizedBox(height: 32),
        
        // Success message
        Text(
          'Subscription Successful!',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Thank you for subscribing to RevBoostApp $planName',
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your subscription is now active and you have full access to all premium features.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // Action buttons
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Go to Dashboard',
            type: AppButtonType.primary,
            fullWidth: true,
            onPressed: () {
              context.go(AppRoutes.dashboard);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'View Subscription Details',
            type: AppButtonType.secondary,
            fullWidth: true,
            onPressed: () {
              context.go(AppRoutes.subscription);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorContent() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Error icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 80,
          ),
        ),
        const SizedBox(height: 32),
        
        // Error message
        Text(
          'Subscription Verification Failed',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'An error occurred while verifying your subscription.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Don't worry, if you completed the payment, your account will be updated shortly. "
          "Please contact support if this issue persists.",
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // Action buttons
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Try Again',
            type: AppButtonType.secondary,
            fullWidth: true,
            onPressed: () {
              setState(() {
                _isProcessing = true;
              });
              _processSubscription();
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Go to Subscription Page',
            type: AppButtonType.primary,
            fullWidth: true,
            onPressed: () {
              context.go(AppRoutes.subscription);
            },
          ),
        ),
      ],
    );
  }
}


// // lib/features/subscription/screens/subscription_success_screen.dart

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:revboostapp/models/subscription_model.dart';
// import 'package:revboostapp/providers/subscription_provider.dart';
// import 'package:revboostapp/routing/app_router.dart';
// import 'package:revboostapp/widgets/layout/app_layout.dart';

// class SubscriptionSuccessScreen extends StatelessWidget {
//   final String? planId;

//   const SubscriptionSuccessScreen({
//     Key? key,
//     this.planId,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       title: 'Subscription Activated',
//       child: _buildSuccessContent(context),
//     );
//   }

//   Widget _buildSuccessContent(BuildContext context) {
//     return Consumer<SubscriptionProvider>(
//       builder: (context, subscriptionProvider, _) {
//         // Plan info
//         final SubscriptionPlan plan = _getPlanInfo(subscriptionProvider);
//         final subscription = subscriptionProvider.subscriptionStatus;

//         return SingleChildScrollView(
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 800),
//               child: Padding(
//                 padding: const EdgeInsets.all(32.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Success Icon
//                     Container(
//                       padding: const EdgeInsets.all(24.0),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.check_circle_outline,
//                         color: Colors.green,
//                         size: 64,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
                    
//                     // Success Title
//                     Text(
//                       'Subscription Activated!',
//                       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[700],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Success Message
//                     Text(
//                       'You now have access to all ${plan.name} features',
//                       style: Theme.of(context).textTheme.titleLarge,
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 32),
                    
//                     // Plan details card
//                     _buildPlanDetailsCard(context, plan, subscription),
//                     const SizedBox(height: 32),
                    
//                     // What's next
//                     _buildNextStepsCard(context),
//                     const SizedBox(height: 48),
                    
//                     // Actions
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             context.go(AppRoutes.dashboard);
//                           },
//                           icon: const Icon(Icons.dashboard),
//                           label: const Text('Go to Dashboard'),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 32,
//                               vertical: 16,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         OutlinedButton.icon(
//                           onPressed: () {
//                             context.go(AppRoutes.qrCode);
//                           },
//                           icon: const Icon(Icons.qr_code),
//                           label: const Text('Create QR Code'),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 32,
//                               vertical: 16,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPlanDetailsCard(
//     BuildContext context,
//     SubscriptionPlan plan,
//     SubscriptionStatus subscription,
//   ) {
//     final renewalDate = subscription.expiresAt != null 
//         ? '${subscription.expiresAt!.month}/${subscription.expiresAt!.day}/${subscription.expiresAt!.year}'
//         : 'Unknown';

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: Theme.of(context).colorScheme.primary,
//           width: 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.verified_user,
//                   color: Theme.of(context).colorScheme.primary,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Subscription Details',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 32),
            
//             // Plan details
//             _buildDetailRow(context, 'Plan', plan.name),
//             _buildDetailRow(context, 'Billing Cycle', '${plan.interval}ly'),
//             _buildDetailRow(context, 'Amount', '\$${plan.price.toStringAsFixed(2)} per ${plan.interval}'),
//             _buildDetailRow(context, 'Next Renewal', renewalDate),
            
//             const SizedBox(height: 16),
//             // Note
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.info_outline, color: Colors.blue, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'You can manage your subscription at any time from the Subscription page.',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: Colors.blue[800],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNextStepsCard(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'What\'s Next?',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Steps
//             _buildNextStep(
//               context,
//               '1',
//               'Access your Review QR code',
//               'Generate a QR code that customers can scan to leave reviews.',
//               Icons.qr_code,
//             ),
//             const SizedBox(height: 20),
//             _buildNextStep(
//               context,
//               '2',
//               'Send review requests',
//               'Email your customers asking for reviews with direct links.',
//               Icons.email,
//             ),
//             const SizedBox(height: 20),
//             // _buildNextStep(
//             //   context,
//             //   '3',
//             //   'Monitor your dashboard',
//             //   'Track your review performance and customer feedback.',
//             //   Icons.analytics,
//             // ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNextStep(
//     BuildContext context,
//     String number,
//     String title,
//     String description,
//     IconData icon,
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.primary,
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: Text(
//               number,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDetailRow(BuildContext context, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   SubscriptionPlan _getPlanInfo(SubscriptionProvider provider) {
//     // Try to get plan by ID passed in constructor
//     if (planId != null) {
//       try {
//         return provider.availablePlans.firstWhere(
//           (plan) => plan.id == planId,
//         );
//       } catch (_) {
//         // If not found, fall through to current plan
//       }
//     }

//     // Get current subscription plan
//     final currentPlanId = provider.subscriptionStatus.planId;

//     // Find the plan by ID
//     if (currentPlanId != null) {
//       try {
//         return provider.availablePlans.firstWhere(
//           (plan) => plan.id == currentPlanId,
//         );
//       } catch (_) {
//         // Plan not found, return a default one
//       }
//     }

//     // Fallback to a default plan if needed
//     return SubscriptionPlan(
//       id: 'unknown',
//       name: 'RevBoost Pro',
//       description: 'Premium subscription',
//       price: 0,
//       interval: 'month',
//       features: [],
//       lemonSqueezyProductId: '',
//     );
//   }
// }