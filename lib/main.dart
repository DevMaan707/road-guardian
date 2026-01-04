import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/organisms/safety_dashboard.dart';
import 'presentation/widgets/organisms/map_hud_dashboard.dart';
import 'config/mapbox_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for automotive HUD experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: RoadGuardianApp(),
    ),
  );
}

class RoadGuardianApp extends StatelessWidget {
  const RoadGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Map HUD if Mapbox is configured, otherwise use basic dashboard
    final useMapView = MapboxConfig.isConfigured;

    return MaterialApp(
      title: 'Road Guardian Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: useMapView
          ? MapHudDashboard(mapboxAccessToken: MapboxConfig.token)
          : const SafetyDashboard(),
    );
  }
}
