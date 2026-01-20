import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../models/card_model.dart';

/// Widget to display a barcode or QR code
class BarcodeDisplay extends StatelessWidget {
  final CardModel card;
  final double height;
  final double? width;
  final Color backgroundColor;
  final Color barcodeColor;

  const BarcodeDisplay({
    super.key,
    required this.card,
    this.height = 120,
    this.width,
    this.backgroundColor = Colors.white,
    this.barcodeColor = Colors.black,
  });

  bw.Barcode _getBarcodeType() {
    switch (card.codeType) {
      case BarcodeTypes.ean13:
        return bw.Barcode.ean13();
      case BarcodeTypes.ean8:
        return bw.Barcode.ean8();
      case BarcodeTypes.code128:
        return bw.Barcode.code128();
      case BarcodeTypes.code39:
        return bw.Barcode.code39();
      case BarcodeTypes.code93:
        return bw.Barcode.code93();
      case BarcodeTypes.codabar:
        return bw.Barcode.codabar();
      case BarcodeTypes.itf:
        return bw.Barcode.itf();
      case BarcodeTypes.upca:
        return bw.Barcode.upcA();
      case BarcodeTypes.upce:
        return bw.Barcode.upcE();
      case BarcodeTypes.qrCode:
        return bw.Barcode.qrCode();
      case BarcodeTypes.dataMatrix:
        return bw.Barcode.dataMatrix();
      case BarcodeTypes.pdf417:
        return bw.Barcode.pdf417();
      case BarcodeTypes.aztec:
        return bw.Barcode.aztec();
      default:
        return bw.Barcode.code128();
    }
  }

  bool get _is2D {
    return card.codeType == BarcodeTypes.qrCode ||
           card.codeType == BarcodeTypes.dataMatrix ||
           card.codeType == BarcodeTypes.pdf417 ||
           card.codeType == BarcodeTypes.aztec;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight - 32;
          final barcodeHeight = _is2D 
              ? (availableHeight - 20).clamp(50.0, height)
              : availableHeight.clamp(50.0, height);
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: barcodeHeight,
                width: _is2D ? barcodeHeight : width,
                child: bw.BarcodeWidget(
              data: card.code,
              barcode: _getBarcodeType(),
              color: barcodeColor,
              drawText: !_is2D,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: barcodeColor,
              ),
              errorBuilder: (context, error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Codice non valido',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_is2D) ...[
            const SizedBox(height: 8),
            Text(
              card.code,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: barcodeColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
            ],
          );
        },
      ),
    );
  }
}
