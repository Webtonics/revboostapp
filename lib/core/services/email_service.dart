// // lib/core/services/email_service.dart

// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// /// A service for sending emails using API server
// class EmailService {
//   // API server URL
//   final String _apiBaseUrl;
  
//   // These are kept for backward compatibility but are not sent to the server
//   final String _fromEmail;
//   final String _fromName;
  
//   /// Creates an instance of [EmailService]
//   EmailService({
//     required String apiKey, // Kept for backward compatibility
//     required String fromEmail,
//     required String fromName,
//     String? apiBaseUrl,
//   }) : _fromEmail = fromEmail,
//        _fromName = fromName,
//        _apiBaseUrl = apiBaseUrl ?? 'https://email-sms-sending-server.onrender.com';

//   /// Sends a review request email to a customer
//   ///
//   /// Returns [true] if the email was sent successfully, [false] otherwise.
//   Future<bool> sendReviewRequest({
//     required String toEmail,
//     required String customerName,
//     required String businessName,
//     required String reviewLink,
//     String? replyTo,
//     Map<String, dynamic>? customData,
//   }) async {
//     try {
//       debugPrint('Preparing to send email to: $toEmail via API server');
      
//       // Create the endpoint URL
//       final url = '$_apiBaseUrl/api/email/review-request';
      
//       // Prepare the request body for the API server
//       final Map<String, dynamic> requestBody = {
//         'toEmail': toEmail,
//         'customerName': customerName,
//         'businessName': businessName,
//         'reviewLink': reviewLink,
//         'fromEmail': _fromEmail,
//         'fromName': _fromName,
//       };

//       if (replyTo != null && replyTo.isNotEmpty) {
//         requestBody['replyTo'] = replyTo;
//       }

//       if (customData != null) {
//         requestBody['customData'] = customData;
//       }
      
//       final encodedBody = jsonEncode(requestBody);
//       debugPrint('Request body (truncated): ${encodedBody.substring(0, min(100, encodedBody.length))}...');
      
//       bool serverConnected = await testServerConnection();
//       if (!serverConnected) {
//         debugPrint('Cannot connect to email server. Check server URL and status.');
//         return false;
//       }
//       // Send request to our API server
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: encodedBody,
//       ).timeout(const Duration(seconds: 15));
      
//       // Log response for debugging
//       debugPrint('API Response Status: ${response.statusCode}');
//       debugPrint('API Response Body: ${response.body}');
      
