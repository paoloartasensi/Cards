import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service to fetch live flight information using FREE APIs
/// - OpenSky Network: Free, unlimited, no API key needed!
/// - OpenWeatherMap: Free tier 1000/day
class FlightInfoService {
  
  /// Fetch live flight info using OpenSky Network (FREE!)
  /// Uses callsign which is typically the flight number
  Future<FlightInfo?> getFlightInfo(String flightNumber, DateTime? flightDate) async {
    try {
      // Clean flight number to create callsign (e.g., "AZ 610" -> "AZA610" or "AZ610")
      final callsign = flightNumber.replaceAll(' ', '').toUpperCase();
      
      // OpenSky Network API - completely FREE, no API key!
      // Get all current flights and filter by callsign
      final uri = Uri.parse('https://opensky-network.org/api/states/all');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final states = data['states'] as List?;
        
        if (states != null) {
          // Find flight by callsign (index 1 in state vector)
          // State vector: [icao24, callsign, origin_country, time_position, last_contact, 
          //                longitude, latitude, baro_altitude, on_ground, velocity, 
          //                true_track, vertical_rate, sensors, geo_altitude, squawk, 
          //                spi, position_source]
          for (final state in states) {
            final stateCallsign = (state[1] as String?)?.trim().toUpperCase() ?? '';
            // Match if callsign contains our flight number
            if (stateCallsign.contains(callsign) || callsign.contains(stateCallsign)) {
              return FlightInfo.fromOpenSky(state);
            }
          }
        }
      }
      debugPrint('OpenSky: Flight $callsign not found in active flights');
    } catch (e) {
      debugPrint('Error fetching flight info from OpenSky: $e');
    }
    return null;
  }

  /// Fetch weather at destination airport
  Future<WeatherInfo?> getWeatherAtAirport(String airportCode) async {
    if (!ApiConfig.isWeatherApiConfigured) {
      debugPrint('OpenWeatherMap API key not configured');
      return null;
    }

    try {
      // First get airport coordinates from a simple lookup
      final coords = _airportCoordinates[airportCode.toUpperCase()];
      if (coords == null) return null;

      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${coords['lat']}'
        '&lon=${coords['lon']}'
        '&appid=${ApiConfig.openWeatherMapKey}'
        '&units=metric'
        '&lang=it'
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherInfo.fromOpenWeather(data);
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
    return null;
  }

  // Common airport coordinates (extend as needed)
  static const Map<String, Map<String, double>> _airportCoordinates = {
    'FCO': {'lat': 41.8003, 'lon': 12.2389}, // Rome Fiumicino
    'LIN': {'lat': 45.4491, 'lon': 9.2783},  // Milan Linate
    'MXP': {'lat': 45.6306, 'lon': 8.7281},  // Milan Malpensa
    'VCE': {'lat': 45.5053, 'lon': 12.3519}, // Venice
    'NAP': {'lat': 40.8860, 'lon': 14.2908}, // Naples
    'JFK': {'lat': 40.6413, 'lon': -73.7781}, // New York JFK
    'LHR': {'lat': 51.4700, 'lon': -0.4543}, // London Heathrow
    'CDG': {'lat': 49.0097, 'lon': 2.5479},  // Paris CDG
    'FRA': {'lat': 50.0379, 'lon': 8.5622},  // Frankfurt
    'AMS': {'lat': 52.3105, 'lon': 4.7683},  // Amsterdam
    'MAD': {'lat': 40.4983, 'lon': -3.5676}, // Madrid
    'BCN': {'lat': 41.2974, 'lon': 2.0833},  // Barcelona
    'DXB': {'lat': 25.2532, 'lon': 55.3657}, // Dubai
    'SIN': {'lat': 1.3644, 'lon': 103.9915}, // Singapore
    'HND': {'lat': 35.5494, 'lon': 139.7798}, // Tokyo Haneda
    'NRT': {'lat': 35.7720, 'lon': 140.3929}, // Tokyo Narita
    'LAX': {'lat': 33.9416, 'lon': -118.4085}, // Los Angeles
    'ORD': {'lat': 41.9742, 'lon': -87.9073}, // Chicago O'Hare
    'ATL': {'lat': 33.6407, 'lon': -84.4277}, // Atlanta
    'MIA': {'lat': 25.7959, 'lon': -80.2870}, // Miami
  };
}

