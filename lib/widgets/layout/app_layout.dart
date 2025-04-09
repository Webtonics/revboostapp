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

class _AppLayoutState extends State<AppLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
      // title: Text(widget.title),
      centerTitle: false,
      elevation: 0,
      actions: [
        // Search bar - expanded
        // Expanded(
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 24.0),
        //     child: TextField(
        //       decoration: InputDecoration(
        //         hintText: 'Search...',
        //         prefixIcon: const Icon(Icons.search),
        //         filled: true,
        //         fillColor: Theme.of(context).brightness == Brightness.dark
        //             ? Colors.grey[800]
        //             : Colors.grey[100],
        //         border: OutlineInputBorder(
        //           borderRadius: BorderRadius.circular(8),
        //           borderSide: BorderSide.none,
        //         ),
        //         contentPadding: const EdgeInsets.symmetric(vertical: 0),
        //       ),
        //     ),
        //   ),
        // ),
        
        // Theme toggle
        const ThemeToggle(showLabel: false),
        
        // Notifications
        // IconButton(
        //   icon: const Icon(Icons.notifications_outlined),
        //   onPressed: () {
        //     // Show notifications panel
        //   },
        // ),
        
        // User profile
        _buildUserProfile(),
        
        const SizedBox(width: 16),
      ],
    );
  }
  
  AppBar _buildMobileAppBar() {
    return AppBar(
      title: Text(widget.title),
      centerTitle: true,
      elevation: 0,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
            ),
      actions: [
        const ThemeToggle(showLabel: false),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Show notifications panel
          },
        ),
      ],
    );
  }
  
  Widget _buildSidebar(bool isSmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final width = isSmallScreen
        ? 250.0
        : (_isSidebarCollapsed ? 70.0 : 250.0);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      child: Drawer(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: isSmallScreen ? 2 : 0,
        child: Column(
          children: [
            _buildSidebarHeader(isSmallScreen),
            
            const SizedBox(height: 8),
            
            // Navigation links
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: AppRoutes.dashboard,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    icon: Icons.reviews_outlined,
                    title: 'Review Requests',
                    route: AppRoutes.reviewRequests,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  // _buildNavItem(
                  //   icon: Icons.people_outline,
                  //   title: 'Contacts',
                  //   route: AppRoutes.contacts,
                  //   isSmallScreen: isSmallScreen,
                  //   isSidebarCollapsed: _isSidebarCollapsed,
                  // ),
                  _buildNavItem(
                    icon: Icons.qr_code,
                    title: 'QR Code',
                    route: AppRoutes.qrCode,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  // _buildNavItem(
                  //   icon: Icons.text_snippet_outlined,
                  //   title: 'Templates',
                  //   route: AppRoutes.templates,
                  //   isSmallScreen: isSmallScreen,
                  //   isSidebarCollapsed: _isSidebarCollapsed,
                  // ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    route: AppRoutes.settings,
                    isSmallScreen: isSmallScreen,
                    isSidebarCollapsed: _isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    icon: Icons.card_membership_outlined,
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
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: ListTile(
                  minLeadingWidth: 0,
                  leading: Icon(
                    _isSidebarCollapsed
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    size: 16,
                  ),
                  title: _isSidebarCollapsed
                      ? null
                      : const Text('Collapse Sidebar'),
                  onTap: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
              ),
            
            // Sign out option on mobile
            if (isSmallScreen)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).signOut();
                    context.go(AppRoutes.splash);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarHeader(bool isSmallScreen) {
    return SafeArea(
      child: Container(
        height: 64,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : _isSidebarCollapsed ? 8.0 : 16.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          children: [
            if (_isSidebarCollapsed && !isSmallScreen)
              const Icon(
                Icons.star,
                size: 24,
                color: AppColors.primary,
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'RevBoostApp',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
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
    final isSelected = GoRouterState.of(context).matchedLocation == route;
    final bgColor = isSelected
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : Colors.transparent;
    final textColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[800];
    final iconColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        selected: isSelected,
        leading: Icon(icon, color: iconColor),
        title: (!isSidebarCollapsed || isSmallScreen)
            ? Text(title, style: TextStyle(color: textColor))
            : null,
        minLeadingWidth: 0,
        onTap: () {
          context.go(route);
          
          // Close drawer on mobile
          if (isSmallScreen) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
  
  Widget _buildUserProfile() {
    final user = Provider.of<AuthProvider>(context).user;
    final displayName = user?.displayName ?? 'User';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        itemBuilder: (context) => [
           PopupMenuItem(
            value: 'profile',
            onTap: () {              
              context.go(AppRoutes.settings);
            },
            child: const Row(
              children: [
                Icon(Icons.person_outline),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
           PopupMenuItem(
            value: 'settings',
            onTap: () {              
              context.go(AppRoutes.settings);
            },
            child: const Row(
              children: [
                Icon(Icons.settings_outlined),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              context.go(AppRoutes.splash);
            },
            child: const Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Sign Out'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}