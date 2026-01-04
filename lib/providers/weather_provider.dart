import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Weather data model
class WeatherData {
  final double temperature;
  final int weatherCode;
  final String condition;
  final String icon;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.icon,
    this.windSpeed = 0,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>;
    final code = current['weathercode'] as int;
    final temp = (current['temperature'] as num).toDouble();
    final wind = (current['windspeed'] as num?)?.toDouble() ?? 0;

    return WeatherData(
      temperature: temp,
      weatherCode: code,
      condition: _getCondition(code),
      icon: _getIcon(code),
      windSpeed: wind,
    );
  }

  static String _getCondition(int code) {
    if (code <= 3) return 'Clear';
    if (code <= 49) return 'Foggy';
    if (code <= 79) return 'Rain';
    return 'Storm';
  }

  static String _getIcon(int code) {
    if (code <= 3) return '☀️';
    if (code <= 49) return '🌫️';
    if (code <= 79) return '🌧️';
    return '⛈️';
  }

  bool get isRainy => weatherCode > 50;
  bool get isSevere => weatherCode > 79;

  WeatherData copyWith({
    double? temperature,
    int? weatherCode,
    String? condition,
    String? icon,
    double? windSpeed,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      weatherCode: weatherCode ?? this.weatherCode,
      condition: condition ?? this.condition,
      icon: icon ?? this.icon,
      windSpeed: windSpeed ?? this.windSpeed,
    );
  }
}

/// Weather API Service
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather({
    double latitude = 17.3850,
    double longitude = 78.4867,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude&current_weather=true',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(json);
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Weather API error: $e');
    }
  }
}

/// Weather Provider using Riverpod
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.fetchWeather();
});

/// Auto-refresh weather provider (refreshes every 5 minutes)
final autoRefreshWeatherProvider =
    StreamProvider.autoDispose<WeatherData>((ref) async* {
  final service = ref.watch(weatherServiceProvider);

  while (true) {
    try {
      yield await service.fetchWeather();
    } catch (e) {
      yield WeatherData(
        temperature: 0,
        weatherCode: 0,
        condition: 'Unknown',
        icon: '❓',
      );
    }
    await Future.delayed(const Duration(minutes: 5));
  }
});
