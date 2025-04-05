// lib/widgets/common/theme_toggle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/providers/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  final bool showLabel;
  final double size;
  
  const ThemeToggle({
    Key? key, 
    this.showLabel = true,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => themeProvider.toggleTheme(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: isDark
                ? Icon(
                    Icons.dark_mode_rounded,
                    key: const ValueKey('dark'),
                    color: Theme.of(context).colorScheme.onSurface,
                    size: size,
                  )
                : Icon(
                    Icons.light_mode_rounded,
                    key: const ValueKey('light'),
                    color: Theme.of(context).colorScheme.onSurface,
                    size: size,
                  ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}