// lib/features/review_requests/screens/review_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/services/email_service.dart';
import 'package:revboostapp/features/review_requests/widgets/complete_csv_import_dialog.dart';
import 'package:revboostapp/features/review_requests/widgets/new_review_request_dialog.dart';
import 'package:revboostapp/features/review_requests/widgets/review_request_list_tile.dart';
import 'package:revboostapp/features/review_requests/widgets/review_request_stats_card.dart';
import 'package:revboostapp/models/business_model.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/complete_review_request_provider.dart';
import 'package:revboostapp/providers/review_request_provider.dart';
import 'package:revboostapp/providers/subscription_provider.dart';
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
        final firestoreService = FirestoreService();
        final businesses = await firestoreService.getBusinessesByOwnerId(userId);

        if (businesses.isNotEmpty) {
          final business = businesses.first;
          
          setState(() {
            _business = business;
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

  void _showNewRequestDialog() {
    if (_business == null) return;
    
    final emailService = Provider.of<EmailService>(context, listen: false);
    
    final reviewRequestProvider = ReviewRequestProvider(
      emailService: emailService,
      businessId: _business!.id,
      businessName: _business!.name,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider<ReviewRequestProvider>.value(
        value: reviewRequestProvider,
        child: NewReviewRequestDialog(business: _business!),
      ),
    ).then((_) {
      if (mounted) {
        try {
          Provider.of<CompleteReviewRequestProvider>(context, listen: false).refreshUsageStats();
        } catch (e) {
          debugPrint('Could not refresh complete provider: $e');
        }
      }
      reviewRequestProvider.dispose();
    });
  }

  void _showCsvImportDialog(CompleteReviewRequestProvider provider, SubscriptionProvider subscriptionProvider) {
    if (_business == null) return;
    
    showDialog(
      context: context,
      builder: (context) => CompleteCsvImportDialog(
        business: _business!,
        hasPremiumAccess: provider.hasPremiumAccess,
        isFreeTrial: subscriptionProvider.isFreeTrial,
        onImport: (contacts, sendImmediately) async {
          return await provider.importContactsFromCsv(
            contacts: contacts,
            business: _business!,
            sendImmediately: sendImmediately,
          );
        },
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
        _selectedRequests.clear();
      } else {
        _selectedRequests = requests.map((req) => req.id).toList();
      }
    });
  }
  
  Future<void> _batchSendRequests(CompleteReviewRequestProvider provider) async {
    if (_selectedRequests.isEmpty || _business == null) return;
    
    if (!provider.hasPremiumAccess) {
      _showPremiumRequiredDialog('Batch Sending');
      return;
    }
    
    final confirmSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Multiple Requests'),
        content: Text('Send review requests to ${_selectedRequests.length} selected customers?'),
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
    ) ?? false;
    
    if (confirmSend) {
      final result = await provider.batchSendRequests(requestIds: _selectedRequests);
      
      setState(() {
        _selectedRequests.clear();
        _isBatchMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['successful']} sent, ${result['failed']} failed'),
            backgroundColor: result['failed'] > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _batchDeleteRequests(CompleteReviewRequestProvider provider) async {
    if (_selectedRequests.isEmpty) return;
    
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Requests'),
        content: Text('Delete ${_selectedRequests.length} selected requests? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          // TextButton(
          //   onPressed: () => Navigator.of(context).pop(true),
          //   child: const Text('Delete', style: TextStyle(color: Colors.red)),
          // ),
        ],
      ),
    ) ?? false;
    
    if (confirmDelete) {
      for (final id in _selectedRequests) {
        await provider.deleteReviewRequest(id);
      }
      
      setState(() {
        _selectedRequests.clear();
        _isBatchMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected requests deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  void _showPremiumRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
          ],
        ),
        content: Text('$feature is only available for premium users. Upgrade to access this feature!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                context.go(AppRoutes.subscription);
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? _buildErrorView()
            : _business == null
                ? _buildNoBusiness()
                : _buildReviewRequestsView();
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final emailService = Provider.of<EmailService>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return _buildErrorView();
    
    return ChangeNotifierProvider<CompleteReviewRequestProvider>(
      create: (_) => CompleteReviewRequestProvider(
        emailService: emailService,
        userId: user.id,
        businessId: _business!.id,
        businessName: _business!.name,
        planType: subscriptionProvider.currentPlanType,
      ),
      child: Consumer<CompleteReviewRequestProvider>(
        builder: (context, provider, child) {
          final reviews = _filterRequests(provider.reviewRequests);
          final isNearLimit = provider.isNearLimit;
          final hasUsageData = provider.hasUsageData;
          
          return RefreshIndicator(
            onRefresh: () => provider.refreshUsageStats(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(provider),
                  const SizedBox(height: 16),
                  if (hasUsageData && isNearLimit) _buildUsageWarning(provider),
                  // _buildActionButtons(provider, subscriptionProvider, reviews),
                  const SizedBox(height: 16),
                  if (reviews.isNotEmpty) _buildSearchBar(),
                  const SizedBox(height: 16),
                  // ReviewRequestStatsCard(statistics: provider.usageStats),
                  // const SizedBox(height: 24),
                  Expanded(
                    child: reviews.isEmpty
                        ? _buildEmptyState(provider.reviewRequests.isEmpty)
                        : _buildRequestsList(reviews, provider),
                  ),
                  if (_isBatchMode && _selectedRequests.isNotEmpty)
                    _buildBatchOperationsBar(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CompleteReviewRequestProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: provider.canSendRequests ? _showNewRequestDialog : null,
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        if (provider.hasUsageData) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.isNearLimit 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: provider.isNearLimit 
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  provider.isNearLimit ? Icons.warning_amber : Icons.info_outline,
                  color: provider.isNearLimit ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.getUsageSummary(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: provider.isNearLimit ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: provider.monthlyUsagePercent / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                      provider.isNearLimit ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUsageWarning(CompleteReviewRequestProvider provider) {
    final warning = provider.getRateLimitWarning();
    if (warning == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.subscription),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CompleteReviewRequestProvider provider, SubscriptionProvider subscriptionProvider, List<ReviewRequestModel> reviews) {
    final batchSendableCount = provider.getBatchSendableRequests().length;
    
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: provider.hasPremiumAccess 
              ? () => _showCsvImportDialog(provider, subscriptionProvider)
              : () => _showPremiumRequiredDialog('CSV Import'),
          icon: Icon(
            Icons.upload_file,
            color: provider.hasPremiumAccess ? null : Colors.grey,
          ),
          label: Text(
            'Import CSV',
            style: TextStyle(
              color: provider.hasPremiumAccess ? null : Colors.grey,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: provider.hasPremiumAccess 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (reviews.isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: _toggleBatchMode,
            icon: Icon(_isBatchMode ? Icons.close : Icons.checklist),
            label: Text(_isBatchMode ? 'Cancel' : 'Select'),
            style: OutlinedButton.styleFrom(
              backgroundColor: _isBatchMode 
                  ? Theme.of(context).primaryColor.withOpacity(0.1) 
                  : null,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (batchSendableCount > 0) ...[
          OutlinedButton.icon(
            onPressed: provider.hasPremiumAccess 
                ? () {
                    setState(() {
                      _selectedRequests = provider.getBatchSendableRequests()
                          .map((req) => req.id).toList();
                      _isBatchMode = true;
                    });
                    _batchSendRequests(provider);
                  }
                : () => _showPremiumRequiredDialog('Batch Sending'),
            icon: Icon(
              Icons.send_rounded,
              color: provider.hasPremiumAccess ? Colors.green : Colors.grey,
            ),
            label: Text(
              'Send All ($batchSendableCount)',
              style: TextStyle(
                color: provider.hasPremiumAccess ? Colors.green : Colors.grey,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: provider.hasPremiumAccess ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (_isBatchMode && reviews.isNotEmpty) ...[
          TextButton(
            onPressed: () => _selectAllRequests(reviews),
            child: Text(
              _selectedRequests.length == reviews.length ? 'Deselect All' : 'Select All',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name or email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildRequestsList(List<ReviewRequestModel> reviews, CompleteReviewRequestProvider provider) {
    return ListView.separated(
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
    );
  }

  Widget _buildBatchOperationsBar(CompleteReviewRequestProvider provider) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedRequests.length} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          OutlinedButton.icon(
            onPressed: () => _batchSendRequests(provider),
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('Send', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => _batchDeleteRequests(provider),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedRequests.clear();
                _isBatchMode = false;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

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
              onPressed: () => context.go(AppRoutes.settings),
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