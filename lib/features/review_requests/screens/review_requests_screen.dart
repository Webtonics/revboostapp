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
import 'package:revboostapp/widgets/layout/app_layout.dart';
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

  void _showNewRequestDialog() {
    if (_business == null) return;
    
    showDialog(
      context: context,
      builder: (context) => NewReviewRequestDialog(business: _business!),
    );
  }
  
  void _showCsvImportDialog() {
    if (_business == null) return;
    
    showDialog(
      context: context,
      builder: (context) => CsvImportDialog(business: _business!),
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
  
  return AppLayout(
    title: 'Review Requests',
    child: _isLoading
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
  
  // Widget _buildReviewRequestsView() {
  //   return Consumer<ReviewRequestProvider>(
  //     builder: (context, provider, child) {
  //       final allRequests = provider.reviewRequests;
  //       final filteredRequests = _filterRequests(allRequests);
  //       final stats = provider.statistics;
        
  //       return RefreshIndicator(
  //         onRefresh: () => provider.refreshStatistics(),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               // Header and action buttons
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           'Review Requests',
  //                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                         Text(
  //                           'Send and manage review requests to your customers',
  //                           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
  //                             color: Colors.grey[600],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   if (!_isBatchMode) ...[
  //                     Row(
  //                       children: [
  //                         IconButton(
  //                           icon: const Icon(Icons.file_upload_outlined),
  //                           tooltip: 'Import CSV',
  //                           onPressed: _showCsvImportDialog,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         ElevatedButton.icon(
  //                           onPressed: _showNewRequestDialog,
  //                           icon: const Icon(Icons.add),
  //                           label: const Text('New Request'),
  //                           style: ElevatedButton.styleFrom(
  //                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ] else ...[
  //                     Row(
  //                       children: [
  //                         IconButton(
  //                           icon: const Icon(Icons.send),
  //                           tooltip: 'Resend Selected',
  //                           onPressed: _selectedRequests.isEmpty ? null : _resendSelectedRequests,
  //                           color: Colors.blue,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         IconButton(
  //                           icon: const Icon(Icons.delete),
  //                           tooltip: 'Delete Selected',
  //                           onPressed: _selectedRequests.isEmpty ? null : _deleteSelectedRequests,
  //                           color: Colors.red,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         OutlinedButton(
  //                           onPressed: _toggleBatchMode,
  //                           child: const Text('Cancel'),
  //                         ),
  //                       ],
  //                     ),
  //                   ]
  //                 ],
  //               ),
                
  //               const SizedBox(height: 24),
                
  //               // Statistics cards
  //               ReviewRequestStatsCard(statistics: stats),
                
  //               const SizedBox(height: 24),
                
  //               // Search and batch options
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextField(
  //                       controller: _searchController,
  //                       decoration: InputDecoration(
  //                         hintText: 'Search by name or email',
  //                         prefixIcon: const Icon(Icons.search),
  //                         suffixIcon: _searchQuery.isNotEmpty
  //                             ? IconButton(
  //                                 icon: const Icon(Icons.clear),
  //                                 onPressed: () {
  //                                   _searchController.clear();
  //                                   _onSearchChanged('');
  //                                 },
  //                               )
  //                             : null,
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
  //                       ),
  //                       onChanged: _onSearchChanged,
  //                     ),
  //                   ),
  //                   if (allRequests.isNotEmpty) ...[
  //                     const SizedBox(width: 16),
  //                     if (!_isBatchMode)
  //                       TextButton.icon(
  //                         onPressed: _toggleBatchMode,
  //                         icon: const Icon(Icons.checklist),
  //                         label: const Text('Batch Actions'),
  //                       )
  //                     else
  //                       TextButton.icon(
  //                         onPressed: () => _selectAllRequests(filteredRequests),
  //                         icon: Icon(
  //                           _selectedRequests.length == filteredRequests.length
  //                               ? Icons.deselect
  //                               : Icons.select_all,
  //                         ),
  //                         label: Text(
  //                           _selectedRequests.length == filteredRequests.length
  //                               ? 'Deselect All'
  //                               : 'Select All',
  //                         ),
  //                       ),
  //                   ],
  //                 ],
  //               ),
                
  //               const SizedBox(height: 16),
                
  //               // Review requests list
  //               Expanded(
  //                 child: filteredRequests.isEmpty
  //                     ? _buildEmptyState(allRequests.isEmpty)
  //                     : ListView.separated(
  //                         itemCount: filteredRequests.length,
  //                         separatorBuilder: (context, index) => const Divider(),
  //                         itemBuilder: (context, index) {
  //                           final request = filteredRequests[index];
  //                           return ReviewRequestListTile(
  //                             request: request,
  //                             onDelete: () => provider.deleteReviewRequest(request.id),
  //                             onResend: _business == null 
  //                                 ? null 
  //                                 : () => provider.resendRequest(request, _business!),
  //                             isSelectable: _isBatchMode,
  //                             isSelected: _selectedRequests.contains(request.id),
  //                             onToggleSelection: () => _toggleRequestSelection(request.id),
  //                           );
  //                         },
  //                       ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  // Fixed _buildReviewRequestsView method with correct _buildEmptyState call


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






















// // lib/features/review_requests/screens/review_requests_screen.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:revboostapp/features/review_requests/widgets/new_review_request_dialog.dart';
// import 'package:revboostapp/features/review_requests/widgets/review_request_list_tile.dart';
// import 'package:revboostapp/features/review_requests/widgets/review_request_stats_card.dart';
// import 'package:revboostapp/features/review_requests/widgets/csv_import_dialog.dart';
// import 'package:revboostapp/models/business_model.dart';
// import 'package:revboostapp/models/review_request_model.dart';
// import 'package:revboostapp/providers/auth_provider.dart';
// import 'package:revboostapp/providers/review_request_provider.dart';
// import 'package:revboostapp/widgets/common/app_button.dart';
// import 'package:revboostapp/widgets/layout/app_layout.dart';
// import 'package:revboostapp/core/services/firestore_service.dart';

// /// Screen for managing review requests
// class ReviewRequestsScreen extends StatefulWidget {
//   /// Creates a [ReviewRequestsScreen]
//   const ReviewRequestsScreen({Key? key}) : super(key: key);

//   @override
//   State<ReviewRequestsScreen> createState() => _ReviewRequestsScreenState();
// }

// class _ReviewRequestsScreenState extends State<ReviewRequestsScreen> {
//   // Business data
//   BusinessModel? _business;
//   bool _isLoading = true;
//   String _errorMessage = '';
  
//   // Filters
//   String _searchQuery = '';
//   List<ReviewRequestStatus> _selectedStatusFilters = [];
//   final TextEditingController _searchController = TextEditingController();
  
//   // View options
//   bool _showCompletedRequests = true;
  
//   @override
//   void initState() {
//     super.initState();
//     _loadBusinessData();
//   }
  
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
  
//   /// Loads the business data for the current user
//   Future<void> _loadBusinessData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userId = authProvider.firebaseUser?.uid;

//       if (userId != null) {
//         // Get user's business
//         final firestoreService = FirestoreService();
//         final businesses = await firestoreService.getBusinessesByOwnerId(userId);

//         if (businesses.isNotEmpty) {
//           final business = businesses.first;
          
//           setState(() {
//             _business = business;
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _errorMessage = 'No business found. Please complete business setup first.';
//             _isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           _errorMessage = 'User not authenticated.';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error loading business data: $e';
//         _isLoading = false;
//       });
//     }
//   }
  
//   /// Shows the new review request dialog
//   void _showNewRequestDialog() {
//     if (_business == null) return;
    
//     showDialog(
//       context: context,
//       builder: (context) => NewReviewRequestDialog(business: _business!),
//     );
//   }
  
//   /// Shows the CSV import dialog
//   void _showImportDialog() {
//     if (_business == null) return;
    
//     showDialog(
//       context: context,
//       builder: (context) => CsvImportDialog(business: _business!),
//     );
//   }
  
//   /// Shows the delete confirmation dialog
//   Future<bool> _showDeleteConfirmation() async {
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Review Request'),
//         content: const Text(
//           'Are you sure you want to delete this review request? This action cannot be undone.'
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
    
//     return result ?? false;
//   }
  
//   /// Resets all filters
//   void _resetFilters() {
//     setState(() {
//       _searchQuery = '';
//       _searchController.clear();
//       _selectedStatusFilters = [];
//       _showCompletedRequests = true;
//     });
//   }
  
//   /// Toggles status filter
//   void _toggleStatusFilter(ReviewRequestStatus status) {
//     setState(() {
//       if (_selectedStatusFilters.contains(status)) {
//         _selectedStatusFilters.remove(status);
//       } else {
//         _selectedStatusFilters.add(status);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
//     return AppLayout(
//       title: 'Review Requests',
//       child: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//               ? _buildErrorView()
//               : _buildReviewRequestsView(isSmallScreen, theme),
//     );
//   }
  
//   /// Builds the error view
//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Theme.of(context).colorScheme.error,
//             ),
//             const SizedBox(height: 16),
        
//         // Status filter chips
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: [
//               // Show/hide completed filter
//               FilterChip(
//                 label: Text(_showCompletedRequests ? 'Hide Completed' : 'Show Completed'),
//                 selected: !_showCompletedRequests,
//                 onSelected: (selected) {
//                   setState(() {
//                     _showCompletedRequests = !selected;
//                   });
//                 },
//                 avatar: Icon(
//                   _showCompletedRequests ? Icons.visibility_off : Icons.visibility,
//                   size: 18,
//                 ),
//                 labelStyle: TextStyle(
//                   color: _showCompletedRequests 
//                       ? theme.brightness == Brightness.dark ? Colors.white : Colors.black
//                       : Colors.white,
//                 ),
//                 backgroundColor: theme.brightness == Brightness.dark 
//                     ? Colors.grey[800]
//                     : Colors.grey[200],
//                 selectedColor: theme.primaryColor,
//                 checkmarkColor: Colors.white,
//               ),
              
//               const SizedBox(width: 8),
              
//               // Status filters
//               ...statusFilters.map((filter) {
//                 final status = filter['status'] as ReviewRequestStatus;
//                 final label = filter['label'] as String;
//                 final icon = filter['icon'] as IconData;
//                 final isSelected = _selectedStatusFilters.contains(status);
                
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: FilterChip(
//                     label: Text(label),
//                     selected: isSelected,
//                     onSelected: (_) => _toggleStatusFilter(status),
//                     avatar: Icon(icon, size: 18),
//                     labelStyle: TextStyle(
//                       color: isSelected 
//                           ? Colors.white 
//                           : theme.brightness == Brightness.dark ? Colors.white : Colors.black,
//                     ),
//                     backgroundColor: theme.brightness == Brightness.dark 
//                         ? Colors.grey[800]
//                         : Colors.grey[200],
//                     selectedColor: theme.primaryColor,
//                     checkmarkColor: Colors.white,
//                   ),
//                 );
//               }).toList(),
              
//               // Filter reset button
//               if (_selectedStatusFilters.isNotEmpty || !_showCompletedRequests || _searchQuery.isNotEmpty) ...[
//                 const SizedBox(width: 8),
//                 ActionChip(
//                   label: const Text('Reset Filters'),
//                   onPressed: _resetFilters,
//                   avatar: const Icon(Icons.refresh, size: 18),
//                   backgroundColor: theme.brightness == Brightness.dark 
//                       ? Colors.grey[800]
//                       : Colors.grey[200],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
  
//   /// Builds the empty state when no requests are available
//   Widget _buildEmptyState() {
//     final hasFilters = _selectedStatusFilters.isNotEmpty || 
//                       !_showCompletedRequests || 
//                       _searchQuery.isNotEmpty;
    
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             hasFilters ? Icons.filter_list : Icons.email_outlined,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             hasFilters 
//                 ? 'No matching review requests found'
//                 : 'No review requests yet',
//             style: Theme.of(context).textTheme.headlineSmall,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             hasFilters
//                 ? 'Try adjusting your filters or search terms'
//                 : 'Send your first review request to start collecting reviews',
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? Colors.grey[400]
//                   : Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (hasFilters)
//             ElevatedButton.icon(
//               onPressed: _resetFilters,
//               icon: const Icon(Icons.filter_alt_off),
//               label: const Text('Reset Filters'),
//             )
//           else
//             ElevatedButton.icon(
//               onPressed: _showNewRequestDialog,
//               icon: const Icon(Icons.add),
//               label: const Text('Send First Request'),
//             ),
//         ],
//       ),
//     );
//   }
// }(height: 16),
//             Text(
//               'Error',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _errorMessage,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//             const SizedBox(height: 24),
//             AppButton(
//               text: 'Try Again',
//               onPressed: _loadBusinessData,
//               icon: Icons.refresh,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   /// Builds the main review requests view
//   Widget _buildReviewRequestsView(bool isSmallScreen, ThemeData theme) {
//     return Consumer<ReviewRequestProvider>(
//       builder: (context, provider, child) {
//         // Get filtered requests
//         final List<ReviewRequestModel> filteredRequests = provider.getFilteredRequests(
//           searchQuery: _searchQuery,
//           statusFilter: _selectedStatusFilters.isEmpty ? null : _selectedStatusFilters,
//         ).where((req) => 
//           _showCompletedRequests || req.status != ReviewRequestStatus.completed
//         ).toList();
        
//         final stats = provider.statistics;
//         final isLoading = provider.status == ReviewRequestOperationStatus.loading;
        
//         return RefreshIndicator(
//           onRefresh: () => provider.refreshStatistics(),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 24.0,
//               vertical: 16.0,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Header section
//                 isSmallScreen
//                     ? _buildMobileHeader(provider, theme)
//                     : _buildDesktopHeader(provider, theme),
                
//                 const SizedBox(height: 24),
                
//                 // Statistics cards
//                 ReviewRequestStatsCard(
//                   statistics: stats,
//                   isLoading: provider.isStatisticsLoading,
//                 ),
                
//                 const SizedBox(height: 24),
                
//                 // Filters section
//                 _buildFilterBar(theme),
                
//                 const SizedBox(height: 16),
                
//                 // Review requests list
//                 Expanded(
//                   child: isLoading && filteredRequests.isEmpty
//                       ? const Center(child: CircularProgressIndicator())
//                       : filteredRequests.isEmpty
//                           ? _buildEmptyState()
//                           : ListView.separated(
//                               itemCount: filteredRequests.length,
//                               separatorBuilder: (context, index) => const SizedBox(height: 8),
//                               itemBuilder: (context, index) {
//                                 final request = filteredRequests[index];
//                                 return ReviewRequestListTile(
//                                   request: request,
//                                   onDelete: () async {
//                                     if (await _showDeleteConfirmation()) {
//                                       provider.deleteReviewRequest(request.id);
//                                     }
//                                   },
//                                   onResend: () {
//                                     provider.resendReviewRequest(request.id);
//                                   },
//                                   onViewDetails: () {
//                                     // Navigate to details screen (to be implemented)
//                                   },
//                                 );
//                               },
//                             ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
  
//   /// Builds the desktop header with actions
//   Widget _buildDesktopHeader(ReviewRequestProvider provider, ThemeData theme) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Review Requests',
//                 style: theme.textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Send review requests to your customers',
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                   color: theme.brightness == Brightness.dark
//                       ? Colors.grey[400]
//                       : Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Row(
//           children: [
//             OutlinedButton.icon(
//               onPressed: _showImportDialog,
//               icon: const Icon(Icons.upload_file),
//               label: const Text('Import CSV'),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               ),
//             ),
//             const SizedBox(width: 12),
//             ElevatedButton.icon(
//               onPressed: _showNewRequestDialog,
//               icon: const Icon(Icons.add),
//               label: const Text('New Request'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 backgroundColor: theme.primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
  
//   /// Builds the mobile header with actions
//   Widget _buildMobileHeader(ReviewRequestProvider provider, ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Review Requests',
//           style: theme.textTheme.headlineMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Send review requests to your customers',
//           style: theme.textTheme.bodyMedium?.copyWith(
//             color: theme.brightness == Brightness.dark
//                 ? Colors.grey[400]
//                 : Colors.grey[600],
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _showImportDialog,
//                 icon: const Icon(Icons.upload_file),
//                 label: const Text('Import CSV'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _showNewRequestDialog,
//                 icon: const Icon(Icons.add),
//                 label: const Text('New Request'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   backgroundColor: theme.primaryColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
  
//   // / Builds the filter bar
//   Widget _buildFilterBar(ThemeData theme) {
//     final statusFilters = [
//       {'status': ReviewRequestStatus.pending, 'label': 'Pending', 'icon': Icons.schedule},
//       {'status': ReviewRequestStatus.sent, 'label': 'Sent', 'icon': Icons.send},
//       {'status': ReviewRequestStatus.clicked, 'label': 'Viewed', 'icon': Icons.remove_red_eye},
//       {'status': ReviewRequestStatus.completed, 'label': 'Completed', 'icon': Icons.check_circle},
//       {'status': ReviewRequestStatus.failed, 'label': 'Failed', 'icon': Icons.error_outline},
//     ];
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Search field
//         TextField(
//           controller: _searchController,
//           decoration: InputDecoration(
//             hintText: 'Search by name or email',
//             prefixIcon: const Icon(Icons.search),
//             suffixIcon: _searchQuery.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(Icons.clear),
//                     onPressed: () {
//                       setState(() {
//                         _searchQuery = '';
//                         _searchController.clear();
//                       });
//                     },
//                   )
//                 : null,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           onChanged: (value) {
//             setState(() {
//               _searchQuery = value;
//             });
//           },
//         ),
        
//         const SizedBox

