import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class BlackSpot {
  final String name;
  final double lat;
  final double lng;
  final double radius;
  final String severity;
  final int accidentCount;
  final int fatalities;
  final List<String> reasons;
  final List<String> safetyMeasures;
  final String peakDangerHours;

  BlackSpot({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.severity,
    required this.accidentCount,
    required this.fatalities,
    required this.reasons,
    required this.safetyMeasures,
    required this.peakDangerHours,
  });

  factory BlackSpot.fromJson(Map<String, dynamic> json) {
    return BlackSpot(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      severity: json['severity'] as String,
      accidentCount: json['accident_count'] as int,
      fatalities: json['fatalities'] as int,
      reasons: List<String>.from(json['reasons'] as List),
      safetyMeasures: List<String>.from(json['safety_measures'] as List),
      peakDangerHours: json['peak_danger_hours'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'severity': severity,
      'accident_count': accidentCount,
      'fatalities': fatalities,
      'reasons': reasons,
      'safety_measures': safetyMeasures,
      'peak_danger_hours': peakDangerHours,
    };
  }

  int getSeverityScore() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 100;
      case 'high':
        return 75;
      case 'moderate':
        return 50;
      default:
        return 25;
    }
  }
}

class BlackSpotService {
  List<BlackSpot> _spots = [];
  bool _isLoaded = false;

  List<BlackSpot> get spots => _spots;
  bool get isLoaded => _isLoaded;

  Future<void> loadBlackSpots() async {
    try {
      final String response = await rootBundle.loadString('assets/black_spots.json');
      final List<dynamic> data = json.decode(response);
      _spots = data.map((json) => BlackSpot.fromJson(json)).toList();
      _isLoaded = true;
      print('✅ Loaded ${_spots.length} Black Spots from JSON');
    } catch (e) {
      print('❌ Error loading black spots: $e');
      _spots = [];
      _isLoaded = false;
    }
  }

  BlackSpot? getNearestBlackSpot(double lat, double lng, {double maxDistance = 5000}) {
    if (_spots.isEmpty) return null;

    BlackSpot? nearest;
    double minDistance = maxDistance;

    for (var spot in _spots) {
      final distance = Geolocator.distanceBetween(lat, lng, spot.lat, spot.lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = spot;
      }
    }

    return nearest;
  }

  Map<String, dynamic>? getNearestBlackSpotWithDistance(double lat, double lng) {
    final nearest = getNearestBlackSpot(lat, lng);
    if (nearest == null) return null;

    final distance = Geolocator.distanceBetween(lat, lng, nearest.lat, nearest.lng);
    
    return {
      'spot': nearest,
      'distance': distance,
    };
  }

  List<BlackSpot> getBlackSpotsInRadius(double lat, double lng, double radiusMeters) {
    return _spots.where((spot) {
      final distance = Geolocator.distanceBetween(lat, lng, spot.lat, spot.lng);
      return distance <= radiusMeters;
    }).toList();
  }

  bool isInDangerZone(double lat, double lng) {
    return _spots.any((spot) {
      final distance = Geolocator.distanceBetween(lat, lng, spot.lat, spot.lng);
      return distance <= spot.radius;
    });
  }

  int calculateBlackSpotRisk(double lat, double lng) {
    final nearby = getBlackSpotsInRadius(lat, lng, 500);
    if (nearby.isEmpty) return 0;

    int totalRisk = 0;
    for (var spot in nearby) {
      final distance = Geolocator.distanceBetween(lat, lng, spot.lat, spot.lng);
      final proximityFactor = 1 - (distance / 500);
      totalRisk += (spot.getSeverityScore() * proximityFactor).round();
    }

    return totalRisk.clamp(0, 100);
  }
}
