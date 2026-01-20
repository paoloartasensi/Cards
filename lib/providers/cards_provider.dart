import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for all cards
final cardsProvider = StateNotifierProvider<CardsNotifier, List<CardModel>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return CardsNotifier(storageService);
});

/// Provider for filtered cards by category
final filteredCardsProvider = Provider.family<List<CardModel>, String?>((ref, category) {
  final cards = ref.watch(cardsProvider);
  if (category == null || category.isEmpty) {
    return cards;
  }
  return cards.where((card) => card.category == category).toList();
});

/// Provider for search results
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedCardsProvider = Provider<List<CardModel>>((ref) {
  final cards = ref.watch(cardsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  if (query.isEmpty) return cards;
  
  return cards.where((card) {
    return card.name.toLowerCase().contains(query) ||
           card.code.toLowerCase().contains(query) ||
           card.category.toLowerCase().contains(query);
  }).toList();
});

/// State notifier for managing cards
class CardsNotifier extends StateNotifier<List<CardModel>> {
  final StorageService _storageService;
  final _uuid = const Uuid();

  CardsNotifier(this._storageService) : super([]);

  /// Load cards from storage
  Future<void> loadCards() async {
    state = _storageService.getAllCards();
  }

  /// Add a new card
  Future<void> addCard({
    required String name,
    required String code,
    required String codeType,
    String category = 'Altro',
    int colorValue = 0xFF2196F3,
    String? note,
    String? brandDomain,
  }) async {
    final card = CardModel(
      id: _uuid.v4(),
      name: name,
      code: code,
      codeType: codeType,
      category: category,
      colorValue: colorValue,
      note: note,
      brandDomain: brandDomain,
    );
    
    await _storageService.addCard(card);
    state = [...state, card];
  }

  /// Update an existing card
  Future<void> updateCard(CardModel card) async {
    await _storageService.updateCard(card);
    state = [
      for (final c in state)
        if (c.id == card.id) card else c,
    ];
  }

  /// Delete a card
  Future<void> deleteCard(String id) async {
    await _storageService.deleteCard(id);
    state = state.where((card) => card.id != id).toList();
  }

  /// Reorder cards
  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final cards = [...state];
    final card = cards.removeAt(oldIndex);
    cards.insert(newIndex, card);
    state = cards;
  }

  /// Export cards to JSON
  Future<void> exportCards() async {
    await _storageService.exportCards();
  }

  /// Import cards from JSON
  Future<int> importCards() async {
    final count = await _storageService.importCards();
    if (count > 0) {
      await loadCards();
    }
    return count;
  }
}
