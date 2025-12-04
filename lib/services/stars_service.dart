import 'package:shared_preferences/shared_preferences.dart';

class StarsService {
  static const String _starsKey = 'user_stars';

  // Get user stars
  static Future<int> getStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey) ?? 0;
  }

  // Add stars
  static Future<int> addStars(int stars) async {
    final currentStars = await getStars();
    final newTotal = currentStars + stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_starsKey, newTotal);
    return newTotal;
  }

  // Set stars (for reset or testing)
  static Future<void> setStars(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_starsKey, stars);
  }

  // Reset stars
  static Future<void> resetStars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_starsKey);
  }
}

