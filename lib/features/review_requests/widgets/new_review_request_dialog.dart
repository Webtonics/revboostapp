// // // lib/features/review_requests/widgets/new_review_request_dialog.dart

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:revboostapp/models/business_model.dart';
// // import 'package:revboostapp/providers/review_request_provider.dart';

// // /// A dialog for creating and sending a new review request
// // class NewReviewRequestDialog extends StatefulWidget {
// //   /// The business to send the request for
// //   final BusinessModel business;
  
// //   /// Creates a [NewReviewRequestDialog]
// //   const NewReviewRequestDialog({
// //     Key? key,
// //     required this.business,
// //   }) : super(key: key);

// //   @override
// //   State<NewReviewRequestDialog> createState() => _NewReviewRequestDialogState();
// // }

// // class _NewReviewRequestDialogState extends State<NewReviewRequestDialog> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nameController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _phoneController = TextEditingController();
  
// //   bool _isLoading = false;
// //   String? _errorMessage;
// //   bool _useBusinessEmail = true;
  
// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _emailController.dispose();
// //     _phoneController.dispose();
// //     super.dispose();
// //   }
  
// //   /// Handle sending the review request
// //   Future<void> _sendRequest() async {
// //     if (!_formKey.currentState!.validate()) return;
    
// //     setState(() {
// //       _isLoading = true;
// //       _errorMessage = null;
// //     });
    
// //     try {
// //       final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
      
// //       final success = await provider.createAndSendReviewRequest(
// //         customerName: _nameController.text.trim(),
// //         customerEmail: _emailController.text.trim(),
// //         customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
// //         business: widget.business,
// //         replyToEmail: _useBusinessEmail ? null : "support@revboostapp.com",
// //       );
      
// //       if (success && mounted) {
// //         Navigator.of(context).pop();
        
// //         // Show success message
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Review request sent successfully!'),
// //             backgroundColor: Colors.green,
// //             duration: Duration(seconds: 3),
// //           ),
// //         );
// //       } else if (mounted) {
// //         setState(() {
// //           _errorMessage = 'Failed to send review request. Please try again.';
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _errorMessage = e.toString();
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
    
