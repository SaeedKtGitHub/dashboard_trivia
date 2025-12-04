import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../models/challenge.dart';
import '../services/api_service.dart';

// Provider for questions list
final questionsProvider = FutureProvider<List<Question>>((ref) async {
  return await ApiService.getQuestions();
});

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Provider for filtered questions
final filteredQuestionsProvider = Provider<AsyncValue<List<Question>>>((ref) {
  final questionsAsync = ref.watch(questionsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return questionsAsync.when(
    data: (questions) {
      if (selectedCategory == null) {
        return AsyncValue.data(questions);
      }
      final filtered = questions
          .where((q) => q.difficulty == selectedCategory)
          .toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for insert question state
final insertQuestionProvider = StateNotifierProvider<InsertQuestionNotifier, InsertQuestionState>((ref) {
  return InsertQuestionNotifier(ref);
});

class InsertQuestionState {
  final bool isLoading;
  final String? error;
  final bool success;

  InsertQuestionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  InsertQuestionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return InsertQuestionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

class InsertQuestionNotifier extends StateNotifier<InsertQuestionState> {
  final Ref ref;

  InsertQuestionNotifier(this.ref) : super(InsertQuestionState());

  Future<void> insertQuestion(Question question) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    
    try {
      await ApiService.insertQuestion(question);
      state = state.copyWith(isLoading: false, success: true);
      
      // Refresh questions list
      ref.invalidate(questionsProvider);
      
      // Reset success after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(success: false);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
    }
  }

  void reset() {
    state = InsertQuestionState();
  }
}

// Provider for delete question state
final deleteQuestionProvider = StateNotifierProvider<DeleteQuestionNotifier, DeleteQuestionState>((ref) {
  return DeleteQuestionNotifier(ref);
});

class DeleteQuestionState {
  final Set<int> deletingIds; // IDs of questions being deleted

  DeleteQuestionState({
    Set<int>? deletingIds,
  }) : deletingIds = deletingIds ?? {};

  DeleteQuestionState copyWith({
    Set<int>? deletingIds,
  }) {
    return DeleteQuestionState(
      deletingIds: deletingIds ?? this.deletingIds,
    );
  }

  bool isDeleting(int id) => deletingIds.contains(id);
}

class DeleteQuestionNotifier extends StateNotifier<DeleteQuestionState> {
  final Ref ref;

  DeleteQuestionNotifier(this.ref) : super(DeleteQuestionState());

  Future<void> deleteQuestion(int questionId) async {
    // Add to deleting set
    state = state.copyWith(
      deletingIds: {...state.deletingIds, questionId},
    );
    
    try {
      await ApiService.deleteQuestion(questionId);
      
      // Remove from deleting set
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(questionId),
      );
      
      // Refresh questions list
      ref.invalidate(questionsProvider);
    } catch (e) {
      // Remove from deleting set even on error
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(questionId),
      );
      rethrow;
    }
  }
}

// Provider for update question state
final updateQuestionProvider = StateNotifierProvider<UpdateQuestionNotifier, UpdateQuestionState>((ref) {
  return UpdateQuestionNotifier(ref);
});

class UpdateQuestionState {
  final Set<int> updatingIds; // IDs of questions being updated

  UpdateQuestionState({
    Set<int>? updatingIds,
  }) : updatingIds = updatingIds ?? {};

  UpdateQuestionState copyWith({
    Set<int>? updatingIds,
  }) {
    return UpdateQuestionState(
      updatingIds: updatingIds ?? this.updatingIds,
    );
  }

  bool isUpdating(int id) => updatingIds.contains(id);
}

class UpdateQuestionNotifier extends StateNotifier<UpdateQuestionState> {
  final Ref ref;

  UpdateQuestionNotifier(this.ref) : super(UpdateQuestionState());

  Future<void> updateQuestion(int questionId, Question question) async {
    // Add to updating set
    state = state.copyWith(
      updatingIds: {...state.updatingIds, questionId},
    );
    
    try {
      await ApiService.updateQuestion(questionId, question);
      
      // Remove from updating set
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(questionId),
      );

      // Refresh questions list
      ref.invalidate(questionsProvider);
    } catch (e) {
      // Remove from updating set even on error
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(questionId),
      );
      rethrow;
    }
  }
}

// Provider for challenges list
final challengesProvider = FutureProvider<List<Challenge>>((ref) async {
  return await ApiService.getChallenges();
});

// Provider for insert daily challenge question state
final insertDailyChallengeQuestionProvider = StateNotifierProvider<InsertDailyChallengeQuestionNotifier, InsertQuestionState>((ref) {
  return InsertDailyChallengeQuestionNotifier(ref);
});

class InsertDailyChallengeQuestionNotifier extends StateNotifier<InsertQuestionState> {
  final Ref ref;

  InsertDailyChallengeQuestionNotifier(this.ref) : super(InsertQuestionState());

  Future<void> insertDailyChallengeQuestion(Question question) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    
    try {
      await ApiService.insertDailyChallengeQuestion(question);
      state = state.copyWith(isLoading: false, success: true);
      
      // Refresh daily challenge questions list if challengeId is available
      if (question.challengeId != null) {
        ref.invalidate(dailyChallengeQuestionsProvider(question.challengeId!));
      }
      
      // Reset success after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(success: false);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
    }
  }

  void reset() {
    state = InsertQuestionState();
  }
}

