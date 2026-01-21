/// BCBP (Bar Coded Boarding Pass) Parser
/// 
/// Parses IATA standard boarding pass barcodes to extract flight information.
/// Reference: IATA Resolution 792 - Bar Coded Boarding Pass
library;

class BcbpParser {
  /// Parse a BCBP barcode string and extract flight information
  static BcbpData? parse(String barcode) {
    if (barcode.isEmpty || barcode.length < 23) {
      return null;
    }

    try {
      // BCBP format starts with 'M' for multiple leg or 'S' for single
      final formatCode = barcode[0];
      if (formatCode != 'M' && formatCode != 'S' && formatCode != '1') {
        // Try to detect if it's still a valid boarding pass
        if (!_looksLikeBcbp(barcode)) {
          return null;
        }
      }

      // Number of legs (1 character at position 1)
      // ignore: unused_local_variable - kept for reference
      final numLegsStr = barcode.length > 1 ? barcode[1] : '1';

      // Passenger name (20 characters, positions 2-21)
      String passengerName = '';
      if (barcode.length >= 22) {
        passengerName = barcode.substring(2, 22).trim();
        // Convert from LASTNAME/FIRSTNAME format
        passengerName = _formatPassengerName(passengerName);
      }

      // Electronic ticket indicator (1 char at position 22)
      // 'E' = electronic ticket
      
      // PNR (Booking reference) - 7 characters at positions 23-29
      String pnr = '';
      if (barcode.length >= 30) {
        pnr = barcode.substring(23, 30).trim();
      }

      // From airport (3 chars at positions 30-32)
      String fromAirport = '';
      if (barcode.length >= 33) {
        fromAirport = barcode.substring(30, 33).trim();
      }

      // To airport (3 chars at positions 33-35)
      String toAirport = '';
      if (barcode.length >= 36) {
        toAirport = barcode.substring(33, 36).trim();
      }

      // Operating carrier (2-3 chars at positions 36-38)
      String carrier = '';
      if (barcode.length >= 39) {
        carrier = barcode.substring(36, 39).trim();
      }

      // Flight number (5 chars at positions 39-43, may include letter suffix)
      String flightNumber = '';
      if (barcode.length >= 44) {
        flightNumber = barcode.substring(39, 44).trim();
        // Remove leading zeros
        flightNumber = flightNumber.replaceFirst(RegExp(r'^0+'), '');
      }

      // Julian date of flight (3 chars at positions 44-46)
      // Day of year (001-366)
      DateTime? flightDate;
      if (barcode.length >= 47) {
        final julianDay = int.tryParse(barcode.substring(44, 47));
        if (julianDay != null && julianDay > 0 && julianDay <= 366) {
          flightDate = _julianToDate(julianDay);
        }
      }

      // Compartment code (1 char at position 47) - class of travel
      String travelClass = '';
      if (barcode.length >= 48) {
        travelClass = _parseCompartmentCode(barcode[47]);
      }

      // Seat number (4 chars at positions 48-51)
      String seatNumber = '';
      if (barcode.length >= 52) {
        seatNumber = barcode.substring(48, 52).trim();
        // Remove leading zeros
        seatNumber = seatNumber.replaceFirst(RegExp(r'^0+'), '');
      }

      // Check-in sequence number (5 chars at positions 52-56)
      String checkInSequence = '';
      if (barcode.length >= 57) {
        checkInSequence = barcode.substring(52, 57).trim();
      }

      // Passenger status (1 char at position 57)
      // 0 = checked in, 1 = not checked in, etc.

      // Build full flight number with carrier
      final fullFlightNumber = carrier.isNotEmpty 
          ? '$carrier$flightNumber' 
          : flightNumber;

      // Build route
      final route = fromAirport.isNotEmpty && toAirport.isNotEmpty
          ? '$fromAirport → $toAirport'
          : null;

      return BcbpData(
        passengerName: passengerName.isNotEmpty ? passengerName : null,
        pnr: pnr.isNotEmpty ? pnr : null,
        fromAirport: fromAirport.isNotEmpty ? fromAirport : null,
        toAirport: toAirport.isNotEmpty ? toAirport : null,
        carrier: carrier.isNotEmpty ? carrier : null,
        flightNumber: fullFlightNumber.isNotEmpty ? fullFlightNumber : null,
        flightDate: flightDate,
        travelClass: travelClass.isNotEmpty ? travelClass : null,
        seatNumber: seatNumber.isNotEmpty ? seatNumber : null,
        checkInSequence: checkInSequence.isNotEmpty ? checkInSequence : null,
        route: route,
        rawData: barcode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if string looks like a BCBP barcode
  static bool _looksLikeBcbp(String data) {
    // Must have minimum length
    if (data.length < 30) return false;
    
    // Should contain airport-like codes (3 uppercase letters)
    final airportPattern = RegExp(r'[A-Z]{3}[A-Z]{3}');
    return airportPattern.hasMatch(data);
  }

  /// Convert LASTNAME/FIRSTNAME to proper format
  static String _formatPassengerName(String name) {
    if (name.contains('/')) {
      final parts = name.split('/');
      if (parts.length >= 2) {
        final lastName = _capitalize(parts[0].trim());
        final firstName = _capitalize(parts[1].trim());
        return '$firstName $lastName';
      }
    }
    return _capitalize(name);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Convert Julian day to DateTime
  /// Assumes current year, or next year if date has passed
  static DateTime _julianToDate(int julianDay) {
    final now = DateTime.now();
    var year = now.year;
    
    // Create date from julian day
    var date = DateTime(year, 1, 1).add(Duration(days: julianDay - 1));
    
    // If date is more than 30 days in the past, assume next year
    if (date.isBefore(now.subtract(const Duration(days: 30)))) {
      date = DateTime(year + 1, 1, 1).add(Duration(days: julianDay - 1));
    }
    
    return date;
  }

  /// Parse compartment/class code
  static String _parseCompartmentCode(String code) {
    switch (code.toUpperCase()) {
      case 'F': return 'First';
      case 'A': return 'First';
      case 'P': return 'First Premium';
      case 'J': return 'Business';
      case 'C': return 'Business';
      case 'D': return 'Business';
      case 'I': return 'Business';
      case 'Z': return 'Business';
      case 'W': return 'Premium Economy';
      case 'Y': return 'Economy';
      case 'B': return 'Economy';
      case 'H': return 'Economy';
      case 'K': return 'Economy';
      case 'L': return 'Economy';
      case 'M': return 'Economy';
      case 'N': return 'Economy';
      case 'Q': return 'Economy';
      case 'S': return 'Economy';
      case 'T': return 'Economy';
      case 'V': return 'Economy';
      case 'X': return 'Economy';
      default: return code;
    }
  }

  /// Try to detect if a barcode is a boarding pass
  static bool isBoardingPass(String barcode, String barcodeType) {
    // PDF417 and Aztec are most common for boarding passes
    if (barcodeType == 'pdf417' || barcodeType == 'aztec') {
      return barcode.length >= 30 && _looksLikeBcbp(barcode);
    }
    // QR codes sometimes used too
    if (barcodeType == 'qrCode') {
      return barcode.length >= 30 && _looksLikeBcbp(barcode);
    }
    return false;
  }
}

/// Parsed BCBP boarding pass data
class BcbpData {
  final String? passengerName;
  final String? pnr;
  final String? fromAirport;
  final String? toAirport;
  final String? carrier;
  final String? flightNumber;
  final DateTime? flightDate;
  final String? travelClass;
  final String? seatNumber;
  final String? checkInSequence;
  final String? route;
  final String rawData;

  BcbpData({
    this.passengerName,
    this.pnr,
    this.fromAirport,
    this.toAirport,
    this.carrier,
    this.flightNumber,
    this.flightDate,
    this.travelClass,
    this.seatNumber,
    this.checkInSequence,
    this.route,
    required this.rawData,
  });

  /// Check if this looks like valid boarding pass data
  bool get isValid {
    return flightNumber != null && 
           fromAirport != null && 
           toAirport != null;
  }

  /// Get a suggested card name
  String get suggestedCardName {
    if (carrier != null && route != null) {
      return '$carrier - $route';
    }
    if (flightNumber != null) {
      return 'Volo $flightNumber';
    }
    return 'Boarding Pass';
  }

  @override
  String toString() {
    return 'BcbpData(passenger: $passengerName, flight: $flightNumber, '
           'route: $route, date: $flightDate, seat: $seatNumber)';
  }
}
