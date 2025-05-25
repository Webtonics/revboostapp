// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/providers/auth_provider.dart';
import 'package:revboostapp/providers/settings_provider.dart';
import 'package:revboostapp/routing/app_router.dart';
import 'package:revboostapp/widgets/common/app_button.dart';
import 'package:revboostapp/widgets/common/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load settings data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadUserSettings();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isLoading = settings.status == SettingsStatus.loading;
        
        return LoadingOverlay(
          isLoading: _isLoading || isLoading,
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: _buildTabContent(settings),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Business'),
          Tab(text: 'Account'),
        ],
      ),
    );
  }
  
  Widget _buildTabContent(SettingsProvider settings) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(settings),
        _buildBusinessTab(settings),
        _buildAccountTab(settings),
      ],
    );
  }
  
  Widget _buildProfileTab(SettingsProvider settings) {
    final userProfile = settings.userProfile;
    
    if (userProfile == null) {
      return const Center(child: Text('No profile data available'));
    }
    
    // Form controllers
    final nameController = TextEditingController(text: userProfile.displayName ?? '');
    final emailController = TextEditingController(text: userProfile.email);
    final phoneController = TextEditingController(text: userProfile.phoneNumber ?? '');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Update your personal details and contact information',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          
          // Profile picture
          // Center(
          //   child: Column(
          //     children: [
          //       CircleAvatar(
          //         radius: 48,
          //         backgroundColor: AppColors.primary.withOpacity(0.1),
          //         child: userProfile.photoUrl != null
          //           ? ClipRRect(
          //               borderRadius: BorderRadius.circular(48),
          //               child: Image.network(
          //                 userProfile.photoUrl!,
          //                 width: 96,
          //                 height: 96,
          //                 fit: BoxFit.cover,
          //                 errorBuilder: (context, error, stackTrace) => Text(
          //                   userProfile.displayName?.isNotEmpty == true
          //                     ? userProfile.displayName![0].toUpperCase()
          //                     : 'U',
          //                   style: const TextStyle(
          //                     fontSize: 36,
          //                     fontWeight: FontWeight.bold,
          //                     color: AppColors.primary,
          //                   ),
          //                 ),
          //               ),
          //             )
          //           : Text(
          //               userProfile.displayName?.isNotEmpty == true
          //                 ? userProfile.displayName![0].toUpperCase()
          //                 : 'U',
          //               style: const TextStyle(
          //                 fontSize: 36,
          //                 fontWeight: FontWeight.bold,
          //                 color: AppColors.primary,
          //               ),
          //             ),
          //       ),
          //       const SizedBox(height: 16),
          //       TextButton.icon(
          //         onPressed: () {
          //           // Upload profile picture logic
          //         },
          //         icon: const Icon(Icons.upload),
          //         label: const Text('Upload Photo'),
          //       ),
          //     ],
          //   ),
          // ),
          
          const SizedBox(height: 32),
          
          // Form fields
          _buildTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: nameController,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            hint: 'Enter your email address',
            controller: emailController,
            prefixIcon: Icons.email_outlined,
            readOnly: true, // Email changes require re-authentication
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            hint: 'Enter your phone number',
            controller: phoneController,
            prefixIcon: Icons.phone_outlined,
          ),
          
          const SizedBox(height: 32),
          
          // Save button
          AppButton(
            text: 'Save Changes',
            onPressed: () async {
              try {
                setState(() {
                  _isLoading = true;
                });
                
                await settings.updateUserProfile(
                  displayName: nameController.text,
                  phoneNumber: phoneController.text,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessTab(SettingsProvider settings) {
    final businessProfile = settings.businessProfile;
    
    if (businessProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No business profile found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your business profile to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Set Up Business',
              onPressed: () {
                // Navigate to business setup
                context.go(AppRoutes.businessSetup);
              },
            ),
          ],
        ),
      );
    }
    
    // Form controllers
    final nameController = TextEditingController(text: businessProfile.name);
    final descriptionController = TextEditingController(text: businessProfile.description ?? '');
    
    // Review platform controllers
    final platformControllers = <String, TextEditingController>{};
    for (final platform in ['Google Business Profile', 'Yelp', 'Facebook', 'TripAdvisor']) {
      platformControllers[platform] = TextEditingController(
        text: businessProfile.reviewLinks[platform] ?? '',
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Update your business details and review platform links',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          
          // Business logo
          // Center(
          //   child: Column(
          //     children: [
          //       Container(
          //         width: 120,
          //         height: 120,
          //         decoration: BoxDecoration(
          //           color: AppColors.primary.withOpacity(0.1),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: businessProfile.logoUrl != null
          //           ? ClipRRect(
          //               borderRadius: BorderRadius.circular(12),
          //               child: Image.network(
          //                 businessProfile.logoUrl!,
          //                 width: 120,
          //                 height: 120,
          //                 fit: BoxFit.cover,
          //                 errorBuilder: (context, error, stackTrace) => const Icon(
          //                   Icons.business_outlined,
          //                   size: 48,
          //                   color: AppColors.primary,
          //                 ),
          //               ),
          //             )
          //           : const Icon(
          //               Icons.business_outlined,
          //               size: 48,
          //               color: AppColors.primary,
          //             ),
          //       ),
          //       const SizedBox(height: 16),
          //       TextButton.icon(
          //         onPressed: () {
          //           // Upload logo logic
          //         },
          //         icon: const Icon(Icons.upload),
          //         label: const Text('Upload Logo'),
          //       ),
          //     ],
          //   ),
          // ),
          
          const SizedBox(height: 32),
          
          // Form fields
          _buildTextField(
            label: 'Business Name',
            hint: 'Enter your business name',
            controller: nameController,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Business Description',
            hint: 'Describe your business',
            controller: descriptionController,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
          
          const SizedBox(height: 32),
          
          // Review platform links
          Text(
            'Review Platform Links',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          for (final platform in platformControllers.keys) ...[
            _buildTextField(
              label: platform,
              hint: 'Enter your $platform URL',
              controller: platformControllers[platform]!,
              prefixIcon: _getPlatformIcon(platform),
            ),
            const SizedBox(height: 16),
          ],
          
          const SizedBox(height: 32),
          
          // Save button
          AppButton(
            text: 'Save Changes',
            onPressed: () async {
              try {
                setState(() {
                  _isLoading = true;
                });
                
                // Prepare review links
                final reviewLinks = <String, String>{};
                for (final entry in platformControllers.entries) {
                  final value = entry.value.text.trim();
                  if (value.isNotEmpty) {
                    reviewLinks[entry.key] = value;
                  }
                }
                
                await settings.updateBusinessProfile(
                  name: nameController.text,
                  description: descriptionController.text,
                  reviewLinks: reviewLinks,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Business profile updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountTab(SettingsProvider settings) {
    final userProfile = settings.userProfile;
    
    if (userProfile == null) {
      return const Center(child: Text('No account data available'));
    }
    
    // Notification settings
    final emailNotifications = userProfile.notificationSettings?['emailEnabled'] ?? true;
    final pushNotifications = userProfile.notificationSettings?['pushEnabled'] ?? true;
    
    // Password change controllers
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            // 'Manage your account preferences and security',
            'Manage your account security',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          
          // Notification settings
          // Text(
          //   'Notification Preferences',
          //   style: Theme.of(context).textTheme.titleLarge,
          // ),
          // const SizedBox(height: 16),
          
          // _buildSwitchTile(
          //   title: 'Email Notifications',
          //   subtitle: 'Receive updates and alerts via email',
          //   value: emailNotifications,
          //   onChanged: (value) async {
          //     try {
          //       setState(() {
          //         _isLoading = true;
          //       });
                
          //       await settings.updateNotificationSettings(
          //         emailNotifications: value,
          //         pushNotifications: pushNotifications,
          //       );
          //     } catch (e) {
          //       if (mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(content: Text('Error: $e')),
          //         );
          //       }
          //     } finally {
          //       setState(() {
          //         _isLoading = false;
          //       });
          //     }
          //   },
          // ),
          
          // _buildSwitchTile(
          //   title: 'Push Notifications',
          //   subtitle: 'Receive real-time alerts on your device',
          //   value: pushNotifications,
          //   onChanged: (value) async {
          //     try {
          //       setState(() {
          //         _isLoading = true;
          //       });
                
          //       await settings.updateNotificationSettings(
          //         emailNotifications: emailNotifications,
          //         pushNotifications: value,
          //       );
          //     } catch (e) {
          //       if (mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(content: Text('Error: $e')),
          //         );
          //       }
          //     } finally {
          //       setState(() {
          //         _isLoading = false;
          //       });
          //     }
          //   },
          // ),
          
          // const SizedBox(height: 32),
          
          // Password change section
          Text(
            'Change Password',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            label: 'Current Password',
            hint: 'Enter your current password',
            controller: currentPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'New Password',
            hint: 'Enter your new password',
            controller: newPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Confirm New Password',
            hint: 'Confirm your new password',
            controller: confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          
          const SizedBox(height: 24),
          
          AppButton(
            text: 'Change Password',
            onPressed: () async {
              // Validate passwords
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              
              try {
                setState(() {
                  _isLoading = true;
                });
                
                await settings.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                
                // Clear form
                currentPasswordController.clear();
                newPasswordController.clear();
                confirmPasswordController.clear();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            fullWidth: true,
          ),
          
          const SizedBox(height: 48),
          
          // // Danger zone
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: AppColors.error.withOpacity(0.5)),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Danger Zone',
          //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //           color: AppColors.error,
          //         ),
          //       ),
          //       const SizedBox(height: 16),
          //       Text(
          //         'Delete your account and all associated data. This action cannot be undone.',
          //         style: Theme.of(context).textTheme.bodyMedium,
          //       ),
          //       const SizedBox(height: 16),
          //       OutlinedButton.icon(
          //         onPressed: () {
          //           _showDeleteAccountDialog();
          //         },
          //         icon: const Icon(Icons.delete_forever, color: AppColors.error),
          //         label: const Text('Delete Account'),
          //         style: OutlinedButton.styleFrom(
          //           foregroundColor: AppColors.error,
          //           side: const BorderSide(color: AppColors.error),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          
          const SizedBox(height: 32),
          
          // Sign out button
          Center(
            child: TextButton.icon(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete account logic
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Google Business Profile':
        return Icons.g_mobiledata_rounded;
      case 'Yelp':
        return Icons.restaurant_menu;
      case 'Facebook':
        return Icons.facebook;
      case 'TripAdvisor':
        return Icons.travel_explore;
      default:
        return Icons.link;
    }
  }
}