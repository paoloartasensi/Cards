import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service to fetch live flight information
class FlightInfoService {
  /// Fetch live flight info by flight number (e.g., "AZ610")
  Future<FlightInfo?> getFlightInfo(String flightNumber, DateTime? flightDate) async {
    if (!ApiConfig.isFlightApiConfigured) {
      debugPrint('AviationStack API key not configured');
      return null;
    }

    try {
      // Clean flight number
      final cleanFlightNumber = flightNumber.replaceAll(' ', '').toUpperCase();
      
      // Format date if provided
      String? dateParam;
      if (flightDate != null) {
        dateParam = '${flightDate.year}-${flightDate.month.toString().padLeft(2, '0')}-${flightDate.day.toString().padLeft(2, '0')}';
      }

      final uri = Uri.parse(
        'http://api.aviationstack.com/v1/flights'
        '?access_key=${ApiConfig.aviationStackKey}'
        '&flight_iata=$cleanFlightNumber'
        '${dateParam != null ? '&flight_date=$dateParam' : ''}'
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final flights = data['data'] as List?;
        
        if (flights != null && flights.isNotEmpty) {
          final flight = flights.first;
          return FlightInfo.fromAviationStack(flight);
        }
      }
    } catch (e) {
      debugPrint('Error fetching flight info: $e');
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

/// Live flight information
class FlightInfo {
  final String? status; // scheduled, active, landed, cancelled, etc.
  final String? departureAirport;
  final String? arrivalAirport;
  final String? departureTerminal;
  final String? departureGate;
  final String? arrivalTerminal;
  final String? arrivalGate;
  final DateTime? scheduledDeparture;
  final DateTime? estimatedDeparture;
  final DateTime? actualDeparture;
  final DateTime? scheduledArrival;
  final DateTime? estimatedArrival;
  final int? delayMinutes;

  FlightInfo({
    this.status,
    this.departureAirport,
    this.arrivalAirport,
    this.departureTerminal,
    this.departureGate,
    this.arrivalTerminal,
    this.arrivalGate,
    this.scheduledDeparture,
    this.estimatedDeparture,
    this.actualDeparture,
    this.scheduledArrival,
    this.estimatedArrival,
    this.delayMinutes,
  });

  factory FlightInfo.fromAviationStack(Map<String, dynamic> json) {
    final departure = json['departure'] as Map<String, dynamic>?;
    final arrival = json['arrival'] as Map<String, dynamic>?;
    
    return FlightInfo(
      status: json['flight_status'] as String?,
      departureAirport: departure?['iata'] as String?,
      arrivalAirport: arrival?['iata'] as String?,
      departureTerminal: departure?['terminal'] as String?,
      departureGate: departure?['gate'] as String?,
      arrivalTerminal: arrival?['terminal'] as String?,
      arrivalGate: arrival?['gate'] as String?,
      scheduledDeparture: _parseDateTime(departure?['scheduled']),
      estimatedDeparture: _parseDateTime(departure?['estimated']),
      actualDeparture: _parseDateTime(departure?['actual']),
      scheduledArrival: _parseDateTime(arrival?['scheduled']),
      estimatedArrival: _parseDateTime(arrival?['estimated']),
      delayMinutes: departure?['delay'] as int?,
    );
  }

  static DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'scheduled': return 'Programmato';
      case 'active': return 'In volo';
      case 'landed': return 'Atterrato';
      case 'cancelled': return 'Cancellato';
      case 'diverted': return 'Dirottato';
      case 'delayed': return 'In ritardo';
      default: return status ?? 'Sconosciuto';
    }
  }

  String get statusEmoji {
    switch (status?.toLowerCase()) {
      case 'scheduled': return '🕐';
      case 'active': return '✈️';
      case 'landed': return '✅';
      case 'cancelled': return '❌';
      case 'diverted': return '↩️';
      case 'delayed': return '⚠️';
      default: return '❓';
    }
  }

  bool get hasDelay => delayMinutes != null && delayMinutes! > 0;
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
