// lib/widgets/layout/app_layout.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/routing/app_router.dart';

// Color variables for easy customization
class AppLayoutColors {
  // Light theme colors
  static const Color lightBackground = Color(0xFFF6FAF6);
  static const Color lightSurface = Colors.white;
  static const Color lightSidebarBg = Color(0xFF0B5D1E);
  static const Color lightHeaderBg = Colors.white;
  static const Color lightDivider = Color(0xFFE3EEE3);
  static const Color lightText = Color(0xFF1D3B29);
  static const Color lightTextSecondary = Color(0xFF5C8370);
  static const Color lightNavItemBg = Color(0xFFEAF5EA);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0A1F14);
  static const Color darkSurface = Color(0xFF132A1C);
  static const Color darkSidebarBg = Color(0xFF05140C);
  static const Color darkHeaderBg = Color(0xFF163526);
  static const Color darkDivider = Color(0xFF1F3D2A);
  static const Color darkText = Color(0xFFECF5EF);
  static const Color darkTextSecondary = Color(0xFFADD6BC);
  static const Color darkNavItemBg = Color(0xFF25432F);
  
  // Accent colors (for both themes)
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color accentGreenLight = Color(0xFF8BC34A);
  static const Color accentGreenDark = Color(0xFF2E7D32);
  static const Color highlightGreen = Color(0xFFB9F6CA);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
}

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Background colors based on theme
    final backgroundColor = isDarkMode 
        ? AppLayoutColors.darkBackground
        : AppLayoutColors.lightBackground;
    
    if (isSmallScreen) {
      // Mobile layout with drawer
      return Scaffold(
        key: _scaffoldKey,
        appBar: _buildMobileAppBar(),
        drawer: _buildSidebar(isSmallScreen),
        body: Container(
          color: backgroundColor,
          child: widget.child,
        ),
      );
    } else {
      // Desktop layout with persistent sidebar
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          children: [
            // Sidebar
            _buildSidebar(isSmallScreen),
            
            // Main content area
            Expanded(
              child: Column(
                children: [
                  // App bar area
                  _buildDesktopHeader(),
                  
                  // Main content
                  Expanded(
                    child: Container(
                      color: backgroundColor,
                      width: double.infinity,
                      child: widget.child,
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
  
  Widget _buildDesktopHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const headerHeight = 70.0;
    final headerColor = isDarkMode 
        ? AppLayoutColors.darkHeaderBg
        : AppLayoutColors.lightHeaderBg;
    final textColor = isDarkMode
        ? AppLayoutColors.darkText
        : AppLayoutColors.lightText;
    
    return Container(
      height: headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: headerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page title (left aligned)
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          
          // Right side actions
          Row(
            children: [
              // const ThemeToggle(showLabel: false),
              const SizedBox(width: 16),
              _buildUserProfile(),
            ],
          ),
        ],
      ),
    );
  }
  
  AppBar _buildMobileAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? AppLayoutColors.darkHeaderBg
        : AppLayoutColors.lightHeaderBg;
    final textColor = isDarkMode
        ? AppLayoutColors.darkText
        : AppLayoutColors.lightText;
        
    return AppBar(
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      backgroundColor: bgColor,
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
      // actions: const[
      //    ThemeToggle(showLabel: false),
      //    SizedBox(width: 8),
      // ],
    );
  }
  
  Widget _buildSidebar(bool isSmallScreen) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final width = isSmallScreen
        ? 280.0
        : (_isSidebarCollapsed ? 80.0 : 280.0);
    
    // Sidebar color - always dark for the demo
    const sidebarColor = AppLayoutColors.darkSidebarBg;
    
    // Text colors - adjusted for dark sidebar
    // final textColor = Colors.grey[300]!;
    final textColorSecondary = Colors.grey[500]!;
    
    final sidebarContent = Column(
      children: [
        // Logo and app name
        _buildSidebarHeader(isSmallScreen),
        
        const SizedBox(height: 24),
        
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
                  color: textColorSecondary,
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
              _buildNavItem(
                icon: Icons.feedback_rounded,
                title: 'Feedback',
                route: AppRoutes.feedback,
                isSmallScreen: isSmallScreen,
                isSidebarCollapsed: _isSidebarCollapsed,
              ),
              
              // Divider for settings section
              if (!_isSidebarCollapsed || isSmallScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[800],
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
                              color: textColorSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      if (!_isSidebarCollapsed || isSmallScreen)
                        Expanded(
                          child: Divider(
                            color: Colors.grey[800],
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
          _buildSidebarFooter(),
        
        // Sign out option on mobile
        if (isSmallScreen)
          _buildSignOutOption(),
      ],
    );

    // For mobile, use a drawer
    if (isSmallScreen) {
      return Drawer(
        backgroundColor: sidebarColor,
        elevation: 2,
        child: sidebarContent,
      );
    }

    // For desktop, use a custom container
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      color: sidebarColor,
      child: sidebarContent,
    );
  }
  
  Widget _buildSidebarHeader(bool isSmallScreen) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : _isSidebarCollapsed ? 12.0 : 20.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
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
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Image(image: AssetImage("assets/branding_dark.png"), height: 24),
                ),
              )
            else
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                     
                  child: Image(image: AssetImage("assets/branding_dark.png"), height: 24),
                ),
                  
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'RevBoostApp',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
    final isSelected = GoRouterState.of(context).matchedLocation == route;
    
    // Enhanced colors for better contrast and visual hierarchy
    final selectedBgColor = isSelected
        ? AppColors.primary.withOpacity(0.2)
        : Colors.transparent;
    final selectedBorderColor = isSelected
        ? AppColors.primary
        : Colors.transparent;
    final textColor = isSelected
        ? AppColors.primary
        : Colors.grey[300];
    final iconColor = isSelected
        ? AppColors.primary
        : Colors.grey[400];
    
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
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.15),
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
  
  Widget _buildSidebarFooter() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
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
                  const Text(
                    'Collapse Sidebar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5)
                      .animate(_animationController),
                  child: const Icon(
                    Icons.keyboard_arrow_left_rounded,
                    size: 22,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSignOutOption() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).signOut();
            context.go(AppRoutes.login);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: Colors.white70,
                ),
                SizedBox(width: 14),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
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
    
    final bgColor = isDarkMode
        ? const Color(0xFF2D2D42).withOpacity(0.5)
        : Colors.white.withOpacity(0.8);
    final borderColor = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey[200]!;
    final textColor = isDarkMode
        ? Colors.white
        : Colors.grey[800]!;
    
    // Enhanced profile button with better styling
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        color: bgColor,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  color: textColor,
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
              context.go(AppRoutes.login);
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