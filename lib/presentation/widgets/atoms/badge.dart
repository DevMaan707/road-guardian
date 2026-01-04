import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Atomic Design: ATOM - Status Badge
/// A small pill-shaped badge with an optional pulsing dot indicator
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool showDot;
  final bool animate;

  const StatusBadge({
    super.key,
    required this.text,
    this.color = AppColors.success,
    this.showDot = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _buildDot(),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTextStyles.dataSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    Widget dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    if (animate) {
      return dot
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 1000.ms)
          .then()
          .fadeOut(duration: 1000.ms);
    }
    return dot;
  }
}

/// Risk Badge - Shows risk level with appropriate color
class RiskBadge extends StatelessWidget {
  final double risk;

  const RiskBadge({super.key, required this.risk});

  String get _label {
    if (risk < 40) return 'LOW RISK';
    if (risk < 80) return 'MODERATE';
    return 'HIGH RISK';
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: _label,
      color: AppColors.getRiskColor(risk),
      showDot: risk >= 80,
      animate: risk >= 80,
    );
  }
}
