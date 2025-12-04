import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';
import '../services/sound_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/first_screen_background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.3), // برتقالي شامي فاتح
                    const Color(0xFFFFD54F).withOpacity(0.2), // ذهبي فاتح
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100.h,),
                    // App Title
                    Text(
                      'تحدي باب الحارة',
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5E6D3), // كريمي فاتح يتناسب مع الخلفية الدافئة
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                            color: Colors.brown.withOpacity(0.8),
                          ),
                          Shadow(
                            offset: const Offset(-1, -1),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 80.h),
                    // Play Button
                    _buildButton(
                      context,
                      text: 'العب',
                      icon: Icons.play_arrow,
                      color: const Color(0xFFFF6B35), // برتقالي شامي
                      onPressed: () {
                        // تشغيل صوت بدء اللعبة
                        SoundService.playStartingGameSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LevelsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 40.h),
                    // Settings Button
                    _buildButton(
                      context,
                      text: 'الإعدادات',
                      icon: Icons.settings,
                      color: const Color(0xFFFFB74D), // برتقالي متوسط شامي
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 280.w,
      height: 80.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32.sp),
            SizedBox(width: 16.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

