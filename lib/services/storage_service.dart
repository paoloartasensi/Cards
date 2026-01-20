import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/card_model.dart';

/// Service for managing card storage and backup/export functionality
class StorageService {
  static const String boxName = 'cards';

  /// Get the cards box (must be opened in main.dart first)
  Box<CardModel> get _box => Hive.box<CardModel>(boxName);

  /// Get all cards
  List<CardModel> getAllCards() {
    return _box.values.toList();
  }

  /// Get a card by ID
  CardModel? getCard(String id) {
    try {
      return _box.values.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new card
  Future<void> addCard(CardModel card) async {
    await _box.put(card.id, card);
  }

  /// Update an existing card
  Future<void> updateCard(CardModel card) async {
    await _box.put(card.id, card);
  }

  /// Delete a card
  Future<void> deleteCard(String id) async {
    await _box.delete(id);
  }

  /// Export all cards to JSON file and share
  Future<void> exportCards() async {
    final cards = getAllCards();
    final jsonList = cards.map((card) => card.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/card_wallet_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Card Wallet Backup',
    );
  }

  /// Import cards from JSON file
  Future<int> importCards() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return 0;
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final jsonList = jsonDecode(jsonString) as List<dynamic>;

    int importedCount = 0;
    for (final json in jsonList) {
      try {
        final card = CardModel.fromJson(json as Map<String, dynamic>);
        await _box.put(card.id, card);
        importedCount++;
      } catch (e) {
        // Skip invalid cards
        continue;
      }
    }

    return importedCount;
  }

  /// Watch for changes in the box
  Stream<BoxEvent> watchCards() {
    return _box.watch();
  }
}
