// lib/features/review_requests/widgets/batch_operations_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:revboostapp/models/review_request_model.dart';
import 'package:revboostapp/providers/review_request_provider.dart';

/// A widget that displays batch operations for review requests
class BatchOperationsBar extends StatelessWidget {
  /// The list of selected review request IDs
  final List<String> selectedIds;
  
  /// Callback when selection is cleared
  final VoidCallback onClearSelection;
  
  /// Creates a [BatchOperationsBar]
  const BatchOperationsBar({
    Key? key,
    required this.selectedIds,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (selectedIds.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Selection count
            Text(
              '${selectedIds.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 24),
            
            // Send button
            _buildActionButton(
              context,
              'Send',
              Icons.send,
              onPressed: () => _handleBatchSend(context),
            ),
            
            const SizedBox(width: 16),
            
            // Delete button
            _buildActionButton(
              context,
              'Delete',
              Icons.delete_outline,
              onPressed: () => _handleBatchDelete(context),
            ),
            
            const Spacer(),
            
            // Clear selection button
            IconButton(
              onPressed: onClearSelection,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Clear selection',
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds an action button for the batch operations bar
  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    {required VoidCallback onPressed}
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  /// Handles sending multiple review requests
  Future<void> _handleBatchSend(BuildContext context) async {
    final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
    
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Multiple Review Requests'),
        content: Text(
          'Are you sure you want to send ${selectedIds.length} review requests? '
          'This action will send emails to the selected customers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending review requests...'),
          ],
        ),
      ),
    );
    
    try {
      // Perform batch send
      final result = await provider.bulkSendReviewRequests(
        requestIds: selectedIds,
      );
      
      if (context.mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        // Show result
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Review Requests Sent'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully sent: ${result['successful']}'),
                Text('Failed: ${result['failed']}'),
                if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Errors:'),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        (result['errors'] as List).join('\n'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Clear selection
        onClearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending review requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Handles deleting multiple review requests
  Future<void> _handleBatchDelete(BuildContext context) async {
    final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
    
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review Requests'),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} review requests? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting review requests...'),
          ],
        ),
      ),
    );
    
    try {
      // Delete each request
      for (final id in selectedIds) {
        await provider.deleteReviewRequest(id);
      }
      
      if (context.mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${selectedIds.length} review requests'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selection
        onClearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting review requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}