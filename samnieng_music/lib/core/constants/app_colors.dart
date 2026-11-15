import 'package:flutter/material.dart';

class AppColors {
  // Midnight-purple base with violet, aqua, and coral accents.
  static const Color background = Color(0xFF0B032D);
  static const Color surface = Color(0xFF150B3E);
  static const Color surfaceLight = Color(0xFF21134F);
  static const Color surfaceVariant = Color(0xFF2D1E5C);

  static const Color primary = Color(0xFF8058D5);
  static const Color secondary = Color(0xFF5BDAC6);
  static const Color accent = Color(0xFFFF7898);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCDC5E3);
  static const Color textMuted = Color(0xFF9B91B8);

  // Status & Feedback
  static const Color cardBg = surface;
  static const Color error = Color(0xFFFF6B7F);
  static const Color success = Color(0xFF5BDAC6);
  static const Color warning = Color(0xFFFFC66D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9A7AF0), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF2A1B5D), background],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navGradient = LinearGradient(
    colors: [Color(0xE60B032D), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
