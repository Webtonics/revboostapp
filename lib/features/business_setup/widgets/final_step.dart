// lib/features/business_setup/widgets/final_step.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FinalStep extends StatelessWidget {
  final String businessName;
  final String businessDescription;
  final String? selectedCategory;
  final Map<String, TextEditingController> platformControllers;
  final AnimationController contentController;

  const FinalStep({
    Key? key,
    required this.businessName,
    required this.businessDescription,
    required this.selectedCategory,
    required this.platformControllers,
    required this.contentController,
  }) : super(key: key);

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
                children: [
                  // Success animation - responsive size
                  _AnimatedWidget(
                    delay: 100,
                    child: Container(
                      height: isSmallScreen ? 150 : isMediumScreen ? 175 : 200,
                      width: isSmallScreen ? 150 : isMediumScreen ? 175 : 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.1),
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Lottie.asset(
                        'assets/lottie/success.json',
                        width: isSmallScreen ? 120 : isMediumScreen ? 140 : 160,
                        height: isSmallScreen ? 120 : isMediumScreen ? 140 : 160,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  // Success message - responsive text
                  _AnimatedWidget(
                    delay: 300,
                    child: Column(
                      children: [
                        Text(
                          '🎉 You\'re All Set!',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : isMediumScreen ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Your business profile is ready to start collecting amazing reviews and growing your reputation!',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                            color: const Color(0xFF64748B),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 32 : 40),
                  
                  // Business summary card
                  _AnimatedWidget(
                    delay: 500,
                    child: _buildBusinessSummary(isSmallScreen, isMediumScreen),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  // Benefits preview
                  _AnimatedWidget(
                    delay: 700,
                    child: _buildBenefitsSection(isSmallScreen, isMediumScreen),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  // Ready to launch
                  _AnimatedWidget(
                    delay: 900,
                    child: _buildReadyToLaunch(isSmallScreen, isMediumScreen),
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

  Widget _buildBusinessSummary(bool isSmallScreen, bool isMediumScreen) {
    final connectedPlatforms = platformControllers.values
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Text(
                  'Business Summary',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          _buildSummaryRow(
            '🏢',
            'Business Name',
            businessName.isEmpty ? 'Not provided' : businessName,
            isSmallScreen: isSmallScreen,
          ),
          
          if (businessDescription.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildSummaryRow(
              '📝',
              'Description',
              businessDescription,
              isDescription: true,
              isSmallScreen: isSmallScreen,
            ),
          ],
          
          if (selectedCategory != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildSummaryRow(
              '🎯',
              'Category',
              selectedCategory!,
              isSmallScreen: isSmallScreen,
            ),
          ],
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildSummaryRow(
            '🔗',
            'Connected Platforms',
            '$connectedPlatforms platform${connectedPlatforms != 1 ? 's' : ''} connected',
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String emoji, 
    String label, 
    String value, {
    bool isDescription = false,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 16 : 20)),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isDescription ? (isSmallScreen ? 12 : 14) : (isSmallScreen ? 14 : 16),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                    height: isDescription ? 1.4 : null,
                  ),
                  maxLines: isDescription ? (isSmallScreen ? 2 : 3) : null,
                  overflow: isDescription ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.05),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Text(
                'What Happens Next?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          if (isSmallScreen)
            _buildMobileBenefits()
          else
            _buildDesktopBenefits(isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildMobileBenefits() {
    return Column(
      children: [
        _buildBenefitItem(
          Icons.star_rounded,
          'Smart Review Collection',
          'Positive reviews (4-5 stars) go to your public platforms automatically',
          const Color(0xFFF59E0B),
          isCompact: true,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          Icons.filter_alt_rounded,
          'Private Feedback Capture',
          'Negative reviews stay private, giving you a chance to improve',
          const Color(0xFF6366F1),
          isCompact: true,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          Icons.qr_code_rounded,
          'Easy QR Code Sharing',
          'Generate QR codes for tables, receipts, and marketing materials',
          const Color(0xFF8B5CF6),
          isCompact: true,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          Icons.analytics_rounded,
          'Performance Analytics',
          'Track your review performance and customer satisfaction trends',
          const Color(0xFF10B981),
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildDesktopBenefits(bool isMediumScreen) {
    return Column(
      children: [
        _buildBenefitItem(
          Icons.star_rounded,
          'Smart Review Collection',
          'Positive reviews (4-5 stars) go to your public platforms automatically',
          const Color(0xFFF59E0B),
          isCompact: false,
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          Icons.filter_alt_rounded,
          'Private Feedback Capture',
          'Negative reviews stay private, giving you a chance to improve',
          const Color(0xFF6366F1),
          isCompact: false,
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          Icons.qr_code_rounded,
          'Easy QR Code Sharing',
          'Generate QR codes for tables, receipts, and marketing materials',
          const Color(0xFF8B5CF6),
          isCompact: false,
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          Icons.analytics_rounded,
          'Performance Analytics',
          'Track your review performance and customer satisfaction trends',
          const Color(0xFF10B981),
          isCompact: false,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon, 
    String title, 
    String description, 
    Color color, {
    required bool isCompact
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          ),
          child: Icon(
            icon,
            color: color,
            size: isCompact ? 16 : 20,
          ),
        ),
        SizedBox(width: isCompact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: isCompact ? 2 : 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyToLaunch(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: isSmallScreen ? 24 : 32,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          Text(
            'Ready to Launch! 🚀',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          Text(
            'Click "Finish" below to complete your setup and start your review collection journey!',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 16 : 20,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'You can always modify these settings later in your dashboard.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white.withOpacity(0.9),
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
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
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}