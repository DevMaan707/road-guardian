import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DriverBehaviorIndicator extends StatelessWidget {
  final double driverScore;
  final int harshBrakingCount;
  final int rapidAccelerationCount;
  final int hardCorneringCount;

  const DriverBehaviorIndicator({
    super.key,
    required this.driverScore,
    required this.harshBrakingCount,
    required this.rapidAccelerationCount,
    required this.hardCorneringCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getScoreColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildBehaviorStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getScoreColor().withOpacity(0.2),
          ),
          child: Icon(
            Icons.drive_eta,
            color: _getScoreColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Score',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                driverScore.toInt().toString(),
                style: AppTextStyles.dataLarge.copyWith(
                  fontSize: 24,
                  color: _getScoreColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildScoreIndicator(),
      ],
    );
  }

  Widget _buildScoreIndicator() {
    IconData icon;
    if (driverScore >= 90) {
      icon = Icons.check_circle;
    } else if (driverScore >= 70) {
      icon = Icons.warning_amber;
    } else {
      icon = Icons.error;
    }

    return Icon(
      icon,
      color: _getScoreColor(),
      size: 32,
    );
  }

  Widget _buildBehaviorStats() {
    return Row(
      children: [
        _buildStatChip('🛑', harshBrakingCount, 'Braking'),
        const SizedBox(width: 8),
        _buildStatChip('⚡', rapidAccelerationCount, 'Accel'),
        const SizedBox(width: 8),
        _buildStatChip('↪️', hardCorneringCount, 'Turns'),
      ],
    );
  }

  Widget _buildStatChip(String emoji, int count, String label) {
    IconData icon;
    if (label == 'Braking') {
      icon = Icons.speed;
    } else if (label == 'Accel') {
      icon = Icons.rocket_launch;
    } else {
      icon = Icons.turn_right;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: count > 5 ? AppColors.warning : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor() {
    if (driverScore >= 90) return AppColors.success;
    if (driverScore >= 70) return AppColors.warning;
    return AppColors.critical;
  }
}
