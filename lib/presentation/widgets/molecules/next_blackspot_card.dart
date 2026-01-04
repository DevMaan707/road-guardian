import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/card_base.dart';

/// Atomic Design: MOLECULE - Next Black Spot Warning Card
/// Google Maps-style warning that appears when approaching danger zone
class NextBlackSpotCard extends StatelessWidget {
  final String spotName;
  final double distanceMeters;
  final VoidCallback? onTap;

  const NextBlackSpotCard({
    super.key,
    required this.spotName,
    required this.distanceMeters,
    this.onTap,
  });

  /// Only show if within 2km
  bool get shouldShow => distanceMeters <= 2000;

  String get _distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Color get _urgencyColor {
    if (distanceMeters < 300) return AppColors.critical;
    if (distanceMeters < 800) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _urgencyColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: _urgencyColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(child: _buildContent()),
            _buildDistance(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _urgencyColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.warning_amber_rounded,
        color: _urgencyColor,
        size: 28,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 800.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1, 1),
          duration: 800.ms,
        );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'APPROACHING BLACK SPOT',
          style: AppTextStyles.labelSmall.copyWith(
            color: _urgencyColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          spotName,
          style: AppTextStyles.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDistance() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _distanceText,
          style: AppTextStyles.dataLarge.copyWith(
            color: _urgencyColor,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ahead',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Compact version for minimal UI
class CompactBlackSpotIndicator extends StatelessWidget {
  final String spotName;
  final double distanceMeters;

  const CompactBlackSpotIndicator({
    super.key,
    required this.spotName,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    if (distanceMeters > 2000) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.critical.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${(distanceMeters / 1000).toStringAsFixed(1)}km',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
