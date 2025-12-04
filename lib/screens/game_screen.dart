import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/question.dart';
import '../providers/stars_provider.dart';
import '../providers/level_progress_provider.dart';
import '../utils/question_distributor.dart';
import '../services/sound_service.dart';
import '../services/ad_service.dart';
import 'legendary_win_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final List<Question> questions;
  final String levelName;
  final String levelId;
  final List<Question> allQuestions; // جميع الأسئلة من API

  const GameScreen({
    super.key,
    required this.questions,
    required this.levelName,
    required this.levelId,
    required this.allQuestions,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late List<Question> _questions;
  late List<Question> _originalQuestions; // حفظ الأسئلة الأصلية من widget.questions
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  int correctAnswers = 0;
  int answeredQuestions = 0; // عدد الأسئلة التي تمت الإجابة عليها (صحيحة أو خاطئة)
  bool showResult = false;
  bool showStarAnimation = false;
  int earnedStars = 0;
  bool timeUp = false; // flag لتحديد انتهاء الوقت
  bool _isChangeQuestionUsed = false; // لتتبع استخدام زر تغيير السؤال
  final ScrollController _scrollController = ScrollController();

  // Timer variables
  Timer? _timer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  
  // خيارات مختلطة لكل سؤال: Map<questionIndex, List<Map<String, dynamic>>>
  // كل Map يحتوي على: {'letter': 'A', 'text': '...', 'originalLetter': 'A'}
  Map<int, List<Map<String, String>>> _shuffledOptions = {};
  
  // AdService instance
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // حفظ نسخة من الأسئلة الأصلية من widget
    _originalQuestions = List<Question>.from(widget.questions);
    // نسخ الأسئلة وترتيبها حسب الصعوبة
    _questions = _sortQuestionsByDifficulty(List<Question>.from(_originalQuestions));
    print('GameScreen initState: _questions.length=${_questions.length}'); // Debug
    // تشغيل صوت بدء المستوى
    SoundService.playStartLevelSound();
    // تحميل الإعلانات مسبقاً
    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();
    // إعادة تعيين استخدام إعلان تغيير السؤال عند بدء المستوى
    _resetAdUsageForNewGame();
    // التحقق من حالة استخدام زر تغيير السؤال
    _checkChangeQuestionStatus();
    _startTimerForCurrentQuestion();
  }
  
  // التحقق من حالة استخدام زر تغيير السؤال
  Future<void> _checkChangeQuestionStatus() async {
    final isUsed = await AdService.isChangeQuestionAdUsed();
    if (mounted) {
      setState(() {
        _isChangeQuestionUsed = isUsed;
      });
    }
  }

  Question get currentQuestion => _questions[currentQuestionIndex];
  
  // خلط الخيارات للسؤال الحالي
  List<Map<String, String>> _getShuffledOptions(Question question) {
    // إذا كان موجوداً بالفعل، استخدمه
    if (_shuffledOptions.containsKey(currentQuestionIndex)) {
      return _shuffledOptions[currentQuestionIndex]!;
    }
    
    // إنشاء قائمة بالخيارات
    final options = <Map<String, String>>[
      {'letter': 'A', 'text': question.optionA, 'originalLetter': 'A'},
      {'letter': 'B', 'text': question.optionB, 'originalLetter': 'B'},
    ];
    
    if (question.optionC != null && question.optionC!.isNotEmpty) {
      options.add({'letter': 'C', 'text': question.optionC!, 'originalLetter': 'C'});
    }
    if (question.optionD != null && question.optionD!.isNotEmpty) {
      options.add({'letter': 'D', 'text': question.optionD!, 'originalLetter': 'D'});
    }
    
    // خلط الخيارات
    options.shuffle();
    
    // تحديث الحروف بعد الخلط
    final letters = ['A', 'B', 'C', 'D'];
    for (int i = 0; i < options.length; i++) {
      options[i] = {
        'letter': letters[i],
        'text': options[i]['text']!,
        'originalLetter': options[i]['originalLetter']!,
      };
    }
    
    // حفظ الخيارات المختلطة
    _shuffledOptions[currentQuestionIndex] = options;
    
    return options;
  }
  
  // الحصول على الحرف الصحيح بعد الخلط
  String _getShuffledCorrectOption(Question question) {
    final shuffled = _getShuffledOptions(question);
    // البحث عن الخيار الذي له originalLetter = correctOption
    final correctShuffled = shuffled.firstWhere(
      (opt) => opt['originalLetter'] == question.correctOption,
    );
    return correctShuffled['letter']!;
  }

  // حساب الوقت حسب صعوبة السؤال
  int _getTimeForDifficulty(String difficulty) {
    return 25;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 16;
      case 'medium':
        return 16;
      case 'hard':
        return 15;
      case 'elegant':
        return 14;
      default:
        return 16;
    }
  }

  // بدء Timer للسؤال الحالي
  void _startTimerForCurrentQuestion() {
    // إيقاف Timer السابق بالكامل
    _timer?.cancel();
    _timer = null;
    
    // حساب الوقت الجديد وإعادة تعيين
    _totalTime = _getTimeForDifficulty(currentQuestion.difficulty);
    _timeRemaining = _totalTime;
    
    // التأكد من أن الـ widget لا يزال mounted قبل بدء Timer جديد
    if (!mounted) return;
    
    // بدء Timer جديد
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _timeRemaining--;
      });
      
      if (_timeRemaining <= 0) {
        timer.cancel();
        _timer = null;
        _onTimeUp();
      }
    });
  }

  // انتهاء الوقت
  void _onTimeUp() {
    if (showResult || timeUp) return;
    
    // إيقاف التفاعل مع الأسئلة بدون إظهار الإجابة الصحيحة
    setState(() {
      timeUp = true; // تعطيل التفاعل
      selectedAnswer = '';
      // لا نضع showResult = true حتى لا تظهر الإجابة الصحيحة باللون الأخضر
    });
    
    // إظهار dialog مباشرة
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showTimeUpDialog();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, color: Colors.red, size: 32.sp),
            SizedBox(width: 8.w),
            Text(
              'انتهى الوقت!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'انتهى الوقت ولم تختر إجابة',
              style: TextStyle(
                fontSize: 20.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _restartGame();
                    },
                    icon: Icon(Icons.refresh, size: 24.sp),
                    label: Text(
                      'ابدأ مرة أخرى',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to levels
                    },
                    icon: Icon(Icons.arrow_back, size: 24.sp),
                    label: Text(
                      'الرجوع',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _adService.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer) {
    if (showResult || timeUp) return;
    
    // إيقاف Timer عند اختيار إجابة
    _timer?.cancel();
    
    // الحصول على الحرف الصحيح بعد الخلط
    final correctOption = _getShuffledCorrectOption(currentQuestion);

    setState(() {
      selectedAnswer = answer;
      showResult = true;
      answeredQuestions++; // زيادة عدد الأسئلة المجاب عليها
      if (answer == correctOption) {
        correctAnswers++;
        earnedStars = currentQuestion.starsReward;
        // Add stars
        ref.read(starsProvider.notifier).addStars(earnedStars);
        // Show star animation
        showStarAnimation = true;
      } else {
        // Show error dialog for wrong answer
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showWrongAnswerDialog();
          }
        });
      }
    });

    // إذا كانت الإجابة صحيحة نمرّر للأسفل لعرض زر "التالي"
    if (answer == correctOption) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
      // إخفاء أنميشن النجمة بعد فترة قصيرة
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showStarAnimation = false;
          });
        }
      });
    }
  }

  void _nextQuestion() {
    // التحقق من انتهاء المستوى بناءً على عدد الأسئلة المجاب عليها، وليس الفهرس الحالي
    // لأن currentQuestionIndex قد يزيد عند تغيير السؤال
    // إذا كان answeredQuestions >= _questions.length، انتهى المستوى
    if (answeredQuestions >= _questions.length) {
      _timer?.cancel();
      _timer = null;
      _showFinalResult();
      return;
    }
    
    // عرض Interstitial Ad بعد الإجابة على السؤال الخامس والتاسع (قبل الانتقال للسؤال السادس والعاشر)
    // نستخدم answeredQuestions لأن currentQuestionIndex قد يزيد عند تغيير السؤال
    final shouldShowAd = answeredQuestions == 5 || answeredQuestions == 9;
    
    // السؤال التالي يجب أن يكون في الفهرس answeredQuestions (0-indexed)
    // لأن answeredQuestions هو عدد الأسئلة المجاب عليها
    final nextQuestionIndex = answeredQuestions;
    
    // التأكد من أن nextQuestionIndex صالح
    if (nextQuestionIndex >= _questions.length) {
      _timer?.cancel();
      _timer = null;
      _showFinalResult();
      return;
    }
    
    // إيقاف Timer قبل تغيير السؤال
    _timer?.cancel();
    _timer = null;
    
    setState(() {
      // نضبط currentQuestionIndex إلى nextQuestionIndex دائماً
      // هذا يضمن أننا ننتقل للسؤال الصحيح بغض النظر عن تغيير السؤال أو استخدام "شاهد إعلان للمتابعة"
      // حتى لو كان currentQuestionIndex أكبر من nextQuestionIndex بسبب تغيير السؤال
      currentQuestionIndex = nextQuestionIndex;
      selectedAnswer = null;
      showResult = false;
      timeUp = false;
    });
    
    // عرض Interstitial Ad بعد السؤال الخامس والتاسع (بعد الانتقال للسؤال السادس والعاشر)
    if (shouldShowAd) {
      // تعيين callback لبدء Timer بعد إغلاق الإعلان
      _adService.onInterstitialAdClosed = () {
        if (mounted) {
          // بدء Timer للسؤال الجديد بعد إغلاق الإعلان
          _startTimerForCurrentQuestion();
          // إزالة callback
          _adService.onInterstitialAdClosed = null;
        }
      };
      
      // انتظار قليل ثم عرض الإعلان
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _adService.showInterstitialAd();
        }
      });
    } else {
      // بدء Timer للسؤال الجديد
      _startTimerForCurrentQuestion();
    }
    
    // Scroll to top
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // تغيير السؤال مع إعلان
  Future<void> _changeQuestionWithAd() async {
    // التحقق من استخدام الإعلان
    final isUsed = await AdService.isChangeQuestionAdUsed();
    print('Change question ad used: $isUsed'); // Debug
    
    if (isUsed) {
      // تم استخدام الإعلان بالفعل - لا نعرض أي شيء، الزر مخفي بالفعل
      return;
    }
    
    // التحقق من أن هناك سؤال آخر متاح
    // لا يمكن تغيير السؤال إذا كنا في آخر سؤال أو تجاوزنا عدد الأسئلة
    if (currentQuestionIndex >= _questions.length - 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن تغيير السؤال - هذا آخر سؤال'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // إيقاف Timer قبل عرض الإعلان - إيقاف كامل وإعادة تعيين
    _timer?.cancel();
    _timer = null;
    
    // التأكد من تحميل الإعلان قبل عرضه
    if (!_adService.isRewardedAdReady) {
      await _adService.loadRewardedAd();
      // انتظار قليل لتحميل الإعلان
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // عرض الإعلان
    await _adService.showRewardedAd(
      onRewarded: () async {
        // تمت مشاهدة الإعلان - تعيين الاستخدام
        await AdService.setChangeQuestionAdUsed();
        
        // تغيير السؤال - فقط زيادة الفهرس، لا نزيل السؤال من القائمة
        if (currentQuestionIndex < _questions.length - 1) {
          // إيقاف Timer مرة أخرى للتأكد
          _timer?.cancel();
          _timer = null;
          
          // حساب الوقت الجديد للسؤال الجديد
          final nextQuestionIndex = currentQuestionIndex + 1;
          final nextQuestion = _questions[nextQuestionIndex];
          final newTotalTime = _getTimeForDifficulty(nextQuestion.difficulty);
          
          setState(() {
            currentQuestionIndex = nextQuestionIndex;
            selectedAnswer = null;
            showResult = false;
            timeUp = false;
            _isChangeQuestionUsed = true;
            // إعادة تعيين Timer بالكامل
            _timeRemaining = newTotalTime;
            _totalTime = newTotalTime;
            // إعادة خلط الخيارات للسؤال الجديد
            _shuffledOptions.remove(currentQuestionIndex);
          });
          
          // بدء Timer للسؤال الجديد بعد التأكد من إيقاف السابق
          _startTimerForCurrentQuestion();
          
          // Scroll to top
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          // إذا كان الفهرس غير صالح، نرجع للمستويات
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      onAdFailedToShow: () {
        // التحقق من أن الـ widget لا يزال mounted قبل استخدام context
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل تحميل الإعلان. حاول مرة أخرى لاحقاً'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  // إعادة تعيين استخدام الإعلانات عند بدء لعبة جديدة
  Future<void> _resetAdUsageForNewGame() async {
    await AdService.resetChangeQuestionAdUsage();
    await AdService.resetWrongAnswerAdUsage();
  }

  void _restartGame() {
    _timer?.cancel();
    // إعادة تعيين استخدام إعلان تغيير السؤال عند إعادة تشغيل اللعبة
    _resetAdUsageForNewGame();
    // ابدأ من جديد مع أسئلة جديدة تماماً من API
    setState(() {
      // استخدام QuestionDistributor لجلب أسئلة جديدة تماماً
      final distributor = QuestionDistributor(widget.allQuestions);
      List<Question> newQuestions;
      
      // جلب أسئلة جديدة حسب المستوى
      switch (widget.levelId.toLowerCase()) {
        case 'easy':
          newQuestions = distributor.getEasyLevelQuestions();
          break;
        case 'medium':
          newQuestions = distributor.getMediumLevelQuestions();
          break;
        case 'hard':
          newQuestions = distributor.getHardLevelQuestions();
          break;
        case 'legendary':
          newQuestions = distributor.getLegendaryLevelQuestions();
          break;
        case 'daily':
          newQuestions = distributor.getDailyChallengeQuestions();
          break;
        default:
          newQuestions = distributor.getEasyLevelQuestions();
      }
      
      // ترتيب الأسئلة حسب الصعوبة
      _questions = _sortQuestionsByDifficulty(newQuestions);
      // تحديث _originalQuestions للعبة الجديدة
      _originalQuestions = List<Question>.from(_questions);
      
      currentQuestionIndex = 0;
      selectedAnswer = null;
      correctAnswers = 0;
      answeredQuestions = 0; // إعادة تعيين عدد الأسئلة المجاب عليها
      showResult = false;
      showStarAnimation = false;
      earnedStars = 0;
      timeUp = false;
      _shuffledOptions.clear(); // مسح الخيارات المختلطة
    });
    
    // التحقق من حالة استخدام زر تغيير السؤال بعد إعادة التشغيل
    _checkChangeQuestionStatus();

    // بدء Timer للسؤال الأول
    _startTimerForCurrentQuestion();

    // إعادة التمرير لأعلى السؤال
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  // ترتيب الأسئلة حسب الصعوبة: سهل -> متوسط -> صعب -> أسطوري
  List<Question> _sortQuestionsByDifficulty(List<Question> questions) {
    final difficultyOrder = {
      'easy': 1,
      'medium': 2,
      'hard': 3,
      'elegant': 4,
    };

    final sorted = List<Question>.from(questions);
    sorted.sort((a, b) {
      final aOrder = difficultyOrder[a.difficulty.toLowerCase()] ?? 99;
      final bOrder = difficultyOrder[b.difficulty.toLowerCase()] ?? 99;
      return aOrder.compareTo(bOrder);
    });

    return sorted;
  }

  void _showWrongAnswerDialog() async {
    final isAdUsed = await AdService.isWrongAnswerAdUsed();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
            SizedBox(width: 8.w),
            Text(
              'إجابة خاطئة',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Watch Ad to Continue button (مرة واحدة فقط)
                if (!isAdUsed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // حفظ context قبل إغلاق الـ dialog
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        
                        Navigator.pop(context); // Close dialog
                        
                        // إيقاف التايمر قبل عرض الإعلان
                        _timer?.cancel();
                        
                        // التأكد من تحميل الإعلان قبل عرضه
                        if (!_adService.isRewardedAdReady) {
                          await _adService.loadRewardedAd();
                          // انتظار قليل لتحميل الإعلان
                          await Future.delayed(const Duration(milliseconds: 500));
                        }
                        
                        await _adService.showRewardedAd(
                          onRewarded: () async {
                            if (!mounted) return;
                            await AdService.setWrongAnswerAdUsed();
                            // إعادة تعيين استخدام إعلان تغيير السؤال بعد استخدام إعلان المتابعة
                            // لأن المستخدم الآن في نفس الجلسة ويجب أن يتمكن من استخدام "تغيير"
                            await AdService.resetChangeQuestionAdUsage();
                            // المتابعة للسؤال التالي (سيبدأ التايمر تلقائياً في _nextQuestion)
                            _nextQuestion();
                          },
                          onAdFailedToShow: () {
                            // التحقق من أن الـ widget لا يزال mounted قبل استخدام scaffoldMessenger
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('فشل تحميل الإعلان. حاول مرة أخرى لاحقاً'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                      icon: Icon(Icons.play_circle_outline, size: 24.sp),
                      label: Text(
                        'شاهد إعلان للمتابعة',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // أخضر
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                if (!isAdUsed) SizedBox(height: 12.h),
                // Restart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _restartGame();
                    },
                    icon: Icon(Icons.refresh, size: 24.sp),
                    label: Text(
                      'ابدأ مرة أخرى',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // Back button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to levels
                    },
                    icon: Icon(Icons.arrow_back, size: 24.sp),
                    label: Text(
                      'الرجوع',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

  void _showFinalResult() async {
    final won = correctAnswers == _questions.length;
    final starsAsync = ref.read(starsProvider);
    final currentStars = starsAsync.value ?? 0;

    // عرض dialog فقط عند الفوز (مع الصوت)
    if (!won) {
      // إذا لم يفز، لا نعرض أي dialog - فقط نرجع للمستويات
      Navigator.pop(context);
      return;
    }

      await ref.read(levelProgressProvider.notifier).markCompleted(widget.levelId);
    
    // تشغيل صوت الفوز حسب المستوى
    switch (widget.levelId.toLowerCase()) {
      case 'easy':
        SoundService.playEasyLevelWinSound();
        break;
      case 'medium':
        SoundService.playMediumLevelWinSound();
        break;
      case 'hard':
        SoundService.playHardLevelWinSound();
        break;
      case 'legendary':
        SoundService.playLegendLevelWinSound();
        break;
      case 'daily':
        // التحدي اليومي يستخدم نفس صوت المستوى الأسطوري
        SoundService.playLegendLevelWinSound();
        break;
    }

    final isLegendaryWin = won && widget.levelId == 'legendary';

    if (isLegendaryWin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LegendaryWinScreen(
            currentStars: currentStars,
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.amber,
                    size: 64.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'مبروك!',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'لقد فزت بـ${widget.levelName}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'أصبح لديك $currentStars نجمة',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'انتقل للمستوى التالي',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to levels
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF8E1), // كريمي فاتح
              const Color(0xFFFFE0B2), // برتقالي فاتح دافئ
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator - تصميم محمس وممتع
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                child: Row(
                              mainAxisSize: MainAxisSize.min,
                  children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: const Color(0xFFFF6B35),
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // زر تغيير السؤال - يظهر فقط إذا لم يتم استخدامه
                        if (!_isChangeQuestionUsed)
                          InkWell(
                            onTap: () {
                              _changeQuestionWithAd();
                            },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blue.shade700,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 4.w),
                    Text(
                                  'تغيير',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                    const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20.sp,
                              ),
                              SizedBox(width: 6.w),
                    Text(
                      'صحيح: $correctAnswers',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Timer - تصميم محمس
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: _timeRemaining <= 5 
                            ? Colors.red.shade50 
                            : const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _timeRemaining <= 5 
                              ? Colors.red.shade300 
                              : const Color(0xFFFF6B35).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: _timeRemaining <= 5 
                                ? Colors.red.shade700 
                                : const Color(0xFFFF6B35),
                            size: 28.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '$_timeRemaining',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: _timeRemaining <= 5 
                                  ? Colors.red.shade700 
                                  : const Color(0xFFFF6B35),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'ثانية',
                      style: TextStyle(
                        fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: _timeRemaining <= 5 
                                  ? Colors.red.shade700 
                                  : const Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Progress bar محمس
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // حساب التقدم بناءً على عدد الأسئلة المجاب عليها، وليس الفهرس الحالي
                        // هذا يضمن أن تغيير السؤال لا يزيد التقدم
                        final progress = answeredQuestions / _questions.length;
                        return Stack(
                          children: [
                            Container(
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0.0,
                                end: progress,
                              ),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Container(
                                  height: 24.h,
                                  width: constraints.maxWidth * value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF6B35),
                                        const Color(0xFFFFB74D),
                                        const Color(0xFFFFD54F),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B35).withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              height: 24.h,
                              alignment: Alignment.center,
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                        );
                      },
                ),
                  ],
              ),
              ),
              SizedBox(height: 12.h),
              // Star animation overlay
              if (showStarAnimation)
                Container(
                  height: 100.h,
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber.shade700,
                                  size: 32.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '+$earnedStars',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Question content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Question image if available
                      if (currentQuestion.imageUrl != null &&
                          currentQuestion.imageUrl!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: CachedNetworkImage(
                              imageUrl: currentQuestion.imageUrl!,
                              width: double.infinity,
                              height: 300.h,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                width: double.infinity,
                                height: 300.h,
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFFFF6B35), // برتقالي شامي
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      // Question text
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          currentQuestion.questionText ?? '',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Answer options - مختلطة
                      ..._getShuffledOptions(currentQuestion).map((option) => 
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _buildAnswerOption(option['letter']!, option['text']!),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Next button (only show if answer is correct and result is shown)
                      if (showResult && selectedAnswer == _getShuffledCorrectOption(currentQuestion))
                        SizedBox(
                          width: double.infinity,
                          height: 60.h,
                          child: ElevatedButton.icon(
                            onPressed: _nextQuestion,
                            icon: Icon(Icons.arrow_forward, size: 28.sp),
                            label: Text(
                              // التحقق من انتهاء المستوى بناءً على answeredQuestions وليس currentQuestionIndex
                              // لأن currentQuestionIndex قد يزيد عند تغيير السؤال
                              answeredQuestions < _questions.length
                                  ? 'التالي'
                                  : 'انتهى',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String option, String text) {
    final isSelected = selectedAnswer == option;
    final shuffledCorrectOption = _getShuffledCorrectOption(currentQuestion);
    final isCorrect = shuffledCorrectOption == option;
    Color? backgroundColor;
    Color? textColor = Colors.black;

    if (showResult) {
      if (isCorrect) {
        // الإجابة الصحيحة دائماً خضراء عند showResult
        backgroundColor = Colors.green.shade400;
        textColor = Colors.white;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red.shade300;
        textColor = Colors.white;
      } else {
        backgroundColor = Colors.grey.shade200;
      }
    } else {
      backgroundColor = isSelected ? const Color(0xFFFFB74D) : Colors.white; // برتقالي متوسط
      textColor = isSelected ? Colors.white : Colors.black;
    }

    return InkWell(
      onTap: (showResult || timeUp) ? null : () => _selectAnswer(option),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300, // برتقالي شامي
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: textColor == Colors.white
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFFFE0B2), // برتقالي فاتح
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            if (showResult && isCorrect)
              Icon(Icons.check_circle, color: Colors.white, size: 32.sp),
            if (showResult && isSelected && !isCorrect)
              Icon(Icons.cancel, color: Colors.white, size: 32.sp),
          ],
        ),
      ),
    );
  }
}

