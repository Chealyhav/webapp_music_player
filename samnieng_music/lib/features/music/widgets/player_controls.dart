import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_previous, color: AppColors.textPrimary),
          onPressed: onPrevious,
        ),
        const SizedBox(width: 16),
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: IconButton(
            iconSize: 48,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: onPlayPause,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_next, color: AppColors.textPrimary),
          onPressed: onNext,
        ),
      ],
    );
  }
}
