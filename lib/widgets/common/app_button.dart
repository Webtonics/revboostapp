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