import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Atomic Design: ORGANISM - Alert Overlay
/// Animated slide-up panel for high-risk alerts
class AlertOverlay extends StatelessWidget {
  final bool isActive;
  final String title;
  final String subtitle;
  final VoidCallback? onDismiss;

  const AlertOverlay({
    super.key,
    required this.isActive,
    this.title = 'High Severity Risk',
    this.subtitle = 'Heavy Rain • Black Spot',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      bottom: 0,
      left: 0,
      right: 0,
      height: isActive ? 350 : 0,
      child: GestureDetector(
        onTap: onDismiss,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 100) {
            onDismiss?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: AppColors.criticalGradient,
            border: Border(
              top: BorderSide(
                color: isActive ? AppColors.critical : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!isActive) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWarningIcon(),
          const SizedBox(height: 12),
          _buildTitle(),
          const SizedBox(height: 4),
          _buildSubtitle(),
          const SizedBox(height: 24),
          _buildDismissHint(),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 100.ms);
  }

  Widget _buildWarningIcon() {
    return const Text(
      '⚠️',
      style: TextStyle(
        fontSize: 56,
        shadows: [
          Shadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .rotate(
          begin: -0.02,
          end: 0.02,
          duration: 250.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .rotate(
          begin: 0.02,
          end: -0.02,
          duration: 250.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildTitle() {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.alertTitle,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      subtitle,
      style: AppTextStyles.alertSubtitle,
    );
  }

  Widget _buildDismissHint() {
    return Text(
      'Tap to dismiss',
      style: AppTextStyles.bodySmall.copyWith(
        color: Colors.white.withOpacity(0.6),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .fadeIn(duration: 800.ms)
        .then()
        .fadeOut(duration: 800.ms);
  }
}

/// Compact Alert Banner - For less intrusive alerts
class AlertBanner extends StatelessWidget {
  final bool isVisible;
  final String message;
  final Color color;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.isVisible,
    required this.message,
    this.color = AppColors.critical,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isVisible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
