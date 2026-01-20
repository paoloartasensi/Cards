import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../widgets/wallet_card.dart';
import '../widgets/swipeable_card_stack.dart';
import 'card_detail_screen.dart';
import 'add_card_screen.dart';

/// Home screen with wallet-style card stack
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  String? _selectedCategory;
  int? _expandedIndex;
  bool _useSwipeMode = true; // Toggle between swipe and list mode

  @override
  void initState() {
    super.initState();
    // Load cards on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardsProvider.notifier).loadCards();
    });
  }

  void _toggleViewMode() {
    setState(() {
      _useSwipeMode = !_useSwipeMode;
      _expandedIndex = null;
    });
  }

  void _toggleCardExpansion(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  void _openCardDetail(CardModel card) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CardDetailScreen(card: card);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _deleteCard(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Elimina tessera',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Vuoi eliminare "${card.name}"?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cardsProvider.notifier).deleteCard(card.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.file_upload, color: Colors.white),
                title: const Text('Esporta tessere', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Salva tutte le tessere in un file JSON',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(cardsProvider.notifier).exportCards();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download, color: Colors.white),
                title: const Text('Importa tessere', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Carica tessere da un file JSON',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final count = await ref.read(cardsProvider.notifier).importCards();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('$count tessere importate'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(searchedCardsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Filter by category if selected
    final filteredCards = _selectedCategory == null
        ? cards
        : cards.where((c) => c.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card Wallet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Le tue tessere',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleViewMode,
                        icon: Icon(
                          _useSwipeMode ? Icons.view_list : Icons.style,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: _useSwipeMode ? 'Vista lista' : 'Vista swipe',
                      ),
                      IconButton(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cerca tessera...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category filter
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(
                    label: 'Tutte',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...CardCategories.all.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onTap: () => setState(() => _selectedCategory = category),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cards view - swipe or list mode
            Expanded(
              child: filteredCards.isEmpty
                  ? _buildEmptyState(searchQuery.isNotEmpty)
                  : _useSwipeMode 
                      ? _buildSwipeView(filteredCards)
                      : _buildCardsList(filteredCards),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCardScreen()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.credit_card_off,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                isSearching ? 'Nessun risultato' : 'Nessuna tessera',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Prova a cercare qualcos\'altro'
                    : 'Aggiungi la tua prima tessera',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeView(List<CardModel> cards) {
    return Column(
      children: [
        // Card count indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${cards.length} tessere',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Swipeable card stack
        Expanded(
          child: Center(
            child: SwipeableCardStack(
              cards: cards,
              onCardTap: (card) => _openCardDetail(card),
              onCardLongPress: (card) => _deleteCard(card),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsList(List<CardModel> cards) {
    // Calculate total height needed for the stack
    double totalHeight = 0;
    for (int i = 0; i < cards.length; i++) {
      final isExpanded = _expandedIndex == i;
      if (i == 0) {
        totalHeight += isExpanded ? 200 : 80;
      } else {
        // Each subsequent card peeks out by 40px when collapsed, 8px spacing when expanded
        totalHeight += isExpanded ? 208 : 40;
      }
    }
    totalHeight += 100; // Space for FAB

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: List.generate(cards.length, (index) {
            final card = cards[index];
            final isExpanded = _expandedIndex == index;
            
            // Calculate top position for this card
            double topPosition = 0;
            for (int i = 0; i < index; i++) {
              final prevExpanded = _expandedIndex == i;
              if (prevExpanded) {
                topPosition += 208; // Full height + spacing
              } else {
                topPosition += 40; // Peek amount
              }
            }

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: topPosition,
              left: 0,
              right: 0,
              child: WalletCard(
                card: card,
                isExpanded: isExpanded,
                peekHeight: 80,
                onTap: () {
                  if (isExpanded) {
                    _openCardDetail(card);
                  } else {
                    _toggleCardExpansion(index);
                  }
                },
                onLongPress: () => _deleteCard(card),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
