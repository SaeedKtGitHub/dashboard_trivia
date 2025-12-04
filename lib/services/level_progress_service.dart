import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressService {
  static const String _completedLevelsKey = 'completed_levels';

  static Future<Set<String>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final levels = prefs.getStringList(_completedLevelsKey) ?? [];
    return levels.toSet();
  }

  static Future<void> saveCompletedLevels(Set<String> levels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedLevelsKey, levels.toList());
  }
}

