import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceAssistantService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 Voice Assistant started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('🔊 Voice Assistant finished speaking');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('Voice Assistant error: $msg');
      });

      _isInitialized = true;
      debugPrint('🔊 Voice Assistant initialized');
    } catch (e) {
      debugPrint('Error initializing Voice Assistant: $e');
    }
  }

  Future<void> announceRisk(String spotName, double distance, int severity) async {
    if (!_isEnabled || !_isInitialized) return;

    await stop();

    String message;
    if (distance < 100) {
      message = 'Caution! Entering $spotName. High severity history. Slow down immediately.';
    } else if (distance < 300) {
      message = 'Warning. Approaching $spotName in ${distance.toInt()} meters. High accident zone ahead.';
    } else {
      message = '$spotName ahead in ${distance.toInt()} meters. Exercise caution.';
    }

    await speak(message);
  }

  Future<void> announceWeatherWarning(String condition) async {
    if (!_isEnabled || !_isInitialized) return;

    final message = 'Weather alert: $condition detected. Reduce speed and increase following distance.';
    await speak(message);
  }

  Future<void> announceDrivingBehavior(String behaviorType) async {
    if (!_isEnabled || !_isInitialized) return;

    String message;
    switch (behaviorType) {
      case 'HARSH_BRAKING':
        message = 'Harsh braking detected. Drive smoothly.';
        break;
      case 'RAPID_ACCELERATION':
        message = 'Rapid acceleration detected. Maintain steady speed.';
        break;
      case 'HARD_CORNERING':
        message = 'Sharp turn detected. Take corners gradually.';
        break;
      default:
        message = 'Aggressive driving detected. Please drive safely.';
    }

    await speak(message);
  }

  Future<void> announceCrashDetection() async {
    if (!_isEnabled || !_isInitialized) return;

    await stop();
    await speak('Crash detected! Emergency services will be contacted in 10 seconds. Say cancel to stop.');
  }

  Future<void> announceHighRisk(int riskScore) async {
    if (!_isEnabled || !_isInitialized || riskScore < 80) return;

    await stop();
    await speak('High risk zone. Current safety score: $riskScore. Exercise extreme caution.');
  }

  Future<void> speak(String message) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      await _flutterTts.speak(message);
      debugPrint('🔊 Speaking: $message');
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isSpeaking) {
      stop();
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}
