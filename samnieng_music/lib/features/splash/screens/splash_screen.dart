import 'package:flutter/material.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/core/widgets/app_button.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const SplashScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // App name
              const Text(
                'Samnieng Music',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Music · Anytime · Anywhere',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(flex: 3),
              // Buttons
              AppButton(
                text: 'Get Started',
                onPressed: onGetStarted,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Log In',
                isOutlined: true,
                onPressed: onGetStarted,
              ),
              const SizedBox(height: 32),
              // Social login
              const Text(
                'or continue with',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(Icons.g_mobiledata_rounded),
                  const SizedBox(width: 16),
                  _socialButton(Icons.facebook_rounded),
                  const SizedBox(width: 16),
                  _socialButton(Icons.apple_rounded),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 24),
    );
  }
}
