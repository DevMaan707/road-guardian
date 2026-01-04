import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/theme/app_colors.dart';
import '../../../services/black_spot_service.dart';
import '../../../providers/services_provider.dart';

/// Atomic Design: ORGANISM - Safety Navigation Map
/// 3D tilted navigation view with black spot markers
class SafetyNavigationMap extends ConsumerStatefulWidget {
  final Function(String name, double distance, BlackSpot? spot) onNextBlackSpotUpdate;
  final String mapboxAccessToken;

  const SafetyNavigationMap({
    super.key,
    required this.onNextBlackSpotUpdate,
    required this.mapboxAccessToken,
  });

  @override
  ConsumerState<SafetyNavigationMap> createState() => _SafetyNavigationMapState();
}

class _SafetyNavigationMapState extends ConsumerState<SafetyNavigationMap> {
  BlackSpotService? _blackSpotService;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  StreamSubscription<geo.Position>? _positionStream;

  // Initial camera position - Hyderabad
  final _initialCameraPosition = CameraOptions(
    center: Point(coordinates: Position(78.5600, 17.4050)),
    zoom: 15.0,
    pitch: 60.0, // Tilted view for "Drive Mode"
    bearing: 0.0,
  );

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          cameraOptions: _initialCameraPosition,
          styleUri: MapboxStyles.DARK, // Dark theme
          textureView: true,
          onMapCreated: _onMapCreated,
        ),
        // Gradient overlay to fade into HUD
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Enable user location
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true, // Rotates with heading
      ),
    );

    // Initialize annotations for black spots
    mapboxMap.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
      _loadBlackSpotMarkers();
    });

    // Start tracking user
    _startLocationTracking();
  }

  Future<void> _loadBlackSpotMarkers() async {
    if (_pointAnnotationManager == null) return;

    try {
      final blackSpotAsync = await ref.read(blackSpotServiceProvider.future);
      _blackSpotService = blackSpotAsync;
      
      if (!blackSpotAsync.isLoaded) {
        print('⚠️ Black spots not loaded yet');
        return;
      }

      final spots = blackSpotAsync.spots;
      print('✅ Loading ${spots.length} black spot markers on map');

      for (var spot in spots) {
        Color markerColor;
        switch (spot.severity.toLowerCase()) {
          case 'critical':
            markerColor = AppColors.critical;
            break;
          case 'high':
            markerColor = Color(0xFFFF6B6B);
            break;
          case 'moderate':
            markerColor = AppColors.warning;
            break;
          default:
            markerColor = AppColors.textSecondary;
        }

        final options = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(spot.lng, spot.lat),
          ),
          iconSize: 2.5,
          iconColor: markerColor.value,
          iconOpacity: 0.9,
          textField: '⚠️ ${spot.name}\n${spot.accidentCount} accidents',
          textOffset: [0.0, -3.0],
          textColor: Colors.white.value,
          textSize: 13.0,
          textHaloColor: Colors.black.value,
          textHaloWidth: 2.5,
        );

        _pointAnnotationManager!.create(options);
      }
      
      _animateBlackSpotMarkers();
    } catch (e) {
      print('❌ Error loading black spots: $e');
    }
  }

  void _animateBlackSpotMarkers() {
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
    });
  }

  void _startLocationTracking() {
    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _updateCamera(position);
      _calculateNearestBlackSpot(position);
    });
  }

  void _updateCamera(geo.Position position) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16.0,
        pitch: 60.0,
        bearing: position.heading, // Rotate based on direction
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _calculateNearestBlackSpot(geo.Position userPosition) {
    if (_blackSpotService == null || !_blackSpotService!.isLoaded) {
      widget.onNextBlackSpotUpdate("Loading spots...", 0, null);
      return;
    }

    final nearestData = _blackSpotService!.getNearestBlackSpotWithDistance(
      userPosition.latitude,
      userPosition.longitude,
    );

    if (nearestData != null) {
      final spot = nearestData['spot'] as BlackSpot;
      final distance = nearestData['distance'] as double;
      widget.onNextBlackSpotUpdate(spot.name, distance, spot);
    } else {
      widget.onNextBlackSpotUpdate("No black spots nearby", 0, null);
    }
  }
}
