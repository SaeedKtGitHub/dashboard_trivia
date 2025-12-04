import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../utils/question_distributor.dart';
import '../providers/stars_provider.dart';
import '../providers/level_progress_provider.dart';
import '../services/ad_service.dart';
import 'game_screen.dart';

class LevelsScreen extends ConsumerStatefulWidget {
  const LevelsScreen({super.key});

  @override
  ConsumerState<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends ConsumerState<LevelsScreen> {
  late Future<List<Question>> _questionsFuture;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // Refresh stars when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(starsProvider.notifier).refreshStars();
    });
    _questionsFuture = ApiService.getQuestions();
    // تحميل الإعلانات مسبقاً
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starsAsync = ref.watch(starsProvider);
    final userStars = starsAsync.value ?? 0;
    final completedLevels = ref.watch(levelProgressProvider);
    final easyCompleted = completedLevels.contains('easy');
    final mediumCompleted = completedLevels.contains('medium');
    final hardCompleted = completedLevels.contains('hard');

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B35), // برتقالي شامي
                const Color(0xFFFFB74D), // برتقالي متوسط
                const Color(0xFFFFD54F), // ذهبي شامي
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: const Color(0xFFFF6B35).withOpacity(0.5),
        actions: [
          // أيقونة مشاهدة إعلان للحصول على نجمتين
          IconButton(
            icon: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade600,
                    Colors.blue.shade600,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.purple.shade600,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
            tooltip: 'شاهد إعلان للحصول على نجمتين',
            onPressed: () async {
              // التأكد من تحميل الإعلان قبل عرضه
              if (!_adService.isRewardedAdReady) {
                await _adService.loadRewardedAd();
                // انتظار قليل لتحميل الإعلان
                await Future.delayed(const Duration(milliseconds: 500));
              }
              
              await _adService.showRewardedAd(
                onRewarded: () {
                  // إضافة نجمتين
                  ref.read(starsProvider.notifier).addStars(2);
                  // عرض dialog جميل مع animation
                  _showStarsRewardDialog(context);
                },
                onAdFailedToShow: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل تحميل الإعلان. حاول مرة أخرى لاحقاً'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(width: 8.w),
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: const Color(0xFFFF6B35), size: 24.sp),
                SizedBox(width: 6.w),
                Text(
                  '$userStars / 500',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        child: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      'حدث خطأ في تحميل الأسئلة',
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _questionsFuture = ApiService.getQuestions();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'حاول مرة أخرى',
                        style: TextStyle(fontSize: 20.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final allQuestions = snapshot.data ?? [];
            final distributor = QuestionDistributor(allQuestions);

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  // Easy Level (no requirement)
                  _buildLevelCard(
                    context,
                    ref: ref,
                    title: 'المستوى السهل',
                    color: const Color(0xFF388E3C), // أخضر متوسط للوضوح
                    icon: Icons.star,
                    requiredStars: 0,
                    userStars: userStars,
                    dependencySatisfied: true,
                    onTap: () {
                      final questions = distributor.getEasyLevelQuestions();
                      if (questions.length < 10) {
                        _showNotEnoughQuestionsDialog(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            questions: questions,
                            levelName: 'المستوى السهل',
                            levelId: 'easy',
                            allQuestions: allQuestions,
                          ),
                        ),
                      ).then((_) {
                        ref.read(starsProvider.notifier).refreshStars();
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Medium Level (50 stars)
                  _buildLevelCard(
                    context,
                    ref: ref,
                    title: 'المستوى المتوسط',
                    color: const Color(0xFFFF6B35), // برتقالي شامي واضح
                    icon: Icons.star,
                    requiredStars: 50,
                    userStars: userStars,
                    dependencySatisfied: easyCompleted,
                    requiredLevelName: 'المستوى السهل',
                    onTap: () {
                      final questions = distributor.getMediumLevelQuestions();
                      if (questions.length < 10) {
                        _showNotEnoughQuestionsDialog(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            questions: questions,
                            levelName: 'المستوى المتوسط',
                            levelId: 'medium',
                            allQuestions: allQuestions,
                          ),
                        ),
                      ).then((_) {
                        ref.read(starsProvider.notifier).refreshStars();
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Hard Level (85 stars)
                  _buildLevelCard(
                    context,
                    ref: ref,
                    title: 'المستوى الصعب',
                    color: const Color(0xFFE65100), // برتقالي شامي دافئ للوضوح
                    icon: Icons.star,
                    requiredStars: 85,
                    userStars: userStars,
                    dependencySatisfied: mediumCompleted,
                    requiredLevelName: 'المستوى المتوسط',
                    onTap: () {
                      final questions = distributor.getHardLevelQuestions();
                      if (questions.length < 10) {
                        _showNotEnoughQuestionsDialog(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            questions: questions,
                            levelName: 'المستوى الصعب',
                            levelId: 'hard',
                            allQuestions: allQuestions,
                          ),
                        ),
                      ).then((_) {
                        ref.read(starsProvider.notifier).refreshStars();
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Legendary Level (130 stars)
                  _buildLevelCard(
                    context,
                    ref: ref,
                    title: 'المستوى الأسطوري',
                    color: const Color(0xFFBF360C), // برتقالي داكن أسطوري للوضوح
                    icon: Icons.star,
                    requiredStars: 130,
                    userStars: userStars,
                    dependencySatisfied: hardCompleted,
                    requiredLevelName: 'المستوى الصعب',
                    onTap: () {
                      final questions = distributor.getLegendaryLevelQuestions();
                      if (questions.length < 10) {
                        _showNotEnoughQuestionsDialog(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            questions: questions,
                            levelName: 'المستوى الأسطوري',
                            levelId: 'legendary',
                            allQuestions: allQuestions,
                          ),
                        ),
                      ).then((_) {
                        ref.read(starsProvider.notifier).refreshStars();
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Daily Challenge (500 stars)
                  _buildLevelCard(
                    context,
                    ref: ref,
                    title: 'التحدي اليومي',
                    color: const Color(0xFF6A1B9A), // بنفسجي للتمييز
                    icon: Icons.calendar_today,
                    requiredStars: 500,
                    userStars: userStars,
                    dependencySatisfied: true, // متاح دائماً إذا كان لديه 500 نجمة
                    onTap: () {
                      final questions = distributor.getDailyChallengeQuestions();
                      if (questions.length < 10) {
                        _showNotEnoughQuestionsDialog(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            questions: questions,
                            levelName: 'التحدي اليومي',
                            levelId: 'daily',
                            allQuestions: allQuestions,
                          ),
                        ),
                      ).then((_) {
                        ref.read(starsProvider.notifier).refreshStars();
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required Color color,
    required IconData icon,
    required int requiredStars,
    required int userStars,
    bool dependencySatisfied = true,
    String? requiredLevelName,
    required VoidCallback onTap,
  }) {
    final isLocked = requiredStars > 0 && userStars < requiredStars;
    final dependencyLabel = requiredLevelName ?? 'المستوى السابق';
    final hasDependencyRequirement = requiredLevelName != null;
    final hasDependencyIssue = hasDependencyRequirement && !dependencySatisfied;

    return InkWell(
      onTap: () {
        if (isLocked) {
          _showNotEnoughStarsDialog(context, ref, requiredStars, userStars);
          return;
        }
        // to back
        if (hasDependencyIssue) {
          _showDependencyDialog(context, dependencyLabel);
          return;
        }
        onTap();
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Opacity(
        opacity: (isLocked || hasDependencyIssue) ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (isLocked || hasDependencyIssue) ? Icons.lock : icon,
                  size: 40.sp,
                  color: color,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: color.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: color.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    if (requiredStars > 0) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.star, size: 18.sp, color: Colors.amber),
                          SizedBox(width: 4.w),
                          Text(
                            '$requiredStars',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: isLocked ? Colors.red : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLocked) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '(مقفل)',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                (isLocked || hasDependencyIssue)
                    ? Icons.lock_outline
                    : Icons.arrow_forward_ios,
                color: color,
                size: 24.sp,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: color.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotEnoughQuestionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير', style: TextStyle(fontSize: 24.sp)),
        content: Text(
          'لا توجد أسئلة كافية لهذا المستوى',
          style: TextStyle(fontSize: 20.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: TextStyle(fontSize: 20.sp)),
          ),
        ],
      ),
    );
  }

  void _showNotEnoughStarsDialog(
    BuildContext context,
    WidgetRef ref,
    int requiredStars,
    int userStars,
  ) {
    final needed = requiredStars - userStars;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: Colors.red,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'مستوى مقفل! 🔒',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32.sp),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لديك: $userStars نجمة',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        'تحتاج: $requiredStars نجمة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24.sp),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'أنت بحاجة إلى $needed نجمة إضافية!',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'العب المستويات السابقة لجمع النجوم ⭐',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.check_circle, size: 24.sp),
              label: Text(
                'حسناً',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStarsRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // نجمة متحركة
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber.shade700,
                        size: 60.sp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
              // نص "تم إضافة نجمتين"
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Column(
                        children: [
                          Text(
                            '🎉 مبروك! 🎉',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 32.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '+2',
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 32.sp,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'تم إضافة نجمتين إلى رصيدك!',
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade700,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'حسناً',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDependencyDialog(
    BuildContext context,
    String requiredLevelName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'تنبيه',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: Colors.orange, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'عليك ختم $requiredLevelName أولاً',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

