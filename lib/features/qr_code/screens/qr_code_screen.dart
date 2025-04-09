// lib/features/qr_code/screens/qr_code_screen.dart

import 'dart:convert';
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

  // In QrCodeScreen class, modify the _loadBusinessData method:
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
          // Replace 'revboostapp.web.app' with your actual Firebase hosting domain
          _reviewLink = 'https://revboostapp-b0307.web.app/r/${business.id}';
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

  Future<void> _captureAndShare() async {
    try {
      final RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // For web platform
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
          // For mobile platforms
          Share.shareXFiles(
            [
              XFile.fromData(
                pngBytes,
                name: '${_businessName.replaceAll(' ', '_')}_qr_code.png',
                mimeType: 'image/png',
              ),
            ],
            text: 'Scan this QR code to leave a review for $_businessName',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing QR code: $e')),
        );
      }
    }
  }

  Future<void> _printQrCode() async {
    if (kIsWeb) {
      // We'll open a new window with the QR code ready to print
      try {
        // Generate a simple HTML page with the QR code
        final qrCodeHtml = '''
          <!DOCTYPE html>
          <html>
            <head>
              <title>QR Code - $_businessName</title>
              <style>
                body {
                  font-family: Arial, sans-serif;
                  text-align: center;
                  margin: 0;
                  padding: 20px;
                }
                .container {
                  max-width: 600px;
                  margin: 0 auto;
                  padding: 20px;
                }
                h1 {
                  font-size: 24px;
                  margin-bottom: 10px;
                }
                p {
                  color: #666;
                  margin-bottom: 20px;
                }
                .qr-image {
                  width: 300px;
                  height: 300px;
                  margin: 0 auto;
                  display: block;
                }
                .footer {
                  margin-top: 20px;
                  font-size: 12px;
                  color: #999;
                }
                @media print {
                  button {
                    display: none;
                  }
                }
              </style>
            </head>
            <body>
              <div class="container">
                <h1>$_businessName</h1>
                <p>Scan to leave a review</p>
                <div>
                  <img class="qr-image" src="$_reviewLink" />
                </div>
                <button onclick="window.print();" style="margin-top: 20px; padding: 10px 20px; background-color: #2563EB; color: white; border: none; border-radius: 4px; cursor: pointer;">Print</button>
                <div class="footer">
                  Powered by RevBoost
                </div>
              </div>
              <script>
                window.onload = function() {
                  setTimeout(function() {
                    window.print();
                  }, 500);
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
          onPressed: _captureAndShare,
        ),
        _buildActionButton(
          icon: Icons.download,
          label: 'Save',
          onPressed: _captureAndShare,
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