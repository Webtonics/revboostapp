// lib/features/review_requests/widgets/review_request_list_tile.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/models/review_request_model.dart';
import 'package:intl/intl.dart';

/// A widget that displays a single review request as a list tile
class ReviewRequestListTile extends StatelessWidget {
  /// The review request to display
  final ReviewRequestModel request;
  
  /// Callback for when delete is pressed
  final VoidCallback? onDelete;
  
  /// Callback for when resend is pressed
  final VoidCallback? onResend;
  
  /// Callback for when view details is pressed
  final VoidCallback? onViewDetails;
  
  /// Whether the list tile is in selection mode
  final bool isSelectable;
  
  /// Whether the list tile is selected
  final bool isSelected;
  
  /// Callback for when selection is toggled
  final VoidCallback? onToggleSelection;
  
  /// Creates a [ReviewRequestListTile]
  const ReviewRequestListTile({
    Key? key,
    required this.request,
    this.onDelete,
    this.onResend,
    this.onViewDetails,
    this.isSelectable = false,
    this.isSelected = false,
    this.onToggleSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    // Status color mapping
    final statusColors = {
      'pending': Colors.grey,
      'sent': theme.primaryColor,
      'clicked': Colors.purple,
      'completed': Colors.green,
      'failed': Colors.red,
    };
    
    final statusColor = statusColors[request.statusText.toLowerCase()] ?? Colors.grey;
    
    // Determine the appropriate date to show
    final date = request.completedAt ?? 
                 request.clickedAt ?? 
                 request.sentAt ?? 
                 request.createdAt;
    
    // Determine subtitle based on status
    String subtitle;
    switch (request.status) {
      case ReviewRequestStatus.pending:
        subtitle = 'Created on ${dateFormat.format(request.createdAt)}';
        break;
      case ReviewRequestStatus.sent:
        subtitle = 'Sent on ${dateFormat.format(request.sentAt!)} at ${timeFormat.format(request.sentAt!)}';
        break;
      case ReviewRequestStatus.clicked:
        subtitle = 'Viewed on ${dateFormat.format(request.clickedAt!)}';
        break;
      case ReviewRequestStatus.completed:
        subtitle = request.isPositive 
            ? 'Completed with ${request.rating}-star rating' 
            : 'Completed with feedback';
        break;
      case ReviewRequestStatus.failed:
        subtitle = 'Failed to send on ${dateFormat.format(request.createdAt)}';
        break;
    }
    
    return GestureDetector(
      onTap: isSelectable ? onToggleSelection : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected 
                ? theme.primaryColor 
                : theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? theme.primaryColor.withOpacity(0.05) : null,
        child: ExpansionTile(
          title: Row(
            children: [
              // Selection checkbox if in selection mode
              if (isSelectable) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelection?.call(),
                  activeColor: theme.primaryColor,
                ),
                const SizedBox(width: 8),
              ],
              
              // Customer avatar with initials
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                radius: 20,
                child: Text(
                  _getInitials(request.customerName),
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.customerEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Status indicator and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRelativeTime(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(
              left: isSelectable ? 88.0 : 52.0,  // Adjust padding based on checkbox
              top: 4.0,
            ),
            child: Text(subtitle),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show divider
                  const Divider(),
                  
                  // Show additional information for completed requests
                  if (request.status == ReviewRequestStatus.completed) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Rating:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (request.rating ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: index < (request.rating ?? 0)
                                  ? Colors.amber
                                  : Colors.grey,
                              size: 18,
                            );
                          }),
                        ),
                      ],
                    ),
                    
                    if (request.feedback != null && request.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Feedback:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.feedback!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons - hide if in selection mode
                  if (!isSelectable) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (request.status == ReviewRequestStatus.failed || 
                            request.status == ReviewRequestStatus.pending) ...[
                          OutlinedButton.icon(
                            onPressed: onResend,
                            icon: const Icon(Icons.send),
                            label: const Text('Send'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.primaryColor),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        if (onViewDetails != null) ...[
                          OutlinedButton.icon(
                            onPressed: onViewDetails,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                              side: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[400]!,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Gets the initials from a name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
  }
  
  /// Gets a relative time string from a date
  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
}