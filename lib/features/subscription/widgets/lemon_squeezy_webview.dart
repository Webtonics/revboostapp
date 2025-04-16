import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
// Add these imports
import 'dart:io' show Platform;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Import for web redirection
import 'dart:js' as js;

class LemonSqueezyWebView extends StatefulWidget {
  final String planId;
  final Function(bool) onComplete;
  
  const LemonSqueezyWebView({
    Key? key,
    required this.planId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LemonSqueezyWebView> createState() => _LemonSqueezyWebViewState();
}

class _LemonSqueezyWebViewState extends State<LemonSqueezyWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _checkoutUrl = '';
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the WebView platform without using context
    _initializePlatform();
    
    // Set up controller
    _setupController();
  }
  
  void _initializePlatform() {
    // Skip platform initialization for web since WebView isn't supported natively
    if (kIsWeb) return;
    
    // Initialize the appropriate WebView platform based on the operating system
    if (WebViewPlatform.instance == null) {
      if (Platform.isAndroid) {
        AndroidWebViewPlatform.registerWith();
      } else if (Platform.isIOS) {
        WebKitWebViewPlatform.registerWith();
      }
    }
  }
  
  void _setupController() {
    _controller = WebViewController();
    
    // Apply settings conditionally for non-web platforms
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      
      // Only set navigation delegate for non-web platforms
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            
            // Check if we're on the thank-you page
            if (url.contains('thank-you') || 
                url.contains('order-confirmation') || 
                url.contains('success')) {
              _handleSuccessfulCheckout();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize the URL after the dependencies are available
    if (!_isInitialized) {
      _initializeCheckoutUrl();
      _isInitialized = true;
    }
  }
  
  void _initializeCheckoutUrl() {
    try {
      // Get checkout URL using Provider
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      _checkoutUrl = subscriptionProvider.getCheckoutUrl(widget.planId);
      
      // Load the URL after we have it (only for non-web platforms)
      if (!kIsWeb) {
        _controller.loadRequest(Uri.parse(_checkoutUrl));
      }
    } catch (e) {
      // Show error using a post-frame callback to avoid the same error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        widget.onComplete(false);
      });
    }
  }
  
  // Method to open external checkout in web platform
  void openExternalCheckout() {
    // Use JavaScript interop to open the URL in a new tab
    // This requires dart:html which should be conditionally imported
    js.context.callMethod('open', [_checkoutUrl, '_blank']);
    if (_checkoutUrl.isNotEmpty) {
      // Use JavaScript interop to open in a new tab
     kIsWeb? js.context.callMethod('open', [_checkoutUrl, '_blank']): null;
    }
  }
  
  Future<void> _handleSuccessfulCheckout() async {
    // Give some time for webhooks to process
    await Future.delayed(const Duration(seconds: 3));
    
    // Try checking subscription status now
    if (mounted) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.reloadSubscriptionStatus();
      
      // Complete the checkout process
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // For web platform, create an iframe or redirect to the checkout URL
    if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Continue to Lemon Squeezy Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Use JavaScript interop to open the URL in a new tab
                    // This requires dart:html which should be conditionally imported
                    openExternalCheckout();
                    widget.onComplete(false);
                  },
                  child: const Text('Continue to Checkout'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => widget.onComplete(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // For non-web platforms, show the WebView
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading secure checkout...'),
                ],
              ),
            ),
          ),
        // Close button
        Positioned(
          top: 40,
          left: 16,
          child: SafeArea(
            child: FloatingActionButton.small(
              onPressed: () => widget.onComplete(false),
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
















