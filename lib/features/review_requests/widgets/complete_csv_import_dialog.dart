// lib/features/review_requests/widgets/complete_csv_import_dialog.dart
// Complete CSV import with premium check

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../../providers/complete_review_request_provider.dart';

class CompleteCsvImportDialog extends StatefulWidget {
  final BusinessModel business;
  
  const CompleteCsvImportDialog({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<CompleteCsvImportDialog> createState() => _CompleteCsvImportDialogState();
}

class _CompleteCsvImportDialogState extends State<CompleteCsvImportDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _fileName;
  List<Map<String, String>> _parsedContacts = [];
  bool _sendRequestsImmediately = false;
  int _currentStep = 0; // 0: upload, 1: preview, 2: complete
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, CompleteReviewRequestProvider>(
      builder: (context, subscriptionProvider, reviewProvider, child) {
        // Check if user has premium access
        final hasPremiumAccess = subscriptionProvider.hasActiveAccess && 
                               !subscriptionProvider.isFreeTrial;
        
        if (!hasPremiumAccess) {
          return _buildUpgradeDialog(context);
        }
        
        return _buildImportDialog(context, reviewProvider);
      },
    );
  }
  
  Widget _buildUpgradeDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upgrade,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Feature',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CSV import is only available for premium users. Upgrade to import multiple contacts at once!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to subscription page
                      // You can add navigation logic here
                    },
                    child: const Text('Upgrade'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImportDialog(BuildContext context, CompleteReviewRequestProvider provider) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Import Contacts from CSV',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Import your customer contacts to send review requests in bulk',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Step content
              Flexible(
                child: _buildStepContent(context, provider),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              _buildButtons(context, provider),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepContent(BuildContext context, CompleteReviewRequestProvider provider) {
    switch (_currentStep) {
      case 0:
        return _buildUploadStep(context);
      case 1:
        return _buildPreviewStep(context);
      case 2:
        return _buildCompleteStep(context);
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildUploadStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File upload area
        InkWell(
          onTap: _isLoading ? null : _pickCsvFile,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  _fileName != null
                      ? 'Selected: $_fileName'
                      : 'Click to select a CSV file',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_fileName == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Drag and drop or click to browse',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Requirements
        Text(
          'CSV File Requirements:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildRequirement('Header row with column names'),
        _buildRequirement('Required columns: Name, Email'),
        _buildRequirement('Optional columns: Phone'),
        _buildRequirement('Maximum 1000 contacts per file'),
        
        const SizedBox(height: 16),
        
        // Example format
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Example CSV Format:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Name,Email,Phone\nJohn Doe,john@example.com,+1234567890\nJane Smith,jane@example.com,+1987654321',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Contacts (${_parsedContacts.length} found)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Send immediately option
        SwitchListTile(
          title: const Text('Send review requests immediately'),
          subtitle: const Text('If disabled, contacts will be imported as drafts'),
          value: _sendRequestsImmediately,
          onChanged: (value) {
            setState(() {
              _sendRequestsImmediately = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Contacts preview
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _parsedContacts.take(10).length, // Show first 10
              itemBuilder: (context, index) {
                final contact = _parsedContacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact['name']![0].toUpperCase()),
                  ),
                  title: Text(contact['name']!),
                  subtitle: Text(contact['email']!),
                  trailing: contact['phone']!.isNotEmpty 
                      ? Text(contact['phone']!)
                      : null,
                );
              },
            ),
          ),
        ),
        
        if (_parsedContacts.length > 10) ...[
          const SizedBox(height: 8),
          Text(
            'Showing first 10 contacts. ${_parsedContacts.length - 10} more will be imported.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCompleteStep(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Import Successful!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Successfully imported ${_parsedContacts.length} contacts.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _sendRequestsImmediately
              ? 'Review requests are being sent to your customers.'
              : 'Contacts have been saved as drafts. You can send them from the review requests page.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Widget _buildButtons(BuildContext context, CompleteReviewRequestProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 0 && _currentStep < 2) ...[
          TextButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _currentStep--;
              });
            },
            child: const Text('Back'),
          ),
          const SizedBox(width: 16),
        ],
        
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(_currentStep == 2 ? 'Close' : 'Cancel'),
        ),
        const SizedBox(width: 16),
        
        if (_currentStep < 2) ...[
          ElevatedButton(
            onPressed: _isLoading ? null : () => _handleNextStep(provider),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_getButtonText()),
          ),
        ],
      ],
    );
  }
  
  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return _fileName != null ? 'Continue' : 'Select File';
      case 1:
        return 'Import Contacts';
      default:
        return 'Finish';
    }
  }
  
  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes == null) {
        setState(() {
          _errorMessage = 'Could not read file content';
        });
        return;
      }
      
      await _parseCsvFile(bytes, file.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }
  
  Future<void> _parseCsvFile(Uint8List bytes, String fileName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final csvString = String.fromCharCodes(bytes);
      final csvRows = const CsvToListConverter().convert(csvString);
      
      if (csvRows.length < 2) {
        setState(() {
          _errorMessage = 'CSV file must have a header row and at least one data row';
          _isLoading = false;
        });
        return;
      }
      
      // Parse headers
      final headers = csvRows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      
      // Find required columns
      final nameIndex = _findColumnIndex(headers, ['name', 'customer name', 'full name']);
      final emailIndex = _findColumnIndex(headers, ['email', 'e-mail', 'email address']);
      final phoneIndex = _findColumnIndex(headers, ['phone', 'telephone', 'mobile', 'cell']);
      
      if (nameIndex == -1) {
        setState(() {
          _errorMessage = 'Could not find Name column. Please ensure your CSV has a column named "Name"';
          _isLoading = false;
        });
        return;
      }
      
      if (emailIndex == -1) {
        setState(() {
          _errorMessage = 'Could not find Email column. Please ensure your CSV has a column named "Email"';
          _isLoading = false;
        });
        return;
      }
      
      // Parse data rows
      final contacts = <Map<String, String>>[];
      for (int i = 1; i < csvRows.length && contacts.length < 1000; i++) {
        final row = csvRows[i];
        if (row.length <= nameIndex || row.length <= emailIndex) continue;
        
        final name = row[nameIndex].toString().trim();
        final email = row[emailIndex].toString().trim();
        final phone = phoneIndex >= 0 && row.length > phoneIndex 
            ? row[phoneIndex].toString().trim() 
            : '';
        
        if (name.isNotEmpty && email.isNotEmpty) {
          contacts.add({
            'name': name,
            'email': email,
            'phone': phone,
          });
        }
      }
      
      if (contacts.isEmpty) {
        setState(() {
          _errorMessage = 'No valid contacts found in the CSV file';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _fileName = fileName;
        _parsedContacts = contacts;
        _currentStep = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing CSV file: $e';
        _isLoading = false;
      });
    }
  }
  
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      for (final name in possibleNames) {
        if (headers[i].contains(name)) {
          return i;
        }
      }
    }
    return -1;
  }
  
  Future<void> _handleNextStep(CompleteReviewRequestProvider provider) async {
    if (_currentStep == 0) {
      await _pickCsvFile();
    } else if (_currentStep == 1) {
      await _importContacts(provider);
    }
  }
  
  Future<void> _importContacts(CompleteReviewRequestProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await provider.importContactsFromCsv(
        contacts: _parsedContacts,
        business: widget.business,
        sendImmediately: _sendRequestsImmediately,
      );
      
      if (result['successful'] > 0) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Import failed: ${result['errors'].join(', ')}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}