// lib/features/qr_code/widgets/qr_link_display.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QrLinkDisplay extends StatefulWidget {
  final String link;
  final VoidCallback onCopy;

  const QrLinkDisplay({
    Key? key,
    required this.link,
    required this.onCopy,
  }) : super(key: key);

  @override
  State<QrLinkDisplay> createState() => _QrLinkDisplayState();
}

class _QrLinkDisplayState extends State<QrLinkDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _justCopied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCopy() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    setState(() {
      _justCopied = true;
    });
    
    widget.onCopy();
    
    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _justCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neutral200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Link',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    Text(
                      'Share this link directly with customers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Link container with copy functionality
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _justCopied
                        ? LinearGradient(
                            colors: [
                              AppColors.success.withOpacity(0.1),
                              AppColors.success.withOpacity(0.05),
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.neutral50,
                              AppColors.neutral100,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _justCopied ? AppColors.success : AppColors.neutral300,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleCopy,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.link,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.neutral700,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _justCopied
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                      key: ValueKey('check'),
                                    )
                                  : const Icon(
                                      Icons.copy_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                      key: ValueKey('copy'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          if (_justCopied) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Link copied to clipboard!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}