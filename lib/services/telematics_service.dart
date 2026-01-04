import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class DrivingBehavior {
  final String type;
  final double severity;
  final DateTime timestamp;
  final String description;

  DrivingBehavior({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.description,
  });
}

class TelematicsService extends ChangeNotifier {
  // Production-grade configuration
  static const double MIN_DRIVING_SPEED = 15.0; // km/h - Ignore sensors below this
  static const double BRAKING_THRESHOLD = -2.5; // m/s² (Hard Stop)
  static const double ACCEL_THRESHOLD = 3.5;    // m/s² (Flooring it)
  static const double TURN_THRESHOLD = 2.0;     // m/s² (Hard Corner)
  static const double NOISE_FILTER = 0.15;      // Low-pass filter alpha (0.1 = smooth, 1.0 = raw)

  bool _isTracking = false;
  int _driverScore = 100;
  int _harshBrakingCount = 0;
  int _rapidAccelerationCount = 0;
  int _hardCorneringCount = 0;

  // Filtered state
  double _currentSpeed = 0.0; // km/h from GPS
  double _filteredX = 0.0;    // Smoothed X axis (lateral)
  double _filteredY = 0.0;    // Smoothed Y axis (longitudinal)

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;

  DateTime _lastEventTime = DateTime.now();

  bool get isTracking => _isTracking;
  int get driverScore => _driverScore;
  int get harshBrakingCount => _harshBrakingCount;
  int get rapidAccelerationCount => _rapidAccelerationCount;
  int get hardCorneringCount => _hardCorneringCount;
  double get currentSpeed => _currentSpeed;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    debugPrint('📊 Production Telematics System Started - Waiting for movement...');

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      // Filter out poor GPS signals (indoors usually > 20m accuracy)
      if (position.accuracy > 20) return;

      // Convert m/s to km/h
      double rawSpeed = position.speed * 3.6;
      
      // Simple debounce for GPS drift
      if (rawSpeed < 3.0) rawSpeed = 0;
      
      _currentSpeed = rawSpeed;
      
      if (_currentSpeed >= MIN_DRIVING_SPEED) {
        debugPrint('🚗 Vehicle moving at ${_currentSpeed.toStringAsFixed(1)} km/h - Telematics ACTIVE');
      }
    });

    _sensorSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // CRITICAL: If we are sitting at home (Speed < 15), ignore everything
      if (_currentSpeed < MIN_DRIVING_SPEED) {
        return;
      }

      // Low-pass filter to smooth out noise
      // New = (Alpha * Raw) + ((1 - Alpha) * Old)
      _filteredX = (NOISE_FILTER * event.x) + ((1 - NOISE_FILTER) * _filteredX);
      _filteredY = (NOISE_FILTER * event.y) + ((1 - NOISE_FILTER) * _filteredY);

      // Analyze the filtered physics
      _analyzePhysics(_filteredX, _filteredY);
    });

    notifyListeners();
  }

  void stopTracking() {
    _gpsSubscription?.cancel();
    _sensorSubscription?.cancel();
    _isTracking = false;
    debugPrint('📊 Telematics tracking stopped');
    notifyListeners();
  }

  void _analyzePhysics(double x, double y) {
    // NOTE: Assumes phone is mounted VERTICALLY (Portrait)
    // Y-axis = Acceleration/Braking (forward/backward)
    // X-axis = Turning (left/right)

    // Detect Braking (Negative Y)
    if (y < BRAKING_THRESHOLD) {
      _recordHarshBraking();
    }

    // Detect Hard Acceleration (Positive Y)
    if (y > ACCEL_THRESHOLD) {
      _recordRapidAcceleration();
    }

    // Detect Hard Turns (Absolute X)
    if (x.abs() > TURN_THRESHOLD) {
      _recordHardCornering();
    }
  }

  void _recordHarshBraking() {
    if (!_shouldTriggerEvent()) return;

    _harshBrakingCount++;
    _driverScore = max(0, _driverScore - 5);
    debugPrint('🛑 HARSH BRAKING @ ${_currentSpeed.toStringAsFixed(1)} km/h | Score: $_driverScore');
    _lastEventTime = DateTime.now();
    notifyListeners();
  }

  void _recordRapidAcceleration() {
    if (!_shouldTriggerEvent()) return;

    _rapidAccelerationCount++;
    _driverScore = max(0, _driverScore - 3);
    debugPrint('⚡ RAPID ACCELERATION @ ${_currentSpeed.toStringAsFixed(1)} km/h | Score: $_driverScore');
    _lastEventTime = DateTime.now();
    notifyListeners();
  }

  void _recordHardCornering() {
    if (!_shouldTriggerEvent()) return;

    _hardCorneringCount++;
    _driverScore = max(0, _driverScore - 4);
    debugPrint('↪️ HARD CORNERING @ ${_currentSpeed.toStringAsFixed(1)} km/h | Score: $_driverScore');
    _lastEventTime = DateTime.now();
    notifyListeners();
  }

  // Debounce events - don't spam 50 times per second
  bool _shouldTriggerEvent() {
    return DateTime.now().difference(_lastEventTime).inSeconds >= 2;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
