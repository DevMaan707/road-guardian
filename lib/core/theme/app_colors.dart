import 'package:flutter/material.dart';

/// Atomic Design: ATOMS - Color Constants
/// Cyberpunk/Automotive HUD Theme - Dark Mode Only
class AppColors {
  AppColors._();

  // Base Colors
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF121214);
  static const Color surfaceBorder = Color(0xFF2A2A2D);

  // Accent Colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient criticalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00EF4444),
      Color(0x1AEF4444),
      Color(0xF2EF4444),
    ],
    stops: [0.0, 0.2, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xF2121214),
      Color(0x00121214),
    ],
  );

  // Glow Effects
  static BoxShadow primaryGlow({double opacity = 0.3}) => BoxShadow(
        color: primary.withOpacity(opacity),
        blurRadius: 8,
        spreadRadius: 0,
      );

  static BoxShadow criticalGlow({double opacity = 0.5}) => BoxShadow(
        color: critical.withOpacity(opacity),
        blurRadius: 12,
        spreadRadius: 0,
      );

  // Risk-based color helper
  static Color getRiskColor(double risk) {
    if (risk < 40) return success;
    if (risk < 80) return warning;
    return critical;
  }
}
