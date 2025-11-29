class Question {
  final int? questionId;
  final String? questionText;
  final String optionA;
  final String optionB;
  final String? optionC;
  final String? optionD;
  final String correctOption; // A, B, C, or D
  final String difficulty; // easy, medium, hard, elegant
  final String? imageUrl;
  final int starsReward;
  final DateTime? createdAt;

  Question({
    this.questionId,
    this.questionText,
    required this.optionA,
    required this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    required this.difficulty,
    this.imageUrl,
    this.starsReward = 2,
    this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id'] as int?,
      questionText: json['question_text'] as String?,
      optionA: json['option_a'] as String? ?? '',
      optionB: json['option_b'] as String? ?? '',
      optionC: json['option_c'] as String?,
      optionD: json['option_d'] as String?,
      correctOption: json['correct_option'] as String? ?? 'A',
      difficulty: json['difficulty'] as String? ?? 'easy',
      imageUrl: json['image_url'] as String?,
      starsReward: json['stars_reward'] as int? ?? 2,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Don't include question_id or created_at when inserting (database handles these)
      'question_text': questionText ?? '',
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'difficulty': difficulty,
      'image_url': imageUrl,
      'stars_reward': starsReward,
    };
  }
}
