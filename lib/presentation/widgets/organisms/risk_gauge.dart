import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Atomic Design: ORGANISM - Risk Gauge
/// Circular progress indicator with animated risk display
class RiskGauge extends StatefulWidget {
  final double risk;
  final double size;

  const RiskGauge({
    super.key,
    required this.risk,
    this.size = 240,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.risk != widget.risk) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    if (widget.risk >= 80) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _gaugeColor => AppColors.getRiskColor(widget.risk);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildGaugeRing(),
          _buildReadout(),
        ],
      ),
    );
  }

  Widget _buildGaugeRing() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = widget.risk >= 80 ? _pulseController.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GaugePainter(
            progress: widget.risk / 100,
            color: _gaugeColor,
            glowIntensity: 0.3 + (pulseValue * 0.4),
          ),
        );
      },
    );
  }

  Widget _buildReadout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.risk),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              value.toInt().toString(),
              style: AppTextStyles.riskValue.copyWith(
                color: _gaugeColor,
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          'SAFETY SCORE',
          style: AppTextStyles.riskLabel,
        ),
      ],
    )
        .animate(
          target: widget.risk >= 80 ? 1 : 0,
        )
        .shake(
          hz: 4,
          rotation: 0.02,
          duration: 500.ms,
        );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;

  _GaugePainter({
    required this.progress,
    required this.color,
    this.glowIntensity = 0.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 40) / 2;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring with glow
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2;

      // Draw glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

/// Mini Risk Gauge - Compact version for smaller spaces
class MiniRiskGauge extends StatelessWidget {
  final double risk;
  final double size;

  const MiniRiskGauge({
    super.key,
    required this.risk,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              progress: risk / 100,
              color: AppColors.getRiskColor(risk),
            ),
          ),
          Text(
            risk.toInt().toString(),
            style: AppTextStyles.dataLarge.copyWith(
              fontSize: size * 0.3,
              color: AppColors.getRiskColor(risk),
            ),
          ),
        ],
      ),
    );
  }
}
