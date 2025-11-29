import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
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

