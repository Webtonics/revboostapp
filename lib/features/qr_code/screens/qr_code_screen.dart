// // lib/features/qr_code/screens/updated_qr_code_screen.dart

// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:revboostapp/core/services/firestore_service.dart';
// import 'package:revboostapp/core/theme/app_colors.dart';
// import 'package:revboostapp/features/qr_code/widgets/qr_display_card.dart';
// import 'package:revboostapp/features/qr_code/widgets/qr_action_buttons.dart';
// import 'package:revboostapp/features/qr_code/widgets/qr_link_display.dart';
// import 'package:revboostapp/features/qr_code/widgets/qr_how_to_guide.dart';
// import 'package:revboostapp/models/business_model.dart';
// import 'package:revboostapp/providers/auth_provider.dart';
// import 'package:revboostapp/widgets/common/app_button.dart';
// import 'package:revboostapp/widgets/common/error_display.dart';
// import 'package:revboostapp/widgets/common/loading_overlay.dart';
// import 'package:share_plus/share_plus.dart';

// import '../../../core/services/qr_pdf_service.dart';

// class UpdatedQrCodeScreen extends StatefulWidget {
//   const UpdatedQrCodeScreen({Key? key}) : super(key: key);

//   @override
//   State<UpdatedQrCodeScreen> createState() => _UpdatedQrCodeScreenState();
// }

// class _UpdatedQrCodeScreenState extends State<UpdatedQrCodeScreen> {
//   // State variables
//   bool _isLoading = true;
//   BusinessModel? _business;
//   String _reviewLink = '';
//   String _errorMessage = '';
  
//   // Loading states for individual actions
//   bool _isPrintLoading = false;
//   bool _isShareLoading = false;
//   bool _isDownloadLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadBusinessData();
//   }

//   /// Load business data and generate review link
//   Future<void> _loadBusinessData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userId = authProvider.firebaseUser?.uid;

//       if (userId != null) {
//         final firestoreService = FirestoreService();
//         final businesses = await firestoreService.getBusinessesByOwnerId(userId);

//         if (businesses.isNotEmpty) {
//           final business = businesses.first;
          
//           setState(() {
//             _business = business;
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

//   /// Generate and print PDF
//   Future<void> _printQrCodePdf() async {
//     if (_business == null) return;
    
//     setState(() {
//       _isPrintLoading = true;
//     });

//     try {
//       final pdfBytes = await QrPdfService.generateModernQrPdf(
//         businessName: _business!.name,
//         reviewLink: _reviewLink,
//         template: QrPdfTemplate.vibrant,
//         size: QrPdfSize.a4,
//       );

//       await QrPdfService.printOrDownloadPdf(
//         pdfBytes: pdfBytes,
//         fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
//         download: false, // This will open print dialog
//       );

//       if (mounted) {
//         _showSuccessSnackBar('QR code is ready to print!');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorSnackBar('Error generating PDF: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isPrintLoading = false;
//         });
//       }
//     }
//   }

//   /// Share QR code as PDF
//   Future<void> _shareQrCode() async {
//     if (_business == null) return;
    
//     setState(() {
//       _isShareLoading = true;
//     });

//     try {
//       final pdfBytes = await QrPdfService.generateModernQrPdf(
//         businessName: _business!.name,
//         reviewLink: _reviewLink,
//         template: QrPdfTemplate.vibrant,
//         size: QrPdfSize.a4,
//       );

//       // Create XFile from bytes for sharing
//       final file = XFile.fromData(
//         pdfBytes,
//         name: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
//         mimeType: 'application/pdf',
//       );

//       // Calculate share position
//       final box = context.findRenderObject() as RenderBox?;
//       final sharePosition = box == null
//           ? null
//           : Rect.fromPoints(
//               box.localToGlobal(Offset.zero),
//               box.localToGlobal(box.size.bottomRight(Offset.zero)),
//             );

//       await Share.shareXFiles(
//         [file],
//         text: 'QR code for ${_business!.name} - Scan to leave a review!',
//         subject: 'Review QR Code - ${_business!.name}',
//         sharePositionOrigin: sharePosition,
//       );

//       if (mounted) {
//         _showSuccessSnackBar('QR code shared successfully!');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorSnackBar('Error sharing QR code: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isShareLoading = false;
//         });
//       }
//     }
//   }

//   /// Download QR code PDF
//   Future<void> _downloadQrCode() async {
//     if (_business == null) return;
    
//     setState(() {
//       _isDownloadLoading = true;
//     });

//     try {
//       final pdfBytes = await QrPdfService.generateModernQrPdf(
//         businessName: _business!.name,
//         reviewLink: _reviewLink,
//         template: QrPdfTemplate.vibrant,
//         size: QrPdfSize.a4,
//       );

//       await QrPdfService.printOrDownloadPdf(
//         pdfBytes: pdfBytes,
//         fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
//         download: true, // This will download the file
//       );

