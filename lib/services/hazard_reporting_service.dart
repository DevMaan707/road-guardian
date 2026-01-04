import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Hazard {
  final String id;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String reportedBy;

  Hazard({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.reportedBy = 'Anonymous',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'reportedBy': reportedBy,
      };

  factory Hazard.fromJson(Map<String, dynamic> json) => Hazard(
        id: json['id'],
        type: json['type'],
        description: json['description'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        timestamp: DateTime.parse(json['timestamp']),
        reportedBy: json['reportedBy'] ?? 'Anonymous',
      );
}

class HazardReportingService extends ChangeNotifier {
  static const String _storageKey = 'reported_hazards';
  final List<Hazard> _hazards = [];

  List<Hazard> get hazards => List.unmodifiable(_hazards);
  int get hazardCount => _hazards.length;

  Future<void> initialize() async {
    await _loadHazards();
  }

  Future<void> _loadHazards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hazardsJson = prefs.getString(_storageKey);
      
      if (hazardsJson != null) {
        final List<dynamic> decoded = json.decode(hazardsJson);
        _hazards.clear();
        _hazards.addAll(decoded.map((json) => Hazard.fromJson(json)));
        
        _removeOldHazards();
        notifyListeners();
        
        debugPrint('Loaded ${_hazards.length} hazards from storage');
      }
    } catch (e) {
      debugPrint('Error loading hazards: $e');
    }
  }

  Future<void> _saveHazards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hazardsJson = json.encode(_hazards.map((h) => h.toJson()).toList());
      await prefs.setString(_storageKey, hazardsJson);
      debugPrint('Saved ${_hazards.length} hazards to storage');
    } catch (e) {
      debugPrint('Error saving hazards: $e');
    }
  }

  void _removeOldHazards() {
    final now = DateTime.now();
    _hazards.removeWhere((hazard) {
      final age = now.difference(hazard.timestamp);
      return age.inDays > 7;
    });
  }

  Future<void> reportHazard({
    required String type,
    required String description,
    required Position position,
  }) async {
    final hazard = Hazard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    _hazards.insert(0, hazard);
    await _saveHazards();
    notifyListeners();

    debugPrint('Hazard reported: $type at (${position.latitude}, ${position.longitude})');
  }

  List<Hazard> getNearbyHazards(double latitude, double longitude, {double radiusMeters = 1000}) {
    return _hazards.where((hazard) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        hazard.latitude,
        hazard.longitude,
      );
      return distance <= radiusMeters;
    }).toList();
  }

  Future<void> clearAllHazards() async {
    _hazards.clear();
    await _saveHazards();
    notifyListeners();
  }
}

class HazardType {
  static const String pothole = 'Pothole';
  static const String brokenLight = 'Broken Street Light';
  static const String construction = 'Construction';
  static const String debris = 'Road Debris';
  static const String flooding = 'Flooding';
  static const String accident = 'Accident';
  static const String other = 'Other';

  static List<String> get all => [
        pothole,
        brokenLight,
        construction,
        debris,
        flooding,
        accident,
        other,
      ];

  static IconData getIcon(String type) {
    switch (type) {
      case pothole:
        return Icons.warning;
      case brokenLight:
        return Icons.lightbulb_outline;
      case construction:
        return Icons.construction;
      case debris:
        return Icons.block;
      case flooding:
        return Icons.water;
      case accident:
        return Icons.car_crash;
      case other:
        return Icons.report_problem;
      default:
        return Icons.report_problem;
    }
  }
}
