// lib/features/review_requests/widgets/new_review_request_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/review_request_provider.dart';

/// A dialog for creating and sending a new review request
class NewReviewRequestDialog extends StatefulWidget {
  /// The business to send the request for
  final BusinessModel business;
  
  /// Creates a [NewReviewRequestDialog]
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
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _useBusinessEmail = true;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  /// Handle sending the review request
  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
      
      final success = await provider.createAndSendReviewRequest(
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        business: widget.business,
        replyToEmail: _useBusinessEmail ? null : "support@revboostapp.com",
      );
      
      if (success && mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review request sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send review request. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Send Review Request',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter customer details to send a review request email',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'Enter customer\'s full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer\'s name';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Customer Email',
                      hintText: 'Enter customer\'s email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer\'s email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone field (optional)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone (Optional)',
                      hintText: 'Enter customer\'s phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _sendRequest,
                  ),
                  const SizedBox(height: 24),
                  
                  // Email settings (reply-to)
                  // SwitchListTile(
                  //   title: const Text('Send from no-reply address'),
                  //   subtitle: Text(
                  //     _useBusinessEmail 
                  //         ? 'Emails will be sent from our system' 
                  //         : 'Replies will go to your business email',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: theme.brightness == Brightness.dark
                  //           ? Colors.grey[400]
                  //           : Colors.grey[600],
                  //     ),
                  //   ),
                  //   value: _useBusinessEmail,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _useBusinessEmail = value;
                  //     });
                  //   },
                  //   activeColor: theme.primaryColor,
                  // ),
                  
                  const SizedBox(height: 24),
                  
                  // Preview of the email that will be sent
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: theme.brightness == Brightness.dark
                  //         ? Colors.grey[800]
                  //         : Colors.grey[100],
                  //     borderRadius: BorderRadius.circular(8),
                  //     border: Border.all(
                  //       color: theme.brightness == Brightness.dark
                  //           ? Colors.grey[700]!
                  //           : Colors.grey[300]!,
                  //     ),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         'Email Preview',
                  //         style: theme.textTheme.titleSmall?.copyWith(
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Row(
                  //         children: [
                  //           Text(
                  //             'From:',
                  //             style: TextStyle(
                  //               fontWeight: FontWeight.bold,
                  //               color: theme.brightness == Brightness.dark
                  //                   ? Colors.grey[400]
                  //                   : Colors.grey[600],
                  //             ),
                  //           ),
                  //           const SizedBox(width: 8),
                  //           Expanded(
                  //             child: Text(
                  //               _useBusinessEmail
                  //                   ? '${widget.business.name} <reviiew@revboostapp.com>'
                  //                   // : '${widget.business.name} <${widget.business.ownerEmail}>',
                  //                   : '${widget.business.name} <no-reply@revboostapp.com>',
                  //               style: TextStyle(
                  //                 color: theme.brightness == Brightness.dark
                  //                     ? Colors.grey[300]
                  //                     : Colors.grey[700],
                  //               ),
                  //               overflow: TextOverflow.ellipsis,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 4),
                  //       Row(
                  //         children: [
                  //           Text(
                  //             'Subject:',
                  //             style: TextStyle(
                  //               fontWeight: FontWeight.bold,
                  //               color: theme.brightness == Brightness.dark
                  //                   ? Colors.grey[400]
                  //                   : Colors.grey[600],
                  //             ),
                  //           ),
                  //           const SizedBox(width: 8),
                  //           Expanded(
                  //             child: Text(
                  //               'We\'d love to hear your feedback!',
                  //               style: TextStyle(
                  //                 color: theme.brightness == Brightness.dark
                  //                     ? Colors.grey[300]
                  //                     : Colors.grey[700],
                  //               ),
                  //               overflow: TextOverflow.ellipsis,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendRequest,
                        icon: _isLoading 
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isLoading ? 'Sending...' : 'Send Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}