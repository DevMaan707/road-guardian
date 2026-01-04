# Mapbox 3D Navigation Integration Guide

## Overview
Road Guardian Pro now supports a **3D tilted navigation view** using Mapbox, providing a professional driving experience with real-time black spot markers.

## Features

### 1. 3D Navigation View
- **Tilted Camera**: 60° pitch for automotive HUD perspective
- **Auto-Rotation**: Map rotates based on driving direction (heading)
- **Dark Theme**: `MapboxStyles.NAVIGATION_NIGHT` for cyberpunk aesthetic
- **Smooth Tracking**: Camera follows user with 1-second animation

### 2. Black Spot Markers
- Red markers at all accident-prone locations
- Labels showing spot names
- Real-time distance calculation to nearest spot

### 3. Next Black Spot Warning Card
- Google Maps-style alert card
- Only appears when within 2km of a black spot
- Color-coded urgency:
  - **Red**: < 300m (critical)
  - **Orange**: < 800m (warning)
  - **Blue**: < 2km (awareness)
- Animated pulsing icon
- Shows distance in meters or kilometers

### 4. HUD Overlay
- Transparent gradient overlay
- Floating UI elements on top of map
- Minimal center gauge when high risk
- Bottom telemetry cards (weather, speed)

## Setup Instructions

### Step 1: Get Mapbox Access Token

1. Go to [https://account.mapbox.com/](https://account.mapbox.com/)
2. Sign up for a free account
3. Navigate to **Access Tokens**
4. Click **Create a token**
5. Enable these scopes:
   - `styles:read`
   - `fonts:read`
   - `navigation:read`
6. Copy the token

### Step 2: Configure Token

Open `lib/config/mapbox_config.dart` and replace:

```dart
static const String accessToken = 'YOUR_MAPBOX_PUBLIC_ACCESS_TOKEN_HERE';
```

With your actual token:

```dart
static const String accessToken = 'pk.eyJ1Ijoie...your_token_here...}';
```

### Step 3: Run the App

```bash
flutter pub get
flutter run
```

The app will automatically detect if Mapbox is configured:
- **With Token**: Shows 3D map navigation view
- **Without Token**: Falls back to basic dashboard

## Architecture

### Files Created

**Organisms:**
- `safety_navigation_map.dart` - Main 3D map widget
- `map_hud_dashboard.dart` - Dashboard with map background

**Molecules:**
- `next_blackspot_card.dart` - Warning card component

**Config:**
- `mapbox_config.dart` - Token management

### Component Hierarchy

```
MapHudDashboard (Organism)
├── SafetyNavigationMap (Organism)
│   ├── MapWidget (Mapbox)
│   ├── Location Tracking
│   └── Black Spot Markers
└── HUD Overlay (Stack)
    ├── Header (StatusBadge + Time)
    ├── Center Gauge (when high risk)
    ├── NextBlackSpotCard (Molecule)
    └── Telemetry Grid (WeatherTile + SpeedTile)
```

## Black Spot Database

From `lib/services/location_service.dart`:

```dart
BlackSpotDatabase.blackSpots = [
  {
    'name': 'Uppal X Road',
    'lat': 17.4050,
    'lng': 78.5600,
    'station': 3,
    'radius': 100, // meters
  },
  // ... 3 more spots
];
```

### Adding More Black Spots

Edit `BlackSpotDatabase.blackSpots` in `location_service.dart`:

```dart
{
  'name': 'Your Location Name',
  'lat': 17.1234,      // Latitude
  'lng': 78.5678,      // Longitude
  'station': 3,        // Police station ID (0-3)
  'radius': 150,       // Detection radius in meters
},
```

## Performance Optimization

### Current Scale
- **4 black spots**: Excellent performance
- Distance calculations: ~4ms per frame

### Future Scale (100+ spots)
If you add many spots, optimize `_calculateNearestBlackSpot`:

```dart
// Pre-filter by rough bounding box before exact distance
if ((spot['lat'] - userLat).abs() > 0.05) continue;
if ((spot['lng'] - userLng).abs() > 0.05) continue;

// Then calculate exact distance
double distance = Geolocator.distanceBetween(...);
```

## Map Styles

Available Mapbox styles in `MapboxStyles`:

- `NAVIGATION_NIGHT` (current) - Dark blue/black for night driving
- `NAVIGATION_DAY` - Light theme for daytime
- `SATELLITE` - Satellite imagery
- `STREETS` - Default street map
- `OUTDOORS` - Topographic style

Change in `safety_navigation_map.dart`:

```dart
styleUri: MapboxStyles.NAVIGATION_NIGHT,
```

## Custom Icons

To use custom danger icons instead of colored circles:

1. Design a PNG icon (e.g., red skull, warning triangle)
2. Add to `assets/icons/danger_marker.png`
3. Update `pubspec.yaml`:
   ```yaml
   assets:
     - assets/icons/
   ```
4. Load in `_loadBlackSpotMarkers()`:
   ```dart
   final bytes = await rootBundle.load('assets/icons/danger_marker.png');
   final image = await _mapboxMap?.style.addImage(
     'danger-icon',
     bytes.buffer.asUint8List(),
   );
   
   PointAnnotationOptions(
     iconImage: 'danger-icon',
     // ...
   );
   ```

## Fallback Mode

If Mapbox token is not configured, the app automatically falls back to:
- `SafetyDashboard` - Basic HUD without map
- Still shows risk gauge, weather, speed
- Still calculates black spot proximity
- Just no visual map

## Testing

### On Device
1. Drive/walk around Hyderabad
2. Watch camera follow your heading
3. Approach a black spot location
4. See warning card slide up

### On Emulator
1. Use Android Studio location simulation
2. Set route through black spots:
   - Start: 17.4000, 78.5500
   - Through: 17.4050, 78.5600 (Uppal X Road)
   - End: 17.4500, 78.5800 (Ghatkesar)

## Troubleshooting

**Map not showing:**
- Check `MapboxConfig.accessToken` is set
- Verify token has correct scopes
- Check internet connection

**Markers not appearing:**
- Check console for "Created annotation" logs
- Verify `BlackSpotDatabase.blackSpots` has valid coordinates

**Camera not following:**
- Grant location permission
- Check GPS is enabled
- Verify `_positionStream` is active

## Future Enhancements

1. **Route Prediction**: Use Mapbox Directions API to predict route and warn about black spots ahead
2. **Traffic Layer**: Show real-time traffic conditions
3. **Incident Reporting**: Allow users to report new black spots
4. **Historical Data**: Show heatmap of past accidents
5. **Voice Alerts**: "Black spot ahead in 500 meters"

## Credits

- Map data: © Mapbox © OpenStreetMap
- Navigation style: Mapbox Navigation
- Icons: Material Icons
