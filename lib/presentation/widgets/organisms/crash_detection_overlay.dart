import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CrashDetectionOverlay extends StatelessWidget {
  final bool isActive;
  final int countdownSeconds;
  final VoidCallback onCancel;

  const CrashDetectionOverlay({
    super.key,
    required this.isActive,
    required this.countdownSeconds,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCrashIcon(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildCountdown(),
              const SizedBox(height: 32),
              _buildMessage(),
              const SizedBox(height: 48),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrashIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.critical.withOpacity(0.2),
        border: Border.all(
          color: AppColors.critical,
          width: 3,
        ),
      ),
      child: Icon(
        Icons.emergency,
        size: 60,
        color: AppColors.critical,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 500.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.05, 1.05),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
        );
  }

  Widget _buildTitle() {
    return Text(
      'EMERGENCY ALERT',
      style: AppTextStyles.alertTitle.copyWith(
        fontSize: 24,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.critical, width: 4),
        gradient: AppColors.criticalGradient,
      ),
      child: Center(
        child: Text(
          countdownSeconds.toString(),
          style: AppTextStyles.riskValue.copyWith(fontSize: 56),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 500.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
        );
  }

  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'Emergency services will be contacted',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your location will be shared',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: onCancel,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 8,
      ),
      child: Text(
        'CANCEL ALERT',
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
