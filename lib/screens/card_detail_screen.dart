import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../models/card_model.dart';
import '../widgets/barcode_display.dart';
import '../widgets/fullscreen_barcode_view.dart';
import '../widgets/flight_live_info.dart';
import 'add_card_screen.dart';

/// Screen to display card details with full barcode
class CardDetailScreen extends ConsumerStatefulWidget {
  final CardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Set maximum brightness for barcode scanning
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _boostBrightness();
  }

  Future<void> _boostBrightness() async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Error resetting brightness: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _resetBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          card.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await navigator.push(
                MaterialPageRoute(
                  builder: (context) => AddCardScreen(cardToEdit: card),
                ),
              );
              // Refresh when coming back from edit
              if (mounted) navigator.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Card preview
            Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(minHeight: 160),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(card.colorValue),
                    Color(card.colorValue).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(card.colorValue).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background decoration
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                card.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                card.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          BarcodeTypes.getDisplayName(card.codeType),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.code,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        // Flight info on card preview
                        if (card.category == CardCategories.voli && 
                            (card.flightRoute != null || card.flightDate != null)) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (card.flightRoute != null) ...[
                                  const Text('✈️', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    card.flightRoute!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                if (card.flightRoute != null && card.flightDate != null)
                                  const SizedBox(width: 12),
                                if (card.flightDate != null)
                                  Text(
                                    '${card.flightDate!.day.toString().padLeft(2, '0')}/${card.flightDate!.month.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Barcode display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullscreenBarcodeView(card: card),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'barcode_${card.id}',
                      child: BarcodeDisplay(
                        card: card,
                        height: 180,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Note if present
            if (card.note != null && card.note!.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        card.note!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Flight details section
            if (card.category == CardCategories.voli && _hasFlightInfo(card))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('✈️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Dettagli Volo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Flight route
                    if (card.flightRoute != null)
                      _buildFlightDetailRow(Icons.flight_takeoff, 'Tratta', card.flightRoute!),
                    
                    // Flight number
                    if (card.flightNumber != null)
                      _buildFlightDetailRow(Icons.confirmation_number, 'N° Volo', card.flightNumber!),
                    
                    // Flight date
                    if (card.flightDate != null)
                      _buildFlightDetailRow(
                        Icons.calendar_today, 
                        'Data', 
                        '${card.flightDate!.day.toString().padLeft(2, '0')}/${card.flightDate!.month.toString().padLeft(2, '0')}/${card.flightDate!.year}',
                      ),
                    
                    // Departure time
                    if (card.departureTime != null)
                      _buildFlightDetailRow(Icons.access_time, 'Orario', card.departureTime!),
                  ],
                ),
              ),
            
            // Live flight info (API)
            if (card.category == CardCategories.voli && card.flightNumber != null)
              FlightLiveInfo(card: card),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _hasFlightInfo(CardModel card) {
    return card.flightRoute != null || 
           card.flightNumber != null || 
           card.flightDate != null || 
           card.departureTime != null;
  }

  Widget _buildFlightDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
