// // lib/widgets/common/loading_overlay.dart

// import 'package:flutter/material.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class LoadingOverlay extends StatelessWidget {
//   final bool isLoading;
//   final Widget child;
//   final String? message;
  
//   const LoadingOverlay({
//     Key? key,
//     required this.isLoading,
//     required this.child,
//     this.message,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         child,
//         if (isLoading)
//           Container(
//             color: Colors.black.withOpacity(0.3),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   LoadingAnimationWidget.fourRotatingDots(
//                     color: Theme.of(context).colorScheme.primary,
//                     size: 50,
//                   ),
//                   if (message != null) ...[
//                     const SizedBox(height: 16),
//                     Text(
//                       message!,
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// lib/widgets/common/loading_overlay.dart

import 'package:flutter/material.dart';

/// A loading overlay that displays a spinner and optional message
/// while an operation is in progress
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? color;
  final Color? backgroundColor;
  final double opacity;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
    this.backgroundColor,
    this.opacity = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = Theme.of(context).primaryColor;
    final defaultBackgroundColor = isDarkMode
        ? Colors.black.withOpacity(opacity)
        : Colors.grey[100]!.withOpacity(opacity);
    
    return Stack(
      children: [
        // The main content
        child,
        
        // The loading overlay
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? defaultBackgroundColor,
              child: Center(
                child: _buildLoadingIndicator(context, defaultColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, Color defaultColor) {
    // For simple loading without message
    if (message == null || message!.isEmpty) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? defaultColor),
        strokeWidth: 3,
      );
    }
    
    // For loading with message
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Card background for better visibility
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(color ?? defaultColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}