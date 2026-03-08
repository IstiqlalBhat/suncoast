import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  const LocalStorageService(this._prefs);

  // Theme
  bool get isDarkMode => _prefs.getBool('dark_mode') ?? true;
  Future<void> setDarkMode(bool value) => _prefs.setBool('dark_mode', value);

  // Onboarding
  bool get hasSeenOnboarding => _prefs.getBool('seen_onboarding') ?? false;
  Future<void> setSeenOnboarding() => _prefs.setBool('seen_onboarding', true);

  // Last activity type filter
  String? get lastActivityFilter => _prefs.getString('last_activity_filter');
  Future<void> setLastActivityFilter(String? value) {
    if (value == null) return _prefs.remove('last_activity_filter');
    return _prefs.setString('last_activity_filter', value);
  }

  // Generic
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}