// //     return Dialog(
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Padding(
// //         padding: const EdgeInsets.all(24.0),
// //         child: ConstrainedBox(
// //           constraints: const BoxConstraints(maxWidth: 500),
// //           child: Form(
// //             key: _formKey,
// //             child: SingleChildScrollView(
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   // Header
// //                   Text(
// //                     'Send Review Request',
// //                     style: theme.textTheme.headlineSmall?.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text(
// //                     'Enter customer details to send a review request email',
// //                     style: theme.textTheme.bodyMedium?.copyWith(
// //                       color: theme.brightness == Brightness.dark
// //                           ? Colors.grey[400]
// //                           : Colors.grey[600],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 24),
                  
// //                   // Error message
// //                   // if (_errorMessage != null) ...[
// //                   //   Container(
// //                   //     padding: const EdgeInsets.all(12),
// //                   //     decoration: BoxDecoration(
// //                   //       color: Colors.red.withOpacity(0.1),
// //                   //       borderRadius: BorderRadius.circular(8),
// //                   //     ),
// //                   //     child: Row(
// //                   //       children: [
// //                   //         const Icon(Icons.error_outline, color: Colors.red),
// //                   //         const SizedBox(width: 12),
// //                   //         Expanded(
// //                   //           child: Text(
// //                   //             _errorMessage!,
// //                   //             style: const TextStyle(color: Colors.red),
// //                   //           ),
// //                   //         ),
// //                   //       ],
// //                   //     ),
// //                     // ),
// //                     // const SizedBox(height: 24),
// //                   // ],
                  
// //                   // Name field
// //                   TextFormField(
// //                     controller: _nameController,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Customer Name',
// //                       hintText: 'Enter customer\'s full name',
// //                       prefixIcon: Icon(Icons.person_outline),
// //                     ),
// //                     validator: (value) {
// //                       if (value == null || value.isEmpty) {
// //                         return 'Please enter customer\'s name';
// //                       }
// //                       return null;
// //                     },
// //                     textInputAction: TextInputAction.next,
// //                   ),
// //                   const SizedBox(height: 16),
                  
// //                   // Email field
// //                   TextFormField(
// //                     controller: _emailController,
// //                     keyboardType: TextInputType.emailAddress,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Customer Email',
// //                       hintText: 'Enter customer\'s email address',
// //                       prefixIcon: Icon(Icons.email_outlined),
// //                     ),
// //                     validator: (value) {
// //                       if (value == null || value.isEmpty) {
// //                         return 'Please enter customer\'s email';
// //                       }
// //                       if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// //                         return 'Please enter a valid email address';
// //                       }
// //                       return null;
// //                     },
// //                     textInputAction: TextInputAction.next,
// //                   ),
// //                   const SizedBox(height: 16),
                  
// //                   // Phone field (optional)
// //                   TextFormField(
// //                     controller: _phoneController,
// //                     keyboardType: TextInputType.phone,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Customer Phone (Optional)',
// //                       hintText: 'Enter customer\'s phone number',
// //                       prefixIcon: Icon(Icons.phone_outlined),
// //                     ),
// //                     textInputAction: TextInputAction.done,
// //                     onEditingComplete: _sendRequest,
// //                   ),
// //                   const SizedBox(height: 24),
                  
// //                   // Email settings (reply-to)
// //                   // SwitchListTile(
// //                   //   title: const Text('Send from no-reply address'),
// //                   //   subtitle: Text(
// //                   //     _useBusinessEmail 
// //                   //         ? 'Emails will be sent from our system' 
// //                   //         : 'Replies will go to your business email',
// //                   //     style: TextStyle(
// //                   //       fontSize: 12,
// //                   //       color: theme.brightness == Brightness.dark
// //                   //           ? Colors.grey[400]
// //                   //           : Colors.grey[600],
// //                   //     ),
// //                   //   ),
// //                   //   value: _useBusinessEmail,
// //                   //   onChanged: (value) {
// //                   //     setState(() {
// //                   //       _useBusinessEmail = value;
// //                   //     });
// //                   //   },
// //                   //   activeColor: theme.primaryColor,
// //                   // ),
                  
// //                   const SizedBox(height: 24),
                  
// //                   // Preview of the email that will be sent
// //                   // Container(
// //                   //   padding: const EdgeInsets.all(12),
// //                   //   decoration: BoxDecoration(
// //                   //     color: theme.brightness == Brightness.dark
// //                   //         ? Colors.grey[800]
// //                   //         : Colors.grey[100],
// //                   //     borderRadius: BorderRadius.circular(8),
// //                   //     border: Border.all(
// //                   //       color: theme.brightness == Brightness.dark
// //                   //           ? Colors.grey[700]!
// //                   //           : Colors.grey[300]!,
// //                   //     ),
// //                   //   ),
// //                   //   child: Column(
// //                   //     crossAxisAlignment: CrossAxisAlignment.start,
// //                   //     children: [
// //                   //       Text(
// //                   //         'Email Preview',
// //                   //         style: theme.textTheme.titleSmall?.copyWith(
// //                   //           fontWeight: FontWeight.bold,
// //                   //         ),
// //                   //       ),
// //                   //       const SizedBox(height: 8),
// //                   //       Row(
// //                   //         children: [
// //                   //           Text(
// //                   //             'From:',
// //                   //             style: TextStyle(
// //                   //               fontWeight: FontWeight.bold,
// //                   //               color: theme.brightness == Brightness.dark
// //                   //                   ? Colors.grey[400]
// //                   //                   : Colors.grey[600],
// //                   //             ),
// //                   //           ),
// //                   //           const SizedBox(width: 8),
// //                   //           Expanded(
// //                   //             child: Text(
// //                   //               _useBusinessEmail
// //                   //                   ? '${widget.business.name} <reviiew@revboostapp.com>'
// //                   //                   // : '${widget.business.name} <${widget.business.ownerEmail}>',
// //                   //                   : '${widget.business.name} <no-reply@revboostapp.com>',
// //                   //               style: TextStyle(
// //                   //                 color: theme.brightness == Brightness.dark
// //                   //                     ? Colors.grey[300]
// //                   //                     : Colors.grey[700],
// //                   //               ),
// //                   //               overflow: TextOverflow.ellipsis,
// //                   //             ),
// //                   //           ),
// //                   //         ],
// //                   //       ),
// //                   //       const SizedBox(height: 4),
// //                   //       Row(
// //                   //         children: [
// //                   //           Text(
// //                   //             'Subject:',
// //                   //             style: TextStyle(
// //                   //               fontWeight: FontWeight.bold,
// //                   //               color: theme.brightness == Brightness.dark
// //                   //                   ? Colors.grey[400]
// //                   //                   : Colors.grey[600],
// //                   //             ),
// //                   //           ),
// //                   //           const SizedBox(width: 8),
// //                   //           Expanded(
// //                   //             child: Text(
// //                   //               'We\'d love to hear your feedback!',
// //                   //               style: TextStyle(
// //                   //                 color: theme.brightness == Brightness.dark
// //                   //                     ? Colors.grey[300]
// //                   //                     : Colors.grey[700],
// //                   //               ),
// //                   //               overflow: TextOverflow.ellipsis,
// //                   //             ),
// //                   //           ),
// //                   //         ],
// //                   //       ),
// //                   //     ],
// //                   //   ),
// //                   // ),
                  
// //                   const SizedBox(height: 24),
                  
// //                   // Buttons
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.end,
// //                     children: [
// //                       TextButton(
// //                         onPressed: _isLoading ? null : () {
// //                           Navigator.of(context).pop();
// //                         },
// //                         child: const Text('Cancel'),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       ElevatedButton.icon(
// //                         onPressed: _isLoading ? null : _sendRequest,
// //                         icon: _isLoading 
// //                             ? Container(
// //                                 width: 24,
// //                                 height: 24,
// //                                 padding: const EdgeInsets.all(2.0),
// //                                 child: const CircularProgressIndicator(
// //                                   color: Colors.white,
// //                                   strokeWidth: 3,
// //                                 ),
// //                               )
// //                             : const Icon(Icons.send),
// //                         label: Text(_isLoading ? 'Sending...' : 'Send Request'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: theme.primaryColor,
// //                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // lib/features/review_requests/widgets/new_review_request_dialog.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:revboostapp/models/business_model.dart';
// import 'package:revboostapp/providers/review_request_provider.dart';

// class NewReviewRequestDialog extends StatefulWidget {
//   final BusinessModel business;
  
//   const NewReviewRequestDialog({
//     Key? key,
//     required this.business,
//   }) : super(key: key);

//   @override
//   State<NewReviewRequestDialog> createState() => _NewReviewRequestDialogState();
// }

// class _NewReviewRequestDialogState extends State<NewReviewRequestDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   bool _showDebugInfo = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _handleSubmit(ReviewRequestProvider provider) async {
//     if (!_formKey.currentState!.validate()) return;
    
//     final success = await provider.createAndSendReviewRequest(
//       customerName: _nameController.text.trim(),
//       customerEmail: _emailController.text.trim(),
//       customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
//       business: widget.business,
//     );
    
//     // Only close the dialog on success
//     if (success && mounted) {
//       Navigator.of(context).pop();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Review request sent successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//     // On failure, the error will be shown in the dialog
//   }

//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Email is required';
//     }
    
//     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//     if (!emailRegex.hasMatch(value)) {
//       return 'Please enter a valid email address';
//     }
    
//     return null;
//   }

//   String? _validateName(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Name is required';
//     }
    
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Consumer<ReviewRequestProvider>(
//         builder: (context, provider, child) {
//           final isLoading = provider.status == ReviewRequestOperationStatus.loading;
//           final hasError = provider.status == ReviewRequestOperationStatus.error;
          
//           return Container(
//             constraints: const BoxConstraints(maxWidth: 500),
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Send Review Request',
//                           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: isLoading 
//                               ? null 
//                               : () => Navigator.of(context).pop(),
//                           tooltip: 'Close',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Send a review request to your customer via email.',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Error message if there was an error
//                     if (hasError && provider.errorMessage != null) ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.red[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.red[300]!),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(Icons.error_outline, color: Colors.red[700], size: 20),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Error sending request',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.red[700],
//                                     ),
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     setState(() {
//                                       _showDebugInfo = !_showDebugInfo;
//                                     });
//                                   },
//                                   child: Text(
//                                     _showDebugInfo ? 'Hide Details' : 'Show Details',
//                                     style: TextStyle(
//                                       color: Colors.red[700],
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               'Unable to send the review request. Please try again.',
//                               style: TextStyle(color: Colors.red[700]),
//                             ),
//                             if (_showDebugInfo) ...[
//                               const SizedBox(height: 8),
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red[100],
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   'Error details: ${provider.errorMessage}',
//                                   style: const TextStyle(
//                                     fontFamily: 'monospace',
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                     ],
                    
//                     // Form
//                     Form(
//                       key: _formKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Customer Name field
//                           Text(
//                             'Customer Name',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           TextFormField(
//                             controller: _nameController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter customer name',
//                               prefixIcon: const Icon(Icons.person),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey[50],
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               enabled: !isLoading,
//                             ),
//                             validator: _validateName,
//                             textInputAction: TextInputAction.next,
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Customer Email field
//                           Text(
//                             'Customer Email',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           TextFormField(
//                             controller: _emailController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter customer email',
//                               prefixIcon: const Icon(Icons.email),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey[50],
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               enabled: !isLoading,
//                             ),
//                             validator: _validateEmail,
//                             keyboardType: TextInputType.emailAddress,
//                             textInputAction: TextInputAction.next,
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Customer Phone field (optional)
//                           Text(
//                             'Customer Phone (Optional)',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           TextFormField(
//                             controller: _phoneController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter customer phone',
//                               prefixIcon: const Icon(Icons.phone),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey[50],
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               enabled: !isLoading,
//                             ),
//                             keyboardType: TextInputType.phone,
//                             textInputAction: TextInputAction.done,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
                    
//                     // Actions
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: isLoading 
//                               ? null 
//                               : () => Navigator.of(context).pop(),
//                           child: const Text('Cancel'),
//                         ),
//                         const SizedBox(width: 16),
//                         ElevatedButton.icon(
//                           onPressed: isLoading 
//                               ? null 
//                               : () => _handleSubmit(provider),
//                           icon: isLoading 
//                               ? Container(
//                                   width: 24,
//                                   height: 24,
//                                   padding: const EdgeInsets.all(2.0),
//                                   child: const CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 3,
//                                   ),
//                                 )
//                               : const Icon(Icons.send),
//                           label: Text(isLoading ? 'Sending...' : 'Send Request'),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 20,
//                               vertical: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
// lib/features/review_requests/widgets/new_review_request_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/review_request_provider.dart';

class NewReviewRequestDialog extends StatefulWidget {
  final BusinessModel business;
  
  const NewReviewRequestDialog({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<NewReviewRequestDialog> createState() => _NewReviewRequestDialogState();
}

class _NewReviewRequestDialogState extends State<NewReviewRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit(ReviewRequestProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await provider.createAndSendReviewRequest(
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
      business: widget.business,
    );
    
    // Only close the dialog if successful
    if (success && mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review request sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } 
    // If there was an error, the error state will be handled by the Consumer in the build method
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Consumer<ReviewRequestProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.status == ReviewRequestOperationStatus.loading;
          final hasError = provider.status == ReviewRequestOperationStatus.error;
          
          return Container(
            width: 500, // Set a fixed width
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Send Review Request',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: isLoading 
                              ? null 
                              : () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send a review request to your customer via email.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Error message if there was an error
                    if (hasError && provider.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error sending request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.errorMessage ?? 'An unknown error occurred.',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter customer name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: _validateName,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          const Text('Customer Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'Enter customer email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: _validateEmail,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          const Text('Customer Phone (Optional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              hintText: 'Enter customer phone',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            enabled: !isLoading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading 
                              ? null 
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: isLoading 
                              ? null 
                              : () => _handleSubmit(provider),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: isLoading 
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Sending...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send),
                                    SizedBox(width: 8),
                                    Text('Send Request'),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}