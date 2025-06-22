// Add this widget temporarily to your review request screen for debugging

import 'package:flutter/material.dart';
import 'package:revboostapp/core/services/email_service.dart';

class DebugConnectivityWidget extends StatefulWidget {
  const DebugConnectivityWidget({Key? key}) : super(key: key);

  @override
  State<DebugConnectivityWidget> createState() => _DebugConnectivityWidgetState();
}

class _DebugConnectivityWidgetState extends State<DebugConnectivityWidget> {
  bool _isTesting = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug: Email Server Connection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              child: _isTesting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test Server Connection'),
            ),
            
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.contains('✅') 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _result!.contains('✅')
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _result = null;
    });

    try {
      final emailService = EmailService(
        apiKey: '', // Not needed for connection test
        fromEmail: 'reviewme@revboostapp.com',
        fromName: 'RevBoost',
      );

      final isConnected = await emailService.testServerConnection();
      
      setState(() {
        _result = isConnected 
            ? '✅ Server is reachable and responding correctly'
            : '❌ Server is not reachable or not responding correctly.\n\nCheck the Flutter console for detailed error messages.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Connection test failed: $e\n\nCheck the Flutter console for more details.';
        _isTesting = false;
      });
    }
  }
}