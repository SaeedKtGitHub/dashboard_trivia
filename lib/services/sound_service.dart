import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static final Random _random = Random();
  
  // تشغيل صوت بدء اللعبة
  static Future<void> playStartingGameSound() async {
    try {
      await _player.play(AssetSource('sounds/starting_game_sound.mpeg'));
    } catch (e) {
      // تجاهل الأخطاء في تشغيل الصوت
      print('Error playing starting game sound: $e');
    }
  }
  
  // تشغيل صوت بدء المستوى (اختيار عشوائي بين صوتين)
  static Future<void> playStartLevelSound() async {
    try {
      // اختيار عشوائي بين صوتين
      final soundPaths = [
        'sounds/start_level_sound.mpeg',
        'sounds/start_level2_sound.mp3',
      ];
      final randomSound = soundPaths[_random.nextInt(soundPaths.length)];
      await _player.play(AssetSource(randomSound));
    } catch (e) {
      print('Error playing start level sound: $e');
    }
  }
  
  // دالة مساعدة لتشغيل الصوت عدة مرات
  static Future<void> _playSoundMultipleTimes(String soundPath, int times) async {
    for (int i = 0; i < times; i++) {
      try {
        // تشغيل الصوت
        await _player.play(AssetSource(soundPath));
        
        // انتظار انتهاء الصوت قبل التشغيل التالي
        if (i < times - 1) {
          try {
            // انتظار حتى ينتهي الصوت (بحد أقصى 10 ثواني)
            await _player.onPlayerComplete.first.timeout(
              const Duration(seconds: 10),
            );
          } catch (e) {
            // إذا انتهى الوقت أو حدث خطأ، تابع
            // هذا يعني أن الصوت لم ينتهِ خلال 10 ثواني، لكننا نتابع
          }
          // انتظار قصير بين التشغيلات
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        print('Error playing sound: $e');
        // في حالة الخطأ، انتظر قليلاً قبل المحاولة التالية
        if (i < times - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }
  
  // تشغيل صوت فوز المستوى السهل (مرتين)
  static Future<void> playEasyLevelWinSound() async {
    _playSoundMultipleTimes('sounds/easy_level_sound.mpeg', 2);
  }
  
  // تشغيل صوت فوز المستوى المتوسط (مرتين)
  static Future<void> playMediumLevelWinSound() async {
    _playSoundMultipleTimes('sounds/meduim_level_sound.mpeg', 2);
  }
  
  // تشغيل صوت فوز المستوى الصعب (مرتين)
  static Future<void> playHardLevelWinSound() async {
    _playSoundMultipleTimes('sounds/hard_level_sound.mpeg', 2);
  }
  
  // تشغيل صوت فوز المستوى الأسطوري (ثلاث مرات)
  static Future<void> playLegendLevelWinSound() async {
    _playSoundMultipleTimes('sounds/legend_level_sound.mpeg', 3);
  }
  
  // إيقاف جميع الأصوات
  static Future<void> stopAllSounds() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping sounds: $e');
    }
  }
}

