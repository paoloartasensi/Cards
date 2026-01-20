import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import 'barcode_display.dart';

/// Screen that shows the barcode in fullscreen for easier scanning
class FullscreenBarcodeView extends StatelessWidget {
  final CardModel card;

  const FullscreenBarcodeView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    // 1D barcodes are often better scanned in landscape
    final bool is1D = card.codeType != BarcodeTypes.qrCode &&
                     card.codeType != BarcodeTypes.dataMatrix &&
                     card.codeType != BarcodeTypes.pdf417 &&
                     card.codeType != BarcodeTypes.aztec;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                card.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Center(
              child: Hero(
                tag: 'barcode_${card.id}',
                child: is1D 
                  ? RotatedBox(
                      quarterTurns: 1, // Rotate 90 degrees for 1D barcodes
                      child: BarcodeDisplay(
                        card: card,
                        height: MediaQuery.of(context).size.width * 0.8,
                        width: MediaQuery.of(context).size.height * 0.6,
                        backgroundColor: Colors.transparent,
                        barcodeColor: Colors.black,
                      ),
                    )
                  : BarcodeDisplay(
                      card: card,
                      height: MediaQuery.of(context).size.width * 0.8,
                      backgroundColor: Colors.transparent,
                      barcodeColor: Colors.black,
                    ),
              ),
            ),
            const Spacer(),
            if (is1D)
              const Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: Text(
                  'Ruota il telefono se necessario',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
