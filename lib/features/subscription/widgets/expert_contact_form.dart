// lib/features/subscription/widgets/expert_contact_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:universal_html/html.dart' as html;

/// A responsive contact form for expert services
/// 
/// This widget provides a form for users to contact experts about 
/// custom services like website development, QR code printing, etc.
class ExpertContactForm extends StatefulWidget {
  /// Whether to use mobile (stacked) layout
  final bool isMobile;
  
  const ExpertContactForm({
    Key? key,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<ExpertContactForm> createState() => _ExpertContactFormState();
}

class _ExpertContactFormState extends State<ExpertContactForm> {
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedService;
  final _formKey = GlobalKey<FormState>();
  
  // Form state
  bool _isSendingForm = false;
  bool _formSubmitted = false;
  String? _errorMessage;
  
  // Service options
  final List<String> _serviceOptions = [
    'Website Development',
    'QR Code Printing',
    'SEO Optimization',
    'Marketing Strategy',
    'Multiple Services',
    'Other',
  ];
  
  // Business email
  static const String _businessEmail = 'support@revboostapp.com';
  
  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Show success message if form was submitted
    if (_formSubmitted) {
      return _buildSuccessMessage();
    }
    
    // Show error message if there was an error
    if (_errorMessage != null) {
      return _buildErrorMessage();
    }
    
    // Select layout based on screen size
    return widget.isMobile ? _buildMobileForm() : _buildDesktopForm();
  }
  
  /// Success message widget shown after form submission
  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Message Sent Successfully!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your interest! Our expert team will review your inquiry and get back to you within 24 hours.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Send Another Message',
            type: AppButtonType.secondary,
            onPressed: () {
              setState(() {
                _formSubmitted = false;
                _resetForm();
              });
            },
          ),
        ],
      ),
    );
  }
  
  /// Error message widget shown if there was an error
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Message Could Not Be Sent',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unexpected error occurred. Please try again or contact us directly.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text: 'Try Again',
                type: AppButtonType.secondary,
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(width: 16),
              AppButton(
                text: 'Email Us Directly',
                type: AppButtonType.primary,
                icon: Icons.email_outlined,
                onPressed: () => _launchEmail(_businessEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Mobile layout for the contact form (stacked)
  Widget _buildMobileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            validator: _validateName,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          
          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email address',
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          
          // Phone field (optional)
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (Optional)',
            hint: 'Enter your phone number',
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          
          // Service dropdown
          _buildServiceDropdown(),
          const SizedBox(height: 16),
          
          // Message field
          _buildTextField(
            controller: _messageController,
            label: 'Your Message',
            hint: 'Tell us about your business needs',
            validator: _validateMessage,
            maxLines: 5,
            icon: Icons.message_outlined,
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Send Message',
              type: AppButtonType.primary,
              icon: Icons.send_rounded,
              isLoading: _isSendingForm,
              fullWidth: true,
              onPressed: _handleSubmit,
            ),
          ),
          
          // Alternative contact method
          _buildDirectContactSection(),
        ],
      ),
    );
  }
  
  /// Desktop layout for the contact form (side by side)
  Widget _buildDesktopForm() {
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - user info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  validator: _validateName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                
                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email address',
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                
                // Phone field (optional)
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                
                // Service dropdown
                _buildServiceDropdown(),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Right column - message and submit
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message field
                _buildTextField(
                  controller: _messageController,
                  label: 'Your Message',
                  hint: 'Tell us about your business needs',
                  validator: _validateMessage,
                  maxLines: 7,
                  icon: Icons.message_outlined,
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Send Message',
                    type: AppButtonType.primary,
                    icon: Icons.send_rounded,
                    isLoading: _isSendingForm,
                    fullWidth: true,
                    onPressed: _handleSubmit,
                  ),
                ),
                
                // Alternative contact method
                _buildDirectContactSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Common text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
  
  /// Service dropdown builder
  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Service You\'re Interested In',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business_center_outlined),
      ),
      value: _selectedService,
      validator: _validateService,
      items: _serviceOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedService = value;
        });
      },
    );
  }
  
  /// Alternative contact section
  Widget _buildDirectContactSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Or email us directly at:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _launchEmail(_businessEmail),
            icon: const Icon(Icons.email),
            label: Text(_businessEmail),
          ),
        ],
      ),
    );
  }
  
  /// Form validation methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  String? _validateService(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a service';
    }
    return null;
  }
  
  String? _validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a message';
    }
    
    if (value.length < 10) {
      return 'Message should be at least 10 characters';
    }
    
    return null;
  }
  
  /// Reset form to initial state
  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
    _selectedService = null;
    _isSendingForm = false;
    _errorMessage = null;
    
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
  }
  
  /// Handle form submission
  void _handleSubmit() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Start loading state
    setState(() {
      _isSendingForm = true;
    });
    
    // Collect form data
    final formData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'service': _selectedService,
      'message': _messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // In a real implementation, you would send this data to your backend
    // This could be done using Firebase Cloud Functions, a custom API, etc.
    
    // For demo purposes, we'll simulate a network request
    _simulateSendingEmail(formData);
  }
  
  /// Simulate sending email (replace with actual implementation)
  void _simulateSendingEmail(Map<String, dynamic> formData) {
    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      // Simulate 95% success rate
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      
      if (random < 95) {
        // Success case
        setState(() {
          _isSendingForm = false;
          _formSubmitted = true;
        });
        
        // Log success for debugging
        debugPrint('Form submitted successfully: $formData');
      } else {
        // Error case
        setState(() {
          _isSendingForm = false;
          _errorMessage = 'Network error while sending message. Please try again.';
        });
        
        // Log error for debugging
        debugPrint('Error submitting form: ${_errorMessage}');
      }
    });
  }
  
  /// Launch email client with pre-filled email
  void _launchEmail(String email) {
    // Create mailto link with pre-filled subject and body
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        'subject': 'Expert Services Inquiry',
        'body': 'Hello,\n\nI\'m interested in learning more about your professional services. '
                'Please contact me with more information.\n\n'
                'Best regards,\n\n',
      }),
    );
    
    // Open email client
    if (kIsWeb) {
      html.window.open(emailUri.toString(), '_blank');
    } else {
      // For mobile, you would use url_launcher package
      // launchUrl(emailUri);
      debugPrint('Would launch: ${emailUri.toString()}');
    }
  }
  
  /// Encode query parameters for mailto URI
  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}