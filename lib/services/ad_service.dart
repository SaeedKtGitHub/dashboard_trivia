import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  // Test Ad Unit IDs - استبدلها بـ Ad Unit IDs الخاصة بك من AdMob
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isLoadingRewardedAd = false; // لمنع التحميل المتعدد
  bool _isLoadingInterstitialAd = false; // لمنع التحميل المتعدد
  
  // Getters للتحقق من حالة الإعلانات
  bool get isRewardedAdReady {
    return _isRewardedAdReady;
  }
  
  bool get isInterstitialAdReady {
    return _isInterstitialAdReady;
  }
  
  // Keys لتتبع استخدام الإعلانات
  static const String _wrongAnswerAdUsedKey = 'wrong_answer_ad_used';
  static const String _changeQuestionAdUsedKey = 'change_question_ad_used';
  
  // تحميل Rewarded Ad
  Future<void> loadRewardedAd() async {
    // لا تحميل الإعلانات على الويب
    if (kIsWeb) {
      return;
    }
    
    // منع التحميل المتعدد
    if (_isLoadingRewardedAd) {
      return;
    }
    
    _isLoadingRewardedAd = true;
    
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _isLoadingRewardedAd = false;
            _setAdListeners(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isRewardedAdReady = false;
            _isLoadingRewardedAd = false;
            print('Failed to load rewarded ad: $error');
            // إعادة المحاولة بعد 5 ثواني إذا فشل التحميل
            Future.delayed(const Duration(seconds: 5), () {
              if (!_isRewardedAdReady && !_isLoadingRewardedAd) {
                loadRewardedAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      _isLoadingRewardedAd = false;
      print('Exception loading rewarded ad: $e');
    }
  }
  
  // تحميل Interstitial Ad
  Future<void> loadInterstitialAd() async {
    // لا تحميل الإعلانات على الويب
    if (kIsWeb) {
      return;
    }
    
    // منع التحميل المتعدد
    if (_isLoadingInterstitialAd) {
      return;
    }
    
    _isLoadingInterstitialAd = true;
    
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _isLoadingInterstitialAd = false;
            _setInterstitialAdListeners(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialAdReady = false;
            _isLoadingInterstitialAd = false;
            print('Failed to load interstitial ad: $error');
            // إعادة المحاولة بعد 5 ثواني إذا فشل التحميل
            Future.delayed(const Duration(seconds: 5), () {
              if (!_isInterstitialAdReady && !_isLoadingInterstitialAd) {
                loadInterstitialAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      _isLoadingInterstitialAd = false;
      print('Exception loading interstitial ad: $e');
    }
  }
  
  // إعداد listeners للإعلان المكافأة
  void _setAdListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        try {
          ad.dispose();
        } catch (e) {
          print('Error disposing rewarded ad: $e');
        }
        _isRewardedAdReady = false;
        // تحميل إعلان جديد بعد تأخير قصير
        Future.delayed(const Duration(seconds: 1), () {
          loadRewardedAd();
        });
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        try {
          ad.dispose();
        } catch (e) {
          print('Error disposing rewarded ad on failure: $e');
        }
        _isRewardedAdReady = false;
        print('Failed to show rewarded ad: $error');
        // تحميل إعلان جديد بعد تأخير قصير
        Future.delayed(const Duration(seconds: 1), () {
          loadRewardedAd();
        });
      },
    );
  }
  
  // Callback عند إغلاق الإعلان Interstitial
  Function()? onInterstitialAdClosed;
  
  // إعداد listeners للإعلان Interstitial
  void _setInterstitialAdListeners(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        try {
          ad.dispose();
        } catch (e) {
          print('Error disposing interstitial ad: $e');
        }
        _isInterstitialAdReady = false;
        // استدعاء callback عند إغلاق الإعلان
        onInterstitialAdClosed?.call();
        // تحميل إعلان جديد بعد تأخير قصير
        Future.delayed(const Duration(seconds: 1), () {
          loadInterstitialAd();
        });
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        try {
          ad.dispose();
        } catch (e) {
          print('Error disposing interstitial ad on failure: $e');
        }
        _isInterstitialAdReady = false;
        print('Failed to show interstitial ad: $error');
        // استدعاء callback حتى لو فشل الإعلان
        onInterstitialAdClosed?.call();
        // تحميل إعلان جديد بعد تأخير قصير
        Future.delayed(const Duration(seconds: 1), () {
          loadInterstitialAd();
        });
      },
    );
  }
  
  // عرض Rewarded Ad
  Future<bool> showRewardedAd({
    required Function() onRewarded,
    Function()? onAdFailedToShow,
  }) async {
    // لا عرض الإعلانات على الويب
    if (kIsWeb) {
      onAdFailedToShow?.call();
      return false;
    }
    
    if (!_isRewardedAdReady || _rewardedAd == null) {
      await loadRewardedAd();
      // انتظار قليل للتحميل
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isRewardedAdReady || _rewardedAd == null) {
        onAdFailedToShow?.call();
        return false;
      }
    }
    
    try {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewarded();
        },
      );
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      _isRewardedAdReady = false;
      _rewardedAd = null;
      onAdFailedToShow?.call();
      return false;
    }
  }
  
  // عرض Interstitial Ad
  Future<bool> showInterstitialAd() async {
    // لا عرض الإعلانات على الويب
    if (kIsWeb) {
      return false;
    }
    
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      await loadInterstitialAd();
      // انتظار قليل للتحميل
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isInterstitialAdReady || _interstitialAd == null) {
        return false;
      }
    }
    
    try {
      _interstitialAd!.show();
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      _isInterstitialAdReady = false;
      _interstitialAd = null;
      return false;
    }
  }
  
  // التحقق من استخدام إعلان الإجابة الخاطئة
  static Future<bool> isWrongAnswerAdUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wrongAnswerAdUsedKey) ?? false;
  }
  
  // تعيين استخدام إعلان الإجابة الخاطئة
  static Future<void> setWrongAnswerAdUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wrongAnswerAdUsedKey, true);
  }
  
  // التحقق من استخدام إعلان تغيير السؤال
  static Future<bool> isChangeQuestionAdUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_changeQuestionAdUsedKey) ?? false;
  }
  
  // تعيين استخدام إعلان تغيير السؤال
  static Future<void> setChangeQuestionAdUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_changeQuestionAdUsedKey, true);
  }
  
  // إعادة تعيين استخدام إعلان تغيير السؤال
  static Future<void> resetChangeQuestionAdUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_changeQuestionAdUsedKey);
  }
  
  // إعادة تعيين استخدام إعلان الإجابة الخاطئة
  static Future<void> resetWrongAnswerAdUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wrongAnswerAdUsedKey);
  }
  
  // إعادة تعيين جميع الإعلانات (للتطوير/الاختبار)
  static Future<void> resetAdUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wrongAnswerAdUsedKey);
    await prefs.remove(_changeQuestionAdUsedKey);
  }
  
  // تنظيف الموارد
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}

