import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atomic Design: ATOM - Card Base
/// The foundational surface card used throughout the app
class CardBase extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final Color? backgroundColor;

  const CardBase({
    super.key,
    required this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.padding,
    this.height,
    this.width,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// HUD Card - Specialized card for dashboard metrics
class HudCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double height;

  const HudCard({
    super.key,
    required this.child,
    this.accentColor,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CardBase(
      height: height,
      borderColor: accentColor?.withOpacity(0.3),
      child: child,
    );
  }
}

/// Location Card - Card with colored left border indicator
class LocationCard extends StatelessWidget {
  final Widget child;
  final Color indicatorColor;

  const LocationCard({
    super.key,
    required this.child,
    this.indicatorColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 60,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
