# Road Guardian Pro

A real-time driver safety app that predicts accident risk using ONNX machine learning model and live weather data.

## Features

- **Real-time Risk Assessment**: Circular gauge displaying safety score (0-100)
- **Live Weather Integration**: Fetches current weather from Open-Meteo API
- **ONNX Model Integration**: Uses trained model for risk prediction
- **Alert System**: Animated slide-up panel for high-risk situations (score > 80)
- **Location Tracking**: Displays current location with risk indicators

## Design Philosophy

This app follows **Atomic Design** principles:

### Atoms (`lib/presentation/widgets/atoms/`)
- **Badge**: Status indicators (StatusBadge, RiskBadge)
- **CardBase**: Foundation surface cards (CardBase, HudCard, LocationCard)

### Molecules (`lib/presentation/widgets/molecules/`)
- **DataTile**: Combines card with label, value, unit, icon (WeatherTile, SpeedTile)
- **LocationStrip**: Location display with risk-based indicator

### Organisms (`lib/presentation/widgets/organisms/`)
- **RiskGauge**: Circular progress indicator with animated risk display
- **AlertOverlay**: Slide-up alert panel for critical situations
- **SafetyDashboard**: Main dashboard combining all elements

## Theme

**"Automotive HUD / Cyberpunk Safety"** - Dark mode only

| Element | Color |
|---------|-------|
| Background | `#050505` |
| Surface | `#121214` |
| Border | `#2A2A2D` |
| Primary (Blue) | `#3B82F6` |
| Success (Green) | `#10B981` |
| Warning (Orange) | `#F59E0B` |
| Critical (Red) | `#EF4444` |

### Typography
- **Body Text**: Inter (Google Fonts)
- **Data/Monospace**: JetBrains Mono

## State Management

Uses **flutter_riverpod** for:
- `weatherProvider`: Fetches and caches weather data
- `riskProvider`: Manages telemetry simulation and risk calculation

## Project Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_theme.dart
├── presentation/
│   └── widgets/
│       ├── atoms/
│       │   ├── badge.dart
│       │   └── card_base.dart
│       ├── molecules/
│       │   ├── data_tile.dart
│       │   └── location_strip.dart
│       └── organisms/
│           ├── risk_gauge.dart
│           ├── alert_overlay.dart
│           └── safety_dashboard.dart
├── providers/
│   ├── risk_provider.dart
│   └── weather_provider.dart
├── services/
│   └── onnx_model_service.dart
└── main.dart
```

## Assets

- `assets/model/road_guardian_model.onnx` - ONNX risk prediction model
- `assets/mappings/android_mappings.json` - Label encodings for model inputs

## Setup

1. Ensure Flutter SDK is installed
2. Run `flutter pub get`
3. Run `flutter run`

## Dependencies

- `flutter_riverpod` - State management
- `flutter_animate` - Animations
- `google_fonts` - Typography (Inter, JetBrains Mono)
- `http` - Weather API calls
- `onnxruntime_flutter` - ONNX model inference

## API

Weather data from [Open-Meteo API](https://open-meteo.com/):
```
https://api.open-meteo.com/v1/forecast?latitude=17.3850&longitude=78.4867&current_weather=true
```

## License

MIT License
