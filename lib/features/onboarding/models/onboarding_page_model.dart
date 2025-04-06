// lib/features/onboarding/models/onboarding_page_model.dart

import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final String lottieAsset;
  final Color backgroundColor;
  final Color textColor;
  
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.lottieAsset,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
  });
}