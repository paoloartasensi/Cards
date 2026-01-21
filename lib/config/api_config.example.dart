/// Copia questo file come api_config.dart e inserisci le tue API keys
/// NON committare api_config.dart!
library;

class ApiConfig {
  /// OpenWeatherMap - https://openweathermap.org/ (GRATIS: 1000 richieste/giorno)
  /// Registrati e copia qui la tua API key
  static const String openWeatherMapKey = 'HERE_YOUR_API';
  
  /// OpenSky Network - GRATUITO e ILLIMITATO! Non serve API key 🎉
  static const bool useOpenSky = true;
  
  /// Check if APIs are configured
  static bool get isFlightApiConfigured => useOpenSky;
  static bool get isWeatherApiConfigured => openWeatherMapKey.isNotEmpty;
  static bool get areApisConfigured => isFlightApiConfigured || isWeatherApiConfigured;
}
