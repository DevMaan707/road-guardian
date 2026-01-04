import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location Service for real GPS tracking
class LocationService {
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  /// Check and request location permissions
  Future<bool> requestPermissions() async {
    // 1. Check Service Status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled - prompting user to enable GPS');
      await Geolocator.openLocationSettings();
      return false;
    }

    // 2. Check Permission Status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied - opening app settings');
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Start listening to location updates
  Future<void> startTracking(Function(Position) onLocationUpdate) async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('Cannot start tracking without location permission');
      return;
    }

    // Get current position first
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      onLocationUpdate(_currentPosition!);
    } catch (e) {
      print('Error getting current position: $e');
    }

    // Start listening to position stream
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        onLocationUpdate(position);
      },
      onError: (error) {
        print('Location stream error: $error');
      },
    );
  }

  /// Stop tracking location
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get distance to a point in meters
  double getDistanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Get current speed in km/h
  double getCurrentSpeed() {
    if (_currentPosition == null) return 0;
    // Speed is in m/s, convert to km/h
    return (_currentPosition!.speed * 3.6).clamp(0, 200);
  }

  void dispose() {
    stopTracking();
  }
}

/// Known accident black spots in Hyderabad with coordinates
class BlackSpotDatabase {
  static const List<Map<String, dynamic>> blackSpots = [
    {
      'name': 'Uppal X Road',
      'lat': 17.4050,
      'lng': 78.5600,
      'station': 3, // Uppal PS
      'radius': 100, // meters
    },
    {
      'name': 'Ghatkesar Highway Junction',
      'lat': 17.4500,
      'lng': 78.5800,
      'station': 0, // Ghatkesar PS
      'radius': 150,
    },
    {
      'name': 'Medipally Circle',
      'lat': 17.4200,
      'lng': 78.5300,
      'station': 1, // Medipally PS
      'radius': 100,
    },
    {
      'name': 'Pocharam Lake Road Curve',
      'lat': 17.4300,
      'lng': 78.5200,
      'station': 2, // Pocharam PS
      'radius': 120,
    },
  ];

  /// Check if current location is near a black spot
  static Map<String, dynamic>? getNearestBlackSpot(
    double latitude,
    double longitude,
  ) {
    for (var spot in blackSpots) {
      double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        spot['lat'] as double,
        spot['lng'] as double,
      );

      if (distance <= (spot['radius'] as int)) {
        return {
          ...spot,
          'distance': distance,
        };
      }
    }
    return null;
  }

  /// Get police station code for location
  /// Returns police station jurisdiction based on proximity to black spots
  /// or geographic zones (bounding boxes)
  static int getPoliceStationForLocation(double latitude, double longitude) {
    // First try: Find nearest black spot to determine jurisdiction
    var nearestSpot = getNearestBlackSpot(latitude, longitude);
    if (nearestSpot != null) {
      return nearestSpot['station'] as int;
    }

    // Second try: Use rough geographic zones (bounding boxes)
    // Note: This is approximate. For production, use proper geofencing.
    // Uppal area: 17.40-17.42, 78.55-78.57
    if (latitude >= 17.40 && latitude <= 17.42 && 
        longitude >= 78.55 && longitude <= 78.57) {
      return 3; // Uppal PS
    }
    // Ghatkesar area: 17.44-17.46, 78.57-78.59
    if (latitude >= 17.44 && latitude <= 17.46 && 
        longitude >= 78.57 && longitude <= 78.59) {
      return 0; // Ghatkesar PS
    }
    // Medipally area: 17.41-17.43, 78.52-78.54
    if (latitude >= 17.41 && latitude <= 17.43 && 
        longitude >= 78.52 && longitude <= 78.54) {
      return 1; // Medipally PS
    }
    // Pocharam area: 17.42-17.44, 78.51-78.53
    if (latitude >= 17.42 && latitude <= 17.44 && 
        longitude >= 78.51 && longitude <= 78.53) {
      return 2; // Pocharam PS
    }

    // Default: Use Uppal PS as fallback
    // For production, consider returning -1 for "Unknown" and handling in UI
    return 3;
  }

  /// Get nearest police station by distance (more accurate than bounding boxes)
  static int getNearestPoliceStation(double latitude, double longitude) {
    // Station headquarters approximate locations
    final stations = [
      {'id': 0, 'name': 'Ghatkesar PS', 'lat': 17.4500, 'lng': 78.5800},
      {'id': 1, 'name': 'Medipally PS', 'lat': 17.4200, 'lng': 78.5300},
      {'id': 2, 'name': 'Pocharam PS', 'lat': 17.4300, 'lng': 78.5200},
      {'id': 3, 'name': 'Uppal PS', 'lat': 17.4050, 'lng': 78.5600},
    ];

    int nearestId = 3;
    double minDistance = double.infinity;

    for (var station in stations) {
      double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        station['lat'] as double,
        station['lng'] as double,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestId = station['id'] as int;
      }
    }

    return nearestId;
  }
}
