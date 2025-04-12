// lib/features/review_requests/widgets/csv_import_dialog.dart

// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/providers/review_request_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

/// A dialog for importing review requests from a CSV file
class CsvImportDialog extends StatefulWidget {
  /// The business to import review requests for
  final BusinessModel business;
  
  /// Creates a [CsvImportDialog]
  const CsvImportDialog({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _fileName;
  List<Map<String, dynamic>> _parsedData = [];
  bool _sendRequestsImmediately = false;
  
  // Steps for the import process
  int _currentStep = 0;
  
  // Mapping from CSV columns to contact fields
  Map<String, String> _columnMapping = {};
  List<String> _availableColumns = [];
  
  // Required fields for a valid import
  final List<String> _requiredFields = ['name', 'email'];
  
  @override
  void initState() {
    super.initState();
    _initializeColumnMapping();
  }
  
  /// Initializes the default column mapping
  void _initializeColumnMapping() {
    _columnMapping = {
      'name': '',
      'email': '',
      'phone': '',
    };
  }
  
  /// Picks and parses a CSV file
  Future<void> _pickAndParseFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get file content
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes == null) {
        setState(() {
          _errorMessage = 'Could not read file content';
          _isLoading = false;
        });
        return;
      }
      
      // Parse CSV
      final csvString = String.fromCharCodes(bytes);
      final csvRows = const CsvToListConverter().convert(csvString);
      
      // Ensure there's at least a header row and one data row
      if (csvRows.length < 2) {
        setState(() {
          _errorMessage = 'CSV file should contain a header row and at least one data row';
          _isLoading = false;
        });
        return;
      }
      
      // Extract headers
      final headers = csvRows.first.map((e) => e.toString().trim()).toList();
      _availableColumns = headers;
      
      // Try to automatically map common column names
      _autoMapColumns(headers);
      
      // Parse data rows
      final data = <Map<String, dynamic>>[];
      for (var i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        if (row.length != headers.length) continue; // Skip malformed rows
        
        final rowMap = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = row[j].toString().trim();
          rowMap[header] = value;
        }
        
        data.add(rowMap);
      }
      
      setState(() {
        _fileName = file.name;
        _parsedData = data;
        _isLoading = false;
        _currentStep = 1; // Move to mapping step
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing CSV: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  /// Attempts to automatically map columns based on common names
  void _autoMapColumns(List<String> headers) {
    final namePatterns = ['name', 'full name', 'customer name', 'customer'];
    final emailPatterns = ['email', 'e-mail', 'customer email', 'email address'];
    final phonePatterns = ['phone', 'telephone', 'cell', 'mobile', 'customer phone'];
    
    // Try to map columns based on patterns
    for (final header in headers) {
      final lowerHeader = header.toLowerCase();
      
      // Check for name patterns
      if (namePatterns.any((pattern) => lowerHeader.contains(pattern))) {
        _columnMapping['name'] = header;
      }
      
      // Check for email patterns
      else if (emailPatterns.any((pattern) => lowerHeader.contains(pattern))) {
        _columnMapping['email'] = header;
      }
      
      // Check for phone patterns
      else if (phonePatterns.any((pattern) => lowerHeader.contains(pattern))) {
        _columnMapping['phone'] = header;
      }
    }
  }
  
  /// Validates the column mapping
  bool _validateMapping() {
    // Check required fields
    for (final required in _requiredFields) {
      if (_columnMapping[required]?.isEmpty ?? true) {
        setState(() {
          _errorMessage = 'Please map the required field: $required';
        });
        return false;
      }
    }
    
    return true;
  }
  
  /// Imports the parsed data using the column mapping
  Future<void> _importData() async {
    if (!_validateMapping()) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Transform data according to column mapping
      final contacts = _parsedData.map((row) {
        final contact = <String, dynamic>{};
        
        // Map each field
        _columnMapping.forEach((field, column) {
          if (column.isNotEmpty && row.containsKey(column)) {
            contact[field] = row[column];
          }
        });
        
        return contact;
      }).where((contact) {
        // Filter out invalid contacts (missing required fields)
        return _requiredFields.every(
          (field) => contact[field] != null && contact[field].toString().isNotEmpty
        );
      }).toList();
      
      if (contacts.isEmpty) {
        setState(() {
          _errorMessage = 'No valid contacts found after mapping';
          _isLoading = false;
        });
        return;
      }
      
      // Generate review link
      final host = Uri.base.host;
      final port = Uri.base.port;
      final scheme = Uri.base.scheme;
      
      final baseUrl = port != 80 && port != 443
          ? '$scheme://$host:$port'
          : '$scheme://$host';
          
      final reviewLink = '$baseUrl/r/${widget.business.id}';
      
      // Import contacts
      final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
      final result = await provider.importReviewRequestsFromCsv(
        contacts: contacts,
        reviewLink: reviewLink,
        sendImmediately: _sendRequestsImmediately,
      );
      
      if (mounted) {
        if (result['successful'] > 0) {
          // Success - move to confirmation step
          setState(() {
            _isLoading = false;
            _currentStep = 2; // Move to confirmation step
          });
        } else {
          // Error - no contacts imported
          setState(() {
            _errorMessage = 'Failed to import contacts: ${result['errors'].join(', ')}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error importing contacts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  /// Handles proceeding to the next step
  void _handleNextStep() {
    if (_currentStep == 0) {
      _pickAndParseFile();
    } else if (_currentStep == 1) {
      _importData();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Import Contacts from CSV',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import your customer contacts to send review requests',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stepper
                Row(
                  children: [
                    _buildStepIndicator(0, 'Upload CSV', theme),
                    _buildStepConnector(0, theme),
                    _buildStepIndicator(1, 'Map Columns', theme),
                    _buildStepConnector(1, theme),
                    _buildStepIndicator(2, 'Complete', theme),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 24),
                ],
                
                // Step content
                _buildStepContent(theme),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentStep == 1) ...[
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _currentStep = 0;
                          });
                        },
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 16),
                    ],
                    
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                      },
                      child: Text(_currentStep == 2 ? 'Close' : 'Cancel'),
                    ),
                    const SizedBox(width: 16),
                    
                    if (_currentStep < 2) ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleNextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            Text(_getButtonText()),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the content for the current step
  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildUploadStep(theme);
      case 1:
        return _buildMappingStep(theme);
      case 2:
        return _buildCompleteStep(theme);
      default:
        return const SizedBox();
    }
  }
  
