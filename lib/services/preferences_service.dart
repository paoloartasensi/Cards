import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app preferences using SharedPreferences
class PreferencesService {
  static const String _lastViewedCardKey = 'last_viewed_card_id';
  static const String _autoOpenLastCardKey = 'auto_open_last_card';
  
  static PreferencesService? _instance;
  static SharedPreferences? _prefs;
  
  PreferencesService._();
  
  /// Get singleton instance
  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }
  
  /// Save the ID of the last viewed card
  Future<void> setLastViewedCard(String cardId) async {
    await _prefs?.setString(_lastViewedCardKey, cardId);
  }
  
  /// Get the ID of the last viewed card
  String? getLastViewedCard() {
    return _prefs?.getString(_lastViewedCardKey);
  }
  
  /// Clear the last viewed card
  Future<void> clearLastViewedCard() async {
    await _prefs?.remove(_lastViewedCardKey);
  }
  
  /// Set whether to auto-open the last viewed card
  Future<void> setAutoOpenLastCard(bool enabled) async {
    await _prefs?.setBool(_autoOpenLastCardKey, enabled);
  }
  
  /// Check if auto-open last card is enabled (default: true)
  bool isAutoOpenLastCardEnabled() {
    return _prefs?.getBool(_autoOpenLastCardKey) ?? false;
  }
}