//       // Check response
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         if (responseData['success'] == true) {
//           debugPrint('Email sent successfully to $toEmail');
//           return true;
//         } else {
//           debugPrint('API reported failure: ${responseData['error'] ?? 'Unknown error'}');
//           return false;
//         }
//       } else {
//         // Log error details
//         try {
//           final responseBody = jsonDecode(response.body);
//           final error = responseBody['error'];

//           if (error is Map && error['message'] != null) {
//             debugPrint('Email sending failed: ${error['message']}');
//           } else {
//             debugPrint('Email sending failed: ${response.body}');
//           }
//         } catch (_) {
//           debugPrint('Failed to parse error response: ${response.body}');
//         }
//         return false;
//       }
//     } on TimeoutException {
//       debugPrint('Request timed out after 15 seconds');
//       return false;
//     } catch (e, stackTrace) {
//       debugPrint('Exception sending email: $e');
//       debugPrint('Stack trace: ${stackTrace.toString().substring(0, min(500, stackTrace.toString().length))}');
//       return false;
//     }
//   }
  
//   /// Sends a feedback notification email to a business owner
//   ///
//   /// Used when negative feedback is submitted by a customer
//   /// Returns [true] if the email was sent successfully, [false] otherwise.
//   Future<bool> sendFeedbackNotification({
//     required String businessId,
//     required String toEmail,
//     required String businessName,
//     required double rating,
//     required String feedback,
//     String? customerName,
//   }) async {
//     try {
//       debugPrint('Sending feedback notification to: $toEmail via API server');
      
//       // Create the endpoint URL
//       final url = '$_apiBaseUrl/api/email/feedback-notification';
      
//       // Check server connection first
//       bool serverConnected = await testServerConnection();
//       if (!serverConnected) {
//         debugPrint('Cannot connect to email server. Check server URL and status.');
//         return false;
//       }
      
//       // Prepare the request body
//       final Map<String, dynamic> requestBody = {
//         'businessId': businessId,
//         'toEmail': toEmail,
//         'businessName': businessName,
//         'rating': rating,
//         'feedback': feedback,
//         'customerName': customerName ?? 'Anonymous Customer',
//         'fromEmail': _fromEmail,
//         'fromName': _fromName,
//       };
      
//       final encodedBody = jsonEncode(requestBody);
//       debugPrint('Request body (truncated): ${encodedBody.substring(0, min(100, encodedBody.length))}...');
      
//       // Send request to our API server
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: encodedBody,
//       ).timeout(const Duration(seconds: 15));
      
//       // Log response for debugging
//       debugPrint('API Response Status: ${response.statusCode}');
//       debugPrint('API Response Body: ${response.body}');
      
//       // Check response
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         if (responseData['success'] == true) {
//           debugPrint('Feedback notification sent successfully to $toEmail');
//           return true;
//         } else {
//           debugPrint('API reported failure: ${responseData['error'] ?? 'Unknown error'}');
//           return false;
//         }
//       } else {
//         // Log error details
//         try {
//           final responseBody = jsonDecode(response.body);
//           debugPrint('Feedback notification failed: ${responseBody['message'] ?? response.body}');
//         } catch (_) {
//           debugPrint('Failed to parse error response: ${response.body}');
//         }
//         return false;
//       }
//     } on TimeoutException {
//       debugPrint('Request timed out after 15 seconds');
//       return false;
//     } catch (e, stackTrace) {
//       debugPrint('Exception sending feedback notification: $e');
//       debugPrint('Stack trace: ${stackTrace.toString().substring(0, min(500, stackTrace.toString().length))}');
//       return false;
//     }
//   }

//   /// Sends a test email to verify the configuration
//   Future<bool> sendTestEmail(String toEmail) async {
//     try {
//       debugPrint('Sending test email to: $toEmail via API server');
      
//       // Create the endpoint URL
//       final url = '$_apiBaseUrl/api/email/test';
      
//       final requestBody = {
//         'toEmail': toEmail,
//         'fromEmail': _fromEmail,
//         'fromName': _fromName,
//       };
      
//       debugPrint('Test email request: ${jsonEncode(requestBody)}');
      
//       // Send the request to our API server
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       ).timeout(const Duration(seconds: 10));
      
//       debugPrint('Test email response: ${response.statusCode} - ${response.body}');
      
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         return responseData['success'] == true;
//       }
      
//       return false;
//     } catch (e) {
//       debugPrint('Error sending test email: $e');
//       return false;
//     }
//   }

//   // Test server connection before sending requests
//   Future<bool> testServerConnection() async {
//     try {
//       final response = await http.get(Uri.parse('$_apiBaseUrl/health'))
//         .timeout(const Duration(seconds: 5));
      
//       debugPrint('Server health check: ${response.statusCode} - ${response.body}');
//       return response.statusCode == 200;
//     } catch (e) {
//       debugPrint('Server connection test failed: $e');
//       return false;
//     }
//   }
  
//   /// Helper method for min function
//   int min(int a, int b) => a < b ? a : b;
// }

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

  /// Sends a review request email to a customer with enhanced error handling
  ///
  /// Returns [true] if the email was sent successfully, throws an exception if there's an error.
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
      
      // Test server connection before sending request
      bool serverConnected = await testServerConnection();
      debugPrint('Server connection test result: $serverConnected');
      
      if (!serverConnected) {
        debugPrint('Cannot connect to email server. Check server URL and status.');
        throw Exception('Unable to connect to email server. Server may be down or unreachable.');
      }
      
      // Send request to our API server
      debugPrint('Sending HTTP request to $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: encodedBody,
      ).timeout(const Duration(seconds: 20)); // Increased timeout slightly
      
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
          throw Exception('Email service reported failure: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        // Log error details
        String errorMessage = 'Email sending failed with status ${response.statusCode}';
        try {
          final responseBody = jsonDecode(response.body);
          final error = responseBody['error'];

          if (error is Map && error['message'] != null) {
            errorMessage = 'Email sending failed: ${error['message']}';
            debugPrint(errorMessage);
          } else {
            debugPrint('Email sending failed: ${response.body}');
          }
        } catch (_) {
          debugPrint('Failed to parse error response: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      debugPrint('Request timed out after 20 seconds');
      throw Exception('Request timed out. The server took too long to respond.');
    } catch (e, stackTrace) {
      if (e is Exception) {
        // Re-throw exceptions that we've already formatted
        rethrow;
      }
      debugPrint('Exception sending email: $e');
      debugPrint('Stack trace: ${stackTrace.toString().substring(0, min(500, stackTrace.toString().length))}');
      throw Exception('Failed to send email: $e');
    }
  }
  
  /// Sends a feedback notification email to a business owner
  ///
  /// Used when negative feedback is submitted by a customer
  /// Returns [true] if the email was sent successfully, [false] otherwise.
  Future<bool> sendFeedbackNotification({
    required String businessId,
    required String toEmail,
    required String businessName,
    required double rating,
    required String feedback,
    String? customerName,
  }) async {
    try {
      debugPrint('Sending feedback notification to: $toEmail via API server');
      
      // Create the endpoint URL
      final url = '$_apiBaseUrl/api/email/feedback-notification';
      
      // Check server connection first
      bool serverConnected = await testServerConnection();
      if (!serverConnected) {
        debugPrint('Cannot connect to email server. Check server URL and status.');
        return false;
      }
      
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'businessId': businessId,
        'toEmail': toEmail,
        'businessName': businessName,
        'rating': rating,
        'feedback': feedback,
        'customerName': customerName ?? 'Anonymous Customer',
        'fromEmail': _fromEmail,
        'fromName': _fromName,
      };
      
      final encodedBody = jsonEncode(requestBody);
      debugPrint('Request body (truncated): ${encodedBody.substring(0, min(100, encodedBody.length))}...');
      
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
          debugPrint('Feedback notification sent successfully to $toEmail');
          return true;
        } else {
          debugPrint('API reported failure: ${responseData['error'] ?? 'Unknown error'}');
          return false;
        }
      } else {
        // Log error details
        try {
          final responseBody = jsonDecode(response.body);
          debugPrint('Feedback notification failed: ${responseBody['message'] ?? response.body}');
        } catch (_) {
          debugPrint('Failed to parse error response: ${response.body}');
        }
        return false;
      }
    } on TimeoutException {
      debugPrint('Request timed out after 15 seconds');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Exception sending feedback notification: $e');
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

  /// Test server connection before sending requests
  Future<bool> testServerConnection() async {
    try {
      debugPrint('Testing connection to email server at $_apiBaseUrl/health');
      final response = await http.get(Uri.parse('$_apiBaseUrl/health'))
        .timeout(const Duration(seconds: 10)); // Increased timeout
      
      debugPrint('Server health check: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData['status'] == 'ok';
        } catch (e) {
          debugPrint('Error parsing health check response: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Server connection test failed: $e');
      return false;
    }
  }
  
  /// Helper method for min function
  int min(int a, int b) => a < b ? a : b;
}