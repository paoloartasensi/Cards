import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import '../models/card_model.dart';

/// Result of a barcode scan
class ScanResult {
  final String code;
  final String codeType;

  ScanResult({required this.code, required this.codeType});
}

/// Service for scanning barcodes from camera or images
class ScannerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Convert MobileScanner BarcodeFormat to our internal type string
  String _convertMobileScannerFormat(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return BarcodeTypes.ean13;
      case BarcodeFormat.ean8:
        return BarcodeTypes.ean8;
      case BarcodeFormat.code128:
        return BarcodeTypes.code128;
      case BarcodeFormat.code39:
        return BarcodeTypes.code39;
      case BarcodeFormat.code93:
        return BarcodeTypes.code93;
      case BarcodeFormat.codabar:
        return BarcodeTypes.codabar;
      case BarcodeFormat.itf:
        return BarcodeTypes.itf;
      case BarcodeFormat.upcA:
        return BarcodeTypes.upca;
      case BarcodeFormat.upcE:
        return BarcodeTypes.upce;
      case BarcodeFormat.qrCode:
        return BarcodeTypes.qrCode;
      case BarcodeFormat.dataMatrix:
        return BarcodeTypes.dataMatrix;
      case BarcodeFormat.pdf417:
        return BarcodeTypes.pdf417;
      case BarcodeFormat.aztec:
        return BarcodeTypes.aztec;
      default:
        return BarcodeTypes.code128; // Default fallback
    }
  }

  /// Convert Google ML Kit BarcodeFormat to our internal type string
  String _convertMlKitFormat(mlkit.BarcodeFormat format) {
    switch (format) {
      case mlkit.BarcodeFormat.ean13:
        return BarcodeTypes.ean13;
      case mlkit.BarcodeFormat.ean8:
        return BarcodeTypes.ean8;
      case mlkit.BarcodeFormat.code128:
        return BarcodeTypes.code128;
      case mlkit.BarcodeFormat.code39:
        return BarcodeTypes.code39;
      case mlkit.BarcodeFormat.code93:
        return BarcodeTypes.code93;
      case mlkit.BarcodeFormat.codabar:
        return BarcodeTypes.codabar;
      case mlkit.BarcodeFormat.itf:
        return BarcodeTypes.itf;
      case mlkit.BarcodeFormat.upca:
        return BarcodeTypes.upca;
      case mlkit.BarcodeFormat.upce:
        return BarcodeTypes.upce;
      case mlkit.BarcodeFormat.qrCode:
        return BarcodeTypes.qrCode;
      case mlkit.BarcodeFormat.dataMatrix:
        return BarcodeTypes.dataMatrix;
      case mlkit.BarcodeFormat.pdf417:
        return BarcodeTypes.pdf417;
      case mlkit.BarcodeFormat.aztec:
        return BarcodeTypes.aztec;
      default:
        return BarcodeTypes.code128;
    }
  }

  /// Parse a barcode from MobileScanner result
  ScanResult? parseMobileScannerBarcode(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return null;
    
    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    
    if (rawValue == null || rawValue.isEmpty) return null;

    return ScanResult(
      code: rawValue,
      codeType: _convertMobileScannerFormat(barcode.format),
    );
  }

  /// Pick an image from gallery and scan for barcodes
  Future<ScanResult?> scanFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile == null) return null;

    return await scanFromFile(File(pickedFile.path));
  }

  /// Scan barcode from a file
  Future<ScanResult?> scanFromFile(File file) async {
    final inputImage = mlkit.InputImage.fromFile(file);
    final barcodeScanner = mlkit.BarcodeScanner();

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      
      if (barcodes.isEmpty) return null;

      final barcode = barcodes.first;
      final rawValue = barcode.rawValue;
      
      if (rawValue == null || rawValue.isEmpty) return null;

      return ScanResult(
        code: rawValue,
        codeType: _convertMlKitFormat(barcode.format),
      );
    } finally {
      await barcodeScanner.close();
    }
  }
}
