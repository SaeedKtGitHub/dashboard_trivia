import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/level_progress_service.dart';

final levelProgressProvider =
    StateNotifierProvider<LevelProgressNotifier, Set<String>>(
  (ref) => LevelProgressNotifier(),
);

class LevelProgressNotifier extends StateNotifier<Set<String>> {
  LevelProgressNotifier() : super(<String>{}) {
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final completed = await LevelProgressService.getCompletedLevels();
    state = completed;
  }

  Future<void> markCompleted(String levelId) async {
    if (state.contains(levelId)) return;

    final updated = {...state, levelId};
    state = updated;
    await LevelProgressService.saveCompletedLevels(updated);
  }
}

