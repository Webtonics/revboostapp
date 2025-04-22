// lib/widgets/layout/app_layout.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/theme_toggle.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final bool showBackButton;
  
  const AppLayout({
    Key? key,
    required this.child,
    required this.title,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with SingleTickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      if (_isSidebarCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 800;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: isSmallScreen 
          ? _buildMobileAppBar() 
          : _buildDesktopAppBar(),
      drawer: isSmallScreen ? _buildSidebar(isSmallScreen) : null,
      body: Row(
        children: [
          // Show sidebar on desktop
          if (!isSmallScreen) 
            _buildSidebar(isSmallScreen),
          
          // Main content
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
  
  AppBar _buildDesktopAppBar() {
    return AppBar(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2.0,
      actions: [
        const ThemeToggle(showLabel: false),
        const SizedBox(width: 8),
        _buildUserProfile(),
        const SizedBox(width: 16),
      ],
    );
  }
  
  AppBar _buildMobileAppBar() {
    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2.0,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
            ),
      actions: const[
         ThemeToggle(showLabel: false),
         SizedBox(width: 8),
      ],
    );
  }
  
  Widget _buildSidebar(bool isSmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final width = isSmallScreen
        ? 280.0
        : (_isSidebarCollapsed ? 80.0 : 280.0);
    
    // Colors
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1E1E2D) 
        : Colors.white;
    final borderColor = isDarkMode 
        ? Colors.grey[800]! 
        : Colors.grey[200]!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      child: Drawer(
        backgroundColor: backgroundColor,
        elevation: isSmallScreen ? 2 : 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
          borderRadius: isSmallScreen 
              ? const BorderRadius.only(
                  topRight: Radius.circular(16), 
                  bottomRight: Radius.circular(16)
                ) 
              : BorderRadius.zero,
        ),
        child: Column(
          children: [
            _buildSidebarHeader(isSmallScreen),
            
            const SizedBox(height: 12),
            
            // Navigation section label
            if (!_isSidebarCollapsed && !isSmallScreen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            
            // Navigation links
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : _isSidebarCollapsed ? 12 : 16,
                  vertical: 8,
                ),
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    route: AppRoutes.dashboard,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    icon: Icons.reviews_rounded,
                    title: 'Review Requests',
                    route: AppRoutes.reviewRequests,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    icon: Icons.qr_code_rounded,
                    title: 'QR Code',
                    route: AppRoutes.qrCode,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  // _buildNavItem(
                  //   icon: Icons.qr_code_rounded,
                  //   title: 'Feedback',
                  //   route: AppRoutes.feedback,
                  //   isSmallScreen: isSmallScreen,
                  //   isSidebarCollapsed: _isSidebarCollapsed,
                  // ),
                  
                  // Divider for settings section
                  if (!_isSidebarCollapsed || isSmallScreen)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              thickness: 1,
                            ),
                          ),
                          if (!_isSidebarCollapsed && !isSmallScreen)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'SYSTEM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          if (!_isSidebarCollapsed || isSmallScreen)
                            Expanded(
                              child: Divider(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                thickness: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    route: AppRoutes.settings,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    icon: Icons.card_membership_rounded,
                    title: 'Subscription',
                    route: AppRoutes.subscription,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                ],
              ),
            ),
            
            // Sidebar footer with collapse button on desktop
            if (!isSmallScreen)
              _buildSidebarFooter(isDarkMode),
            
            // Sign out option on mobile
            if (isSmallScreen)
              _buildSignOutOption(isDarkMode),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarHeader(bool isSmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : _isSidebarCollapsed ? 12.0 : 20.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: _isSidebarCollapsed && !isSmallScreen 
              ? MainAxisAlignment.center 
              : MainAxisAlignment.start,
          children: [
            if (_isSidebarCollapsed && !isSmallScreen)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'RevBoostApp',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String route,
    required bool isSmallScreen,
    required bool isSidebarCollapsed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = GoRouterState.of(context).matchedLocation == route;
    
    // Colors
    final selectedBgColor = isSelected
        ? AppColors.primary.withOpacity(0.15)
        : Colors.transparent;
    final selectedBorderColor = isSelected
        ? AppColors.primary
        : Colors.transparent;
    final textColor = isSelected
        ? AppColors.primary
        : isDarkMode
            ? Colors.grey[300]
            : Colors.grey[700];
    final iconColor = isSelected
        ? AppColors.primary
        : isDarkMode
            ? Colors.grey[400]
            : Colors.grey[600];
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: isSidebarCollapsed && !isSmallScreen ? 0 : 0,
      ),
      decoration: BoxDecoration(
        color: selectedBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(
                color: selectedBorderColor,
                width: 0.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go(route);
            
            // Close drawer on mobile
            if (isSmallScreen) {
              Navigator.pop(context);
            }
          },
          splashColor: AppColors.primary.withOpacity(0.05),
          highlightColor: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isSidebarCollapsed && !isSmallScreen ? 12 : 12,
            ),
            child: Row(
              mainAxisAlignment: isSidebarCollapsed && !isSmallScreen 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
                if (!isSidebarCollapsed || isSmallScreen) ...[
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
                if (isSelected && (!isSidebarCollapsed || isSmallScreen))
                  const Spacer(),
                if (isSelected && (!isSidebarCollapsed || isSmallScreen))
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSidebarFooter(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleSidebar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed)
                  Text(
                    'Collapse Sidebar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5)
                      .animate(_animationController),
                  child: Icon(
                    Icons.keyboard_arrow_left_rounded,
                    size: 22,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSignOutOption(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).signOut();
            context.go(AppRoutes.splash);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 14),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserProfile() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;
    final displayName = user?.displayName ?? 'User';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  displayName.isNotEmpty 
                      ? displayName[0].toUpperCase() 
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'profile',
            onTap: () {              
              context.go(AppRoutes.settings);
            },
            child: Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            onTap: () {              
              context.go(AppRoutes.settings);
            },
            child: Row(
              children: [
                Icon(
                  Icons.settings_rounded,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(
            height: 1,
          ),
          PopupMenuItem(
            value: 'logout',
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              context.go(AppRoutes.splash);
            },
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}