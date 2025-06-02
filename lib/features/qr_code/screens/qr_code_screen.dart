// lib/features/qr_code/screens/updated_qr_code_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/features/qr_code/widgets/qr_display_card.dart';
import 'package:revboostapp/features/qr_code/widgets/qr_action_buttons.dart';
import 'package:revboostapp/features/qr_code/widgets/qr_link_display.dart';
import 'package:revboostapp/features/qr_code/widgets/qr_how_to_guide.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/error_display.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/qr_pdf_service.dart';

class UpdatedQrCodeScreen extends StatefulWidget {
  const UpdatedQrCodeScreen({Key? key}) : super(key: key);

  @override
  State<UpdatedQrCodeScreen> createState() => _UpdatedQrCodeScreenState();
}

class _UpdatedQrCodeScreenState extends State<UpdatedQrCodeScreen> {
  // State variables
  bool _isLoading = true;
  BusinessModel? _business;
  String _reviewLink = '';
  String _errorMessage = '';
  
  // Loading states for individual actions
  bool _isPrintLoading = false;
  bool _isShareLoading = false;
  bool _isDownloadLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  /// Load business data and generate review link
  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId != null) {
        final firestoreService = FirestoreService();
        final businesses = await firestoreService.getBusinessesByOwnerId(userId);

        if (businesses.isNotEmpty) {
          final business = businesses.first;
          
          setState(() {
            _business = business;
            _reviewLink = 'https://app.revboostapp.com/r/${business.id}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No business found. Please complete business setup first.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'User not authenticated.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading business data: $e';
        _isLoading = false;
      });
    }
  }

  /// Generate and print PDF
  Future<void> _printQrCodePdf() async {
    if (_business == null) return;
    
    setState(() {
      _isPrintLoading = true;
    });

    try {
      final pdfBytes = await QrPdfService.generateModernQrPdf(
        businessName: _business!.name,
        reviewLink: _reviewLink,
        template: QrPdfTemplate.vibrant,
        size: QrPdfSize.a4,
      );

      await QrPdfService.printOrDownloadPdf(
        pdfBytes: pdfBytes,
        fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        download: false, // This will open print dialog
      );

      if (mounted) {
        _showSuccessSnackBar('QR code is ready to print!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error generating PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintLoading = false;
        });
      }
    }
  }

  /// Share QR code as PDF
  Future<void> _shareQrCode() async {
    if (_business == null) return;
    
    setState(() {
      _isShareLoading = true;
    });

    try {
      final pdfBytes = await QrPdfService.generateModernQrPdf(
        businessName: _business!.name,
        reviewLink: _reviewLink,
        template: QrPdfTemplate.vibrant,
        size: QrPdfSize.a4,
      );

      // Create XFile from bytes for sharing
      final file = XFile.fromData(
        pdfBytes,
        name: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        mimeType: 'application/pdf',
      );

      // Calculate share position
      final box = context.findRenderObject() as RenderBox?;
      final sharePosition = box == null
          ? null
          : Rect.fromPoints(
              box.localToGlobal(Offset.zero),
              box.localToGlobal(box.size.bottomRight(Offset.zero)),
            );

      await Share.shareXFiles(
        [file],
        text: 'QR code for ${_business!.name} - Scan to leave a review!',
        subject: 'Review QR Code - ${_business!.name}',
        sharePositionOrigin: sharePosition,
      );

      if (mounted) {
        _showSuccessSnackBar('QR code shared successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error sharing QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShareLoading = false;
        });
      }
    }
  }

  /// Download QR code PDF
  Future<void> _downloadQrCode() async {
    if (_business == null) return;
    
    setState(() {
      _isDownloadLoading = true;
    });

    try {
      final pdfBytes = await QrPdfService.generateModernQrPdf(
        businessName: _business!.name,
        reviewLink: _reviewLink,
        template: QrPdfTemplate.vibrant,
        size: QrPdfSize.a4,
      );

      await QrPdfService.printOrDownloadPdf(
        pdfBytes: pdfBytes,
        fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        download: true, // This will download the file
      );

      if (mounted) {
        _showSuccessSnackBar('QR code downloaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error downloading QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadLoading = false;
        });
      }
    }
  }

  /// Copy review link to clipboard
  void _copyLinkToClipboard() {
    Clipboard.setData(ClipboardData(text: _reviewLink));
    _showSuccessSnackBar('Link copied to clipboard!');
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.successBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading your QR code...',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_business == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeaderSection(),
          
          const SizedBox(height: 32),
          
          // QR code display
          Center(
            child: QrDisplayCard(
              data: _reviewLink,
              businessName: _business!.name,
              size: 280,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          QrActionButtonsGrid(
            onPrint: _printQrCodePdf,
            onShare: _shareQrCode,
            onDownload: _downloadQrCode,
            onCopyLink: _copyLinkToClipboard,
            isPrintLoading: _isPrintLoading,
            isShareLoading: _isShareLoading,
            isDownloadLoading: _isDownloadLoading,
          ),
          
          const SizedBox(height: 32),
          
          // Review link display
          QrLinkDisplay(
            link: _reviewLink,
            onCopy: _copyLinkToClipboard,
          ),
          
          const SizedBox(height: 32),
          
          // How to use guide
          const QrHowToGuide(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'QR Code for ${_business!.name}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white, // This will be masked by the gradient
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Display this QR code in your restaurant or cafe to collect reviews easily',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick stats or tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Tip',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Place QR codes near your register, on tables, or at the entrance for maximum visibility.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ErrorDisplay(
              message: _errorMessage,
              margin: EdgeInsets.zero,
              onRetry: _loadBusinessData,
            ),
            
            const SizedBox(height: 24),
            
            AppButton(
              text: 'Try Again',
              onPressed: _loadBusinessData,
              icon: Icons.refresh_rounded,
              type: AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }
}






// // lib/features/qr_code/screens/qr_code_screen.dart

// // ignore_for_file: unused_import

// import 'dart:convert';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:revboostapp/core/services/firestore_service.dart';
// import 'package:revboostapp/models/business_model.dart';
// import 'package:revboostapp/providers/auth_provider.dart';
// import 'package:revboostapp/widgets/common/app_button.dart';
// import 'package:revboostapp/widgets/layout/app_layout.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:universal_html/js.dart' as js;
// import 'package:flutter/foundation.dart' show kIsWeb;

// class QrCodeScreen extends StatefulWidget {
//   const QrCodeScreen({Key? key}) : super(key: key);

//   @override
//   State<QrCodeScreen> createState() => _QrCodeScreenState();
// }

// class _QrCodeScreenState extends State<QrCodeScreen> {
//   final GlobalKey _qrKey = GlobalKey();
//   String _businessName = '';
//   String _reviewLink = '';
//   bool _isLoading = true;
//   BusinessModel? _business;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadBusinessData();
//   }

//   Future<void> _loadBusinessData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userId = authProvider.firebaseUser?.uid;

//       if (userId != null) {
//         // Get user's business
//         final firestoreService = FirestoreService();
//         final businesses = await firestoreService.getBusinessesByOwnerId(userId);

//         if (businesses.isNotEmpty) {
//           final business = businesses.first;
          
//           setState(() {
//             _business = business;
//             _businessName = business.name;
            
//             // Generate the review link for the business using Firebase Hosting URL
//             _reviewLink = 'https://app.revboostapp.com/r/${business.id}';
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _errorMessage = 'No business found. Please complete business setup first.';
//             _isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           _errorMessage = 'User not authenticated.';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error loading business data: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   // Helper function to capture QR code as image
//   Future<Uint8List?> _captureQrCode() async {
//     try {
//       final RenderRepaintBoundary boundary = 
//           _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
//       if (byteData != null) {
//         return byteData.buffer.asUint8List();
//       }
//       return null;
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error capturing QR code: $e')),
//         );
//       }
//       return null;
//     }
//   }

//   // Share QR code with other apps
//   Future<void> _shareQrCode() async {
//     final Uint8List? pngBytes = await _captureQrCode();
    
//     if (pngBytes == null) return;
    
//     if (kIsWeb) {
//       // For web, we'll use a different approach since Share isn't well supported
//       // Create a blob URL and use web APIs for sharing
//       try {
//         final content = base64Encode(pngBytes);
        
//         // Check if Web Share API is available
//         bool canShare = false;
//         try {
//           canShare = js.context.hasProperty('navigator') && 
//                      js.context['navigator'].hasProperty('share');
//         } catch (e) {
//           canShare = false;
//         }
        
//         if (canShare) {
//           // Use Web Share API if available
//           final blob = '''
//             (function() {
//               const base64 = "$content";
//               const binary = atob(base64);
//               const len = binary.length;
//               const bytes = new Uint8Array(len);
//               for (let i = 0; i < len; i++) {
//                 bytes[i] = binary.charCodeAt(i);
//               }
//               const blob = new Blob([bytes.buffer], {type: 'image/png'});
//               const file = new File([blob], '${_businessName.replaceAll(' ', '_')}_qr_code.png', {type: 'image/png'});
              
//               navigator.share({
//                 title: 'Review QR Code for $_businessName',
//                 text: 'Scan this QR code to leave a review for $_businessName',
//                 files: [file]
//               }).catch(e => console.error('Error sharing:', e));
//             })();
//           ''';
          
//           js.context.callMethod('eval', [blob]);
//         } else {
//           // Fallback to a custom share dialog
//           _showWebShareDialog(pngBytes);
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error sharing QR code: $e')),
//           );
//         }
//       }
//     } else {
//       // For mobile platforms, use share_plus
//       try {
//         final tempFile = XFile.fromData(
//           pngBytes,
//           name: '${_businessName.replaceAll(' ', '_')}_qr_code.png',
//           mimeType: 'image/png',
//         );
        
//         // Calculate position for share sheet
      
      
//         final box = context.findRenderObject() as RenderBox?;
//         final sharePosition = box == null
//             ? null
//             : Rect.fromPoints(
//                 box.localToGlobal(Offset.zero),
//                 box.localToGlobal(box.size.bottomRight(Offset.zero)),
//               );
              
//         await Share.shareXFiles(
//           [tempFile],
//           text: 'Scan this QR code to leave a review for $_businessName',
//           subject: 'Review QR Code for $_businessName',
//           sharePositionOrigin: sharePosition,
//         );
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error sharing QR code: $e')),
//           );
//         }
//       }
//     }
//   }

//   // Custom share dialog for web when Web Share API is not available
//   void _showWebShareDialog(Uint8List pngBytes) {
//     final String imgSrc = 'data:image/png;base64,${base64Encode(pngBytes)}';
    
//     // Create a dialog with options
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Share QR Code'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Image.memory(
//                   pngBytes,
//                   width: 200,
//                   height: 200,
//                 ),
//                 const SizedBox(height: 16),
//                 const Text('Choose how to share:'),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton.icon(
//               icon: const Icon(Icons.email),
//               label: const Text('Email'),
//               onPressed: () {
//                 final mailtoLink = 'mailto:?subject=Review QR Code for $_businessName&body=Scan this QR code to leave a review for $_businessName';
//                 js.context.callMethod('open', [mailtoLink]);
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton.icon(
//               icon: const Icon(Icons.download),
//               label: const Text('Download'),
//               onPressed: () {
//                 _downloadQrCode(pngBytes);
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton.icon(
//               icon: const Icon(Icons.copy),
//               label: const Text('Copy Link'),
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: _reviewLink));
//                 Navigator.of(context).pop();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Link copied to clipboard')),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Download QR code (for Web or Save button)
//   Future<void> _downloadQrCode(Uint8List? bytes) async {
//     // Allow function to be called with bytes or capture them if null
//     final Uint8List? pngBytes = bytes ?? await _captureQrCode();
    
//     if (pngBytes == null) return;
    
//     if (kIsWeb) {
//       final content = base64Encode(pngBytes);
      
//       // Create a download link for the QR code
//       final href = 'data:image/png;base64,$content';
//       final filename = '${_businessName.replaceAll(' ', '_')}_qr_code.png';
      
//       // Use a JavaScript approach that works cross-browser
//       final jsString = 
//           "var a = document.createElement('a'); "
//           "a.href = '$href'; "
//           "a.download = '$filename'; "
//           "document.body.appendChild(a); "
//           "a.click(); "
//           "document.body.removeChild(a);";
          
//       js.context.callMethod('eval', [jsString]);
//     } else {
//       // For mobile platforms - handle appropriately
//       // This may require additional implementation using path_provider
//       // and file saving logic for mobile platforms
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Download not supported on this platform')),
//       );
//     }
//   }

//   // Improved print function
//   // Updated _printQrCode function with enhanced design
//   Future<void> _printQrCode() async {
//   if (kIsWeb) {
//     try {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Preparing QR code for printing...')),
//         );
//       }
      
//       // Capture the QR code as image
//       final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//       if (boundary == null) {
//         throw Exception("Could not find QR code element");
//       }
      
//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       if (byteData == null) {
//         throw Exception("Failed to convert QR code to image");
//       }
      
//       final bytes = byteData.buffer.asUint8List();
//       final base64Image = base64Encode(bytes);
      
//       // Create HTML with inline CSS for the printout
//       final htmlContent = '''
//         <!DOCTYPE html>
//         <html>
//         <head>
//           <meta charset="utf-8">
//           <title>$_businessName - Review QR Code</title>
//           <style>
//             @page {
//               size: A4;
//               margin: 0;
//             }
//             body {
//               margin: 0;
//               padding: 0;
//               background-color: #f0f0f0;
//               font-family: Arial, sans-serif;
//             }
//             .page {
//               width: 210mm;
//               height: 297mm;
//               padding: 20mm;
//               box-sizing: border-box;
//               position: relative;
//             }
//             .card {
//               background-color: white;
//               border-radius: 12px;
//               box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
//               padding: 30px;
//               width: 170mm;
//               height: 257mm;
//               box-sizing: border-box;
//               display: flex;
//               flex-direction: column;
//               align-items: center;
//               justify-content: space-between;
//             }
//             .header {
//               text-align: center;
//               margin-bottom: 20px;
//               width: 100%;
//             }
//             .business-name {
//               color: #1A73E8;
//               font-size: 28pt;
//               font-weight: bold;
//               margin: 0 0 10px 0;
//             }
//             .subtitle {
//               font-size: 14pt;
//               color: #555;
//               margin: 0 0 5px 0;
//               line-height: 1.4;
//             }
//             .instructions {
//               font-size: 12pt;
//               color: #666;
//               margin: 5px 0 0 0;
//               text-align: center;
//             }
//             .qr-container {
//               display: flex;
//               justify-content: center;
//               align-items: center;
//               margin: 30px 0;
//             }
//             .qr-code {
//               width: 60mm;
//               height: 60mm;
//               padding: 4mm;
//               border: 1px solid #ddd;
//               background-color: white;
//             }
//             .thank-you {
//               font-size: 13pt;
//               color: #555;
//               margin: 15px 0 0 0;
//               font-style: italic;
//             }
//             .footer {
//               text-align: center;
//               color: #777;
//               font-size: 10pt;
//               margin-top: 20px;
//               width: 100%;
//             }
//           </style>
//         </head>
//         <body>
//           <div class="page">
//             <div class="card">
//               <div class="header">
//                 <h1 class="business-name">$_businessName</h1>
//                 <p class="subtitle">Your opinion matters!</p>
//                 <p class="instructions">Scan this QR code to share your experience</p>
//               </div>
//               <div class="qr-container">
//                 <img class="qr-code" src="data:image/png;base64,$base64Image" alt="Review QR Code">
//               </div>
//               <p class="thank-you">Thank you for helping us improve!</p>
//               <div class="footer">
//                 Powered by RevBoost • www.revboostapp.com
//               </div>
//             </div>
//           </div>
//           <script>
//             // Use a delayed print to ensure resources are loaded
//             setTimeout(function() {
//               try {
//                 window.print();
//                 // Close the window after print dialog is closed (optional)
//                 // setTimeout(function() { window.close(); }, 500);
//               } catch(e) {
//                 console.error('Print error:', e);
//               }
//             }, 500);
//           </script>
//         </body>
//         </html>
//       ''';
      
//       // JavaScript to open a new window and print the HTML content
//       final jsScript = '''
//         (function() {
//           try {
//             const printWindow = window.open('', '_blank');
//             if (!printWindow) {
//               alert('Please allow pop-ups to print the QR code.');
//               return;
//             }
            
//             printWindow.document.write(`$htmlContent`);
//             printWindow.document.close();
//           } catch(e) {
//             console.error('Error creating print window:', e);
//             alert('Error preparing print. Please try again.');
//           }
//         })();
//       ''';
      
//       // Execute the JavaScript
//       js.context.callMethod('eval', [jsScript]);
      
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error preparing QR code: $e')),
//         );
//       }
//     }
//   } else {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Print functionality is only available on web')),
//       );
//     }
//   }
// }
  
//   void _copyLinkToClipboard() {
//     Clipboard.setData(ClipboardData(text: _reviewLink));
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Link copied to clipboard')),
//       );
//     }
//   }

  
//   @override
//   Widget build(BuildContext context) {
//     return _buildContent();
//   }

//   Widget _buildContent() {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Theme.of(context).colorScheme.error,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Error',
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _errorMessage,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.bodyLarge,
//               ),
//               const SizedBox(height: 24),
//               AppButton(
//                 text: 'Try Again',
//                 onPressed: _loadBusinessData,
//                 icon: Icons.refresh,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'QR Code for ${_business?.name ?? "Your Business"}',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Display this QR code in your business to collect reviews easily',
//             style: Theme.of(context).textTheme.bodyLarge,
//           ),
//           const SizedBox(height: 32),
          
//           // QR code display
//           Center(
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       RepaintBoundary(
//                         key: _qrKey,
//                         child: QrImageView(
//                           data: _reviewLink,
//                           version: QrVersions.auto,
//                           size: 280,
//                           eyeStyle: const QrEyeStyle(
//                             eyeShape: QrEyeShape.square,
//                             color: Color(0xFF2563EB),
//                           ),
//                           dataModuleStyle: const QrDataModuleStyle(
//                             dataModuleShape: QrDataModuleShape.square,
//                             color: Color(0xFF2563EB),
//                           ),
//                           embeddedImage: const AssetImage('assets/splash_logo_light.png'),
//                           embeddedImageStyle: const QrEmbeddedImageStyle(
//                             size: Size(40, 40),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Scan to leave a review',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _businessName,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Actions
//                 _buildActionsSection(),
//               ],
//             ),
//           ),
          
//           const SizedBox(height: 32),
          
//           // Review Link
//           _buildReviewLinkSection(),
          
//           const SizedBox(height: 32),
          
//           // Additional Information
//           Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//               side: BorderSide(
//                 color: Colors.grey[300]!,
//                 width: 1,
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'How to use your QR code',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildHowToItem(
//                     context,
//                     '1',
//                     'Print the QR code',
//                     'Display it prominently in your business where customers can easily scan it',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildHowToItem(
//                     context,
//                     '2',
//                     'Customers scan the code',
//                     'When customers scan the code, they can leave a review on their preferred platform',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildHowToItem(
//                     context,
//                     '3',
//                     'Collect more reviews',
//                     'The system automatically filters negative reviews for private feedback',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildHowToItem(
//                     context,
//                     '4',
//                     'Boost your reputation',
//                     'Increase your online presence with more positive public reviews',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionsSection() {
//     return Wrap(
//       alignment: WrapAlignment.center,
//       spacing: 16,
//       runSpacing: 16,
//       children: [
//         _buildActionButton(
//           icon: Icons.print,
//           label: 'Print',
//           onPressed: _printQrCode,
//         ),
//         _buildActionButton(
//           icon: Icons.share,
//           label: 'Share',
//           onPressed: _shareQrCode,
//         ),
//         _buildActionButton(
//           icon: Icons.download,
//           label: 'Save',
//           onPressed: () => _downloadQrCode(null),
//         ),
//         _buildActionButton(
//           icon: Icons.copy,
//           label: 'Copy Link',
//           onPressed: _copyLinkToClipboard,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   Widget _buildReviewLinkSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Review Link',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Share this link with your customers to collect reviews',
//           style: Theme.of(context).textTheme.bodyMedium,
//         ),
//         const SizedBox(height: 16),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: Colors.grey[300]!,
//             ),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Text(
//                     _reviewLink,
//                     style: Theme.of(context).textTheme.bodyMedium,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//               Material(
//                 color: Theme.of(context).primaryColor,
//                 borderRadius: const BorderRadius.only(
//                   topRight: Radius.circular(7),
//                   bottomRight: Radius.circular(7),
//                 ),
//                 child: InkWell(
//                   onTap: _copyLinkToClipboard,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(7),
//                     bottomRight: Radius.circular(7),
//                   ),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.copy, color: Colors.white, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Copy',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHowToItem(
//     BuildContext context,
//     String number,
//     String title,
//     String description,
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             color: Theme.of(context).primaryColor,
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
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
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
// }
