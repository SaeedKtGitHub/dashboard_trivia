import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stars_service.dart';

// Provider for user stars - using FutureProvider to ensure async loading
final starsFutureProvider = FutureProvider<int>((ref) async {
  return await StarsService.getStars();
});

// StateNotifier for managing stars
final starsProvider = StateNotifierProvider<StarsNotifier, AsyncValue<int>>((ref) {
  return StarsNotifier(ref);
});

class StarsNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref ref;
  
  StarsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadStars();
  }

  Future<void> _loadStars() async {
    try {
      final stars = await StarsService.getStars();
      state = AsyncValue.data(stars);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addStars(int stars) async {
    try {
      final newTotal = await StarsService.addStars(stars);
      state = AsyncValue.data(newTotal);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshStars() async {
    await _loadStars();
  }
}