//       if (mounted) {
//         _showSuccessSnackBar('QR code downloaded successfully!');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorSnackBar('Error downloading QR code: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isDownloadLoading = false;
//         });
//       }
//     }
//   }

//   /// Copy review link to clipboard
//   void _copyLinkToClipboard() {
//     Clipboard.setData(ClipboardData(text: _reviewLink));
//     _showSuccessSnackBar('Link copied to clipboard!');
//   }

//   /// Show success snackbar
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(
//               Icons.check_circle_rounded,
//               color: AppColors.success,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: AppColors.successBg,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   /// Show error snackbar
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(
//               Icons.error_outline_rounded,
//               color: AppColors.error,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: AppColors.errorBg,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LoadingOverlay(
//       isLoading: _isLoading,
//       message: 'Loading your QR code...',
//       child: _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     if (_errorMessage.isNotEmpty) {
//       return _buildErrorState();
//     }

//     if (_business == null) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header section
//           _buildHeaderSection(),
          
//           const SizedBox(height: 32),
          
//           // QR code display
//           Center(
//             child: QrDisplayCard(
//               data: _reviewLink,
//               businessName: _business!.name,
//               size: 280,
//             ),
//           ),
          
//           const SizedBox(height: 32),
          
//           // Action buttons
//           QrActionButtonsGrid(
//             onPrint: _printQrCodePdf,
//             onShare: _shareQrCode,
//             onDownload: _downloadQrCode,
//             onCopyLink: _copyLinkToClipboard,
//             isPrintLoading: _isPrintLoading,
//             isShareLoading: _isShareLoading,
//             isDownloadLoading: _isDownloadLoading,
//           ),
          
//           const SizedBox(height: 32),
          
//           // Review link display
//           QrLinkDisplay(
//             link: _reviewLink,
//             onCopy: _copyLinkToClipboard,
//           ),
          
//           const SizedBox(height: 32),
          
//           // How to use guide
//           const QrHowToGuide(),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Title with gradient text effect
//         ShaderMask(
//           shaderCallback: (bounds) => const LinearGradient(
//             colors: [
//               AppColors.primary,
//               AppColors.secondary,
//             ],
//           ).createShader(bounds),
//           child: Text(
//             'QR Code for ${_business!.name}',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: Colors.white, // This will be masked by the gradient
//             ),
//           ),
//         ),
        
//         const SizedBox(height: 8),
        
//         // Subtitle
//         Text(
//           'Display this QR code in your restaurant or cafe to collect reviews easily',
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//             color: AppColors.neutral600,
//           ),
//         ),
        
//         const SizedBox(height: 16),
        
//         // Quick stats or tips
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppColors.primary.withOpacity(0.05),
//                 AppColors.secondary.withOpacity(0.05),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppColors.primary.withOpacity(0.1),
//               width: 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.lightbulb_outline_rounded,
//                   color: AppColors.primary,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Pro Tip',
//                       style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     Text(
//                       'Place QR codes near your register, on tables, or at the entrance for maximum visibility.',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: AppColors.neutral600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: AppColors.errorBg,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: AppColors.error.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 64,
//                 color: AppColors.error,
//               ),
//             ),
            
//             const SizedBox(height: 24),
            
//             Text(
//               'Oops! Something went wrong',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.neutral900,
//               ),
//             ),
            
//             const SizedBox(height: 12),
            
//             ErrorDisplay(
//               message: _errorMessage,
//               margin: EdgeInsets.zero,
//               onRetry: _loadBusinessData,
//             ),
            
//             const SizedBox(height: 24),
            
//             AppButton(
//               text: 'Try Again',
//               onPressed: _loadBusinessData,
//               icon: Icons.refresh_rounded,
//               type: AppButtonType.primary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// lib/features/qr_code/screens/optimized_qr_code_screen.dart

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
  
  // Pre-generated PDF cache
  Uint8List? _cachedPdf;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  /// Load business data and pre-generate PDF
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
          
          // Pre-generate PDF in background for instant access
          _preGeneratePdf();
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

  /// Pre-generate PDF in background for instant access
  Future<void> _preGeneratePdf() async {
    if (_business == null || _isGeneratingPdf) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await QrPdfService.generateModernQrPdf(
        businessName: _business!.name,
        reviewLink: _reviewLink,
        template: QrPdfTemplate.vibrant,
        size: QrPdfSize.a4,
      );

      if (mounted) {
        setState(() {
          _cachedPdf = pdfBytes;
          _isGeneratingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
      debugPrint('Background PDF generation failed: $e');
    }
  }

  /// Print QR code PDF with instant feedback
  Future<void> _printQrCodePdf() async {
    if (_business == null) return;
    
    // Show immediate feedback
    setState(() {
      _isPrintLoading = true;
    });
    
    // Show instant feedback to user
    _showLoadingSnackBar('Preparing PDF for printing...');

    try {
      Uint8List pdfBytes;
      
      // Use cached PDF if available, otherwise generate on demand
      if (_cachedPdf != null) {
        pdfBytes = _cachedPdf!;
      } else {
        pdfBytes = await QrPdfService.generateModernQrPdf(
          businessName: _business!.name,
          reviewLink: _reviewLink,
          template: QrPdfTemplate.vibrant,
          size: QrPdfSize.a4,
        );
      }

      await QrPdfService.printOrDownloadPdf(
        pdfBytes: pdfBytes,
        fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        download: false,
      );

      if (mounted) {
        _showSuccessSnackBar('Print dialog opened!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintLoading = false;
        });
      }
    }
  }

  /// Share QR code with instant feedback
  Future<void> _shareQrCode() async {
    if (_business == null) return;
    
    setState(() {
      _isShareLoading = true;
    });
    
    _showLoadingSnackBar('Preparing PDF for sharing...');

    try {
      Uint8List pdfBytes;
      
      if (_cachedPdf != null) {
        pdfBytes = _cachedPdf!;
      } else {
        pdfBytes = await QrPdfService.generateModernQrPdf(
          businessName: _business!.name,
          reviewLink: _reviewLink,
          template: QrPdfTemplate.vibrant,
          size: QrPdfSize.a4,
        );
      }

      final file = XFile.fromData(
        pdfBytes,
        name: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        mimeType: 'application/pdf',
      );

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
        _showErrorSnackBar('Error sharing: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShareLoading = false;
        });
      }
    }
  }

  /// Download QR code with instant feedback
  Future<void> _downloadQrCode() async {
    if (_business == null) return;
    
    setState(() {
      _isDownloadLoading = true;
    });
    
    _showLoadingSnackBar('Preparing download...');

    try {
      Uint8List pdfBytes;
      
      if (_cachedPdf != null) {
        pdfBytes = _cachedPdf!;
      } else {
        pdfBytes = await QrPdfService.generateModernQrPdf(
          businessName: _business!.name,
          reviewLink: _reviewLink,
          template: QrPdfTemplate.vibrant,
          size: QrPdfSize.a4,
        );
      }

      await QrPdfService.printOrDownloadPdf(
        pdfBytes: pdfBytes,
        fileName: '${_business!.name.replaceAll(' ', '_')}_qr_code.pdf',
        download: true,
      );

      if (mounted) {
        _showSuccessSnackBar('Download started!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Download failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadLoading = false;
        });
      }
    }
  }

  /// Copy review link with haptic feedback
  void _copyLinkToClipboard() {
    Clipboard.setData(ClipboardData(text: _reviewLink));
    HapticFeedback.lightImpact(); // Add haptic feedback
    _showSuccessSnackBar('Link copied to clipboard!');
  }

  /// Show instant loading feedback
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
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
        backgroundColor: AppColors.neutral800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show success feedback
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error feedback
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        duration: const Duration(seconds: 4),
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
          // Header section with PDF status
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
          
          // Action buttons with enhanced UX
          _buildEnhancedActionButtons(),
          
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
              color: Colors.white,
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
        
        // PDF status indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (_cachedPdf != null ? AppColors.success : AppColors.warning).withOpacity(0.05),
                (_cachedPdf != null ? AppColors.success : AppColors.warning).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_cachedPdf != null ? AppColors.success : AppColors.warning).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_cachedPdf != null ? AppColors.success : AppColors.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                        ),
                      )
                    : Icon(
                        _cachedPdf != null ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                        color: _cachedPdf != null ? AppColors.success : AppColors.warning,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGeneratingPdf
                          ? 'Preparing PDF...'
                          : _cachedPdf != null
                              ? 'PDF Ready!'
                              : 'PDF Preparing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _cachedPdf != null ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    Text(
                      _isGeneratingPdf
                          ? 'Your PDF is being generated in the background for instant access.'
                          : _cachedPdf != null
                              ? 'Print, download, and share actions will be instant!'
                              : 'PDF generation will happen when you first use print/download.',
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

  Widget _buildEnhancedActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Share Your QR Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const Spacer(),
              if (_cachedPdf != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        size: 12,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Instant',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QrActionButton(
                icon: Icons.print_rounded,
                label: 'Print PDF',
                onPressed: _printQrCodePdf,
                isLoading: _isPrintLoading,
                backgroundColor: AppColors.success,
              ),
              QrActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onPressed: _shareQrCode,
                isLoading: _isShareLoading,
                backgroundColor: AppColors.secondary,
              ),
              QrActionButton(
                icon: Icons.download_rounded,
                label: 'Download',
                onPressed: _downloadQrCode,
                isLoading: _isDownloadLoading,
                backgroundColor: AppColors.orange,
              ),
              QrActionButton(
                icon: Icons.link_rounded,
                label: 'Copy Link',
                onPressed: _copyLinkToClipboard,
                backgroundColor: AppColors.teal,
              ),
            ],
          ),
        ],
      ),
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
              onRetry: _loadBusinessData,
            ),
          ],
        ),
      ),
    );
  }
}