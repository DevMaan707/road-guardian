# Real Data Integration Guide

## Overview
Road Guardian Pro now uses **real GPS location** and **real ONNX model predictions** instead of simulations.

## What Changed

### 1. Real GPS Location Tracking
**File**: `lib/services/location_service.dart`

- Uses `geolocator` package for real GPS coordinates
- Requests location permissions automatically
- Updates location every 10 meters
- Calculates real speed from GPS (m/s → km/h)
- Falls back to default Hyderabad coordinates if permission denied

### 2. Black Spot Detection
**File**: `lib/services/location_service.dart` - `BlackSpotDatabase`

Real accident black spots in Hyderabad:
- **Uppal X Road** (17.4050, 78.5600) - 100m radius
- **Ghatkesar Highway Junction** (17.4500, 78.5800) - 150m radius
- **Medipally Circle** (17.4200, 78.5300) - 100m radius
- **Pocharam Lake Road Curve** (17.4300, 78.5200) - 120m radius

The app detects when you're within these zones and increases risk score.

### 3. ONNX Model Integration
**File**: `lib/services/onnx_model_service.dart`

- Loads `road_guardian_model.onnx` from assets
- Uses `onnxruntime` package for inference
- Input features (10 dimensions):
  1. Accused vehicle type (0-3)
  2. Victim vehicle type (0-3)
  3. Police station jurisdiction (0-3)
  4. Hour of day (0-23)
  5. Day of week (1-7)
  6. Month (1-12)
  7. Latitude
  8. Longitude
  9. Weather code
  10. Speed (km/h)

- Output: Risk probability (0-1) scaled to 0-100
- Falls back to rule-based calculation if model fails

### 4. Real-time Risk Calculation
**File**: `lib/providers/risk_provider.dart`

Updates every **3 seconds** with:
- Current GPS position
- Real speed from GPS sensor
- Live weather from Open-Meteo API
- Black spot proximity check
- ONNX model prediction

## How It Works

```
1. App starts → Request location permission
2. GPS tracking starts → Position updates every 10m
3. Every 3 seconds:
   ├─ Get current GPS coordinates
   ├─ Calculate speed from GPS
   ├─ Fetch weather data
   ├─ Check if near black spot
   ├─ Determine police station jurisdiction
   ├─ Create input vector for ONNX model
   ├─ Run ONNX inference
   └─ Update UI with risk score
```

## Testing

### On Real Device
1. Enable GPS/Location services
2. Grant location permission when prompted
3. Drive around Hyderabad (or walk/simulate)
4. Watch risk score update based on:
   - Your actual speed
   - Proximity to black spots
   - Current weather conditions
   - Time of day

### On Emulator
1. Use Android Studio's location simulation
2. Set coordinates to Hyderabad area (17.3850, 78.4867)
3. Simulate movement to test black spot detection
4. Change speed in emulator settings

## Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)
Add location usage descriptions for App Store approval.

## Debug Logs

When running, you'll see console output:
```
ONNX Model initialized successfully
Input vector: [0.0, 3.0, 3.0, 14.0, 6.0, 1.0, 17.4050, 78.5600, 0.0, 45.0]
ONNX output tensor: [0.78]
ONNX risk score: 78.0
```

## Fallback Behavior

If ONNX model fails to load or predict:
- Uses rule-based calculation
- Still considers all real data (GPS, weather, black spots)
- Prints error to console for debugging

## Model Input Mappings

From `assets/mappings/android_mappings.json`:

**Accused_Type / Victim_Type:**
- 0: Car
- 1: Heavy Vehicle
- 2: Other
- 3: Two Wheeler

**Police_Station:**
- 0: Ghatkesar PS
- 1: Medipally PS
- 2: Pocharam PS
- 3: Uppal PS

## Performance

- GPS updates: Every 10 meters
- Risk calculation: Every 3 seconds
- Weather refresh: Every 5 minutes (cached)
- ONNX inference: ~10-50ms per prediction

## Next Steps

To improve accuracy:
1. Add more black spots to database
2. Retrain ONNX model with more data
3. Add reverse geocoding for location names
4. Implement historical accident data overlay
