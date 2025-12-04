import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../models/challenge.dart';
import '../providers/question_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form for regular questions
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _starsRewardController = TextEditingController(text: '2');
  
  // Form for daily challenge questions
  final _dailyFormKey = GlobalKey<FormState>();
  final _dailyQuestionController = TextEditingController();
  final _dailyOptionAController = TextEditingController();
  final _dailyOptionBController = TextEditingController();
  final _dailyOptionCController = TextEditingController();
  final _dailyOptionDController = TextEditingController();
  final _dailyImageUrlController = TextEditingController();
  final _dailyStarsRewardController = TextEditingController(text: '2');
  
  String _selectedCategory = 'easy';
  String _selectedCorrectOption = 'A';
  String? _selectedChallengeId; // For daily challenge questions
  int? _selectedChallengeIdForViewing; // For viewing questions of a challenge
  
  // Form for adding challenge
  final _challengeFormKey = GlobalKey<FormState>();
  final _challengeTitleController = TextEditingController();
  final _challengeImageUrlController = TextEditingController();

  final List<String> categories = ['easy', 'medium', 'hard', 'elegant'];
  final Map<String, String> categoryLabels = {
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
    'elegant': 'أسطوري',
  };

  final List<String> correctOptions = ['A', 'B', 'C', 'D'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _imageUrlController.dispose();
    _starsRewardController.dispose();
    _dailyQuestionController.dispose();
    _dailyOptionAController.dispose();
    _dailyOptionBController.dispose();
    _dailyOptionCController.dispose();
    _dailyOptionDController.dispose();
    _dailyImageUrlController.dispose();
    _dailyStarsRewardController.dispose();
    _challengeTitleController.dispose();
    _challengeImageUrlController.dispose();
    super.dispose();
  }
  
  void _submitChallengeForm() {
    if (_challengeFormKey.currentState!.validate()) {
      final challenge = Challenge(
        challengeTitle: _challengeTitleController.text.trim(),
        imageUrl: _challengeImageUrlController.text.trim().isEmpty 
            ? null 
            : _challengeImageUrlController.text.trim(),
      );

      ref.read(insertChallengeProvider.notifier).insertChallenge(challenge).then((_) {
        if (mounted) {
          _challengeTitleController.clear();
          _challengeImageUrlController.clear();
        }
      });
    }
  }


  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final question = Question(
        questionText: _questionController.text.trim(),
        optionA: _optionAController.text.trim(),
        optionB: _optionBController.text.trim(),
        optionC: _optionCController.text.trim().isEmpty 
            ? null 
            : _optionCController.text.trim(),
        optionD: _optionDController.text.trim().isEmpty 
            ? null 
            : _optionDController.text.trim(),
        correctOption: _selectedCorrectOption,
        difficulty: _selectedCategory,
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        starsReward: int.tryParse(_starsRewardController.text.trim()) ?? 2,
      );

      ref.read(insertQuestionProvider.notifier).insertQuestion(question).then((_) {
        if (mounted) {
          _questionController.clear();
          _optionAController.clear();
          _optionBController.clear();
          _optionCController.clear();
          _optionDController.clear();
          _imageUrlController.clear();
          _starsRewardController.text = '2';
          _selectedCategory = 'easy';
          _selectedCorrectOption = 'A';
        }
      });
    }
  }
  
  void _submitDailyChallengeForm() {
    if (_dailyFormKey.currentState!.validate()) {
      if (_selectedChallengeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار التحدي')),
        );
        return;
      }
      
      final question = Question(
        questionText: _dailyQuestionController.text.trim(),
        optionA: _dailyOptionAController.text.trim(),
        optionB: _dailyOptionBController.text.trim(),
        optionC: _dailyOptionCController.text.trim().isEmpty 
            ? null 
            : _dailyOptionCController.text.trim(),
        optionD: _dailyOptionDController.text.trim().isEmpty 
            ? null 
            : _dailyOptionDController.text.trim(),
        correctOption: _selectedCorrectOption,
        difficulty: _selectedCategory,
        imageUrl: _dailyImageUrlController.text.trim().isEmpty 
            ? null 
            : _dailyImageUrlController.text.trim(),
        starsReward: int.tryParse(_dailyStarsRewardController.text.trim()) ?? 2,
        challengeId: int.parse(_selectedChallengeId!),
      );

      ref.read(insertDailyChallengeQuestionProvider.notifier).insertDailyChallengeQuestion(question).then((_) {
        if (mounted) {
          _dailyQuestionController.clear();
          _dailyOptionAController.clear();
          _dailyOptionBController.clear();
          _dailyOptionCController.clear();
          _dailyOptionDController.clear();
          _dailyImageUrlController.clear();
          _dailyStarsRewardController.text = '2';
          _selectedCategory = 'easy';
          _selectedCorrectOption = 'A';
          _selectedChallengeId = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final insertState = ref.watch(insertQuestionProvider);
    final insertDailyState = ref.watch(insertDailyChallengeQuestionProvider);
    final insertChallengeState = ref.watch(insertChallengeProvider);
    final filteredQuestions = ref.watch(filteredQuestionsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - الأسئلة'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة تحدي جديد',
            onPressed: () => _showAddChallengeDialog(context, insertChallengeState),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'أسئلة عادية',),
            Tab(text: 'أسئلة التحدي اليومي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Regular Questions Tab
          _buildRegularQuestionsTab(insertState, filteredQuestions, selectedCategory),
          // Daily Challenge Questions Tab
          _buildDailyChallengeQuestionsTab(insertDailyState, challengesAsync),
        ],
      ),
    );
  }
  
  Widget _buildRegularQuestionsTab(
    InsertQuestionState insertState,
    AsyncValue<List<Question>> filteredQuestions,
    String? selectedCategory,
  ) {
    return Row(
      children: [
          // Left side - Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'إضافة سؤال جديد',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'السؤال',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال السؤال';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _optionAController,
                        decoration: const InputDecoration(
                          labelText: 'الخيار A',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال الخيار A';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _optionBController,
                        decoration: const InputDecoration(
                          labelText: 'الخيار B',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال الخيار B';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _optionCController,
                        decoration: const InputDecoration(
                          labelText: 'الخيار C (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _optionDController,
                        decoration: const InputDecoration(
                          labelText: 'الخيار D (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCorrectOption,
                        decoration: const InputDecoration(
                          labelText: 'الإجابة الصحيحة',
                          border: OutlineInputBorder(),
                        ),
                        items: correctOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCorrectOption = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار الإجابة الصحيحة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'رابط الصورة (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _starsRewardController,
                        decoration: const InputDecoration(
                          labelText: 'النجوم',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال عدد النجوم';
                          }
                          final stars = int.tryParse(value.trim());
                          if (stars == null || stars < 0) {
                            return 'يرجى إدخال رقم صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'الفئة:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return ChoiceChip(
                            label: Text(categoryLabels[category]!),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: insertState.isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: insertState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'إضافة',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      if (insertState.success)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'تمت الإضافة بنجاح!',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      if (insertState.error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  insertState.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right side - Questions List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Category Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'تصفية حسب الفئة:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('الكل'),
                              selected: selectedCategory == null,
                              onSelected: (selected) {
                                ref.read(selectedCategoryProvider.notifier).state = null;
                              },
                            ),
                            ...categories.map((category) {
                              final isSelected = selectedCategory == category;
                              return FilterChip(
                                label: Text(categoryLabels[category]!),
                                selected: isSelected,
                                onSelected: (selected) {
                                  ref.read(selectedCategoryProvider.notifier).state =
                                      selected ? category : null;
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Questions List
                Expanded(
                  child: filteredQuestions.when(
                    data: (questions) {
                      if (questions.isEmpty) {
                        return const Center(
                          child: Text('لا توجد أسئلة'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          question.imageUrl!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 150,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  Text(
                                    question.questionText ?? 'بدون سؤال',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOptionRow('أ', question.optionA, question.correctOption == 'A'),
                                  _buildOptionRow('ب', question.optionB, question.correctOption == 'B'),
                                  if (question.optionC != null && question.optionC!.isNotEmpty)
                                    _buildOptionRow('ج', question.optionC!, question.correctOption == 'C'),
                                  if (question.optionD != null && question.optionD!.isNotEmpty)
                                    _buildOptionRow('د', question.optionD!, question.correctOption == 'D'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          categoryLabels[question.difficulty] ?? question.difficulty,
                                        ),
                                        backgroundColor: _getCategoryColor(question.difficulty),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star, size: 16),
                                            const SizedBox(width: 4),
                                            Text('${question.starsReward}'),
                                          ],
                                        ),
                                        backgroundColor: Colors.amber.shade100,
                                      ),
                                      const Spacer(),
                                      if (question.questionId != null) ...[
                                        _buildEditButton(question),
                                        const SizedBox(width: 8),
                                        _buildDeleteButton(question.questionId!),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'خطأ: $error',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(questionsProvider);
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildOptionRow(String label, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? Colors.green : Colors.grey.shade300,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isCorrect ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isCorrect ? Colors.green.shade700 : Colors.black87,
                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildEditButton(Question question) {
    final updateState = ref.watch(updateQuestionProvider);
    final isUpdating = question.questionId != null && updateState.isUpdating(question.questionId!);

    return IconButton(
      icon: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.edit, color: Colors.blue),
      onPressed: isUpdating
          ? null
          : () => _showEditDialog(question),
    );
  }

  void _showEditDialog(Question question) {
    if (question.questionId == null) return;

    final editFormKey = GlobalKey<FormState>();
    final questionController = TextEditingController(text: question.questionText ?? '');
    final optionAController = TextEditingController(text: question.optionA);
    final optionBController = TextEditingController(text: question.optionB);
    final optionCController = TextEditingController(text: question.optionC ?? '');
    final optionDController = TextEditingController(text: question.optionD ?? '');
    final imageUrlController = TextEditingController(text: question.imageUrl ?? '');
    final starsRewardController = TextEditingController(text: question.starsReward.toString());
    
    String selectedCategory = question.difficulty;
    String selectedCorrectOption = question.correctOption;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل السؤال'),
          content: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'السؤال',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال السؤال';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionAController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار A',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الخيار A';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionBController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار B',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الخيار B';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionCController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار C (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionDController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار D (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCorrectOption,
                    decoration: const InputDecoration(
                      labelText: 'الإجابة الصحيحة',
                      border: OutlineInputBorder(),
                    ),
                    items: correctOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCorrectOption = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار الإجابة الصحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'رابط الصورة (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: starsRewardController,
                    decoration: const InputDecoration(
                      labelText: 'النجوم',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال عدد النجوم';
                      }
                      final stars = int.tryParse(value.trim());
                      if (stars == null || stars < 0) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الفئة:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return ChoiceChip(
                        label: Text(categoryLabels[category]!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  final updatedQuestion = Question(
                    questionText: questionController.text.trim(),
                    optionA: optionAController.text.trim(),
                    optionB: optionBController.text.trim(),
                    optionC: optionCController.text.trim().isEmpty
                        ? null
                        : optionCController.text.trim(),
                    optionD: optionDController.text.trim().isEmpty
                        ? null
                        : optionDController.text.trim(),
                    correctOption: selectedCorrectOption,
                    difficulty: selectedCategory,
                    imageUrl: imageUrlController.text.trim().isEmpty
                        ? null
                        : imageUrlController.text.trim(),
                    starsReward: int.tryParse(starsRewardController.text.trim()) ?? 2,
                  );

                  try {
                    await ref
                        .read(updateQuestionProvider.notifier)
                        .updateQuestion(question.questionId!, updatedQuestion);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث السؤال بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في تحديث السؤال: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    ).then((_) {
      questionController.dispose();
      optionAController.dispose();
      optionBController.dispose();
      optionCController.dispose();
      optionDController.dispose();
      imageUrlController.dispose();
      starsRewardController.dispose();
    });
  }

  Widget _buildDeleteButton(int questionId) {
    final deleteState = ref.watch(deleteQuestionProvider);
    final isDeleting = deleteState.isDeleting(questionId);

    return IconButton(
      icon: isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.delete, color: Colors.red),
      onPressed: isDeleting
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد من حذف هذا السؤال؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  await ref
                      .read(deleteQuestionProvider.notifier)
                      .deleteQuestion(questionId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف السؤال بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في حذف السؤال: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.blue.shade100;
      case 'hard':
        return Colors.orange.shade100;
      case 'elegant':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
  
  Widget _buildDailyChallengeQuestionsTab(
    InsertQuestionState insertDailyState,
    AsyncValue<List<Challenge>> challengesAsync,
  ) {
    return Row(
      children: [
        // Left side - Form
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _dailyFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'إضافة سؤال التحدي اليومي',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Challenge Dropdown
                    challengesAsync.when(
                      data: (challenges) {
                        if (challenges.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'لا توجد تحديات متاحة. يرجى إضافة تحديات أولاً.',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedChallengeId,
                          decoration: const InputDecoration(
                            labelText: 'اختر التحدي *',
                            border: OutlineInputBorder(),
                          ),
                          items: challenges.map((challenge) {
                            return DropdownMenuItem(
                              value: challenge.challengeId.toString(),
                              child: Text(challenge.challengeTitle),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedChallengeId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى اختيار التحدي';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('خطأ: $error'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyQuestionController,
                      decoration: const InputDecoration(
                        labelText: 'السؤال',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال السؤال';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyOptionAController,
                      decoration: const InputDecoration(
                        labelText: 'الخيار A',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الخيار A';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyOptionBController,
                      decoration: const InputDecoration(
                        labelText: 'الخيار B',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الخيار B';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyOptionCController,
                      decoration: const InputDecoration(
                        labelText: 'الخيار C (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyOptionDController,
                      decoration: const InputDecoration(
                        labelText: 'الخيار D (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCorrectOption,
                      decoration: const InputDecoration(
                        labelText: 'الإجابة الصحيحة',
                        border: OutlineInputBorder(),
                      ),
                      items: correctOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCorrectOption = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'يرجى اختيار الإجابة الصحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyImageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dailyStarsRewardController,
                      decoration: const InputDecoration(
                        labelText: 'النجوم',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال عدد النجوم';
                        }
                        final stars = int.tryParse(value.trim());
                        if (stars == null || stars < 0) {
                          return 'يرجى إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الفئة:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(categoryLabels[category]!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: insertDailyState.isLoading ? null : _submitDailyChallengeForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: insertDailyState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'إضافة سؤال التحدي',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    if (insertDailyState.success)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'تمت الإضافة بنجاح!',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    if (insertDailyState.error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                insertDailyState.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right side - Challenges List or Questions List
        Expanded(
          flex: 2,
          child: _selectedChallengeIdForViewing == null
              ? _buildChallengesList(challengesAsync)
              : _buildChallengeQuestionsList(_selectedChallengeIdForViewing!),
        ),
      ],
    );
  }
  
  void _showAddChallengeDialog(BuildContext context, InsertQuestionState insertChallengeState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تحدي جديد'),
        content: Form(
          key: _challengeFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _challengeTitleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان التحدي *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عنوان التحدي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _challengeImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (insertChallengeState.success)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'تمت الإضافة بنجاح!',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                if (insertChallengeState.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insertChallengeState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _challengeTitleController.clear();
              _challengeImageUrlController.clear();
              ref.read(insertChallengeProvider.notifier).reset();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: insertChallengeState.isLoading ? null : () {
              if (_challengeFormKey.currentState!.validate()) {
                _submitChallengeForm();
                // إغلاق الـ dialog بعد نجاح الإضافة
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && insertChallengeState.success && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: insertChallengeState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('إضافة'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Widget _buildChallengesList(AsyncValue<List<Challenge>> challengesAsync) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'قائمة التحديات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Challenges List
        Expanded(
          child: challengesAsync.when(
            data: (challenges) {
              if (challenges.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد تحديات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على + لإضافة تحدي جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  final isSelected = _selectedChallengeIdForViewing == challenge.challengeId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      onTap: challenge.challengeId != null
                          ? () {
                              setState(() {
                                _selectedChallengeIdForViewing = challenge.challengeId;
                              });
                            }
                          : null,
                      leading: challenge.imageUrl != null && challenge.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                challenge.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                            ),
                      title: Text(
                        challenge.challengeTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: challenge.createdAt != null
                          ? Text(
                              'تاريخ الإنشاء: ${_formatDate(challenge.createdAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            )
                          : null,
                      trailing: challenge.challengeId != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ID: ${challenge.challengeId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildEditChallengeButton(challenge),
                                const SizedBox(width: 8),
                                _buildDeleteChallengeButton(challenge.challengeId!),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(challengesProvider);
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeQuestionsList(int challengeId) {
    final questionsAsync = ref.watch(dailyChallengeQuestionsProvider(challengeId));
    final challengesAsync = ref.watch(challengesProvider);
    
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedChallengeIdForViewing = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              challengesAsync.when(
                data: (challenges) {
                  final challenge = challenges.firstWhere(
                    (c) => c.challengeId == challengeId,
                    orElse: () => Challenge(challengeTitle: 'تحدي'),
                  );
                  return Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.quiz, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'أسئلة: ${challenge.challengeTitle}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Text(
                  'أسئلة التحدي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                error: (_, __) => const Text(
                  'أسئلة التحدي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Questions List
        Expanded(
          child: questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أسئلة لهذا التحدي',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  question.imageUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          Text(
                            question.questionText ?? 'بدون سؤال',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOptionRow('أ', question.optionA, question.correctOption == 'A'),
                          _buildOptionRow('ب', question.optionB, question.correctOption == 'B'),
                          if (question.optionC != null && question.optionC!.isNotEmpty)
                            _buildOptionRow('ج', question.optionC!, question.correctOption == 'C'),
                          if (question.optionD != null && question.optionD!.isNotEmpty)
                            _buildOptionRow('د', question.optionD!, question.correctOption == 'D'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  categoryLabels[question.difficulty] ?? question.difficulty,
                                ),
                                backgroundColor: _getCategoryColor(question.difficulty),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${question.starsReward}'),
                                  ],
                                ),
                                backgroundColor: Colors.amber.shade100,
                              ),
                              const Spacer(),
                              if (question.questionId != null) ...[
                                _buildEditDailyChallengeButton(question, challengeId),
                                const SizedBox(width: 8),
                                _buildDeleteDailyChallengeButton(question.questionId!, challengeId),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(dailyChallengeQuestionsProvider(challengeId));
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditDailyChallengeButton(Question question, int challengeId) {
    final updateState = ref.watch(updateDailyChallengeQuestionProvider);
    final isUpdating = question.questionId != null && updateState.isUpdating(question.questionId!);

    return IconButton(
      icon: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.edit, color: Colors.blue),
      onPressed: isUpdating
          ? null
          : () => _showEditDailyChallengeDialog(question, challengeId),
    );
  }

  void _showEditDailyChallengeDialog(Question question, int challengeId) {
    if (question.questionId == null) return;

    final editFormKey = GlobalKey<FormState>();
    final questionController = TextEditingController(text: question.questionText ?? '');
    final optionAController = TextEditingController(text: question.optionA);
    final optionBController = TextEditingController(text: question.optionB);
    final optionCController = TextEditingController(text: question.optionC ?? '');
    final optionDController = TextEditingController(text: question.optionD ?? '');
    final imageUrlController = TextEditingController(text: question.imageUrl ?? '');
    final starsRewardController = TextEditingController(text: question.starsReward.toString());
    
    String selectedCategory = question.difficulty;
    String selectedCorrectOption = question.correctOption;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل سؤال التحدي'),
          content: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'السؤال',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال السؤال';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionAController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار A',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الخيار A';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionBController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار B',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الخيار B';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionCController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار C (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: optionDController,
                    decoration: const InputDecoration(
                      labelText: 'الخيار D (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCorrectOption,
                    decoration: const InputDecoration(
                      labelText: 'الإجابة الصحيحة',
                      border: OutlineInputBorder(),
                    ),
                    items: correctOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCorrectOption = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار الإجابة الصحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'رابط الصورة (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: starsRewardController,
                    decoration: const InputDecoration(
                      labelText: 'النجوم',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال عدد النجوم';
                      }
                      final stars = int.tryParse(value.trim());
                      if (stars == null || stars < 0) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الفئة:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return ChoiceChip(
                        label: Text(categoryLabels[category]!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  final updatedQuestion = Question(
                    questionText: questionController.text.trim(),
                    optionA: optionAController.text.trim(),
                    optionB: optionBController.text.trim(),
                    optionC: optionCController.text.trim().isEmpty
                        ? null
                        : optionCController.text.trim(),
                    optionD: optionDController.text.trim().isEmpty
                        ? null
                        : optionDController.text.trim(),
                    correctOption: selectedCorrectOption,
                    difficulty: selectedCategory,
                    imageUrl: imageUrlController.text.trim().isEmpty
                        ? null
                        : imageUrlController.text.trim(),
                    starsReward: int.tryParse(starsRewardController.text.trim()) ?? 2,
                    challengeId: challengeId,
                  );

                  try {
                    await ref
                        .read(updateDailyChallengeQuestionProvider.notifier)
                        .updateDailyChallengeQuestion(question.questionId!, updatedQuestion, challengeId);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث السؤال بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في تحديث السؤال: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    ).then((_) {
      questionController.dispose();
      optionAController.dispose();
      optionBController.dispose();
      optionCController.dispose();
      optionDController.dispose();
      imageUrlController.dispose();
      starsRewardController.dispose();
    });
  }

  Widget _buildDeleteDailyChallengeButton(int questionId, int challengeId) {
    final deleteState = ref.watch(deleteDailyChallengeQuestionProvider);
    final isDeleting = deleteState.isDeleting(questionId);

    return IconButton(
      icon: isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.delete, color: Colors.red),
      onPressed: isDeleting
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد من حذف هذا السؤال؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  await ref
                      .read(deleteDailyChallengeQuestionProvider.notifier)
                      .deleteDailyChallengeQuestion(questionId, challengeId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف السؤال بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في حذف السؤال: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
    );
  }

  Widget _buildEditChallengeButton(Challenge challenge) {
    if (challenge.challengeId == null) return const SizedBox.shrink();
    
    final updateState = ref.watch(updateChallengeProvider);
    final isUpdating = updateState.isUpdating(challenge.challengeId!);

    return IconButton(
      icon: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.edit, color: Colors.blue),
      onPressed: isUpdating
          ? null
          : () => _showEditChallengeDialog(challenge),
    );
  }

  void _showEditChallengeDialog(Challenge challenge) {
    if (challenge.challengeId == null) return;

    final editFormKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: challenge.challengeTitle);
    final imageUrlController = TextEditingController(text: challenge.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التحدي'),
        content: Form(
          key: editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان التحدي *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عنوان التحدي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              titleController.dispose();
              imageUrlController.dispose();
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                final updatedChallenge = Challenge(
                  challengeTitle: titleController.text.trim(),
                  imageUrl: imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                );

                try {
                  await ref
                      .read(updateChallengeProvider.notifier)
                      .updateChallenge(challenge.challengeId!, updatedChallenge);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث التحدي بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في تحديث التحدي: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ).then((_) {
      titleController.dispose();
      imageUrlController.dispose();
    });
  }

  Widget _buildDeleteChallengeButton(int challengeId) {
    final deleteState = ref.watch(deleteChallengeProvider);
    final isDeleting = deleteState.isDeleting(challengeId);

    return IconButton(
      icon: isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.delete, color: Colors.red),
      onPressed: isDeleting
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد من حذف هذا التحدي؟ سيتم حذف جميع الأسئلة المرتبطة به أيضاً.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  await ref
                      .read(deleteChallengeProvider.notifier)
                      .deleteChallenge(challengeId);
                  
                  // If we were viewing this challenge's questions, go back to challenges list
                  if (_selectedChallengeIdForViewing == challengeId) {
                    setState(() {
                      _selectedChallengeIdForViewing = null;
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف التحدي بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في حذف التحدي: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
    );
  }
}
