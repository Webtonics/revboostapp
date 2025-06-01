// lib/features/review_requests/screens/review_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/features/review_requests/widgets/batch_operations_bar.dart';
import 'package:revboostapp/features/review_requests/widgets/review_request_list_tile.dart';
import 'package:revboostapp/features/review_requests/widgets/review_request_stats_card.dart';
import 'package:revboostapp/features/review_requests/widgets/csv_import_dialog.dart';
import 'package:revboostapp/features/review_requests/widgets/new_review_request_dialog.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/review_request_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/core/services/firestore_service.dart';

class ReviewRequestsScreen extends StatefulWidget {
  const ReviewRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewRequestsScreen> createState() => _ReviewRequestsScreenState();
}

class _ReviewRequestsScreenState extends State<ReviewRequestsScreen> {
  BusinessModel? _business;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isBatchMode = false;
  List<String> _selectedRequests = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _isLoading = false;
          });
          
          // Initialize the review request provider now that we have the business
          // Provider.of<ReviewRequestProvider>(context, listen: false).refreshStatistics();
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


  // Update this method in your ReviewRequestsScreen class
void _showNewRequestDialog() {
  if (_business == null) return;
  
  // Get the email service from the context
  final emailService = Provider.of<EmailService>(context, listen: false);
  
  // Create a fresh provider for the dialog to avoid state issues
  final reviewRequestProvider = ReviewRequestProvider(
    emailService: emailService,
    businessId: _business!.id,
    businessName: _business!.name,
  );
  
  // Show dialog with its own provider
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by clicking outside
    builder: (context) => ChangeNotifierProvider<ReviewRequestProvider>.value(
      value: reviewRequestProvider,
      child: NewReviewRequestDialog(business: _business!),
    ),
  ).then((_) {
    // Refresh data after the dialog is closed
    Provider.of<ReviewRequestProvider>(context, listen: false).refreshStatistics();
    
    // Dispose the provider when the dialog is closed to prevent memory leaks
    reviewRequestProvider.dispose();
  });
}
  void _showCsvImportDialog() {
  if (_business == null) return;
  
  // Get the email service from the context
  final emailService = Provider.of<EmailService>(context, listen: false);
  
  // Show dialog with its own provider
  showDialog(
    context: context,
    builder: (context) => ChangeNotifierProvider<ReviewRequestProvider>(
      create: (_) => ReviewRequestProvider(
        emailService: emailService,
        businessId: _business!.id,
        businessName: _business!.name,
      ),
      child: CsvImportDialog(business: _business!),
    ),
  );
}
  
  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedRequests.clear();
      }
    });
  }
  
  void _toggleRequestSelection(String requestId) {
    setState(() {
      if (_selectedRequests.contains(requestId)) {
        _selectedRequests.remove(requestId);
      } else {
        _selectedRequests.add(requestId);
      }
    });
  }
  
  void _selectAllRequests(List<ReviewRequestModel> requests) {
    setState(() {
      if (_selectedRequests.length == requests.length) {
        // If all are selected, clear the selection
        _selectedRequests.clear();
      } else {
        // Otherwise, select all
        _selectedRequests = requests.map((req) => req.id).toList();
      }
    });
  }
  
  Future<void> _deleteSelectedRequests() async {
    if (_selectedRequests.isEmpty) return;
    
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Requests'),
        content: Text('Are you sure you want to delete ${_selectedRequests.length} selected requests? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmDelete) {
      final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
      await provider.batchDeleteRequests(_selectedRequests);
      
      setState(() {
        _selectedRequests.clear();
        _isBatchMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected requests deleted successfully'),
          ),
        );
      }
    }
  }
  
  Future<void> _resendSelectedRequests() async {
    if (_selectedRequests.isEmpty || _business == null) return;
    
    final confirmResend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Selected Requests'),
        content: Text('Are you sure you want to resend ${_selectedRequests.length} selected requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resend'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmResend) {
      final provider = Provider.of<ReviewRequestProvider>(context, listen: false);
      final result = await provider.batchResendRequests(_selectedRequests, _business!);
      
      setState(() {
        _selectedRequests.clear();
        _isBatchMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.success} requests sent, ${result.failure} failed'),
            backgroundColor: result.failure > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
  
  List<ReviewRequestModel> _filterRequests(List<ReviewRequestModel> requests) {
    if (_searchQuery.isEmpty) return requests;
    
    return requests.where((request) {
      return request.customerName.toLowerCase().contains(_searchQuery) ||
             request.customerEmail.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
Widget build(BuildContext context) {
  final emailService = Provider.of<EmailService>(context, listen: false);
  
  return _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _business == null
              ? _buildNoBusiness()
              : ChangeNotifierProvider<ReviewRequestProvider>(
                  create: (_) => ReviewRequestProvider(
                    emailService: emailService,
                    businessId: _business!.id,
                    businessName: _business!.name,
                  ),
                  child: Builder(
                    builder: (context) => _buildReviewRequestsView(),
                  ),
                );
}
  
  Widget _buildErrorView() {
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

Widget _buildReviewRequestsView() {
  return Consumer<ReviewRequestProvider>(
      builder: (context, provider, child) {
        final reviews = provider.reviewRequests;
        final stats = provider.statistics;
        
        return RefreshIndicator(
          onRefresh: () => provider.refreshStatistics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header and action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Requests',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Send and manage review requests to your customers',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showNewRequestDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('New Request'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Statistics cards
                ReviewRequestStatsCard(statistics: stats),
                
                const SizedBox(height: 24),
                
                
                // Review requests list
                Expanded(
                  child: reviews.isEmpty
                      ? _buildEmptyState(true) // Pass true to indicate it's completely empty
                      : ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final request = reviews[index];
                            return ReviewRequestListTile(
                              request: request,
                              onDelete: () => provider.deleteReviewRequest(request.id),
                              onResend: () {
                                provider.createAndSendReviewRequest(
                                  customerName: request.customerName,
                                  customerEmail: request.customerEmail,
                                  customerPhone: request.customerPhone,
                                  business: _business!,
                                );
                              },
                              isSelectable: _isBatchMode,
                              isSelected: _selectedRequests.contains(request.id),
                              onToggleSelection: () => _toggleRequestSelection(request.id),
                            );
                          },
                        ),
                ),
                
                // Batch operations bar for selected requests
                if (_isBatchMode)
                  BatchOperationsBar(
                    selectedIds: _selectedRequests,
                    onClearSelection: () {
                      setState(() {
                        _selectedRequests.clear();
                        _isBatchMode = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  
}



// Make sure your _buildEmptyState method looks like this:
Widget _buildEmptyState(bool isCompletelyEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCompletelyEmpty ? Icons.email_outlined : Icons.search_off,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          isCompletelyEmpty ? 'No review requests yet' : 'No matching results',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isCompletelyEmpty 
              ? 'Send your first review request to start collecting reviews'
              : 'Try adjusting your search query',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (isCompletelyEmpty) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewRequestDialog,
            icon: const Icon(Icons.add),
            label: const Text('Send First Request'),
          ),
        ],
      ],
    ),
  );
}

Widget _buildNoBusiness() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Business Found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You need to set up your business before you can manage review requests',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the business setup page
              context.go(AppRoutes.settings);
            },
            icon: const Icon(Icons.add_business),
            label: const Text('Set Up Business'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
  
 
}




















