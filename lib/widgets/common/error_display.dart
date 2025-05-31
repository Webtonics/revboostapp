// lib/widgets/common/error_display.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/core/theme/app_colors.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? suggestion;
  final VoidCallback? onRetry;
  final VoidCallback? onSuggestionTap;
  final bool isNetworkError;
  final EdgeInsetsGeometry? margin;
  final bool showIcon;
  
  const ErrorDisplay({
    Key? key,
    required this.message,
    this.suggestion,
    this.onRetry,
    this.onSuggestionTap,
    this.isNetworkError = false,
    this.margin,
    this.showIcon = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.errorDark.withOpacity(0.1) : AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.error.withOpacity(0.3) : AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
                Icon(
                  isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    if (suggestion != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onSuggestionTap,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            suggestion!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: onSuggestionTap != null 
                                  ? TextDecoration.underline 
                                  : null,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Alternative compact error display for smaller spaces
class CompactErrorDisplay extends StatelessWidget {
  final String message;
  final String? suggestion;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  
  const CompactErrorDisplay({
    Key? key,
    required this.message,
    this.suggestion,
    this.onDismiss,
    this.margin,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.errorDark.withOpacity(0.1) : AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Success display widget for positive feedback
class SuccessDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final bool showIcon;
  
  const SuccessDisplay({
    Key? key,
    required this.message,
    this.onDismiss,
    this.margin,
    this.showIcon = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.successDark.withOpacity(0.1) : AppColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.success.withOpacity(0.3) : AppColors.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}