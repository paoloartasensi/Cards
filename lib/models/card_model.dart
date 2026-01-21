import 'package:hive/hive.dart';

part 'card_model.g.dart';

/// Represents a loyalty card, boarding pass, or any barcode/QR code-based card
@HiveType(typeId: 0)
class CardModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String code;

  @HiveField(3)
  String codeType; // ean13, ean8, code128, code39, qrCode, dataMatrix, etc.

  @HiveField(4)
  String category; // Supermercato, Voli, Negozi, Altro

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? note;

  @HiveField(8)
  String? brandDomain; // Kept for backward compatibility with existing data

  // Flight-specific fields (optional, used when category is "Voli")
  @HiveField(9)
  DateTime? flightDate;

  @HiveField(10)
  String? flightRoute; // e.g., "FCO → JFK"

  @HiveField(11)
  String? flightNumber; // e.g., "AZ610"

  @HiveField(12)
  String? departureTime; // e.g., "14:30"

  @HiveField(13)
  String? seatNumber; // e.g., "23A"

  @HiveField(14)
  String? travelClass; // e.g., "Economy", "Business"

  @HiveField(15)
  String? pnr; // Booking reference

  @HiveField(16)
  String? passengerName; // Passenger name from boarding pass

  CardModel({
    required this.id,
    required this.name,
    required this.code,
    required this.codeType,
    this.category = 'Altro',
    this.colorValue = 0xFF2196F3, // Default blue
    DateTime? createdAt,
    this.note,
    this.brandDomain,
    this.flightDate,
    this.flightRoute,
    this.flightNumber,
    this.departureTime,
    this.seatNumber,
    this.travelClass,
    this.pnr,
    this.passengerName,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get Color from colorValue
  int get color => colorValue;

  /// Create a copy with modified fields
  CardModel copyWith({
    String? id,
    String? name,
    String? code,
    String? codeType,
    String? category,
    int? colorValue,
    DateTime? createdAt,
    String? note,
    DateTime? flightDate,
    String? flightRoute,
    String? flightNumber,
    String? departureTime,
    String? seatNumber,
    String? travelClass,
    String? pnr,
    String? passengerName,
  }) {
    return CardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      codeType: codeType ?? this.codeType,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      flightDate: flightDate ?? this.flightDate,
      flightRoute: flightRoute ?? this.flightRoute,
      flightNumber: flightNumber ?? this.flightNumber,
      departureTime: departureTime ?? this.departureTime,
      seatNumber: seatNumber ?? this.seatNumber,
      travelClass: travelClass ?? this.travelClass,
      pnr: pnr ?? this.pnr,
      passengerName: passengerName ?? this.passengerName,
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'codeType': codeType,
      'category': category,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'flightDate': flightDate?.toIso8601String(),
      'flightRoute': flightRoute,
      'flightNumber': flightNumber,
      'departureTime': departureTime,
      'seatNumber': seatNumber,
      'travelClass': travelClass,
      'pnr': pnr,
      'passengerName': passengerName,
    };
  }

  /// Create from JSON for import
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      codeType: json['codeType'] as String,
      category: json['category'] as String? ?? 'Altro',
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
      flightDate: json['flightDate'] != null 
          ? DateTime.parse(json['flightDate'] as String) 
          : null,
      flightRoute: json['flightRoute'] as String?,
      flightNumber: json['flightNumber'] as String?,
      departureTime: json['departureTime'] as String?,
      seatNumber: json['seatNumber'] as String?,
      travelClass: json['travelClass'] as String?,
      pnr: json['pnr'] as String?,
      passengerName: json['passengerName'] as String?,
    );
  }
}

/// List of supported barcode types for display
class BarcodeTypes {
  static const String ean13 = 'ean13';
  static const String ean8 = 'ean8';
  static const String code128 = 'code128';
  static const String code39 = 'code39';
  static const String code93 = 'code93';
  static const String codabar = 'codabar';
  static const String itf = 'itf';
  static const String upca = 'upca';
  static const String upce = 'upce';
  static const String qrCode = 'qrCode';
  static const String dataMatrix = 'dataMatrix';
  static const String pdf417 = 'pdf417';
  static const String aztec = 'aztec';

  static const List<String> all = [
    ean13, ean8, code128, code39, code93, codabar, itf, upca, upce,
    qrCode, dataMatrix, pdf417, aztec,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case ean13: return 'EAN-13';
      case ean8: return 'EAN-8';
      case code128: return 'Code 128';
      case code39: return 'Code 39';
      case code93: return 'Code 93';
      case codabar: return 'Codabar';
      case itf: return 'ITF';
      case upca: return 'UPC-A';
      case upce: return 'UPC-E';
      case qrCode: return 'QR Code';
      case dataMatrix: return 'Data Matrix';
      case pdf417: return 'PDF417';
      case aztec: return 'Aztec';
      default: return type.toUpperCase();
    }
  }
}

/// Card categories
class CardCategories {
  static const String supermercato = 'Supermercato';
  static const String negozi = 'Negozi';
  static const String trasporti = 'Trasporti';
  static const String voli = 'Voli';
  static const String sport = 'Sport';
  static const String salute = 'Salute';
  static const String carburante = 'Carburante';
  static const String ristorazione = 'Ristorazione';
  static const String altro = 'Altro';

  static const List<String> all = [
    supermercato, negozi, trasporti, voli, 
    sport, salute, carburante, ristorazione, altro,
  ];

  /// Get icon for category
  static String getIcon(String category) {
    switch (category) {
      case supermercato: return '🛒';
      case negozi: return '🛍️';
      case trasporti: return '🚇';
      case voli: return '✈️';
      case sport: return '🏋️';
      case salute: return '💊';
      case carburante: return '⛽';
      case ristorazione: return '🍕';
      case altro: return '📇';
      default: return '📇';
    }
  }
}
