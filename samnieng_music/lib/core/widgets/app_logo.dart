import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 140,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: size * 0.3,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: Icon(
            Icons.music_note_rounded,
            size: size * 0.6,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'Samnieng Music',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: size * 0.05),
          Text(
            'Your Music · Anytime · Anywhere',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: size * 0.1,
              letterSpacing: 1,
            ),
          ),
        ]
      ],
    );
  }
}
