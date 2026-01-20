import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../services/scanner_service.dart';

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
  
  late String _selectedCategory;
  late String _selectedCodeType;
  late int _selectedColor;
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  
  // Brand detection
  String? _detectedBrandDomain;
  String? _selectedBrandDomain;
  bool _isDetectingBrand = false;
  bool _brandSuggestionDismissed = false;

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
      _selectedBrandDomain = card.brandDomain;
    } else {
      _selectedCategory = CardCategories.altro;
      _selectedCodeType = BarcodeTypes.code128;
      _selectedColor = 0xFF2196F3;
    }
    
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _codeController.dispose();
    _noteController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  /// Called when name changes - try to detect brand
  void _onNameChanged() {
    if (_brandSuggestionDismissed) return;
    
    final name = _nameController.text.trim();
    if (name.length >= 3) {
      _detectBrand(name);
    } else {
      setState(() {
        _detectedBrandDomain = null;
      });
    }
  }

  /// Try to detect a brand domain from the name
  Future<void> _detectBrand(String name) async {
    if (_isDetectingBrand) return;
    
    setState(() => _isDetectingBrand = true);
    
    // Clean the name and generate possible domains
    final cleaned = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
    
    if (cleaned.isEmpty) {
      setState(() {
        _isDetectingBrand = false;
        _detectedBrandDomain = null;
      });
      return;
    }

    // Try different domain variations
    final domainsToTry = [
      '$cleaned.com',
      '$cleaned.it',
      '$cleaned.eu',
      // Try with common variations
      if (cleaned.length > 4) '${cleaned.substring(0, cleaned.length > 10 ? 10 : cleaned.length)}.com',
    ];

    for (final domain in domainsToTry) {
      final exists = await _checkLogoExists(domain);
      if (exists && mounted) {
        setState(() {
          _detectedBrandDomain = domain;
          _isDetectingBrand = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _detectedBrandDomain = null;
        _isDetectingBrand = false;
      });
    }
  }

  /// Check if a logo exists for the given domain using Clearbit
  Future<bool> _checkLogoExists(String domain) async {
    try {
      final response = await http.head(
        Uri.parse('https://logo.clearbit.com/$domain'),
      ).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Accept the brand suggestion
  void _acceptBrandSuggestion() {
    setState(() {
      _selectedBrandDomain = _detectedBrandDomain;
    });
  }

  /// Dismiss the brand suggestion
  void _dismissBrandSuggestion() {
    setState(() {
      _brandSuggestionDismissed = true;
      _detectedBrandDomain = null;
    });
  }

  /// Remove the selected brand
  void _removeBrand() {
    setState(() {
      _selectedBrandDomain = null;
      _brandSuggestionDismissed = false;
    });
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
      setState(() {
        _codeController.text = result.code;
        _selectedCodeType = result.codeType;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Codice rilevato: ${BarcodeTypes.getDisplayName(result.codeType)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final result = await _scannerService.scanFromGallery();
      if (result != null) {
        setState(() {
          _codeController.text = result.code;
          _selectedCodeType = result.codeType;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Codice rilevato: ${BarcodeTypes.getDisplayName(result.codeType)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      // Use selected brand domain, or detected if user hasn't dismissed it
      final brandDomain = _selectedBrandDomain ?? 
          (!_brandSuggestionDismissed ? _detectedBrandDomain : null);
      
      if (widget.isEditing) {
        // Update existing card
        final updatedCard = widget.cardToEdit!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          codeType: _selectedCodeType,
          category: _selectedCategory,
          colorValue: _selectedColor,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          brandDomain: brandDomain,
          clearBrandDomain: brandDomain == null,
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
          brandDomain: brandDomain,
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
            const SizedBox(height: 12),
            
            // Brand logo suggestion/display
            _buildBrandSection(),
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
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

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

  Widget _buildBrandSection() {
    // If user already selected a brand, show it
    if (_selectedBrandDomain != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: 'https://logo.clearbit.com/$_selectedBrandDomain',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logo brand attivo',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _selectedBrandDomain!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removeBrand,
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              tooltip: 'Rimuovi logo',
            ),
          ],
        ),
      );
    }

    // If a brand was detected but not yet accepted, show suggestion
    if (_detectedBrandDomain != null && !_brandSuggestionDismissed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: 'https://logo.clearbit.com/$_detectedBrandDomain',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logo trovato!',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Vuoi usare questo logo?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _dismissBrandSuggestion,
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              tooltip: 'No, grazie',
            ),
            IconButton(
              onPressed: _acceptBrandSuggestion,
              icon: const Icon(Icons.check, color: Colors.green, size: 20),
              tooltip: 'Usa questo logo',
            ),
          ],
        ),
      );
    }

    // If detecting brand, show loading
    if (_isDetectingBrand) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Cerco logo brand...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Nothing to show
    return const SizedBox.shrink();
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
