import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../services/scanner_service.dart';
import '../services/bcbp_parser.dart';

/// Screen for adding or editing a card
class AddCardScreen extends ConsumerStatefulWidget {
  final CardModel? cardToEdit;

  const AddCardScreen({super.key, this.cardToEdit});

  bool get isEditing => cardToEdit != null;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _noteController = TextEditingController();
  final _scannerService = ScannerService();
  
  // Flight-specific controllers
  final _flightRouteController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _departureTimeController = TextEditingController();
  DateTime? _flightDate;
  
  // Additional flight fields (from boarding pass)
  String? _seatNumber;
  String? _travelClass;
  String? _pnr;
  String? _passengerName;
  
  late String _selectedCategory;
  late String _selectedCodeType;
  late int _selectedColor;
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    final card = widget.cardToEdit;
    if (card != null) {
      _nameController.text = card.name;
      _codeController.text = card.code;
      _noteController.text = card.note ?? '';
      _selectedCategory = card.category;
      _selectedCodeType = card.codeType;
      _selectedColor = card.colorValue;
      // Flight fields
      _flightRouteController.text = card.flightRoute ?? '';
      _flightNumberController.text = card.flightNumber ?? '';
      _departureTimeController.text = card.departureTime ?? '';
      _flightDate = card.flightDate;
    } else {
      _selectedCategory = CardCategories.altro;
      _selectedCodeType = BarcodeTypes.code128;
      _selectedColor = 0xFF2196F3;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _noteController.dispose();
    _flightRouteController.dispose();
    _flightNumberController.dispose();
    _departureTimeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  final List<int> _availableColors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
    0xFF00BCD4, // Cyan
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFF000000, // Black
  ];

