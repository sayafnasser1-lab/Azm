import '../../models/activity_model.dart';
import '../../models/focus_session_model.dart';
import '../../models/goal_model.dart';
import '../../models/habit_model.dart';
import '../../models/task_model.dart';

/// محلل سلوكي محلي يعمل 100% بدون إنترنت وبناءً على البيانات الفعلية فقط
class LocalBehavioralAnalyzer {
  const LocalBehavioralAnalyzer();

  String analyze({
    required String prompt,
    required List<GoalModel> goals,
    required List<TaskItemModel> tasks,
    required List<HabitModel> habits,
    required List<FocusSessionModel> sessions,
    required List<ActivityEventModel> activities,
    bool arabic = true,
  }) {
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    final activeGoals =
        goals.where((g) => g.status == GoalStatus.active).toList();
    final totalFocusMinutes = sessions
        .where((s) => s.status == FocusStatus.completed)
        .fold<int>(0, (sum, s) => sum + (s.actualFocusSeconds ~/ 60));

    final distractingSeconds = activities
        .where((a) => a.category == 'distracting')
        .fold<int>(0, (sum, a) => sum + a.durationSeconds);

    final lower = prompt.toLowerCase();

    if (lower.contains('خطة') ||
        lower.contains('تقسيم') ||
        lower.contains('plan') ||
        lower.contains('goal') ||
        lower.contains('هدف')) {
      return _buildGoalPlanReply(
        activeGoals: activeGoals,
        pendingTasks: pendingTasks,
        arabic: arabic,
      );
    }

    if (lower.contains('تشتت') ||
        lower.contains('تركيز') ||
        lower.contains('focus') ||
        lower.contains('distract')) {
      return _buildFocusDiagnosis(
        totalFocusMinutes: totalFocusMinutes,
        distractingSeconds: distractingSeconds,
        pendingTasks: pendingTasks,
        arabic: arabic,
      );
    }

    return _buildGeneralSummary(
      activeGoals: activeGoals.length,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      habitsCount: habits.length,
      totalFocusMinutes: totalFocusMinutes,
      arabic: arabic,
    );
  }

  List<String> suggestSubtasksForGoal(String goalTitle, {bool arabic = true}) {
    final clean = goalTitle.trim();
    if (arabic) {
      return [
        'تحديد المخرجات والمعيار النهائي لإنجاز: $clean',
        'تجهيز المصادر والبيئة المطلوبة والبدء بأول جلسة (25 دقيقة)',
        'تطبيق عملي أو حل تمارين على الجزء الأساسي من: $clean',
        'مراجعة التقدم وتثبيت النقاط الصعبة في نهاية الأسبوع',
      ];
    }
    return [
      'Define clear success criteria for: $clean',
      'Prepare tools/resources and run first 25-min focus block',
      'Build a practical exercise or milestone for: $clean',
      'Review progress and consolidate weak points',
    ];
  }

  String _buildGoalPlanReply({
    required List<GoalModel> activeGoals,
    required int pendingTasks,
    required bool arabic,
  }) {
    if (activeGoals.isEmpty) {
      return arabic
          ? 'لا توجد أهداف نشطة مسجلة حاليًا في قاعدة بياناتك.\n\nابدأ بإضافة هدف واحد رئيسي في صفحة «أهدافي»، ثم قسّمه إلى 3 مهام يومية لا تتجاوز كل منها 25–50 دقيقة.'
          : 'You currently have no active goals saved.\n\nAdd one primary goal in the Goals page, then break it down into 3 focused daily tasks (25–50 minutes each).';
    }
    final top = activeGoals.first;
    final steps = suggestSubtasksForGoal(top.title, arabic: arabic);
    if (arabic) {
      return 'بناءً على بياناتك الفعلية، هدفك النشط الأبرز هو: **${top.title}** (نسبة التقدم: ${top.progress}%، ولديك $pendingTasks مهام متبقية).\n\nخطة تنفيذ مقترحة:\n1. ${steps[0]}\n2. ${steps[1]}\n3. ${steps[2]}\n4. ${steps[3]}';
    }
    return 'Based on your real data, your top active goal is **${top.title}** (${top.progress}% progress, $pendingTasks pending tasks).\n\nSuggested plan:\n1. ${steps[0]}\n2. ${steps[1]}\n3. ${steps[2]}\n4. ${steps[3]}';
  }

  String _buildFocusDiagnosis({
    required int totalFocusMinutes,
    required int distractingSeconds,
    required int pendingTasks,
    required bool arabic,
  }) {
    final distMin = distractingSeconds ~/ 60;
    if (arabic) {
      return 'ملخص تركيزك المسجّل فعليًا:\n'
          '• إجمالي دقائق التركيز المكتملة: $totalFocusMinutes دقيقة.\n'
          '• وقت التشتت المرصود: $distMin دقيقة.\n'
          '• المهام المتبقية: $pendingTasks مهمة.\n\n'
          'التوصية: ابدأ جلسة بومودورو (25 دقيقة) على أصغر مهمة غير مكتملة الآن، وفعّل قاعدة تأخير للتطبيقات المشتتة قبل بدء الجلسة.';
    }
    return 'Your recorded focus metrics:\n'
        '• Completed focus time: $totalFocusMinutes min.\n'
        '• Recorded distraction time: $distMin min.\n'
        '• Pending tasks: $pendingTasks.\n\n'
        'Recommendation: Start one 25-minute Pomodoro session on your smallest pending task now.';
  }

  String _buildGeneralSummary({
    required int activeGoals,
    required int completedTasks,
    required int pendingTasks,
    required int habitsCount,
    required int totalFocusMinutes,
    required bool arabic,
  }) {
    if (arabic) {
      return 'مرحبًا! هذا ملخص وضعك الحالي من بياناتك الحقيقية:\n'
          '• الأهداف النشطة: $activeGoals\n'
          '• المهام المكتملة: $completedTasks | المتبقية: $pendingTasks\n'
          '• العادات المتابَعة: $habitsCount\n'
          '• دقائق التركيز المكتملة: $totalFocusMinutes دقيقة\n\n'
          'اسألني عن: «اقتراح خطة لهدفي» أو «تحليل تركيزي» وسأساعدك فورًا.';
    }
    return 'Here is your current snapshot from real stored data:\n'
        '• Active goals: $activeGoals\n'
        '• Tasks completed: $completedTasks | Pending: $pendingTasks\n'
        '• Tracked habits: $habitsCount\n'
        '• Completed focus: $totalFocusMinutes min\n\n'
        'Ask me to "plan my goal" or "analyze my focus" anytime.';
  }
}
