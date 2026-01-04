import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class CrashDetectionService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  bool _isMonitoring = false;
  bool _crashDetected = false;
  bool _countdownActive = false;
  int _countdownSeconds = 10;
  Timer? _countdownTimer;
  Timer? _movementCheckTimer;
  
  Position? _crashLocation;
  DateTime? _crashTime;
  double _crashGForce = 0.0;
  
  bool _hasMovedAfterImpact = false;
  AccelerometerEvent? _lastReading;

  bool get isMonitoring => _isMonitoring;
  bool get crashDetected => _crashDetected;
  bool get countdownActive => _countdownActive;
  int get countdownSeconds => _countdownSeconds;
  Position? get crashLocation => _crashLocation;
  DateTime? get crashTime => _crashTime;
  double get crashGForce => _crashGForce;

  static const double crashThresholdGForce = 25.0;
  static const double movementThreshold = 2.0;
  
  DateTime? _lastCrashCheck;
  static const Duration crashCooldown = Duration(seconds: 30);

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _checkForCrash(event);
        _lastReading = event;
      },
    );

    notifyListeners();
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _countdownTimer?.cancel();
    _movementCheckTimer?.cancel();
    _isMonitoring = false;
    notifyListeners();
  }

  void _checkForCrash(AccelerometerEvent event) {
    if (_crashDetected) return;
    
    final now = DateTime.now();
    if (_lastCrashCheck != null && now.difference(_lastCrashCheck!) < crashCooldown) {
      return;
    }

    final totalGForce = _calculateTotalGForce(event);

    if (totalGForce >= crashThresholdGForce) {
      _lastCrashCheck = now;
      _onCrashDetected(totalGForce);
    }
  }

  double _calculateTotalGForce(AccelerometerEvent event) {
    return (event.x * event.x + event.y * event.y + event.z * event.z);
  }

  void _onCrashDetected(double gForce) {
    _crashDetected = true;
    _crashGForce = gForce;
    _crashTime = DateTime.now();
    _hasMovedAfterImpact = false;

    debugPrint('🚨 CRASH DETECTED! G-Force: ${gForce.toStringAsFixed(2)}g');

    _getCurrentLocation();
    _startMovementCheck();
    _startCountdown();
    
    notifyListeners();
  }

  void _startMovementCheck() {
    _movementCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (_lastReading != null) {
          final movement = _calculateTotalGForce(_lastReading!);
          if (movement > movementThreshold) {
            _hasMovedAfterImpact = true;
            timer.cancel();
          }
        }
      },
    );
  }

  void _startCountdown() {
    _countdownActive = true;
    _countdownSeconds = 10;
    notifyListeners();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _countdownSeconds--;
        notifyListeners();

        if (_countdownSeconds <= 0) {
          timer.cancel();
          if (!_hasMovedAfterImpact) {
            _triggerEmergency();
          } else {
            debugPrint('Movement detected - Cancelling emergency alert');
            _resetCrashState();
          }
        }
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      _crashLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting crash location: $e');
    }
  }

  Future<void> _triggerEmergency() async {
    debugPrint('🚨 TRIGGERING EMERGENCY ALERT');
    
    final message = _buildEmergencyMessage();
    await _sendEmergencySMS(message);
    await _callEmergencyNumber();
    
    _countdownActive = false;
    notifyListeners();
  }

  String _buildEmergencyMessage() {
    final location = _crashLocation;
    final coords = location != null
        ? 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}'
        : 'Location unavailable';
    
    final mapLink = location != null
        ? 'https://www.google.com/maps?q=${location.latitude},${location.longitude}'
        : '';

    return '''
🚨 ROAD GUARDIAN EMERGENCY ALERT 🚨

CRASH DETECTED
Impact Force: ${_crashGForce.toStringAsFixed(1)}g
Time: ${_crashTime?.toString() ?? 'Unknown'}

Location: $coords
Map: $mapLink

No movement detected after impact.
Please check on the driver immediately.
''';
  }

  Future<void> _sendEmergencySMS(String message) async {
    final emergencyContacts = ['112', '108'];
    
    for (final contact in emergencyContacts) {
      final uri = Uri(
        scheme: 'sms',
        path: contact,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          debugPrint('Emergency SMS sent to $contact');
        }
      } catch (e) {
        debugPrint('Error sending SMS to $contact: $e');
      }
    }
  }

  Future<void> _callEmergencyNumber() async {
    final uri = Uri(scheme: 'tel', path: '112');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('Calling emergency number: 112');
      }
    } catch (e) {
      debugPrint('Error calling emergency: $e');
    }
  }

  void cancelEmergency() {
    debugPrint('Emergency alert cancelled by user');
    _countdownTimer?.cancel();
    _movementCheckTimer?.cancel();
    _resetCrashState();
  }

  void _resetCrashState() {
    _crashDetected = false;
    _countdownActive = false;
    _countdownSeconds = 10;
    _crashLocation = null;
    _crashTime = null;
    _crashGForce = 0.0;
    _hasMovedAfterImpact = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
