// lib/core/services/email_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service for sending emails using API server
class EmailService {
  // API server URL
  final String _apiBaseUrl;
  
  // These are kept for backward compatibility but are not sent to the server
  final String _fromEmail;
  final String _fromName;
  
  /// Creates an instance of [EmailService]
  EmailService({
    required String apiKey, // Kept for backward compatibility
    required String fromEmail,
    required String fromName,
    String? apiBaseUrl,
  }) : _fromEmail = fromEmail,
       _fromName = fromName,
       _apiBaseUrl = apiBaseUrl ?? 'https://email-sms-sending-server.onrender.com';

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
      debugPrint('Preparing to send email to: $toEmail via API server');
      
      // Create the endpoint URL
      final url = '$_apiBaseUrl/api/email/review-request';
      
      // Prepare the request body for the API server
      final Map<String, dynamic> requestBody = {
        'toEmail': toEmail,
        'customerName': customerName,
        'businessName': businessName,
        'reviewLink': reviewLink,
        'fromEmail': _fromEmail,
        'fromName': _fromName,
      };

      if (replyTo != null && replyTo.isNotEmpty) {
        requestBody['replyTo'] = replyTo;
      }

      if (customData != null) {
        requestBody['customData'] = customData;
      }
      
      final encodedBody = jsonEncode(requestBody);
      debugPrint('Request body (truncated): ${encodedBody.substring(0, min(100, encodedBody.length))}...');
      
      bool serverConnected = await testServerConnection();
      if (!serverConnected) {
        debugPrint('Cannot connect to email server. Check server URL and status.');
        return false;
      }
      // Send request to our API server
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: encodedBody,
      ).timeout(const Duration(seconds: 15));
      
      // Log response for debugging
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');
      
      // Check response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('Email sent successfully to $toEmail');
          return true;
        } else {
          debugPrint('API reported failure: ${responseData['error'] ?? 'Unknown error'}');
          return false;
        }
      } else {
        // Log error details
        try {
          final responseBody = jsonDecode(response.body);
          final error = responseBody['error'];

          if (error is Map && error['message'] != null) {
            debugPrint('Email sending failed: ${error['message']}');
          } else {
            debugPrint('Email sending failed: ${response.body}');
          }
        } catch (_) {
          debugPrint('Failed to parse error response: ${response.body}');
        }
        return false;
      }
    } on TimeoutException {
      debugPrint('Request timed out after 15 seconds');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Exception sending email: $e');
      debugPrint('Stack trace: ${stackTrace.toString().substring(0, min(500, stackTrace.toString().length))}');
      return false;
    }
  }
  
  


  /// Sends a test email to verify the configuration
  Future<bool> sendTestEmail(String toEmail) async {
    try {
      debugPrint('Sending test email to: $toEmail via API server');
      
      // Create the endpoint URL
      final url = '$_apiBaseUrl/api/email/test';
      
      final requestBody = {
        'toEmail': toEmail,
        'fromEmail': _fromEmail,
        'fromName': _fromName,
      };
      
      debugPrint('Test email request: ${jsonEncode(requestBody)}');
      
      // Send the request to our API server
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Test email response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error sending test email: $e');
      return false;
    }
  }


  // Add this function to your EmailService class
Future<bool> testServerConnection() async {
  try {
    final response = await http.get(Uri.parse('$_apiBaseUrl/health'))
      .timeout(const Duration(seconds: 5));
    
    debugPrint('Server health check: ${response.statusCode} - ${response.body}');
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Server connection test failed: $e');
    return false;
  }
}

// Call this function before attempting to send email

  
  /// Helper method for min function
  int min(int a, int b) => a < b ? a : b;
}