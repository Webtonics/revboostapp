// lib/features/business_setup/widgets/review_platforms_step.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewPlatformsStep extends StatelessWidget {
  final Map<String, TextEditingController> platformControllers;
  final AnimationController contentController;

  const ReviewPlatformsStep({
    Key? key,
    required this.platformControllers,
    required this.contentController,
  }) : super(key: key);

  // Platform configurations with icons and colors
  static const Map<String, Map<String, dynamic>> platformConfig = {
    'Google Business Profile': {
      'icon': "assets/icons/icons8-google.svg",
      'color': Color(0xFF4285F4),
      'description': 'Get reviews on Google Search & Maps',
    },
    'Yelp': {
      'icon': "assets/icons/icons8-yelp.svg",
      'color': Color(0xFFD32323),
      'description': 'Connect with local customers',
    },
    'Facebook': {
      'icon': "assets/icons/icons8-facebook.svg",
      'color': Color(0xFF1877F2),
      'description': 'Engage your social media audience',
    },
    'TripAdvisor': {
      'icon': "assets/icons/icons8-tripadvisor.svg",
      'color': Color(0xFF00AF87),
      'description': 'Perfect for hospitality & travel',
    },
  };

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: contentController,
          curve: Curves.easeOutCubic,
        )),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallScreen = screenWidth < 600;
            final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 70),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with video help
                  _AnimatedWidget(
                    delay: 0,
                    child: _buildHeaderSection(isSmallScreen, isMediumScreen),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Platform fields - responsive layout
                  if (isSmallScreen)
                    _buildMobileLayout()
                  else if (isMediumScreen)
                    _buildTabletLayout()
                  else
                    _buildDesktopLayout(),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Help section
                  _AnimatedWidget(
                    delay: 500,
                    child: _buildHelpSection(isSmallScreen),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: List.generate(
        platformControllers.length,
        (index) {
          final platform = platformControllers.keys.elementAt(index);
          final config = platformConfig[platform]!;
          
          return Column(
            children: [
              _AnimatedWidget(
                delay: 100 * index,
                child: _buildPlatformField(
                  platform: platform,
                  controller: platformControllers[platform]!,
                  config: config,
                  isCompact: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: List.generate(
        platformControllers.length,
        (index) {
          final platform = platformControllers.keys.elementAt(index);
          final config = platformConfig[platform]!;
          
          return Column(
            children: [
              _AnimatedWidget(
                delay: 100 * index,
                child: _buildPlatformField(
                  platform: platform,
                  controller: platformControllers[platform]!,
                  config: config,
                  isCompact: false,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: List.generate(
        platformControllers.length,
        (index) {
          final platform = platformControllers.keys.elementAt(index);
          final config = platformConfig[platform]!;
          
          return Column(
            children: [
              _AnimatedWidget(
                delay: 100 * index,
                child: _buildPlatformField(
                  platform: platform,
                  controller: platformControllers[platform]!,
                  config: config,
                  isCompact: false,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.08),
            const Color(0xFF8B5CF6).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (isSmallScreen)
            _buildMobileHeader()
          else
            _buildDesktopHeader(),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Video help button - responsive
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchVideoGuide(),
              icon: Icon(
                Icons.play_circle_filled_rounded,
                size: isSmallScreen ? 20 : 24,
              ),
              label: Text(
                isSmallScreen ? 'How to Get Links' : 'Watch: How to Get Review Links',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Connect Your Review Platforms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Add links where customers can leave reviews. We\'ll redirect positive feedback here automatically.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.link_rounded,
            color: Color(0xFF6366F1),
            size: 32,
          ),
        ),
        const SizedBox(width: 20),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect Your Review Platforms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add links where customers can leave reviews. We\'ll redirect positive feedback here automatically.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformField({
    required String platform,
    required TextEditingController controller,
    required Map<String, dynamic> config,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform header - responsive layout
            if (isCompact)
              _buildCompactHeader(platform, config, controller)
            else
              _buildFullHeader(platform, config, controller),
            
            SizedBox(height: isCompact ? 12 : 16),
            
            // URL input field
            TextField(
              controller: controller,
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Paste your $platform review URL here',
                hintStyle: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: isCompact ? 14 : 16,
                ),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF1F5F9),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: config['color'] as Color,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isCompact ? 12 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(String platform, Map<String, dynamic> config, TextEditingController controller) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (config['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image(
                width: 20,
                 image: AssetImage(config['icon']),
                // color: config['color'] as Color,
                // size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                platform,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: controller.text.isNotEmpty
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFF64748B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                controller.text.isNotEmpty ? 'Connected' : 'Optional',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: controller.text.isNotEmpty
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          config['description'] as String,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFullHeader(String platform, Map<String, dynamic> config, TextEditingController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (config['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:Image(
            width: 20,
            image: AssetImage(config['icon']),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config['description'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: controller.text.isNotEmpty
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF64748B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            controller.text.isNotEmpty ? 'Connected' : 'Optional',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: controller.text.isNotEmpty
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: const Color(0xFFD97706),
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Text(
                  'Need Help Finding Your Links?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildHelpStep(
            '🔍',
            'Google Business Profile',
            'Search your business on Google → Click "Write a review" → Copy URL',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildHelpStep(
            '📱',
            'Yelp & TripAdvisor',
            'Go to your business page → Find "Write a Review" → Copy page URL',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildHelpStep(
            '👥',
            'Facebook',
            'Go to your Facebook page → Reviews tab → Copy page URL',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFFD97706),
                  size: isSmallScreen ? 16 : 20,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'Don\'t worry if you skip some platforms now. You can always add them later in settings.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String emoji, String platform, String instruction, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 16 : 20)),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: const Color(0xFFD97706),
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                instruction,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchVideoGuide() async {
    // Replace this URL with your actual Loom video URL
    const String videoUrl = 'https://www.loom.com/share/your-video-id';
    
    try {
      final Uri uri = Uri.parse(videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch video');
      }
    } catch (e) {
      debugPrint('Error launching video: $e');
      // You could show a snackbar here to inform the user
    }
  }
}

class _AnimatedWidget extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedWidget({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<_AnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}