  /// Builds the upload step
  Widget _buildUploadStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CSV file upload area
        InkWell(
          onTap: _isLoading ? null : _pickAndParseFile,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[600]!
                    : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 48,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  _fileName != null
                      ? 'Selected: $_fileName'
                      : 'Click to select a CSV file',
                  style: theme.textTheme.bodyLarge,
                ),
                if (_fileName == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'or drag and drop',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // File format instructions
        Text(
          'CSV File Requirements:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildRequirement(
          'The CSV must have a header row with column names',
          theme,
        ),
        _buildRequirement(
          'The file should include columns for name and email (required)',
          theme,
        ),
        _buildRequirement(
          'Phone number is optional but recommended for SMS',
          theme,
        ),
        
        const SizedBox(height: 16),
        
        // Example CSV format
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Example CSV Format:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customer Name,Email,Phone Number\nJohn Doe,john@example.com,+1234567890\nJane Smith,jane@example.com,+1987654321',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Builds the column mapping step
  Widget _buildMappingStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map CSV Columns',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select which columns from your CSV file correspond to contact information fields.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        
        // File summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: $_fileName',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Found ${_parsedData.length} contacts to import',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Column mapping
        ...['name', 'email', 'phone'].map((field) {
          final isRequired = _requiredFields.contains(field);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${field.substring(0, 1).toUpperCase()}${field.substring(1)}${isRequired ? ' *' : ''}:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: _columnMapping[field]!.isEmpty ? null : _columnMapping[field],
                          hint: Text('Select column for $field'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('-- Not mapped --'),
                            ),
                            ..._availableColumns.map((column) {
                              return DropdownMenuItem<String>(
                                value: column,
                                child: Text(column),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _columnMapping[field] = value ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Send options
        SwitchListTile(
          title: const Text('Send review requests immediately'),
          subtitle: Text(
            _sendRequestsImmediately
                ? 'Emails will be sent as soon as contacts are imported'
                : 'Contacts will be imported without sending emails',
            style: TextStyle(
              fontSize: 12,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          value: _sendRequestsImmediately,
          onChanged: (value) {
            setState(() {
              _sendRequestsImmediately = value;
            });
          },
          activeColor: theme.primaryColor,
        ),
      ],
    );
  }
  
  /// Builds the completion step
  Widget _buildCompleteStep(ThemeData theme) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Import Successful!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your contacts have been successfully imported.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _sendRequestsImmediately
              ? 'Review requests are being sent to the imported contacts.'
              : 'You can now send review requests to these contacts from the review requests screen.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  /// Builds a requirement item with bullet point
  Widget _buildRequirement(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  /// Builds a step indicator
  Widget _buildStepIndicator(int step, String label, ThemeData theme) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          // Circle indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? theme.primaryColor : Colors.grey[300],
              border: Border.all(
                color: isCurrent ? theme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      _currentStep > step ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      (step + 1).toString(),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Step label
          Text(
            label,
            style: TextStyle(
              color: isActive ? theme.primaryColor : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Builds a connector between step indicators
  Widget _buildStepConnector(int step, ThemeData theme) {
    final isActive = _currentStep > step;
    
    return Container(
      width: 40,
      height: 2,
      color: isActive ? theme.primaryColor : Colors.grey[300],
    );
  }
  
  /// Gets the text for the next button based on the current step
  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return _fileName != null ? 'Continue' : 'Select File';
      case 1:
        return _isLoading ? 'Importing...' : 'Import Contacts';
      default:
        return 'Finish';
    }
  }
}