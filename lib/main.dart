import 'package:bab_alhara_challenge/screens/dashboard_screen.dart';
import 'package:bab_alhara_challenge/services/ad_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة AdMob فقط على Android/iOS وليس على الويب
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      
      // تحميل الإعلانات مسبقاً
      final adService = AdService();
      adService.loadRewardedAd();
      adService.loadInterstitialAd();
    } catch (e) {
      print('Error initializing AdMob: $e');
    }
  }

  // اضبط النجوم على العدد المطلوب للاختبار (احذف السطر بعد انتهائك)
  // to back
    // await StarsService.setStars(200);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// mobile
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(360, 800),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//             useMaterial3: true,
//           ),
//           home: const HomeScreen(),
//         );
//       },
//     );
//   }
// }

// web
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة التحكم - الأسئلة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
