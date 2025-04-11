// lib/features/subscription/widgets/lemon_squeezy_webview.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';

class LemonSqueezyWebView extends StatefulWidget {
  final String planId;
  final Function(bool success) onComplete;
  
  const LemonSqueezyWebView({
    Key? key,
    required this.planId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LemonSqueezyWebView> createState() => _LemonSqueezyWebViewState();
}

class _LemonSqueezyWebViewState extends State<LemonSqueezyWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // Get the user's email for checkout
    final userEmail = authProvider.user?.email ?? '';
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please update your email address first')),
      );
      widget.onComplete(false);
      return;
    }
    
    try {
      // Get checkout URL
      final checkoutUrl = subscriptionProvider.getCheckoutUrl(widget.planId);
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
              
              // Check if we're on a success page
              if (url.contains('success=true') || url.contains('thank-you')) {
                // Payment likely succeeded
                // Wait briefly to allow webhook to process
                Future.delayed(const Duration(seconds: 2), () {
                  widget.onComplete(true);
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation within the checkout flow
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(checkoutUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting checkout: $e')),
      );
      widget.onComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: FloatingActionButton.small(
              onPressed: () {
                widget.onComplete(false);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}