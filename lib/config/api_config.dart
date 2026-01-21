/// API Configuration for live flight info
/// 
/// To enable live flight information, you need to get API keys from:
/// 
/// 1. **AviationStack** (Flight info: gate, delays, status)
///    - Sign up at: https://aviationstack.com/
///    - Free tier: 100 requests/month
///    - Get your API key from the dashboard
/// 
/// 2. **OpenWeatherMap** (Weather at destination)
///    - Sign up at: https://openweathermap.org/api
///    - Free tier: 1000 requests/day
///    - Get your API key from the API keys section
/// 
/// After getting your keys, replace the empty strings below:
library;

class ApiConfig {
  /// AviationStack API key for flight information
  /// Get yours at: https://aviationstack.com/
  static const String aviationStackKey = '';
  
  /// OpenWeatherMap API key for weather information
  /// Get yours at: https://openweathermap.org/api
  static const String openWeatherMapKey = '';
  
  /// Check if APIs are configured
  static bool get isFlightApiConfigured => aviationStackKey.isNotEmpty;
  static bool get isWeatherApiConfigured => openWeatherMapKey.isNotEmpty;
  static bool get areApisConfigured => isFlightApiConfigured || isWeatherApiConfigured;
}
