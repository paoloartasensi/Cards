/// API Configuration for live flight info
/// 
/// 🆓 **OpenSky Network** - GRATUITO e ILLIMITATO!
///    - Non richiede API key
///    - Dati di volo in tempo reale (posizione, altitudine, velocità)
///    - https://opensky-network.org/
/// 
/// 🌤️ **OpenWeatherMap** (Meteo a destinazione)
///    - Sign up at: https://openweathermap.org/api
///    - Free tier: 1000 requests/giorno
///    - Inserisci la tua API key qui sotto
library;

class ApiConfig {
  /// OpenWeatherMap API key for weather information
  /// Get yours FREE at: https://openweathermap.org/api
  static const String openWeatherMapKey = '';
  
  /// OpenSky Network - NO API KEY NEEDED! 🎉
  /// Completely free and unlimited
  static const bool useOpenSky = true;
  
  /// Check if APIs are configured
  static bool get isFlightApiConfigured => useOpenSky; // Always true - OpenSky is free!
  static bool get isWeatherApiConfigured => openWeatherMapKey.isNotEmpty;
  static bool get areApisConfigured => isFlightApiConfigured || isWeatherApiConfigured;
}
