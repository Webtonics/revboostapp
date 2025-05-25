// lib/features/business_setup/widgets/business_info_step.dart

import 'package:flutter/material.dart';

class BusinessInfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;
  final AnimationController contentController;

  const BusinessInfoStep({
    Key? key,
    required this.nameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
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
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 108, vertical: isSmallScreen ? 16 : 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business name field
                  _AnimatedFormField(
                    controller: nameController,
                    label: 'Business Name',
                    hint: 'e.g., Joe\'s Coffee Shop',
                    icon: Icons.storefront_rounded,
                    delay: 100,
                    required: true,
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Business description field
                  _AnimatedFormField(
                    controller: descriptionController,
                    label: 'Business Description',
                    hint: 'Tell your customers what makes your business special...',
                    icon: Icons.description_rounded,
                    maxLines: isSmallScreen ? 3 : 4,
                    delay: 200,
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Business category dropdown
                  _AnimatedDropdown(
                    label: 'Business Category',
                    hint: 'Select your business type',
                    icon: Icons.category_rounded,
                    items: const [
                      'Restaurant or Café',
                      'Home Services',
                      'Retail Store',
                      'Service Business',
                      'Professional Services',
                      'Healthcare',
                      'Beauty & Wellness',
                      'Automotive',
                      'Entertainment',
                      'Education',
                      'Other',
                    ],
                    value: selectedCategory,
                    onChanged: onCategoryChanged,
                    delay: 300,
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  // Pro tips section
                  _AnimatedWidget(
                    delay: 400,
                    child: _buildProTipsCard(isSmallScreen, isMediumScreen),
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

  Widget _buildProTipsCard(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.08),
            const Color(0xFF8B5CF6).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: const Color(0xFF3B82F6),
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 20,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          if (isSmallScreen)
            _buildMobileTips()
          else
            _buildDesktopTips(isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildMobileTips() {
    return Column(
      children: [
        _buildTipItem(
          '📝',
          'Use a clear, memorable business name',
          'Make it easy for customers to find and remember you',
          isCompact: true,
        ),
        const SizedBox(height: 12),
        _buildTipItem(
          '✨',
          'Highlight what makes you unique',
          'Share your unique value proposition in the description',
          isCompact: true,
        ),
        const SizedBox(height: 12),
        _buildTipItem(
          '🎯',
          'Choose the most specific category',
          'This helps us customize your review experience',
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildDesktopTips(bool isMediumScreen) {
    return Column(
      children: [
        _buildTipItem(
          '📝',
          'Use a clear, memorable business name',
          'Make it easy for customers to find and remember you',
          isCompact: false,
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          '✨',
          'Highlight what makes you unique',
          'Share your unique value proposition in the description',
          isCompact: false,
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          '🎯',
          'Choose the most specific category',
          'This helps us customize your review experience',
          isCompact: false,
        ),
      ],
    );
  }

  Widget _buildTipItem(String emoji, String title, String subtitle, {required bool isCompact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: isCompact ? 16 : 20)),
        SizedBox(width: isCompact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 14 : 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: isCompact ? 2 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final int delay;
  final bool required;
  final bool isSmallScreen;

  const _AnimatedFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.delay = 0,
    this.required = false,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedWidget(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: maxLines > 1 
                      ? (isSmallScreen ? 16 : 20) 
                      : (isSmallScreen ? 12 : 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final int delay;
  final bool isSmallScreen;

  const _AnimatedDropdown({
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    this.delay = 0,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedWidget(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF64748B),
                size: isSmallScreen ? 20 : 24,
              ),
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