import 'dart:math';
import '../models/question.dart';

class QuestionDistributor {
  final List<Question> allQuestions;
  final Random _random = Random();

  QuestionDistributor(this.allQuestions);

  // Easy Level: 6 easy, 2 medium, 1 hard, 1 legendary
  List<Question> getEasyLevelQuestions() {
    final easy = _getQuestionsByDifficulty('easy');
    final medium = _getQuestionsByDifficulty('medium');
    final hard = _getQuestionsByDifficulty('hard');
    final legendary = _getQuestionsByDifficulty('elegant');

    final List<Question> selected = [];
    selected.addAll(_selectRandom(easy, 6)); // 12 stars
    selected.addAll(_selectRandom(medium, 2)); // 6 stars
    selected.addAll(_selectRandom(hard, 1)); // 4 stars
    selected.addAll(_selectRandom(legendary, 1)); // 5
                                                // = /27

    final sorted = _sortByDifficulty(selected);
    print('Easy level: Selected ${sorted.length} questions (expected 10)'); // Debug
    return sorted;
  }

  // Medium Level: 4 easy, 3 medium, 2 hard, 1 legendary
  List<Question> getMediumLevelQuestions() {
    final easy = _getQuestionsByDifficulty('easy');
    final medium = _getQuestionsByDifficulty('medium');
    final hard = _getQuestionsByDifficulty('hard');
    final legendary = _getQuestionsByDifficulty('elegant');

    final List<Question> selected = [];
    selected.addAll(_selectRandom(easy, 4));// 8
    selected.addAll(_selectRandom(medium, 3)); // 9
    selected.addAll(_selectRandom(hard, 2)); // 8
    selected.addAll(_selectRandom(legendary, 1)); // 5
                                                // = /30

    return _sortByDifficulty(selected);
  }

  // Hard Level: 3 easy, 2 medium, 3 hard, 2 legendary
  List<Question> getHardLevelQuestions() {
    final easy = _getQuestionsByDifficulty('easy');
    final medium = _getQuestionsByDifficulty('medium');
    final hard = _getQuestionsByDifficulty('hard');
    final legendary = _getQuestionsByDifficulty('elegant');

    final List<Question> selected = [];
    selected.addAll(_selectRandom(easy, 3)); // 6
    selected.addAll(_selectRandom(medium, 2)); // 6
    selected.addAll(_selectRandom(hard, 3)); // 12
    selected.addAll(_selectRandom(legendary, 2)); // 10
                                                // =

    return _sortByDifficulty(selected);
  }

  // Legendary Level: 2 easy, 3 medium, 2 hard, 3 legendary
  List<Question> getLegendaryLevelQuestions() {
    final easy = _getQuestionsByDifficulty('easy');
    final medium = _getQuestionsByDifficulty('medium');
    final hard = _getQuestionsByDifficulty('hard');
    final legendary = _getQuestionsByDifficulty('elegant');

    final List<Question> selected = [];
    selected.addAll(_selectRandom(easy, 2));// 4
    selected.addAll(_selectRandom(medium, 3));// 9
    selected.addAll(_selectRandom(hard, 2));//  8
    selected.addAll(_selectRandom(legendary, 3));// 15
                                                // = /36

    return _sortByDifficulty(selected);
  }

  // Daily Challenge: 10 random questions from all levels (no specific distribution)
  List<Question> getDailyChallengeQuestions() {
    // اختيار 10 أسئلة عشوائية من جميع الأسئلة بغض النظر عن الصعوبة
    if (allQuestions.isEmpty) {
      return [];
    }
    
    // إذا كان عدد الأسئلة أقل من 10، نعيد جميع الأسئلة
    if (allQuestions.length <= 10) {
      // خلط الأسئلة عشوائياً
      final shuffled = List<Question>.from(allQuestions);
      shuffled.shuffle(_random);
      return shuffled;
    }
    
    // اختيار 10 أسئلة عشوائية
    final selected = <Question>[];
    final available = List<Question>.from(allQuestions);
    
    for (int i = 0; i < 10 && available.isNotEmpty; i++) {
      final index = _random.nextInt(available.length);
      selected.add(available.removeAt(index));
    }
    
    // خلط الأسئلة المختارة عشوائياً (لا نرتبها حسب الصعوبة)
    selected.shuffle(_random);
    
    return selected;
  }

  List<Question> _getQuestionsByDifficulty(String difficulty) {
    return allQuestions
        .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  List<Question> _selectRandom(List<Question> questions, int count) {
    if (questions.isEmpty) {
      return [];
    }
    
    // إذا كان عدد الأسئلة المتاحة أقل من المطلوب، نعيد جميع الأسئلة المتاحة
    if (questions.length <= count) {
      return List.from(questions);
    }

    final selected = <Question>[];
    final available = List<Question>.from(questions);

    // التأكد من اختيار العدد المطلوب بالضبط
    for (int i = 0; i < count && available.isNotEmpty; i++) {
      final index = _random.nextInt(available.length);
      selected.add(available.removeAt(index));
    }

    return selected;
  }

  // ترتيب الأسئلة حسب الصعوبة: سهل -> متوسط -> صعب -> أسطوري
  List<Question> _sortByDifficulty(List<Question> questions) {
    final difficultyOrder = {
      'easy': 1,
      'medium': 2,
      'hard': 3,
      'elegant': 4,
    };

    questions.sort((a, b) {
      final aOrder = difficultyOrder[a.difficulty.toLowerCase()] ?? 99;
      final bOrder = difficultyOrder[b.difficulty.toLowerCase()] ?? 99;
      return aOrder.compareTo(bOrder);
    });

    return questions;
  }
}

