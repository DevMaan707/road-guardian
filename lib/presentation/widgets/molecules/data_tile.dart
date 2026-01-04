import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/card_base.dart';

/// Atomic Design: MOLECULE - Data Tile
/// Combines CardBase with label, value, unit, and icon display
class DataTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? emoji;
  final String? secondaryValue;
  final Color? accentColor;
  final bool animateValue;

  const DataTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.emoji,
    this.secondaryValue,
    this.accentColor,
    this.animateValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return HudCard(
      accentColor: accentColor,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel(),
              _buildValueGroup(),
            ],
          ),
          if (emoji != null) _buildEmoji(),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelMedium,
        ),
        if (secondaryValue != null)
          Text(
            secondaryValue!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildValueGroup() {
    Widget valueWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: AppTextStyles.cardValue),
        if (unit != null) ...[
          const SizedBox(width: 4),
          Text(unit!, style: AppTextStyles.cardUnit),
        ],
      ],
    );

    if (animateValue) {
      return valueWidget.animate().fadeIn(duration: 300.ms);
    }
    return valueWidget;
  }

  Widget _buildEmoji() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Text(
        emoji!,
        style: const TextStyle(fontSize: 24),
      ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}

/// Weather Tile - Specialized data tile for weather display
class WeatherTile extends StatelessWidget {
  final String condition;
  final double temperature;
  final String icon;

  const WeatherTile({
    super.key,
    required this.condition,
    required this.temperature,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DataTile(
      label: 'Weather',
      value: condition,
      secondaryValue: '${temperature.toStringAsFixed(0)}°C',
      emoji: icon,
      accentColor: const Color(0xFF6366F1),
      animateValue: true,
    );
  }
}

/// Speed Tile - Specialized data tile for speed display
class SpeedTile extends StatelessWidget {
  final int speed;

  const SpeedTile({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return DataTile(
      label: 'Speed',
      value: speed.toString(),
      unit: 'km/h',
      animateValue: true,
    );
  }
}
