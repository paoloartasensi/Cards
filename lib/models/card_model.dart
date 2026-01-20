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
  String? brandDomain; // Optional brand domain for logo (e.g., "esselunga.it")

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
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get Color from colorValue
  int get color => colorValue;

  /// Get the logo URL if brandDomain is set
  String? get logoUrl => brandDomain != null 
      ? 'https://logo.clearbit.com/$brandDomain' 
      : null;

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
    String? brandDomain,
    bool clearBrandDomain = false,
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
      brandDomain: clearBrandDomain ? null : (brandDomain ?? this.brandDomain),
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
      'brandDomain': brandDomain,
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
      brandDomain: json['brandDomain'] as String?,
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
  static const String voli = 'Voli';
  static const String negozi = 'Negozi';
  static const String altro = 'Altro';

  static const List<String> all = [supermercato, voli, negozi, altro];
}
