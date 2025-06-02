// lib/features/qr_code/widgets/qr_action_buttons.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QrActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? iconColor;

  const QrActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primary).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: iconColor ?? Colors.white,
              ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: iconColor ?? Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: iconColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class QrActionButtonsGrid extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onCopyLink;
  final bool isPrintLoading;
  final bool isShareLoading;
  final bool isDownloadLoading;

  const QrActionButtonsGrid({
    Key? key,
    required this.onPrint,
    required this.onShare,
    required this.onDownload,
    required this.onCopyLink,
    this.isPrintLoading = false,
    this.isShareLoading = false,
    this.isDownloadLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your QR Code',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 16),
          
          // Action buttons grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QrActionButton(
                icon: Icons.print_rounded,
                label: 'Print PDF',
                onPressed: onPrint,
                isLoading: isPrintLoading,
                backgroundColor: AppColors.success,
              ),
              QrActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onPressed: onShare,
                isLoading: isShareLoading,
                backgroundColor: AppColors.secondary,
              ),
              QrActionButton(
                icon: Icons.download_rounded,
                label: 'Download',
                onPressed: onDownload,
                isLoading: isDownloadLoading,
                backgroundColor: AppColors.orange,
              ),
              QrActionButton(
                icon: Icons.link_rounded,
                label: 'Copy Link',
                onPressed: onCopyLink,
                backgroundColor: AppColors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