// Provider for insert challenge state
final insertChallengeProvider = StateNotifierProvider<InsertChallengeNotifier, InsertQuestionState>((ref) {
  return InsertChallengeNotifier(ref);
});

class InsertChallengeNotifier extends StateNotifier<InsertQuestionState> {
  final Ref ref;

  InsertChallengeNotifier(this.ref) : super(InsertQuestionState());

  Future<void> insertChallenge(Challenge challenge) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    
    try {
      await ApiService.insertChallenge(challenge);
      state = state.copyWith(isLoading: false, success: true);
      
      // Refresh challenges list
      ref.invalidate(challengesProvider);
      
      // Reset success after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(success: false);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
    }
  }

  void reset() {
    state = InsertQuestionState();
  }
}

// Provider for update challenge state
final updateChallengeProvider = StateNotifierProvider<UpdateChallengeNotifier, UpdateQuestionState>((ref) {
  return UpdateChallengeNotifier(ref);
});

class UpdateChallengeNotifier extends StateNotifier<UpdateQuestionState> {
  final Ref ref;

  UpdateChallengeNotifier(this.ref) : super(UpdateQuestionState());

  Future<void> updateChallenge(int challengeId, Challenge challenge) async {
    // Add to updating set
    state = state.copyWith(
      updatingIds: {...state.updatingIds, challengeId},
    );
    
    try {
      await ApiService.updateChallenge(challengeId, challenge);
      
      // Remove from updating set
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(challengeId),
      );

      // Refresh challenges list
      ref.invalidate(challengesProvider);
    } catch (e) {
      // Remove from updating set even on error
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(challengeId),
      );
      rethrow;
    }
  }
}

// Provider for delete challenge state
final deleteChallengeProvider = StateNotifierProvider<DeleteChallengeNotifier, DeleteQuestionState>((ref) {
  return DeleteChallengeNotifier(ref);
});

class DeleteChallengeNotifier extends StateNotifier<DeleteQuestionState> {
  final Ref ref;

  DeleteChallengeNotifier(this.ref) : super(DeleteQuestionState());

  Future<void> deleteChallenge(int challengeId) async {
    // Add to deleting set
    state = state.copyWith(
      deletingIds: {...state.deletingIds, challengeId},
    );
    
    try {
      await ApiService.deleteChallenge(challengeId);
      
      // Remove from deleting set
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(challengeId),
      );
      
      // Refresh challenges list
      ref.invalidate(challengesProvider);
    } catch (e) {
      // Remove from deleting set even on error
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(challengeId),
      );
      rethrow;
    }
  }
}

// Provider for daily challenge questions by challenge ID
final dailyChallengeQuestionsProvider = FutureProvider.family<List<Question>, int>((ref, challengeId) async {
  return await ApiService.getDailyChallengeQuestions(challengeId);
});

// Provider for update daily challenge question state
final updateDailyChallengeQuestionProvider = StateNotifierProvider<UpdateDailyChallengeQuestionNotifier, UpdateQuestionState>((ref) {
  return UpdateDailyChallengeQuestionNotifier(ref);
});

class UpdateDailyChallengeQuestionNotifier extends StateNotifier<UpdateQuestionState> {
  final Ref ref;

  UpdateDailyChallengeQuestionNotifier(this.ref) : super(UpdateQuestionState());

  Future<void> updateDailyChallengeQuestion(int questionId, Question question, int challengeId) async {
    // Add to updating set
    state = state.copyWith(
      updatingIds: {...state.updatingIds, questionId},
    );
    
    try {
      await ApiService.updateDailyChallengeQuestion(questionId, question);
      
      // Remove from updating set
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(questionId),
      );

      // Refresh daily challenge questions list
      ref.invalidate(dailyChallengeQuestionsProvider(challengeId));
    } catch (e) {
      // Remove from updating set even on error
      state = state.copyWith(
        updatingIds: {...state.updatingIds}..remove(questionId),
      );
      rethrow;
    }
  }
}

// Provider for delete daily challenge question state
final deleteDailyChallengeQuestionProvider = StateNotifierProvider<DeleteDailyChallengeQuestionNotifier, DeleteQuestionState>((ref) {
  return DeleteDailyChallengeQuestionNotifier(ref);
});

class DeleteDailyChallengeQuestionNotifier extends StateNotifier<DeleteQuestionState> {
  final Ref ref;

  DeleteDailyChallengeQuestionNotifier(this.ref) : super(DeleteQuestionState());

  Future<void> deleteDailyChallengeQuestion(int questionId, int challengeId) async {
    // Add to deleting set
    state = state.copyWith(
      deletingIds: {...state.deletingIds, questionId},
    );
    
    try {
      await ApiService.deleteDailyChallengeQuestion(questionId);
      
      // Remove from deleting set
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(questionId),
      );
      
      // Refresh daily challenge questions list
      ref.invalidate(dailyChallengeQuestionsProvider(challengeId));
    } catch (e) {
      // Remove from deleting set even on error
      state = state.copyWith(
        deletingIds: {...state.deletingIds}..remove(questionId),
      );
      rethrow;
    }
  }
}

