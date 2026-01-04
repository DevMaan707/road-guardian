import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/risk_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/services_provider.dart';
import '../../../services/black_spot_service.dart';
import '../atoms/badge.dart';
import '../molecules/data_tile.dart';
import '../molecules/next_blackspot_card.dart';
import '../molecules/driver_behavior_indicator.dart';
import 'risk_gauge.dart';
import 'safety_navigation_map.dart';
import 'crash_detection_overlay.dart';
import 'hazard_report_button.dart';
import 'alert_overlay.dart';

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
  BlackSpot? _nextBlackSpot;
  Position? _currentPosition;
  bool _alertDismissed = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupVoiceAlerts();
    });
  }

  void _setupVoiceAlerts() {
    final riskState = ref.read(riskProvider);
    final voiceService = ref.read(voiceAssistantProvider);
    
    if (riskState.isHighRisk && !_alertDismissed) {
      voiceService.announceHighRisk(riskState.riskScore.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskState = ref.watch(riskProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final telematicsState = ref.watch(telematicsProvider);
    final crashState = ref.watch(crashDetectionProvider);
    final hazardService = ref.watch(hazardReportingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // LAYER 1: 3D Navigation Map
          SafetyNavigationMap(
            mapboxAccessToken: widget.mapboxAccessToken,
            onNextBlackSpotUpdate: (name, distance, spot) {
              setState(() {
                _nextSpotName = name;
                _nextSpotDistance = distance;
                _nextBlackSpot = spot;
              });
              
              if (distance < 500 && spot != null) {
                final voiceService = ref.read(voiceAssistantProvider);
                voiceService.announceRisk(name, distance, spot.getSeverityScore());
              }
            },
          ),

          // LAYER 2: HUD Overlay
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildTopRiskGauge(riskState),
                const Spacer(),
                if (telematicsState.isTracking)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // child: DriverBehaviorIndicator(
                    //   driverScore: telematicsState.driverScore.toDouble(),
                    //   harshBrakingCount: telematicsState.harshBrakingCount,
                    //   rapidAccelerationCount: telematicsState.rapidAccelerationCount,
                    //   hardCorneringCount: telematicsState.hardCorneringCount,
                    // ),
                  ),
                const SizedBox(height: 12),
                _buildNextBlackSpotCard(),
                const SizedBox(height: 12),
                _buildTelemetryGrid(riskState, weatherAsync),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // LAYER 3: Hazard Report Button
          Positioned(
            bottom: 240,
            right: 20,
            child: HazardReportButton(
              onPressed: () => _showHazardReportDialog(context, hazardService),
            ),
          ),

          // LAYER 4: High Risk Alert Overlay
          if (riskState.isHighRisk && !_alertDismissed)
            AlertOverlay(
              isActive: true,
              title: 'High Risk Zone',
              subtitle: _getAlertReason(riskState),
              onDismiss: () {
                setState(() {
                  _alertDismissed = true;
                });
              },
            ),

          // LAYER 5: Crash Detection Overlay
          CrashDetectionOverlay(
            isActive: crashState.countdownActive,
            countdownSeconds: crashState.countdownSeconds,
            onCancel: () {
              crashState.cancelEmergency();
            },
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

  Widget _buildTopRiskGauge(RiskState riskState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.getRiskColor(riskState.riskScore).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY SCORE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRiskLevel(riskState.riskScore),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.getRiskColor(riskState.riskScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            MiniRiskGauge(
              risk: riskState.riskScore,
              size: 70,
            ),
          ],
        ),
      ),
    );
  }

  String _getRiskLevel(double score) {
    if (score >= 80) return 'HIGH RISK';
    if (score >= 40) return 'MODERATE';
    return 'LOW RISK';
  }

  String _getAlertReason(RiskState riskState) {
    final reasons = <String>[];
    if (riskState.isRainyWeather) reasons.add('Heavy Rain');
    if (riskState.isBlackSpot) reasons.add('Black Spot');
    if (riskState.speed > 60) reasons.add('High Speed');
    return reasons.isEmpty ? 'High Risk Zone' : reasons.join(' • ');
  }

  void _showHazardReportDialog(BuildContext context, hazardService) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => HazardReportDialog(
          hazardService: hazardService,
          currentPosition: position,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get location: $e'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  Widget _buildNextBlackSpotCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _nextBlackSpot != null 
              ? AppColors.getRiskColor(_nextBlackSpot!.getSeverityScore().toDouble())
              : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.place,
                  color: _nextBlackSpot != null 
                    ? AppColors.getRiskColor(_nextBlackSpot!.getSeverityScore().toDouble())
                    : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nextSpotName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_nextBlackSpot != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.getRiskColor(_nextBlackSpot!.getSeverityScore().toDouble()).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _nextBlackSpot!.severity.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.getRiskColor(_nextBlackSpot!.getSeverityScore().toDouble()),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${(_nextSpotDistance / 1000).toStringAsFixed(2)} km',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_nextBlackSpot != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.warning, size: 16, color: AppColors.critical),
                  const SizedBox(width: 4),
                  Text(
                    '${_nextBlackSpot!.accidentCount} accidents',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