  void _startScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    setState(() => _isScanning = true);
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isScanning = false);
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final result = _scannerService.parseMobileScannerBarcode(capture);
    if (result != null) {
      _stopScanner();
      _processScannedCode(result.code, result.codeType);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final result = await _scannerService.scanFromGallery();
      if (result != null) {
        _processScannedCode(result.code, result.codeType);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nessun codice trovato nell\'immagine'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process scanned barcode - detect boarding pass and auto-fill fields
  void _processScannedCode(String code, String codeType) {
    setState(() {
      _codeController.text = code;
      _selectedCodeType = codeType;
    });

    // Try to detect if it's a boarding pass
    if (BcbpParser.isBoardingPass(code, codeType)) {
      final bcbpData = BcbpParser.parse(code);
      
      if (bcbpData != null && bcbpData.isValid) {
        // Auto-fill all flight fields!
        setState(() {
          _selectedCategory = CardCategories.voli;
          
          // Set suggested name or use flight number
          if (_nameController.text.isEmpty) {
            _nameController.text = bcbpData.suggestedCardName;
          }
          
          // Fill flight-specific fields
          if (bcbpData.route != null) {
            _flightRouteController.text = bcbpData.route!;
          }
          if (bcbpData.flightNumber != null) {
            _flightNumberController.text = bcbpData.flightNumber!;
          }
          if (bcbpData.flightDate != null) {
            _flightDate = bcbpData.flightDate;
          }
          
          // Save additional boarding pass info
          _seatNumber = bcbpData.seatNumber;
          _travelClass = bcbpData.travelClass;
          _pnr = bcbpData.pnr;
          _passengerName = bcbpData.passengerName;
          
          // Set a nice color for flights
          _selectedColor = 0xFF2196F3; // Blue for flights
        });

        // Show success message with extracted info
        if (mounted) {
          _showBoardingPassDetectedDialog(bcbpData);
        }
        return;
      }
    }

    // Regular barcode - just show simple message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Codice rilevato: ${BarcodeTypes.getDisplayName(codeType)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show dialog when boarding pass is detected
  void _showBoardingPassDetectedDialog(BcbpData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('✈️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Boarding Pass rilevato!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.passengerName != null)
              _buildInfoItem('👤 Passeggero', data.passengerName!),
            if (data.flightNumber != null)
              _buildInfoItem('✈️ Volo', data.flightNumber!),
            if (data.route != null)
              _buildInfoItem('📍 Tratta', data.route!),
            if (data.flightDate != null)
              _buildInfoItem('📅 Data', 
                '${data.flightDate!.day.toString().padLeft(2, '0')}/${data.flightDate!.month.toString().padLeft(2, '0')}/${data.flightDate!.year}'),
            if (data.seatNumber != null)
              _buildInfoItem('💺 Posto', data.seatNumber!),
            if (data.travelClass != null)
              _buildInfoItem('🎫 Classe', data.travelClass!),
            if (data.pnr != null)
              _buildInfoItem('🔖 PNR', data.pnr!),
            const SizedBox(height: 12),
            Text(
              'I campi sono stati compilati automaticamente!',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isFlightCategory = _selectedCategory == CardCategories.voli;
    
    try {
      if (widget.isEditing) {
        // Update existing card
        final updatedCard = widget.cardToEdit!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          codeType: _selectedCodeType,
          category: _selectedCategory,
          colorValue: _selectedColor,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          flightDate: isFlightCategory ? _flightDate : null,
          flightRoute: isFlightCategory && _flightRouteController.text.trim().isNotEmpty
              ? _flightRouteController.text.trim() : null,
          flightNumber: isFlightCategory && _flightNumberController.text.trim().isNotEmpty
              ? _flightNumberController.text.trim() : null,
          departureTime: isFlightCategory && _departureTimeController.text.trim().isNotEmpty
              ? _departureTimeController.text.trim() : null,
          seatNumber: isFlightCategory ? _seatNumber : null,
          travelClass: isFlightCategory ? _travelClass : null,
          pnr: isFlightCategory ? _pnr : null,
          passengerName: isFlightCategory ? _passengerName : null,
        );
        await ref.read(cardsProvider.notifier).updateCard(updatedCard);
      } else {
        // Add new card
        await ref.read(cardsProvider.notifier).addCard(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          codeType: _selectedCodeType,
          category: _selectedCategory,
          colorValue: _selectedColor,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          flightDate: isFlightCategory ? _flightDate : null,
          flightRoute: isFlightCategory && _flightRouteController.text.trim().isNotEmpty
              ? _flightRouteController.text.trim() : null,
          flightNumber: isFlightCategory && _flightNumberController.text.trim().isNotEmpty
              ? _flightNumberController.text.trim() : null,
          departureTime: isFlightCategory && _departureTimeController.text.trim().isNotEmpty
              ? _departureTimeController.text.trim() : null,
          seatNumber: isFlightCategory ? _seatNumber : null,
          travelClass: isFlightCategory ? _travelClass : null,
          pnr: isFlightCategory ? _pnr : null,
          passengerName: isFlightCategory ? _passengerName : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Tessera aggiornata!' : 'Tessera salvata!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (_isScanning) {
              _stopScanner();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isScanning ? 'Scansiona codice' : (widget.isEditing ? 'Modifica tessera' : 'Nuova tessera'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isScanning ? _buildScannerView() : _buildFormView(),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onBarcodeDetected,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Inquadra il codice a barre o QR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    label: 'Scansiona',
                    onTap: _startScanner,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Da immagine',
                    onTap: _scanFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Nome tessera',
              hint: 'es. Esselunga, Coop...',
              icon: Icons.credit_card,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci un nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Code field
            _buildTextField(
              controller: _codeController,
              label: 'Codice',
              hint: 'Scansiona o inserisci manualmente',
              icon: Icons.qr_code,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci il codice';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Code type selector
            _buildLabel('Tipo codice'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCodeType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  items: BarcodeTypes.all.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(BarcodeTypes.getDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCodeType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category selector
            _buildLabel('Categoria'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CardCategories.all.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Color(_selectedColor)
                        : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                          ? Colors.transparent 
                          : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CardCategories.getIcon(category),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Flight-specific fields (only when category is Voli)
            if (_selectedCategory == CardCategories.voli) ...[
              _buildFlightFields(),
              const SizedBox(height: 16),
            ],

            // Color selector
            _buildLabel('Colore'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Note field
            _buildTextField(
              controller: _noteController,
              label: 'Note (opzionale)',
              hint: 'Aggiungi informazioni extra...',
              icon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_selectedColor),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Color(_selectedColor).withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Salva tessera',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFlightFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
          _buildTextField(
            controller: _flightRouteController,
            label: 'Tratta',
            hint: 'es. FCO → JFK',
            icon: Icons.flight_takeoff,
          ),
          const SizedBox(height: 12),
          
          // Flight number and departure time in a row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _flightNumberController,
                  label: 'N° Volo',
                  hint: 'es. AZ610',
                  icon: Icons.confirmation_number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _departureTimeController,
                  label: 'Orario',
                  hint: 'es. 14:30',
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Flight date picker
          _buildLabel('Data del volo'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectFlightDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Text(
                    _flightDate != null
                        ? '${_flightDate!.day.toString().padLeft(2, '0')}/${_flightDate!.month.toString().padLeft(2, '0')}/${_flightDate!.year}'
                        : 'Seleziona data',
                    style: TextStyle(
                      color: _flightDate != null 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const Spacer(),
                  if (_flightDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _flightDate = null),
                      child: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFlightDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _flightDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(_selectedColor),
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _flightDate = picked);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(_selectedColor)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
