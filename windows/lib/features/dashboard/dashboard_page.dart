import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/l10n/app_strings.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/focus_session_model.dart';
import '../../core/models/goal_model.dart';
import '../../core/models/habit_model.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/azm_repository.dart';

class DashboardPage extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final ar = (settings?.languageCode ?? 'ar') == 'ar';
    final s = AppStrings(ar);
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final habits = ref.watch(habitsProvider).valueOrNull ?? [];
    final sessions = ref.watch(focusProvider).valueOrNull ?? [];

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final pendingCount = tasks.where((t) => !t.isCompleted).length;
    final activeGoals =
        goals.where((g) => g.status == GoalStatus.active).toList();
    final featuredGoal = activeGoals.isEmpty
        ? null
        : activeGoals.firstWhere(
            (g) => g.isFeatured,
            orElse: () => activeGoals.first,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الترحيب
              Text(
                s.greeting(settings?.userName ?? 'سياف'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.greetingSub,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 18),

              // بطاقة الهدف الرئيسي هذا الشهر (من تصميم عزم)
              _FeaturedGoalBanner(
                s: s,
                goal: featuredGoal,
                onTap: () => onNavigate(2),
              ),
              const SizedBox(height: 18),

              // 3 بطاقات مؤشرات (مهام مكتملة، متبقية، أهداف نشطة)
              Row(
                children: [
                  Expanded(
                    child: _KpiTile(
                      label: s.completedTasks,
                      value: '$completedCount',
                      icon: Icons.check_circle,
                      color: AzmColors.emerald,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiTile(
                      label: s.pendingTasks,
                      value: '$pendingCount',
                      icon: Icons.pending_actions,
                      color: AzmColors.sky,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiTile(
                      label: s.activeGoals,
                      value: '${activeGoals.length}',
                      icon: Icons.flag,
                      color: AzmColors.gold,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (isWide) ...[
                // تخطيط سطح المكتب (Bento Grid مستوحى من الصورة 1)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _TodaysFocusCard(
                        s: s,
                        tasks: tasks,
                        onStartFocus: () => onNavigate(3),
                        onToggleTask: (t) =>
                            ref.read(tasksProvider.notifier).toggle(t),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _HabitRingsCard(
                            s: s,
                            habits: habits,
                            onTapAll: () => onNavigate(5),
                            onIncrement: (h) =>
                                ref.read(habitsProvider.notifier).increment(h),
                          ),
                          const SizedBox(height: 16),
                          _WeeklyFocusBarCard(
                            s: s,
                            sessions: sessions,
                            ar: ar,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _UpcomingGoalsCard(
                            s: s,
                            goals: activeGoals,
                            onSeeAll: () => onNavigate(2),
                          ),
                          const SizedBox(height: 16),
                          _AiRecommendationsCard(
                            s: s,
                            pendingCount: pendingCount,
                            activeGoalsCount: activeGoals.length,
                            onOpenAi: () => onNavigate(7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // تخطيط الجوال (شبكة أقسام عزم الـ 6 من الصورة 3)
                Text(
                  s.azmSections,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _SectionTile(
                      label: ar ? 'تعلمي' : 'Learning',
                      icon: Icons.menu_book_rounded,
                      color: AzmColors.primary,
                      onTap: () => onNavigate(5),
                    ),
                    _SectionTile(
                      label: s.navTasks,
                      icon: Icons.checklist_rounded,
                      color: AzmColors.sky,
                      onTap: () => onNavigate(1),
                    ),
                    _SectionTile(
                      label: s.navGoals,
                      icon: Icons.track_changes_rounded,
                      color: AzmColors.gold,
                      onTap: () => onNavigate(2),
                    ),
                    _SectionTile(
                      label: s.navAi,
                      icon: Icons.smart_toy_rounded,
                      color: AzmColors.emerald,
                      onTap: () => onNavigate(7),
                    ),
                    _SectionTile(
                      label: ar ? 'التركيز' : 'Focus',
                      icon: Icons.timer_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => onNavigate(3),
                    ),
                    _SectionTile(
                      label: s.navAnalytics,
                      icon: Icons.analytics_rounded,
                      color: AzmColors.rose,
                      onTap: () => onNavigate(8),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _TodaysFocusCard(
                  s: s,
                  tasks: tasks,
                  onStartFocus: () => onNavigate(3),
                  onToggleTask: (t) =>
                      ref.read(tasksProvider.notifier).toggle(t),
                ),
                const SizedBox(height: 14),
                _HabitRingsCard(
                  s: s,
                  habits: habits,
                  onTapAll: () => onNavigate(5),
                  onIncrement: (h) =>
                      ref.read(habitsProvider.notifier).increment(h),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FeaturedGoalBanner extends StatelessWidget {
  final AppStrings s;
  final GoalModel? goal;
  final VoidCallback onTap;

  const _FeaturedGoalBanner({
    required this.s,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal?.progress ?? 0;
    final rem = goal?.remainingDays;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AzmColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_circle, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  s.mainGoalMonth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (rem != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.ar ? 'متبقي $rem يوم' : '$rem days left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal?.title ??
                  (s.ar
                      ? 'أضف هدفك الرئيسي الآن لتبدأ التتبع'
                      : 'Add your main goal to start tracking'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SectionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysFocusCard extends StatelessWidget {
  final AppStrings s;
  final List<TaskItemModel> tasks;
  final VoidCallback onStartFocus;
  final ValueChanged<TaskItemModel> onToggleTask;

  const _TodaysFocusCard({
    required this.s,
    required this.tasks,
    required this.onStartFocus,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    final today = AzmRepository.todayIso();
    final todaysTasks =
        tasks.where((t) => t.scheduledDate == today).take(5).toList();
    final display = todaysTasks.isNotEmpty ? todaysTasks : tasks.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.todaysFocus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onStartFocus,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: Text(s.ar ? 'بدء جلسة' : 'Focus'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (display.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    s.ar
                        ? 'لا توجد مهام مجدولة اليوم بعد.'
                        : 'No tasks scheduled yet.',
                  ),
                ),
              )
            else
              ...display.map(
                (t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: t.isCompleted,
                    onChanged: (_) => onToggleTask(t),
                  ),
                  title: Text(
                    t.title,
                    style: TextStyle(
                      decoration:
                          t.isCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${t.scheduledTime ?? "--:--"} • ${t.estimatedMinutes}m',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitRingsCard extends StatelessWidget {
  final AppStrings s;
  final List<HabitModel> habits;
  final VoidCallback onTapAll;
  final ValueChanged<HabitModel> onIncrement;

  const _HabitRingsCard({
    required this.s,
    required this.habits,
    required this.onTapAll,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.habitTracker,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onTapAll,
                  child: Text(s.ar ? 'عرض الكل' : 'View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (habits.isEmpty)
              Text(
                s.ar
                    ? 'أضف عاداتك اليومية من قسم العادات وتطوري.'
                    : 'Add daily habits in Habits & Growth.',
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: habits.take(4).map((h) {
                  final color = Color(h.colorHex);
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onIncrement(h),
                    child: SizedBox(
                      width: 78,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  value: h.ratio,
                                  strokeWidth: 5,
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                              Text(
                                '${h.completedToday}/${h.targetPerDay}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            h.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyFocusBarCard extends StatelessWidget {
  final AppStrings s;
  final List<FocusSessionModel> sessions;
  final bool ar;

  const _WeeklyFocusBarCard({
    required this.s,
    required this.sessions,
    required this.ar,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = List<double>.filled(7, 0);
    for (final ses in sessions) {
      if (ses.status != FocusStatus.completed) continue;
      final local = ses.startedAt.toLocal();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(local.year, local.month, local.day))
          .inDays;
      if (diff >= 0 && diff < 7) {
        final idx = 6 - diff;
        buckets[idx] += ses.actualFocusSeconds / 60.0;
      }
    }
    final totalMinutes = buckets.fold<double>(0, (a, b) => a + b).round();
    final maxY = buckets.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.thisWeek,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  ar ? '$totalMinutes د' : '${totalMinutes}m',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AzmColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  maxY: maxY < 30 ? 30 : maxY * 1.2,
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          color: AzmColors.primary.withValues(
                            alpha: i == 6 ? 1.0 : 0.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingGoalsCard extends StatelessWidget {
  final AppStrings s;
  final List<GoalModel> goals;
  final VoidCallback onSeeAll;

  const _UpcomingGoalsCard({
    required this.s,
    required this.goals,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.upcomingGoals,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(s.ar ? 'الكل' : 'See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (goals.isEmpty)
              Text(s.ar ? 'لا توجد أهداف نشطة.' : 'No active goals yet.')
            else
              ...goals.take(3).map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text('${g.progress}%'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: g.progress / 100,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _AiRecommendationsCard extends StatelessWidget {
  final AppStrings s;
  final int pendingCount;
  final int activeGoalsCount;
  final VoidCallback onOpenAi;

  const _AiRecommendationsCard({
    required this.s,
    required this.pendingCount,
    required this.activeGoalsCount,
    required this.onOpenAi,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AzmColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  s.aiRecommendations,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt, color: AzmColors.gold),
              title: Text(
                s.ar
                    ? 'لديك $pendingCount مهام متبقية و$activeGoalsCount أهداف نشطة'
                    : '$pendingCount pending tasks & $activeGoalsCount active goals',
              ),
              subtitle: Text(
                s.ar
                    ? 'اضغط لفتح المساعد الذكي وتوليد خطة تنفيذ'
                    : 'Tap to ask AZM AI for a focused plan',
              ),
              onTap: onOpenAi,
            ),
          ],
        ),
      ),
    );
  }
}
