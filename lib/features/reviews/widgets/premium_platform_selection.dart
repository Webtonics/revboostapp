// lib/features/reviews/widgets/premium_platform_selection.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPlatformSelection extends StatelessWidget {
  final int rating;
  final Map<String, String> reviewLinks;
  final VoidCallback onSkip;

  const PremiumPlatformSelection({
    Key? key,
    required this.rating,
    required this.reviewLinks,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[400]!,
                  Colors.green[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank you for the $rating-star rating!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Would you mind sharing your experience publicly?\nIt really helps other customers find us!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Platform buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                if (reviewLinks.isNotEmpty) ...[
                  Text(
                    'Choose where to leave your review:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...reviewLinks.entries.map(
                    (entry) => _buildPlatformButton(context, entry.key, entry.value),
                  ).toList(),
                ] else ...[
                  Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No review platforms configured',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Skip button
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Maybe Later',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: context.pop,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformButton(BuildContext context, String platform, String url) {
    final platformData = _getPlatformData(platform);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _launchUrl(url, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: platformData['color'],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              platformData['icon'],
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Review on $platform',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlatformData(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
      case 'google business profile':
        return {
          'icon': Icons.business_rounded,
          'color': Colors.blue[600],
        };
      case 'facebook':
        return {
          'icon': Icons.facebook_rounded,
          'color': const Color(0xFF4267B2),
        };
      case 'yelp':
        return {
          'icon': Icons.restaurant_menu_rounded,
          'color': const Color(0xFFD32323),
        };
      case 'tripadvisor':
        return {
          'icon': Icons.travel_explore_rounded,
          'color': const Color(0xFF00AA6C),
        };
      default:
        return {
          'icon': Icons.link_rounded,
          'color': Colors.grey[600],
        };
    }
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context, 'Could not open review platform');
      }
    } catch (e) {
      _showError(context, 'Error opening review platform: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }
}