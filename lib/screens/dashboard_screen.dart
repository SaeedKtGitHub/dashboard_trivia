import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../providers/question_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _starsRewardController = TextEditingController(text: '2');
  
  String _selectedCategory = 'easy';
  String _selectedCorrectOption = 'A';

  final List<String> categories = ['easy', 'medium', 'hard', 'elegant'];
  final Map<String, String> categoryLabels = {
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
    'elegant': 'أسطوري',
  };

  final List<String> correctOptions = ['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _imageUrlController.dispose();
    _starsRewardController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final insertState = ref.watch(insertQuestionProvider);
    final filteredQuestions = ref.watch(filteredQuestionsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - الأسئلة'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Row(
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
      ),
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
}
