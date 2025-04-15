// lib/features/qr_code/screens/qr_code_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:revboostapp/core/services/firestore_service.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/layout/app_layout.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/js.dart' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({Key? key}) : super(key: key);

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String _businessName = '';
  String _reviewLink = '';
  bool _isLoading = true;
  BusinessModel? _business;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId != null) {
        // Get user's business
        final firestoreService = FirestoreService();
        final businesses = await firestoreService.getBusinessesByOwnerId(userId);

        if (businesses.isNotEmpty) {
          final business = businesses.first;
          
          setState(() {
            _business = business;
            _businessName = business.name;
            
            // Generate the review link for the business using Firebase Hosting URL
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

  // Helper function to capture QR code as image
  Future<Uint8List?> _captureQrCode() async {
    try {
      final RenderRepaintBoundary boundary = 
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing QR code: $e')),
        );
      }
      return null;
    }
  }

  // Share QR code with other apps
  Future<void> _shareQrCode() async {
    final Uint8List? pngBytes = await _captureQrCode();
    
    if (pngBytes == null) return;
    
    if (kIsWeb) {
      // For web, we'll use a different approach since Share isn't well supported
      // Create a blob URL and use web APIs for sharing
      try {
        final content = base64Encode(pngBytes);
        
        // Check if Web Share API is available
        bool canShare = false;
        try {
          canShare = js.context.hasProperty('navigator') && 
                     js.context['navigator'].hasProperty('share');
        } catch (e) {
          canShare = false;
        }
        
        if (canShare) {
          // Use Web Share API if available
          final blob = '''
            (function() {
              const base64 = "$content";
              const binary = atob(base64);
              const len = binary.length;
              const bytes = new Uint8Array(len);
              for (let i = 0; i < len; i++) {
                bytes[i] = binary.charCodeAt(i);
              }
              const blob = new Blob([bytes.buffer], {type: 'image/png'});
              const file = new File([blob], '${_businessName.replaceAll(' ', '_')}_qr_code.png', {type: 'image/png'});
              
              navigator.share({
                title: 'Review QR Code for $_businessName',
                text: 'Scan this QR code to leave a review for $_businessName',
                files: [file]
              }).catch(e => console.error('Error sharing:', e));
            })();
          ''';
          
          js.context.callMethod('eval', [blob]);
        } else {
          // Fallback to a custom share dialog
          _showWebShareDialog(pngBytes);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing QR code: $e')),
          );
        }
      }
    } else {
      // For mobile platforms, use share_plus
      try {
        final tempFile = XFile.fromData(
          pngBytes,
          name: '${_businessName.replaceAll(' ', '_')}_qr_code.png',
          mimeType: 'image/png',
        );
        
        // Calculate position for share sheet
        final box = context.findRenderObject() as RenderBox?;
        final sharePosition = box == null
            ? null
            : Rect.fromPoints(
                box.localToGlobal(Offset.zero),
                box.localToGlobal(box.size.bottomRight(Offset.zero)),
              );
              
        await Share.shareXFiles(
          [tempFile],
          text: 'Scan this QR code to leave a review for $_businessName',
          subject: 'Review QR Code for $_businessName',
          sharePositionOrigin: sharePosition,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing QR code: $e')),
          );
        }
      }
    }
  }

  // Custom share dialog for web when Web Share API is not available
  void _showWebShareDialog(Uint8List pngBytes) {
    final String imgSrc = 'data:image/png;base64,${base64Encode(pngBytes)}';
    
    // Create a dialog with options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share QR Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(
                  pngBytes,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 16),
                const Text('Choose how to share:'),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('Email'),
              onPressed: () {
                final mailtoLink = 'mailto:?subject=Review QR Code for $_businessName&body=Scan this QR code to leave a review for $_businessName';
                js.context.callMethod('open', [mailtoLink]);
                Navigator.of(context).pop();
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              onPressed: () {
                _downloadQrCode(pngBytes);
                Navigator.of(context).pop();
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _reviewLink));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Download QR code (for Web or Save button)
  Future<void> _downloadQrCode(Uint8List? bytes) async {
    // Allow function to be called with bytes or capture them if null
    final Uint8List? pngBytes = bytes ?? await _captureQrCode();
    
    if (pngBytes == null) return;
    
    if (kIsWeb) {
      final content = base64Encode(pngBytes);
      
      // Create a download link for the QR code
      final href = 'data:image/png;base64,$content';
      final filename = '${_businessName.replaceAll(' ', '_')}_qr_code.png';
      
      // Use a JavaScript approach that works cross-browser
      final jsString = 
          "var a = document.createElement('a'); "
          "a.href = '$href'; "
          "a.download = '$filename'; "
          "document.body.appendChild(a); "
          "a.click(); "
          "document.body.removeChild(a);";
          
      js.context.callMethod('eval', [jsString]);
    } else {
      // For mobile platforms - handle appropriately
      // This may require additional implementation using path_provider
      // and file saving logic for mobile platforms
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download not supported on this platform')),
      );
    }
  }

  // Improved print function
  // Updated _printQrCode function with enhanced design
