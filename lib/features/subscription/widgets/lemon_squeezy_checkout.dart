// lib/features/subscription/widgets/lemon_squeezy_checkout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_util' as js_util;

class LemonSqueezyCheckout extends StatefulWidget {
  final String planId;
  final Function(bool) onComplete;
  
  const LemonSqueezyCheckout({
    Key? key,
    required this.planId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LemonSqueezyCheckout> createState() => _LemonSqueezyCheckoutState();
}

class _LemonSqueezyCheckoutState extends State<LemonSqueezyCheckout> {
  String _checkoutUrl = '';
  bool _isLoading = true;
  bool _isEmbedded = false;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
    });
  }
  
  void _initializeCheckout() async {
    setState(() => _isLoading = true);
    
    try {
      // Get checkout URL using Provider
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final url = subscriptionProvider.getCheckoutUrl(widget.planId);
      
      setState(() {
        _checkoutUrl = url;
        _isLoading = false;
      });
      
      // Try to load embedded checkout on web platform
      if (kIsWeb) {
        _loadLemonSqueezyScript();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      widget.onComplete(false);
    }
  }
  
  // Load Lemon Squeezy checkout script
  void _loadLemonSqueezyScript() {
    try {
      // Create script element
      final document = js_util.getProperty(js_util.globalThis, 'document');
      final script = js_util.callMethod(document, 'createElement', ['script']);
      
      // Set script attributes
      js_util.setProperty(script, 'src', 'https://app.lemonsqueezy.com/js/checkout.js');
      js_util.setProperty(script, 'async', true);
      
      // Define onload handler
      js_util.setProperty(script, 'onload', js_util.allowInterop(() {
        _initLemonSqueezyCheckout();
      }));
      
      // Append script to document head
      final head = js_util.callMethod(document, 'getElementsByTagName', ['head'])[0];
      js_util.callMethod(head, 'appendChild', [script]);
    } catch (e) {
      print('Failed to load LemonSqueezy script: $e');
      // Fall back to redirect method
      setState(() => _isEmbedded = false);
    }
  }
  
  // Initialize embedded checkout
  void _initLemonSqueezyCheckout() {
    try {
      // Check if lemonsqueezy object is available
      final hasLemonSqueezy = js_util.hasProperty(js_util.globalThis, 'lemonsqueezy');
      
      if (hasLemonSqueezy) {
        setState(() => _isEmbedded = true);
      }
    } catch (e) {
      print('LemonSqueezy initialization error: $e');
      // Fall back to redirect method
      setState(() => _isEmbedded = false);
    }
  }
  
  // Open embedded checkout
  void _openEmbeddedCheckout() {
    try {
      final lemonsqueezy = js_util.getProperty(js_util.globalThis, 'lemonsqueezy');
      
      // Create checkout options
      final checkoutOptions = js_util.newObject();
      js_util.setProperty(checkoutOptions, 'url', _checkoutUrl);
      
      // Set up checkout complete callback
      js_util.setProperty(checkoutOptions, 'onSuccess', js_util.allowInterop(() {
        _handleSuccessfulCheckout();
      }));
      
      // Add close callback
      js_util.setProperty(checkoutOptions, 'onClose', js_util.allowInterop(() {
        print('Checkout closed by user');
      }));
      
      // Launch checkout
      js_util.callMethod(lemonsqueezy, 'Checkout', [checkoutOptions]);
    } catch (e) {
      print('Failed to open embedded checkout: $e');
      // Fall back to redirect
      _openRedirectCheckout();
    }
  }
  
  // Open checkout in same tab
  void _openRedirectCheckout() {
    if (_checkoutUrl.isEmpty) return;
    
    try {
      // Open in same tab for a seamless experience
      js_util.callMethod(js_util.globalThis, 'open', [_checkoutUrl, '_self']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open checkout: $e')),
      );
    }
  }
  
  // Start polling for subscription status updates
  Future<void> _startStatusPolling() async {
    if (_isCheckingStatus) return;
    
    setState(() => _isCheckingStatus = true);
    
    try {
      // Poll for status changes
      for (int i = 0; i < 5; i++) {
        // Wait a bit between checks
        await Future.delayed(const Duration(seconds: 3));
        
        // Check if subscription is active
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        final isActive = await subscriptionProvider.checkSubscriptionStatus();
        
        if (isActive) {
          // Subscription is active, success!
          widget.onComplete(true);
          return;
        }
      }
      
      // After polling limit, let user manually confirm
      setState(() => _isCheckingStatus = false);
      
    } catch (e) {
      print('Error polling for subscription status: $e');
      setState(() => _isCheckingStatus = false);
    }
  }
  
  Future<void> _handleSuccessfulCheckout() async {
    // Give some time for webhooks to process
    await Future.delayed(const Duration(seconds: 2));
    
    // Try checking subscription status now
    if (mounted) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.reloadSubscriptionStatus();
      
      // Start polling for changes if not immediately updated
      if (!subscriptionProvider.isSubscribed) {
        _startStatusPolling();
      } else {
        // Complete the checkout process
        widget.onComplete(true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your checkout...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => widget.onComplete(false),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Complete Your Subscription',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'You\'ll be securely redirected to complete your purchase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            if (_isCheckingStatus) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Verifying your subscription...'),
            ] else ...[
              ElevatedButton(
                onPressed: _isEmbedded ? _openEmbeddedCheckout : _openRedirectCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  _isEmbedded ? 'Complete Purchase' : 'Proceed to Checkout', 
                  style: const TextStyle(fontSize: 16)
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _handleSuccessfulCheckout,
                child: const Text("I've already completed my purchase"),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => widget.onComplete(false),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}