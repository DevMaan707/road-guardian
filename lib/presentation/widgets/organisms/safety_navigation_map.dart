import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/black_spot_service.dart';
import '../../../providers/services_provider.dart';
import '../../../providers/risk_provider.dart';

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
  bool _initialCameraSet = false;
  double? _lastLat;
  double? _lastLng;

  // Initial camera position - Hyderabad (fallback)
  final _initialCameraPosition = CameraOptions(
    center: Point(coordinates: Position(78.5600, 17.4050)),
    zoom: 15.0,
    pitch: 60.0, // Tilted view for "Drive Mode"
    bearing: 0.0,
  );

  @override
  Widget build(BuildContext context) {
    // Use ref.listen to react to location changes OUTSIDE of build phase
    // This avoids the "setState called during build" error
    ref.listen<RiskState>(riskProvider, (previous, next) {
      _onLocationUpdate(next.latitude, next.longitude);
    });
    
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

    // Enable user location puck
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
  }

  void _onLocationUpdate(double lat, double lng) {
    // Skip if location hasn't changed or is still at default
    if (lat == 17.3850 && lng == 78.4867) return; // Skip initial/default values
    if (_lastLat == lat && _lastLng == lng) return;
    
    _lastLat = lat;
    _lastLng = lng;
    
    // Update camera position
    if (_mapboxMap != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(lng, lat),
          ),
          zoom: 16.0,
          pitch: 60.0,
          bearing: 0.0,
        ),
        MapAnimationOptions(duration: _initialCameraSet ? 1000 : 500),
      );
      _initialCameraSet = true;
    }
    
    // Calculate nearest black spot
    _calculateNearestBlackSpot(lat, lng);
  }

  Future<void> _loadBlackSpotMarkers() async {
    if (_pointAnnotationManager == null) return;

    try {
      final blackSpotAsync = await ref.read(blackSpotServiceProvider.future);
      _blackSpotService = blackSpotAsync;
      
      if (!blackSpotAsync.isLoaded) {
        return;
      }

      final spots = blackSpotAsync.spots;

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
      
      // Recalculate with current position now that service is loaded
      if (_lastLat != null && _lastLng != null) {
        _calculateNearestBlackSpot(_lastLat!, _lastLng!);
      }
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

  void _calculateNearestBlackSpot(double lat, double lng) {
    if (_blackSpotService == null || !_blackSpotService!.isLoaded) {
      widget.onNextBlackSpotUpdate("Loading spots...", 0, null);
      return;
    }

    final nearestData = _blackSpotService!.getNearestBlackSpotWithDistance(
      lat,
      lng,
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
