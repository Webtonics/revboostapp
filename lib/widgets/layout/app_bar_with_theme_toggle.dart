// lib/widgets/layout/app_bar_with_theme_toggle.dart

import 'package:flutter/material.dart';
import 'package:revboostapp/widgets/common/theme_toggle.dart';

class AppBarWithThemeToggle extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  
  const AppBarWithThemeToggle({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        const ThemeToggle(showLabel: false),
        const SizedBox(width: 8),
        ...?actions,
      ],
    );
  }
}