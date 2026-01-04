import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telematics_service.dart';
import '../services/crash_detection_service.dart';
import '../services/voice_assistant_service.dart';
import '../services/hazard_reporting_service.dart';
import '../services/black_spot_service.dart';

final telematicsProvider = ChangeNotifierProvider<TelematicsService>((ref) {
  final service = TelematicsService();
  service.startTracking();
  return service;
});

final crashDetectionProvider = ChangeNotifierProvider<CrashDetectionService>((ref) {
  final service = CrashDetectionService();
  return service;
});

final voiceAssistantProvider = Provider<VoiceAssistantService>((ref) {
  final service = VoiceAssistantService();
  service.initialize();
  return service;
});

final hazardReportingProvider = ChangeNotifierProvider<HazardReportingService>((ref) {
  final service = HazardReportingService();
  return service;
});

final blackSpotServiceProvider = FutureProvider<BlackSpotService>((ref) async {
  final service = BlackSpotService();
  await service.loadBlackSpots();
  return service;
});
