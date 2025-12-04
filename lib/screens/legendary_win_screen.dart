import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LegendaryWinScreen extends StatefulWidget {
  final int currentStars;

  const LegendaryWinScreen({
    super.key,
    required this.currentStars,
  });

  @override
  State<LegendaryWinScreen> createState() => _LegendaryWinScreenState();
}

class _LegendaryWinScreenState extends State<LegendaryWinScreen> {
  int _counter = 3;
  bool _showCelebration = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_counter == 1) {
        setState(() {
          _showCelebration = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _counter--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF8E1), // كريمي فاتح
              const Color(0xFFFFE0B2), // برتقالي فاتح دافئ
              const Color(0xFFFFD54F), // أصفر ذهبي
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showCelebration
                ? _buildCelebrationContent()
                : _buildCountdown(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'لحظة الأسطورة تبدأ بعد',
            style: TextStyle(
              fontSize: 24.sp,
              color: const Color(0xFFE65100), // برتقالي شامي دافئ
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$_counter',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B35), // برتقالي شامي
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Image as a normal container at the top
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            height: 250.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/celebrate_bab_alhara.JPG',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'لقد فزت بلقب أسطورة باب الحارة 🎉',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE65100), // برتقالي شامي دافئ
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFFFFD54F), size: 32.sp), // ذهبي شامي
                SizedBox(width: 8.w),
                Text(
                  'أصبح لديك ${widget.currentStars} نجمة',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Separate container for "استمر في جمع" with gift icon
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2), // برتقالي فاتح دافئ
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFFFB74D), // برتقالي متوسط
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB74D).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: const Color(0xFFE65100), // برتقالي شامي دافئ
                  size: 36.sp,
                ),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    'استمر في جمع 500 نجمة لتحصل على جائزتك',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: const Color(0xFFBF360C), // برتقالي داكن شامي
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // العودة مباشرة إلى شاشة المستويات
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'العودة إلى المستويات',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35), // برتقالي شامي
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 4,
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

