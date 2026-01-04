import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/location_service.dart';

/// Atomic Design: ORGANISM - Safety Navigation Map
/// 3D tilted navigation view with black spot markers
class SafetyNavigationMap extends StatefulWidget {
  final Function(String name, double distance) onNextBlackSpotUpdate;
  final String mapboxAccessToken;

  const SafetyNavigationMap({
    super.key,
    required this.onNextBlackSpotUpdate,
    required this.mapboxAccessToken,
  });

  @override
  State<SafetyNavigationMap> createState() => _SafetyNavigationMapState();
}

class _SafetyNavigationMapState extends State<SafetyNavigationMap> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  StreamSubscription<Position>? _positionStream;

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
          styleUri: MapboxStyles.NAVIGATION_NIGHT, // Dark theme
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

    final spots = BlackSpotDatabase.blackSpots;

    for (var spot in spots) {
      // Create red circle annotation for each black spot
      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            spot['lng'] as double,
            spot['lat'] as double,
          ),
        ),
        iconSize: 1.2,
        iconColor: AppColors.critical.value,
        textField: spot['name'] as String,
        textOffset: [0.0, -2.0],
        textColor: AppColors.critical.value,
        textSize: 12.0,
      );

      _pointAnnotationManager!.create(options);
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _updateCamera(position);
      _calculateNearestBlackSpot(position);
    });
  }

  void _updateCamera(Position position) {
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

  void _calculateNearestBlackSpot(Position userPosition) {
    double minDistance = double.infinity;
    String nextSpotName = "No black spots nearby";

    final spots = BlackSpotDatabase.blackSpots;

    for (var spot in spots) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        spot['lat'] as double,
        spot['lng'] as double,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nextSpotName = spot['name'] as String;
      }
    }

    // Notify parent widget
    widget.onNextBlackSpotUpdate(nextSpotName, minDistance);
  }
}
