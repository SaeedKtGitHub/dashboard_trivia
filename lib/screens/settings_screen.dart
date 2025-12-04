import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                _buildSettingItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'حول التطبيق',
                  subtitle: 'تحدي باب الحارة',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                SizedBox(height: 20.h),
                _buildSettingItem(
                  context,
                  icon: Icons.volume_up,
                  title: 'الصوت',
                  subtitle: 'تشغيل/إيقاف الصوت',
                  onTap: () {
                    // TODO: Implement sound toggle
                  },
                ),
                SizedBox(height: 20.h),
                _buildSettingItem(
                  context,
                  icon: Icons.notifications,
                  title: 'الإشعارات',
                  subtitle: 'إدارة الإشعارات',
                  onTap: () {
                    // TODO: Implement notifications settings
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.blue.shade600, size: 28.sp),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حول التطبيق',
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'تحدي باب الحارة\n\nلعبة أسئلة تفاعلية مع مستويات متعددة',
          style: TextStyle(fontSize: 20.sp),
          textAlign: TextAlign.center,
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
}

