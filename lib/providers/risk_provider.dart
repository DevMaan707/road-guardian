import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_provider.dart';
import '../services/onnx_model_service.dart';
import '../services/location_service.dart';

/// Risk State Model
class RiskState {
  final double riskScore;
  final int speed;
  final String currentLocation;
  final double latitude;
  final double longitude;
  final bool isRainyWeather;
  final bool isBlackSpot;
  final DateTime timestamp;

  RiskState({
    required this.riskScore,
    required this.speed,
    required this.currentLocation,
    required this.latitude,
    required this.longitude,
    this.isRainyWeather = false,
    this.isBlackSpot = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RiskState.initial() {
    return RiskState(
      riskScore: 0,
      speed: 0,
      currentLocation: 'Initializing...',
      latitude: 17.3850,
      longitude: 78.4867,
    );
  }

  RiskState copyWith({
    double? riskScore,
    int? speed,
    String? currentLocation,
    double? latitude,
    double? longitude,
    bool? isRainyWeather,
    bool? isBlackSpot,
  }) {
    return RiskState(
      riskScore: riskScore ?? this.riskScore,
      speed: speed ?? this.speed,
      currentLocation: currentLocation ?? this.currentLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isRainyWeather: isRainyWeather ?? this.isRainyWeather,
      isBlackSpot: isBlackSpot ?? this.isBlackSpot,
    );
  }

  bool get isHighRisk => riskScore >= 80;
  bool get isModerateRisk => riskScore >= 40 && riskScore < 80;
  bool get isLowRisk => riskScore < 40;
}

/// Telemetry Data for ONNX model input
class TelemetryData {
  final int accusedType;
  final int victimType;
  final int policeStation;
  final int hour;
  final int dayOfWeek;
  final int month;
  final double latitude;
  final double longitude;
  final int weatherCode;
  final int speed;

  TelemetryData({
    required this.accusedType,
    required this.victimType,
    required this.policeStation,
    required this.hour,
    required this.dayOfWeek,
    required this.month,
    required this.latitude,
    required this.longitude,
    required this.weatherCode,
    required this.speed,
  });

  List<double> toInputVector() {
    return [
      accusedType.toDouble(),
      victimType.toDouble(),
      policeStation.toDouble(),
      hour.toDouble(),
      dayOfWeek.toDouble(),
      month.toDouble(),
      latitude,
      longitude,
      weatherCode.toDouble(),
      speed.toDouble(),
    ];
  }
}

/// Risk Notifier with real GPS location and ONNX model predictions
class RiskNotifier extends StateNotifier<RiskState> {
  final Ref ref;
  Timer? _updateTimer;
  OnnxModelService? _onnxService;
  LocationService? _locationService;
  Position? _lastPosition;

  RiskNotifier(this.ref) : super(RiskState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize ONNX model
    try {
      _onnxService = OnnxModelService();
      await _onnxService!.initialize();
      print('ONNX Model initialized successfully');
    } catch (e) {
      print('ONNX initialization failed: $e');
      _onnxService = null;
    }

    // Initialize location service
    _locationService = LocationService();
    await _startLocationTracking();

    // Start periodic risk updates
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _updateRiskScore(),
    );
  }

  Future<void> _startLocationTracking() async {
    try {
      await _locationService!.startTracking((Position position) {
        _lastPosition = position;
        _updateRiskScore();
      });
    } catch (e) {
      print('Failed to start location tracking: $e');
      // Use default Hyderabad location
      state = state.copyWith(
        currentLocation: 'Location unavailable',
        latitude: 17.3850,
        longitude: 78.4867,
      );
    }
  }

  Future<void> _updateRiskScore() async {
    if (_lastPosition == null) return;

    // Get current position data
    final latitude = _lastPosition!.latitude;
    final longitude = _lastPosition!.longitude;
    final speed = (_lastPosition!.speed * 3.6).clamp(0, 200).toInt(); // m/s to km/h

    // Get weather data
    WeatherData? weather;
    try {
      weather = await ref.read(weatherProvider.future);
    } catch (_) {
      weather = null;
    }

    // Check if near a black spot
    final blackSpot = BlackSpotDatabase.getNearestBlackSpot(latitude, longitude);
    final isBlackSpot = blackSpot != null;
    final policeStation = BlackSpotDatabase.getPoliceStationForLocation(latitude, longitude);

    // Get location name
    String locationName;
    if (blackSpot != null) {
      locationName = '${blackSpot['name']} (${blackSpot['distance'].toInt()}m)';
    } else {
      locationName = 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }

    // Prepare telemetry data for ONNX model
    final now = DateTime.now();
    final telemetry = TelemetryData(
      accusedType: 0, // Car (default assumption)
      victimType: 3, // Two Wheeler (most vulnerable)
      policeStation: policeStation,
      hour: now.hour,
      dayOfWeek: now.weekday,
      month: now.month,
      latitude: latitude,
      longitude: longitude,
      weatherCode: weather?.weatherCode ?? 0,
      speed: speed,
    );

    // Calculate risk score using ONNX model
    double riskScore;
    if (_onnxService != null && _onnxService!.isInitialized) {
      riskScore = await _onnxService!.predictRisk(telemetry);
      print('ONNX prediction: $riskScore');
    } else {
      // Fallback: use rule-based calculation
      riskScore = _calculateRuleBasedRisk(telemetry, weather, isBlackSpot);
      print('Rule-based prediction: $riskScore');
    }

    // Update state
    state = state.copyWith(
      riskScore: riskScore,
      speed: speed,
      currentLocation: locationName,
      latitude: latitude,
      longitude: longitude,
      isRainyWeather: weather?.isRainy ?? false,
      isBlackSpot: isBlackSpot,
    );
  }

  double _calculateRuleBasedRisk(
    TelemetryData telemetry,
    WeatherData? weather,
    bool isBlackSpot,
  ) {
    double baseRisk = 15;

    // Weather factor
    if (weather != null) {
      if (weather.isRainy) baseRisk += 30;
      if (weather.isSevere) baseRisk += 20;
    }

    // Black spot factor
    if (isBlackSpot) {
      baseRisk += 35;
    }

    // Speed factor
    if (telemetry.speed > 60) baseRisk += 15;
    if (telemetry.speed > 80) baseRisk += 10;

    // Time factor (late night/early morning is riskier)
    if (telemetry.hour >= 22 || telemetry.hour <= 5) {
      baseRisk += 10;
    }

    // Peak hour traffic
    if ((telemetry.hour >= 8 && telemetry.hour <= 10) ||
        (telemetry.hour >= 17 && telemetry.hour <= 20)) {
      baseRisk += 8;
    }

    return baseRisk.clamp(0, 100);
  }

  void manualRefresh() {
    _updateRiskScore();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _locationService?.dispose();
    _onnxService?.dispose();
    super.dispose();
  }
}

/// Risk Provider
final riskProvider = StateNotifierProvider<RiskNotifier, RiskState>((ref) {
  return RiskNotifier(ref);
});

/// Derived providers for specific data
final currentRiskScoreProvider = Provider<double>((ref) {
  return ref.watch(riskProvider).riskScore;
});

final isHighRiskProvider = Provider<bool>((ref) {
  return ref.watch(riskProvider).isHighRisk;
});

final currentSpeedProvider = Provider<int>((ref) {
  return ref.watch(riskProvider).speed;
});

final currentLocationProvider = Provider<String>((ref) {
  return ref.watch(riskProvider).currentLocation;
});
