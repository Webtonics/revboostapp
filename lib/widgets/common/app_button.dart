// lib/widgets/common/app_button.dart

import 'package:flutter/material.dart';

enum AppButtonType { primary, secondary, text }
enum AppButtonSize { small, medium, large }


class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonSize = _getButtonSize();
    
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: _getIconSize()),
          SizedBox(width: size == AppButtonSize.small ? 6 : 8),
        ],
        if (isLoading) ...[
          SizedBox(
            width: _getIconSize(),
            height: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: size == AppButtonSize.small ? 6 : 8),
        ],
        Text(text),
      ],
    );
    
    if (fullWidth) {
      child = Center(child: child);
    }
    
    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonSize,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          ),
        );
      case AppButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonSize,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          ),
        );
      case AppButtonType.text:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonSize,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          ),
        );
    }
  }
  
  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          padding: _getPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case AppButtonType.secondary:
        return OutlinedButton.styleFrom(
          padding: _getPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case AppButtonType.text:
        return TextButton.styleFrom(
          padding: _getPadding(),
        );
    }
  }
  
  double _getButtonSize() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }
  
  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }
}

// // lib/widgets/common/app_button.dart

// import 'package:flutter/material.dart';

// /// Types of buttons available in the app
// enum AppButtonType {
//   primary,
//   secondary,
//   outline,
//   text,
//   danger,
//   success,
// }

// /// Button sizes for responsive design
// enum AppButtonSize {
//   small,
//   medium,
//   large,
// }

// /// A consistent button component with multiple styles and sizes
// class AppButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;
//   final AppButtonType type;
//   final AppButtonSize size;
//   final IconData? icon;
//   final bool isLoading;
//   final bool disabled;
//   final bool iconRight;
//   final double? width;
//   final double? height;
//   final BorderRadius? borderRadius;

//   const AppButton({
//     Key? key,
//     required this.text,
//     required this.onPressed,
//     this.type = AppButtonType.primary,
//     this.size = AppButtonSize.medium,
//     this.icon,
//     this.isLoading = false,
//     this.disabled = false,
//     this.iconRight = false,
//     this.width,
//     this.height,
//     this.borderRadius,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Get the theme
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
    
//     // Button styling based on type
//     Color backgroundColor;
//     Color textColor;
//     Color borderColor;
//     Color? overlayColor;
    
//     switch (type) {
//       case AppButtonType.primary:
//         backgroundColor = theme.primaryColor;
//         textColor = Colors.white;
//         borderColor = theme.primaryColor;
//         overlayColor = theme.primaryColorDark;
//         break;
//       case AppButtonType.secondary:
//         backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
//         textColor = isDarkMode ? Colors.white : Colors.black87;
//         borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
//         overlayColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
//         break;
//       case AppButtonType.outline:
//         backgroundColor = Colors.transparent;
//         textColor = theme.primaryColor;
//         borderColor = theme.primaryColor;
//         overlayColor = theme.primaryColor.withOpacity(0.1);
//         break;
//       case AppButtonType.text:
//         backgroundColor = Colors.transparent;
//         textColor = theme.primaryColor;
//         borderColor = Colors.transparent;
//         overlayColor = theme.primaryColor.withOpacity(0.1);
//         break;
//       case AppButtonType.danger:
//         backgroundColor = Colors.red[600]!;
//         textColor = Colors.white;
//         borderColor = Colors.red[600]!;
//         overlayColor = Colors.red[700];
//         break;
//       case AppButtonType.success:
//         backgroundColor = Colors.green[600]!;
//         textColor = Colors.white;
//         borderColor = Colors.green[600]!;
//         overlayColor = Colors.green[700];
//         break;
//     }
    
//     // Button dimensions based on size
//     double horizontalPadding;
//     double verticalPadding;
//     double fontSize;
//     double iconSize;
//     double spinnerSize;
    
