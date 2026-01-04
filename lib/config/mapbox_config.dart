/// Mapbox Configuration
/// 
/// To use Mapbox, you need to:
/// 1. Sign up at https://account.mapbox.com/
/// 2. Create an access token
/// 3. Replace the placeholder below with your token
/// 
/// For production apps, store the token in environment variables
/// or use flutter_dotenv to keep it secure.
class MapboxConfig {
  MapboxConfig._();

  /// Public Access Token
  /// Get yours from: https://account.mapbox.com/access-tokens/
  /// 
  /// Using environment variable with fallback to hardcoded token
  static const String accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: 'pk....',
  );

  /// Check if token is configured
  static bool get isConfigured => 
      accessToken.isNotEmpty && !accessToken.contains('YOUR_MAPBOX');

  /// Get token or return empty string
  static String get token => isConfigured ? accessToken : '';
}
