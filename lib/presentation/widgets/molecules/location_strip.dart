import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/card_base.dart';

/// Atomic Design: MOLECULE - Location Strip
/// Displays current location with a colored indicator based on risk level
class LocationStrip extends StatelessWidget {
  final String location;
  final double risk;
  final VoidCallback? onTap;

  const LocationStrip({
    super.key,
    required this.location,
    this.risk = 0,
    this.onTap,
  });

  Color get _indicatorColor => AppColors.getRiskColor(risk);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: LocationCard(
          indicatorColor: _indicatorColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLocationInfo(),
              _buildIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CURRENT LOCATION',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 2),
        Text(
          location,
          style: AppTextStyles.bodyLarge,
        )
            .animate(
              key: ValueKey(location),
            )
            .fadeIn(duration: 200.ms)
            .slideX(begin: -0.1, end: 0, duration: 200.ms),
      ],
    );
  }

  Widget _buildIcon() {
    return const Text(
      '📍',
      style: TextStyle(fontSize: 18),
    );
  }
}

/// Coordinates Strip - Shows lat/lng coordinates
class CoordinatesStrip extends StatelessWidget {
  final double latitude;
  final double longitude;

  const CoordinatesStrip({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return CardBase(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gps_fixed,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'GPS',
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
          Text(
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            style: AppTextStyles.dataMedium,
          ),
        ],
      ),
    );
  }
}