//     switch (size) {
//       case AppButtonSize.small:
//         horizontalPadding = 12;
//         verticalPadding = 8;
//         fontSize = 14;
//         iconSize = 16;
//         spinnerSize = 16;
//         break;
//       case AppButtonSize.medium:
//         horizontalPadding = 16;
//         verticalPadding = 12;
//         fontSize = 16;
//         iconSize = 18;
//         spinnerSize = 18;
//         break;
//       case AppButtonSize.large:
//         horizontalPadding = 24;
//         verticalPadding = 16;
//         fontSize = 18;
//         iconSize = 20;
//         spinnerSize = 20;
//         break;
//     }
    
//     // If disabled, adjust the colors
//     if (disabled) {
//       backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
//       textColor = isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;
//       borderColor = backgroundColor;
//     }
    
//     // Define the border radius (default or custom)
//     final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(10);
    
//     // Build the button content based on loading state and icon position
//     Widget buttonContent;
    
//     if (isLoading) {
//       buttonContent = SizedBox(
//         height: spinnerSize,
//         width: spinnerSize,
//         child: CircularProgressIndicator(
//           strokeWidth: 2,
//           valueColor: AlwaysStoppedAnimation<Color>(textColor),
//         ),
//       );
//     } else {
//       if (icon != null) {
//         // Button with icon and text
//         final iconWidget = Icon(
//           icon,
//           color: textColor,
//           size: iconSize,
//         );
        
//         final textWidget = Text(
//           text,
//           style: TextStyle(
//             color: textColor,
//             fontSize: fontSize,
//             fontWeight: FontWeight.w500,
//           ),
//         );
        
//         if (iconRight) {
//           buttonContent = Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               textWidget,
//               SizedBox(width: size == AppButtonSize.small ? 4 : 8),
//               iconWidget,
//             ],
//           );
//         } else {
//           buttonContent = Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               iconWidget,
//               SizedBox(width: size == AppButtonSize.small ? 4 : 8),
//               textWidget,
//             ],
//           );
//         }
//       } else {
//         // Text-only button
//         buttonContent = Text(
//           text,
//           style: TextStyle(
//             color: textColor,
//             fontSize: fontSize,
//             fontWeight: FontWeight.w500,
//           ),
//         );
//       }
//     }
    
//     // Determine the button style based on type
//     final ButtonStyle buttonStyle;
    
//     if (type == AppButtonType.text) {
//       // Text button has no border or background
//       buttonStyle = TextButton.styleFrom(
//         foregroundColor: textColor,
//         padding: EdgeInsets.symmetric(
//           horizontal: horizontalPadding,
//           vertical: verticalPadding,
//         ),
//         backgroundColor: backgroundColor,
//         minimumSize: Size(width ?? 0, height ?? 0),
//         shape: RoundedRectangleBorder(
//           borderRadius: effectiveBorderRadius,
//         ),
//         overlayColor: overlayColor,
//       );
      
//       return SizedBox(
//         width: width,
//         height: height,
//         child: TextButton(
//           onPressed: disabled ? null : onPressed,
//           style: buttonStyle,
//           child: buttonContent,
//         ),
//       );
//     } else {
//       // Other button types
//       buttonStyle = ElevatedButton.styleFrom(
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//         padding: EdgeInsets.symmetric(
//           horizontal: horizontalPadding,
//           vertical: verticalPadding,
//         ),
//         minimumSize: Size(width ?? 0, height ?? 0),
//         shape: RoundedRectangleBorder(
//           borderRadius: effectiveBorderRadius,
//           side: BorderSide(
//             color: borderColor,
//             width: 1.0,
//           ),
//         ),
//         elevation: type == AppButtonType.outline ? 0 : 1,
//         shadowColor: backgroundColor.withOpacity(0.5),
//       );
      
//       return SizedBox(
//         width: width,
//         height: height,
//         child: ElevatedButton(
//           onPressed: disabled || isLoading ? null : onPressed,
//           style: buttonStyle,
//           child: buttonContent,
//         ),
//       );
//     }
//   }
// }