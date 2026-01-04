import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/risk_provider.dart';
import '../../../providers/weather_provider.dart';
import '../atoms/badge.dart';
import '../molecules/data_tile.dart';
import '../molecules/location_strip.dart';
import 'risk_gauge.dart';
import 'alert_overlay.dart';

/// Atomic Design: ORGANISM - Safety Dashboard
/// The main dashboard combining all elements
class SafetyDashboard extends ConsumerStatefulWidget {
  const SafetyDashboard({super.key});

  @override
  ConsumerState<SafetyDashboard> createState() => _SafetyDashboardState();
}

class _SafetyDashboardState extends ConsumerState<SafetyDashboard> {
  bool _alertDismissed = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    // Check permissions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    if (_permissionChecked) return;
    _permissionChecked = true;
    // Permission check is handled in RiskNotifier initialization
  }

  @override
  Widget build(BuildContext context) {
    final riskState = ref.watch(riskProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(riskState),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGaugeSection(riskState),
                        const SizedBox(height: 24),
                        _buildLocationStrip(riskState),
                        const SizedBox(height: 24),
                        _buildDataGrid(riskState, weatherAsync),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildAlertOverlay(riskState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RiskState riskState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StatusBadge(
            text: 'LIVE / HYDERABAD',
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

  Widget _buildGaugeSection(RiskState riskState) {
    return SizedBox(
      height: 260,
      child: Center(
        child: RiskGauge(risk: riskState.riskScore),
      ),
    );
  }

  Widget _buildLocationStrip(RiskState riskState) {
    return LocationStrip(
      location: riskState.currentLocation,
      risk: riskState.riskScore,
    );
  }

  Widget _buildDataGrid(RiskState riskState, AsyncValue<WeatherData> weatherAsync) {
    return Row(
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
    );
  }

  Widget _buildAlertOverlay(RiskState riskState) {
    final showAlert = riskState.riskScore >= 80 && !_alertDismissed;

    if (riskState.riskScore < 80) {
      _alertDismissed = false;
    }

    return AlertOverlay(
      isActive: showAlert,
      subtitle: _getAlertReason(riskState),
      onDismiss: () {
        setState(() {
          _alertDismissed = true;
        });
      },
    );
  }

  String _getAlertReason(RiskState riskState) {
    final reasons = <String>[];
    if (riskState.isRainyWeather) reasons.add('Heavy Rain');
    if (riskState.isBlackSpot) reasons.add('Black Spot');
    if (riskState.speed > 60) reasons.add('High Speed');
    return reasons.isEmpty ? 'High Risk Zone' : reasons.join(' • ');
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
