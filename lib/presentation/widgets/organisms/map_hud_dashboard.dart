import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/risk_provider.dart';
import '../../../providers/weather_provider.dart';
import '../atoms/badge.dart';
import '../molecules/data_tile.dart';
import '../molecules/next_blackspot_card.dart';
import 'risk_gauge.dart';
import 'safety_navigation_map.dart';

/// Atomic Design: ORGANISM - Map HUD Dashboard
/// Main dashboard with 3D map background and floating HUD elements
class MapHudDashboard extends ConsumerStatefulWidget {
  final String mapboxAccessToken;

  const MapHudDashboard({
    super.key,
    required this.mapboxAccessToken,
  });

  @override
  ConsumerState<MapHudDashboard> createState() => _MapHudDashboardState();
}

class _MapHudDashboardState extends ConsumerState<MapHudDashboard> {
  String _nextSpotName = "Scanning...";
  double _nextSpotDistance = 0;

  @override
  Widget build(BuildContext context) {
    final riskState = ref.watch(riskProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // LAYER 1: 3D Navigation Map
          SafetyNavigationMap(
            mapboxAccessToken: widget.mapboxAccessToken,
            onNextBlackSpotUpdate: (name, distance) {
              setState(() {
                _nextSpotName = name;
                _nextSpotDistance = distance;
              });
            },
          ),

          // LAYER 2: HUD Overlay
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                if (riskState.isHighRisk) _buildCenterRiskGauge(riskState),
                const Spacer(),
                _buildNextBlackSpotCard(),
                const SizedBox(height: 12),
                _buildTelemetryGrid(riskState, weatherAsync),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StatusBadge(
            text: 'LIVE / NAVIGATION',
            color: AppColors.success,
          ),
          Text(
            _formatTime(),
            style: AppTextStyles.dataMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterRiskGauge(RiskState riskState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.getRiskColor(riskState.riskScore),
          width: 2,
        ),
      ),
      child: MiniRiskGauge(
        risk: riskState.riskScore,
        size: 100,
      ),
    );
  }

  Widget _buildNextBlackSpotCard() {
    return NextBlackSpotCard(
      spotName: _nextSpotName,
      distanceMeters: _nextSpotDistance,
    );
  }

  Widget _buildTelemetryGrid(
    RiskState riskState,
    AsyncValue<WeatherData> weatherAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: weatherAsync.when(
              data: (weather) => WeatherTile(
                condition: weather.condition,
                temperature: weather.temperature,
                icon: weather.icon,
              ),
              loading: () => const DataTile(
                label: 'Weather',
                value: 'Loading',
                emoji: '☁️',
                accentColor: Color(0xFF6366F1),
              ),
              error: (_, __) => const DataTile(
                label: 'Weather',
                value: 'Error',
                emoji: '❌',
                accentColor: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SpeedTile(speed: riskState.speed),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
