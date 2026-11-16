class AppStrings {
  final bool isAr;
  const AppStrings(this.isAr);

  String get appName => isAr ? 'عزم AI' : 'AZM AI';
  String get tagline => isAr ? 'استعد سيطرتك على وقتك وانتباهك' : 'Reclaim your time and attention';

  // Navigation
  String get navDashboard => isAr ? 'لوحة التحكم' : 'Dashboard';
  String get navGoals => isAr ? 'الأهداف والمهام' : 'Goals & Tasks';
  String get navFocus => isAr ? 'جلسة التركيز' : 'Focus';
  String get navActivity => isAr ? 'مراقبة النشاط' : 'Activity';
  String get navRules => isAr ? 'مقاومة التشتت' : 'Distraction Control';
  String get navAi => isAr ? 'المساعد الذكي' : 'AI Assistant';
  String get navAnalytics => isAr ? 'التحليلات' : 'Analytics';
  String get navSettings => isAr ? 'الإعدادات' : 'Settings';

  // Common
  String get offlineReady => isAr ? 'يعمل محليًا دون إنترنت' : 'Offline-First Active';
  String get monitoringOn => isAr ? 'المراقبة مفعّلة' : 'Monitoring On';
  String get monitoringOff => isAr ? 'المراقبة متوقفة' : 'Monitoring Paused';
  String get noDataYet => isAr ? 'لا توجد بيانات مسجلة بعد' : 'No recorded data yet';
  String get add => isAr ? 'إضافة' : 'Add';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get save => isAr ? 'حفظ' : 'Save';
  String get delete => isAr ? 'حذف' : 'Delete';
}
