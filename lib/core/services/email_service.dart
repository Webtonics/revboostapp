// lib/core/services/email_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service for sending emails using Resend API
class EmailService {
  final String _apiKey;
  final String _fromEmail;
  final String _fromName;
  
  /// Creates an instance of [EmailService]
  /// 
  /// Requires a Resend API key, sender email, and sender name.
  EmailService({
    required String apiKey,
    required String fromEmail,
    required String fromName,
  }) : _apiKey = apiKey,
       _fromEmail = fromEmail,
       _fromName = fromName;
  
  /// Sends a review request email to a customer
  ///
  /// Returns [true] if the email was sent successfully, [false] otherwise.
  Future<bool> sendReviewRequest({
    required String toEmail,
    required String customerName,
    required String businessName,
    required String reviewLink,
    String? replyTo,
    Map<String, dynamic>? customData,
  }) async {
    try {
      const url = 'https://api.resend.com/emails';
      
      // Build a nice HTML email with responsive design
      final htmlContent = _buildReviewRequestHtml(
        customerName: customerName,
        businessName: businessName,
        reviewLink: reviewLink,
        customData: customData,
      );
      
      // Prepare email data
      final emailData = {
        'from': '$_fromName <$_fromEmail>',
        'to': [toEmail],
        'subject': 'We\'d love to hear your feedback!',
        'html': htmlContent,
        'tags': [
          {'name': 'type', 'value': 'review_request'},
          {'name': 'business', 'value': businessName},
        ],
      };
      
      // Add reply-to if provided
      if (replyTo != null && replyTo.isNotEmpty) {
        emailData['reply_to'] = replyTo;
      }
      
      // Send email via Resend API
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'RevBoost/1.0',
        },
        body: jsonEncode(emailData),
      );
      
      // Log response for debugging in development
      if (kDebugMode) {
        print('Resend API Response: ${response.statusCode} - ${response.body}');
      }
      
      // Check response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Log error details
        final responseBody = jsonDecode(response.body);
        debugPrint('Email sending failed: ${responseBody['message'] ?? response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception sending email: $e');
      return false;
    }
  }
  
  /// Builds HTML content for the review request email
  String _buildReviewRequestHtml({
    required String customerName,
    required String businessName,
    required String reviewLink,
    Map<String, dynamic>? customData,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>We'd Love Your Feedback</title>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        
        /* Base styles */
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          line-height: 1.6;
          color: #374151;
          background-color: #f3f4f6;
          margin: 0;
          padding: 0;
        }
        
        /* Container styles */
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #ffffff;
        }
        
        /* Header styles */
        .header {
          text-align: center;
          padding: 20px 0;
          border-bottom: 1px solid #e5e7eb;
        }
        
        .header h2 {
          color: #1e3a8a;
          margin: 0;
          font-size: 24px;
          font-weight: 700;
        }
        
        /* Content styles */
        .content {
          padding: 24px 20px;
        }
        
        /* Button styles */
        .button-container {
          text-align: center;
          margin: 30px 0;
        }
        
        .button {
          display: inline-block;
          padding: 12px 24px;
          background-color: #2563eb;
          color: white !important;
          text-decoration: none;
          border-radius: 6px;
          font-weight: 600;
          font-size: 16px;
          transition: background-color 0.3s;
        }
        
        .button:hover {
          background-color: #1e40af;
        }
        
        /* Star rating styles */
        .rating-container {
          text-align: center;
          margin: 30px 0;
        }
        
        .stars {
          display: inline-block;
        }
        
        .star {
          display: inline-block;
          margin: 0 5px;
          font-size: 40px;
          color: #d1d5db;
        }
        
        .star a {
          color: #d1d5db;
          text-decoration: none;
        }
        
        .star a:hover {
          color: #fbbf24;
        }
        
        /* Footer styles */
        .footer {
          text-align: center;
          margin-top: 20px;
          padding-top: 20px;
          border-top: 1px solid #e5e7eb;
          font-size: 12px;
          color: #6b7280;
        }
        
        /* Responsive adjustments */
        @media only screen and (max-width: 480px) {
          .container {
            padding: 10px;
          }
          
          .content {
            padding: 20px 15px;
          }
          
          .button {
            display: block;
            text-align: center;
          }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>We'd Love Your Feedback!</h2>
        </div>
        <div class="content">
          <p>Hello ${_escapeHtml(customerName)},</p>
          <p>Thank you for choosing ${_escapeHtml(businessName)}. We hope you had a great experience!</p>
          <p>We value your feedback and would appreciate it if you could take a moment to share your experience with us.</p>
          
          <div class="button-container">
            <a href="${_escapeHtml(reviewLink)}" class="button">Leave a Review</a>
          </div>
          
          <p>Your feedback helps us improve and better serve our customers.</p>
          <p>Thank you for your time!</p>
          <p>
            Best regards,<br>
            The ${_escapeHtml(businessName)} Team
          </p>
        </div>
        <div class="footer">
          <p>This email was sent to you because you interacted with ${_escapeHtml(businessName)}.</p>
          <p>© ${DateTime.now().year} ${_escapeHtml(businessName)}. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
  
  /// Simple HTML escaping for basic security
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
  
  /// Sends a test email to verify the configuration
  Future<bool> sendTestEmail(String toEmail) async {
    try {
      const url = 'https://api.resend.com/emails';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': '$_fromName <$_fromEmail>',
          'to': [toEmail],
          'subject': 'RevBoost Email Test',
          'html': '<p>This is a test email from RevBoost. If you received this, email sending is working properly!</p>',
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending test email: $e');
      return false;
    }
  }
}