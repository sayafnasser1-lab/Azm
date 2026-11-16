class AppStrings {
  final bool ar;
  const AppStrings(this.ar);

  String get appName => ar ? 'عزم' : 'AZM AI';
  String get slogan =>
      ar ? 'خطط .. أنجز .. حقق رسالتك' : 'Plan .. Achieve .. Fulfill Your Mission';
  String get splashVerse =>
      '{ وَمَن جَاهَدَ فَإِنَّمَا يُجَاهِدُ لِنَفْسِهِ ۚ إِنَّ اللَّهَ لَغَنِيٌّ عَنِ الْعَالَمِينَ }';
  String get loading => ar ? 'جاري التحميل...' : 'Loading...';

  // Navigation
  String get navDashboard => ar ? 'الرئيسية' : 'Overview';
  String get navTasks => ar ? 'مهامي' : 'Tasks';
  String get navGoals => ar ? 'أهدافي' : 'Goals';
  String get navFocus => ar ? 'التركيز' : 'Focus';
  String get navCalendar => ar ? 'التقويم' : 'Calendar';
  String get navHabits => ar ? 'العادات وتطوري' : 'Habits & Growth';
  String get navActivity => ar ? 'مراقبة التشتت' : 'Distraction Guard';
  String get navAi => ar ? 'المساعد الذكي' : 'AI Assistant';
  String get navAnalytics => ar ? 'إحصائياتي' : 'Analytics';
  String get navSettings => ar ? 'الإعدادات' : 'Settings';

  // Dashboard
  String greeting(String name) =>
      ar ? 'مرحبًا بك، $name' : 'Welcome back, $name';
  String get greetingSub =>
      ar ? 'معًا نحو أهداف أكبر ويوم أكثر تركيزًا' : 'A calmer, more intentional day starts here.';
  String get mainGoalMonth =>
      ar ? 'هدفك الرئيسي هذا الشهر' : 'Your Main Goal This Month';
  String get completedTasks => ar ? 'مهام مكتملة' : 'Completed';
  String get pendingTasks => ar ? 'مهام متبقية' : 'Remaining';
  String get activeGoals => ar ? 'أهداف نشطة' : 'Active Goals';
  String get azmSections => ar ? 'أقسام عزم' : 'AZM Sections';
  String get todaysFocus => ar ? 'تركيز اليوم' : "Today's Focus";
  String get habitTracker => ar ? 'متتبع العادات' : 'Habit Tracker';
  String get upcomingGoals => ar ? 'الأهداف القادمة' : 'Upcoming Goals';
  String get aiRecommendations =>
      ar ? 'توصيات المساعد الذكي' : 'AI Recommendations';
  String get thisWeek => ar ? 'هذا الأسبوع' : 'This Week';
  String get addNew => ar ? '+ جديد' : '+ New';
}
