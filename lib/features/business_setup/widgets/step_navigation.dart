// lib/features/business_setup/widgets/step_navigation.dart

import 'package:flutter/material.dart';

class StepNavigation extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const StepNavigation({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    final isFirstStep = currentStep == 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: _buildNavigationContent(
                isSmallScreen, 
                isMediumScreen, 
                isFirstStep, 
                isLastStep
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationContent(
    bool isSmallScreen, 
    bool isMediumScreen, 
    bool isFirstStep, 
    bool isLastStep
  ) {
    if (isSmallScreen) {
      return _buildMobileNavigation(isFirstStep, isLastStep);
    } else {
      return _buildDesktopNavigation(isFirstStep, isLastStep, isMediumScreen);
    }
  }

  Widget _buildMobileNavigation(bool isFirstStep, bool isLastStep) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main action button (full width)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _buildNextButton(isLastStep, isCompact: true),
        ),
        
        // Back button (if not first step)
        if (!isFirstStep) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _buildBackButton(isCompact: true),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopNavigation(bool isFirstStep, bool isLastStep, bool isMediumScreen) {
    return Row(
      children: [
        // Back button
        if (!isFirstStep)
          Expanded(
            child: SizedBox(
              height: isMediumScreen ? 52 : 56,
              child: _buildBackButton(isCompact: false),
            ),
          )
        else
          const Expanded(child: SizedBox()),
        
        SizedBox(width: isMediumScreen ? 12 : 16),
        
        // Next/Finish button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: isMediumScreen ? 52 : 56,
            child: _buildNextButton(isLastStep, isCompact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton({required bool isCompact}) {
    return OutlinedButton.icon(
      onPressed: onPrevious,
      icon: Icon(
        Icons.arrow_back_rounded,
        size: isCompact ? 18 : 20,
      ),
      label: Text(
        'Back',
        style: TextStyle(
          fontSize: isCompact ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: isCompact ? 12 : 16,
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isLastStep, {required bool isCompact}) {
    return ElevatedButton.icon(
      onPressed: onNext,
      icon: Icon(
        isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
        size: isCompact ? 18 : 20,
      ),
      label: Text(
        isLastStep ? 'Finish Setup' : 'Continue',
        style: TextStyle(
          fontSize: isCompact ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLastStep 
            ? const Color(0xFF10B981) 
            : const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: isLastStep 
            ? const Color(0xFF10B981) 
            : const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32,
          vertical: isCompact ? 12 : 16,
        ),
      ).copyWith(
        elevation: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) {
            return 0;
          }
          return 2;
        }),
        shadowColor: MaterialStateProperty.all(
          (isLastStep 
              ? const Color(0xFF10B981) 
              : const Color(0xFF6366F1)).withOpacity(0.3),
        ),
      ),
    );
  }
}