Future<void> _printQrCode() async {
  if (kIsWeb) {
    try {
      // First capture the QR code
      final Uint8List? pngBytes = await _captureQrCode();
      if (pngBytes == null) return;
      
      // Convert to base64 for embedding in HTML
      final qrImageSrc = 'data:image/png;base64,${base64Encode(pngBytes)}';
      
      // Generate an enhanced HTML page with the QR code
      final qrCodeHtml = '''
        <!DOCTYPE html>
        <html>
          <head>
            <title>RevBoost QR Code - $_businessName</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');
              
              body {
                font-family: 'Poppins', sans-serif;
                text-align: center;
                margin: 0;
                padding: 0;
                background-color: #f8fafc;
                color: #334155;
              }
              
              .page {
                width: 100%;
                max-width: 800px;
                margin: 0 auto;
                padding: 40px 20px;
                box-sizing: border-box;
              }
              
              .card {
                background: white;
                border-radius: 16px;
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
                padding: 40px;
                margin-bottom: 20px;
                position: relative;
                overflow: hidden;
              }
              
              .card::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 8px;
                background: linear-gradient(90deg, #2563EB, #1E40AF);
              }
              
              .accent-bg {
                position: absolute;
                top: 8px;
                right: 0;
                width: 150px;
                height: 150px;
                background: linear-gradient(135deg, rgba(219, 234, 254, 0.4) 0%, rgba(37, 99, 235, 0.1) 100%);
                border-radius: 0 0 0 100%;
                z-index: 0;
              }
              
              .content {
                position: relative;
                z-index: 1;
              }
              
              .header {
                margin-bottom: 30px;
              }
              
              h1 {
                font-size: 28px;
                font-weight: 700;
                color: #1E3A8A;
                margin-bottom: 8px;
              }
              
              .tagline {
                font-size: 16px;
                color: #64748B;
                margin-bottom: 20px;
              }
              
              .highlight {
                color: #2563EB;
                font-weight: 600;
              }
              
              .qr-container {
                background: white;
                padding: 24px;
                border-radius: 12px;
                display: inline-block;
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                position: relative;
              }
              
              .qr-container::after {
                content: '';
                position: absolute;
                bottom: 12px;
                right: 12px;
                width: 48px;
                height: 48px;
                background-image: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgiIGhlaWdodD0iNDgiIHZpZXdCb3g9IjAgMCA0OCA0OCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjQgMEMzNy4yNTQ4IDAgNDggMTAuNzQ1MiA0OCAyNEM0OCAzNy4yNTQ4IDM3LjI1NDggNDggMjQgNDhDMTMuNzY1NyA0OCA1LjAwNTcxIDQyLjM5NDMgMS4zMzcxNCAzNC4xMTQzTDI0IDI0TDM2LjA2ODYgMTEuOTMxNEMzMy4xMiA3LjYxMTQzIDI4Ljg2ODYgNC41MjU3MSAyNCAzLjcwMjg2QzE1LjU2NTcgMi4yNjI4NiA3LjA2Mjg2IDYuMDM0MjkgMi40Njg1NyAxMy43MTQzQzAuODkxNDI5IDE2Ljg2ODYgMCAyMC4zMzE0IDAgMjRDMCAyOC42NjI5IDEuMzQ0IDMzLjAxNzEgMy43MDI4NiAzNi42ODU3QzUuMjQ4NDQgMzkuMDYgNy4yMzk0MyA0MS4wODggOS41NjU3MSA0Mi42NTE1QzEzLjcwNTcgNDUuNzAxIDE4LjY5NiA0Ny4zNzcyIDI0IDQ3LjM3NzJDMzMuOTE1NCA0Ny4zNzcyIDQyLjEzMzcgNDAuNDY1MiA0NC4yOTIgMzEuMDY2M0wyNC42NTE0IDI0LjUxNzdMNC4yMTcxNCAzMi40MzQzQzcuNjExNDMgNDAuMzIgMTUuMjU3MSA0NS42Njg2IDI0IDQ1LjY2ODZDMzUuNjU3MSA0NS42Njg2IDQ1LjI1NzEgMzYuMDY4NiA0NS4yNTcxIDI0QzQ1LjI1NzEgMTEuOTMxNCAzNS42NTcxIDIuMzMxNDMgMjQgMi4zMzE0M0MyMC40MzEyIDIuMzMxNDMgMTcuMDM2NSAzLjA5OTQzIDEzLjk4ODUgNC41MjU3MUw5LjA1MTQzIDkuNDYyODZDNS43NiAxMy40NCAzLjg0IDE4LjUxNDMgMy44NCAyNEMzLjg0IDM0Ljk3MTQgMTMuMDI4NiA0NC4xNiAyNCA0NC4xNkMzNC45NzE0IDQ0LjE2IDQ0LjE2IDM0Ljk3MTQgNDQuMTYgMjRDNDQuMTYgMTMuMDI4NiAzNC45NzE0IDMuODQgMjQgMy44NEMxNy45MiAzLjg0IDEyLjQ1NzEgNi40ODU3MSA4Ljg4IDEwLjg4Nkw2LjI0IDEzLjUyNTdDNS44NzQyOSAxMy44OTE0IDUuNTJxtwgMTQuMjhDMi40NjUxNCAxNy4yMTE0IDAuOTYgMjAuNzc3MSAwLjk2IDI0LjY4NTdDMC45NiAzMi45MTQzIDcuNjggMzkuNjM0MyAxNS45MDg2IDM5LjYzNDNDMjQuMTM3MSAzOS42MzQzIDMwLjg1NzEgMzIuOTE0MyAzMC44NTcxIDI0LjY4NTdDMzAuODU3MSAxNi40NTcxIDI0LjEzNzEgOS43MzcxNCAxNS45MDg2IDkuNzM3MTRDMTMuOTI1NyA5LjczNzE0IDEyLjAzNDMgMTAuMTgyOSAxMC4zMTQzIDExLjAwNTdMOC4xOTQyOSAxMy4xMjU3QzcuODk3MTQgMTMuNDIyOSA3LjYxMTQzIDEzLjcyIDcuMzM3MTQgMTQuMDI4NkM1Ljc1NDI5IDE2LjAzNDMgNC44IDIxLjgzNDMgNC44IDI0LjY4NTdDNC44IDMwLjg1NzEgOS45Mi4../></style>
          </head>
          <body>
            <div class="page">
              <div class="card">
                <div class="accent-bg"></div>
                <div class="content">
                  <div class="header">
                    <h1>$_businessName</h1>
                    <div class="tagline">We value your feedback! Scan to share your experience</div>
                  </div>
                  
                  <div class="qr-container">
                    <img class="qr-image" src="$qrImageSrc" alt="QR Code for $_businessName" />
                  </div>
                  
                  <p>Scan with your <span class="highlight">smartphone camera</span> to leave a review</p>
                  
                  <div class="url">$_reviewLink</div>
                  
                  <div class="instructions">
                    <h2>Why Your Review Matters:</h2>
                    <ol>
                      <li>Help others discover our quality service</li>
                      <li>Support our local business growth</li>
                      <li>Let us know how we can serve you better</li>
                    </ol>
                  </div>
                  
                  <div class="footer">
                    <svg class="revboost-logo" width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M16 0C24.8366 0 32 7.16344 32 16C32 24.8366 24.8366 32 16 32C9.17714 32 3.33714 28.2629 0.891429 22.7429L16 16L24.0457 7.95429C22.08 5.07429 19.2457 3.01714 16 2.46857C10.3771 1.50857 4.70857 4.02286 1.64571 9.14286C0.594286 11.2457 0 13.5543 0 16C0 19.1086 0.896 22.0114 2.46857 24.4571C3.49896 26.04 4.82629 27.392 6.37714 28.4343C9.13714 30.4674 12.464 31.5848 16 31.5848C22.6103 31.5848 28.0891 26.9768 29.528 20.7109L16.4343 16.3451L2.81143 21.6229C5.07429 26.88 10.1714 30.4457 16 30.4457C23.7714 30.4457 30.1714 24.0457 30.1714 16C30.1714 7.95429 23.7714 1.55429 16 1.55429C13.6208 1.55429 11.3577 2.06629 9.32571 3.01714L6.03429 6.30857C3.84 8.96 2.56 12.3429 2.56 16C2.56 23.3143 8.68571 29.44 16 29.44C23.3143 29.44 29.44 23.3143 29.44 16C29.44 8.68571 23.3143 2.56 16 2.56C13.84 2.56 11.7486 3.03771 9.87657 3.88343L7.25943 6.50057C6.55314 7.20686 5.96914 8.02286 5.52229 8.91429C3.97257 11.9863 3.84 15.7394 5.13829 18.9257C5.80114 20.5211 6.85943 21.9291 8.21714 23.0114C10.1257 24.5257 12.48 25.36 16 25.36C20.8457 25.36 24.9371 22.2171 26.3771 17.8514L16.8114 14.3657L3.60686 20.4343C4.14629 21.7703 4.91886 22.9989 5.89943 24.0686C8.55086 26.92 12.0869 28.64 16 28.64C22.5943 28.64 28.0457 23.1886 28.0457 16.5943C28.0457 9.99886 22.5943 4.54743 16 4.54743C14.9966 4.54743 14.0114 4.66743 13.0686 4.89486L9.54514 8.41829C8.70857 9.25486 8.01371 10.2217 7.48114 11.2663C6.33029 13.5714 5.98629 16.1989 6.50286 18.7657C7.15886 21.9074 9.07429 24.6629 11.7257 26.4343C12.9554 27.2663 14.3463 27.8537 15.8286 28.1371C16.5543 28.2743 17.3029 28.3429 18.0686 28.3429C23.5143 28.3429 28.0686 24.0914 28.4343 18.6743L18.4114 15.7394L6.65486 21.4171C7.40114 22.9486 8.49714 24.2629 9.82857 25.2686C12.0229 26.9486 14.7657 27.92 16 27.92C15.9314 27.92 15.8629 27.92 15.8457 27.92C11.6114 27.92 7.99314 25.7029 6.08114 22.24L17.0629 16.1829L17.9657 15.7394" fill="#2563EB"/>
                    </svg>
                    <div class="logo-text">
                      <div class="powered-by">Powered by</div>
                      <div class="brand-name">RevBoost</div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div class="print-button screen-only">
                <button onclick="window.print();" class="print-btn">Print QR Code</button>
              </div>
              
              <div class="print-info print-only">
                Printed on: ${DateTime.now().toLocal().toString().split('.')[0]}
              </div>
            </div>
            
            <script>
              window.onload = function() {
                setTimeout(function() {
                  // Auto-trigger print dialog after a short delay
                  window.print();
                }, 800);
              }
            </script>
          </body>
        </html>
      ''';
  
      // Open a new window with this HTML
      js.context.callMethod('eval', [
        "var printWindow = window.open('', '_blank');"
        "printWindow.document.write(`$qrCodeHtml`);"
        "printWindow.document.close();"
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing print view: $e')),
        );
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print functionality is only available on web')),
      );
    }
  }
}

  void _copyLinkToClipboard() {
    Clipboard.setData(ClipboardData(text: _reviewLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'QR Code',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Try Again',
                onPressed: _loadBusinessData,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QR Code for ${_business?.name ?? "Your Business"}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Display this QR code in your business to collect reviews easily',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          
          // QR code display
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _qrKey,
                        child: QrImageView(
                          data: _reviewLink,
                          version: QrVersions.auto,
                          size: 280,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF2563EB),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2563EB),
                          ),
                          embeddedImage: const AssetImage('assets/images/logo_small.png'),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(40, 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan to leave a review',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _businessName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Actions
                _buildActionsSection(),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Review Link
          _buildReviewLinkSection(),
          
          const SizedBox(height: 32),
          
          // Additional Information
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use your QR code',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowToItem(
                    context,
                    '1',
                    'Print the QR code',
                    'Display it prominently in your business where customers can easily scan it',
                  ),
                  const SizedBox(height: 12),
                  _buildHowToItem(
                    context,
                    '2',
                    'Customers scan the code',
                    'When customers scan the code, they can leave a review on their preferred platform',
                  ),
                  const SizedBox(height: 12),
                  _buildHowToItem(
                    context,
                    '3',
                    'Collect more reviews',
                    'The system automatically filters negative reviews for private feedback',
                  ),
                  const SizedBox(height: 12),
                  _buildHowToItem(
                    context,
                    '4',
                    'Boost your reputation',
                    'Increase your online presence with more positive public reviews',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildActionButton(
          icon: Icons.print,
          label: 'Print',
          onPressed: _printQrCode,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: _shareQrCode,
        ),
        _buildActionButton(
          icon: Icons.download,
          label: 'Save',
          onPressed: () => _downloadQrCode(null),
        ),
        _buildActionButton(
          icon: Icons.copy,
          label: 'Copy Link',
          onPressed: _copyLinkToClipboard,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildReviewLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Link',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share this link with your customers to collect reviews',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _reviewLink,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Material(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                child: InkWell(
                  onTap: _copyLinkToClipboard,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Row(
                      children: [
                        Icon(Icons.copy, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Copy',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowToItem(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}