/// Live flight information from OpenSky Network
class FlightInfo {
  final String? status; // in_flight, on_ground
  final String? callsign;
  final String? originCountry;
  final double? longitude;
  final double? latitude;
  final double? altitude; // meters
  final double? velocity; // m/s
  final double? heading; // degrees from north
  final double? verticalRate; // m/s
  final bool? onGround;

  FlightInfo({
    this.status,
    this.callsign,
    this.originCountry,
    this.longitude,
    this.latitude,
    this.altitude,
    this.velocity,
    this.heading,
    this.verticalRate,
    this.onGround,
  });

  /// Create from OpenSky state vector
  /// [icao24, callsign, origin_country, time_position, last_contact, 
  ///  longitude, latitude, baro_altitude, on_ground, velocity, 
  ///  true_track, vertical_rate, sensors, geo_altitude, squawk, spi, position_source]
  factory FlightInfo.fromOpenSky(List<dynamic> state) {
    final isOnGround = state[8] as bool? ?? false;
    
    String status;
    if (isOnGround) {
      status = 'on_ground';
    } else {
      final vertRate = (state[11] as num?)?.toDouble() ?? 0;
      if (vertRate > 2) {
        status = 'climbing';
      } else if (vertRate < -2) {
        status = 'descending';
      } else {
        status = 'cruising';
      }
    }
    
    return FlightInfo(
      status: status,
      callsign: (state[1] as String?)?.trim(),
      originCountry: state[2] as String?,
      longitude: (state[5] as num?)?.toDouble(),
      latitude: (state[6] as num?)?.toDouble(),
      altitude: (state[7] as num?)?.toDouble(),
      onGround: isOnGround,
      velocity: (state[9] as num?)?.toDouble(),
      heading: (state[10] as num?)?.toDouble(),
      verticalRate: (state[11] as num?)?.toDouble(),
    );
  }

  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'on_ground': return 'A terra';
      case 'climbing': return 'In salita';
      case 'descending': return 'In discesa';
      case 'cruising': return 'In crociera';
      default: return 'In volo';
    }
  }

  String get statusEmoji {
    switch (status?.toLowerCase()) {
      case 'on_ground': return '🛬';
      case 'climbing': return '📈';
      case 'descending': return '📉';
      case 'cruising': return '✈️';
      default: return '✈️';
    }
  }

  /// Altitude in feet (more common in aviation)
  int? get altitudeFeet => altitude != null ? (altitude! * 3.28084).round() : null;
  
  /// Velocity in km/h
  int? get velocityKmh => velocity != null ? (velocity! * 3.6).round() : null;
  
  /// Velocity in knots (aviation standard)
  int? get velocityKnots => velocity != null ? (velocity! * 1.94384).round() : null;
  
  /// Heading as compass direction
  String get headingDirection {
    if (heading == null) return '';
    final h = heading!;
    if (h >= 337.5 || h < 22.5) return 'N';
    if (h >= 22.5 && h < 67.5) return 'NE';
    if (h >= 67.5 && h < 112.5) return 'E';
    if (h >= 112.5 && h < 157.5) return 'SE';
    if (h >= 157.5 && h < 202.5) return 'S';
    if (h >= 202.5 && h < 247.5) return 'SW';
    if (h >= 247.5 && h < 292.5) return 'W';
    return 'NW';
  }
}

/// Weather information at destination
class WeatherInfo {
  final String? description;
  final double? temperature;
  final int? humidity;
  final double? windSpeed;
  final String? icon;

  WeatherInfo({
    this.description,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.icon,
  });

  factory WeatherInfo.fromOpenWeather(Map<String, dynamic> json) {
    final weather = (json['weather'] as List?)?.first as Map<String, dynamic>?;
    final main = json['main'] as Map<String, dynamic>?;
    final wind = json['wind'] as Map<String, dynamic>?;

    return WeatherInfo(
      description: weather?['description'] as String?,
      icon: weather?['icon'] as String?,
      temperature: (main?['temp'] as num?)?.toDouble(),
      humidity: main?['humidity'] as int?,
      windSpeed: (wind?['speed'] as num?)?.toDouble(),
    );
  }

  String get weatherEmoji {
    switch (icon?.substring(0, 2)) {
      case '01': return '☀️'; // clear sky
      case '02': return '🌤️'; // few clouds
      case '03': return '☁️'; // scattered clouds
      case '04': return '☁️'; // broken clouds
      case '09': return '🌧️'; // shower rain
      case '10': return '🌦️'; // rain
      case '11': return '⛈️'; // thunderstorm
      case '13': return '❄️'; // snow
      case '50': return '🌫️'; // mist
      default: return '🌡️';
    }
  }
}
