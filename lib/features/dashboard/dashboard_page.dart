import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/models/goal_model.dart';
import '../../core/providers/app_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final sessions = ref.watch(recentFocusSessionsProvider).valueOrNull ?? [];
    final activities = ref.watch(recentActivityProvider).valueOrNull ?? [];

    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    final completionRate = tasks.isEmpty ? 0 : ((completedTasks / tasks.length) * 100).round();

    final today = DateTime.now();
    final todayFocusSec = sessions
        .where((s) =>
            s.startedAt.year == today.year &&
            s.startedAt.month == today.month &&
            s.startedAt.day == today.day)
        .fold<int>(0, (sum, s) => sum + s.actualFocusSec);

    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    final upcomingTasks =
        tasks.where((t) => t.status != TaskStatus.completed).take(5).toList();

    final Map<String, int> appDurations = {};
    for (final act in activities) {
      if (act.isIdle) continue;
      appDurations[act.displayName] = (appDurations[act.displayName] ?? 0) + act.durationSec;
    }
    final topApps = appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              isAr ? 'لوحة التحكم — ملخص اليوم' : 'Dashboard — Today\'s Summary',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'بيانات حقيقية مخزنة محليًا دون أي أرقام تجريبية'
                  : 'Real local SQLite metrics — zero mock data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: isAr ? 'الهدف النشط' : 'Active Goal',
                  value: activeGoals.isNotEmpty
                      ? activeGoals.first.title
                      : (isAr ? 'لا يوجد هدف بعد' : 'No goal yet'),
                  icon: Icons.flag_rounded,
                  color: AzmTheme.brightTeal,
                ),
                _StatCard(
                  title: isAr ? 'مدة التركيز اليوم' : 'Focus Today',
                  value: '${todayFocusSec ~/ 60} ${isAr ? "دقيقة" : "min"}',
                  icon: Icons.timer_rounded,
                  color: AzmTheme.primaryTeal,
                ),
                _StatCard(
                  title: isAr ? 'مستوى الإنجاز' : 'Completion Rate',
                  value: '$completionRate% ($completedTasks/${tasks.length})',
                  icon: Icons.check_circle_rounded,
                  color: AzmTheme.accentAmber,
                ),
                _StatCard(
                  title: isAr ? 'سجلات النشاط' : 'Activity Logs',
                  value: '${activities.length}',
                  icon: Icons.monitor_heart_rounded,
                  color: Colors.indigoAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCols = constraints.maxWidth > 800;
                final upcomingCard = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'المهام القادمة' : 'Upcoming Tasks',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (upcomingTasks.isEmpty)
                          Text(isAr ? 'لا توجد مهام معلقة حاليًا.' : 'No pending tasks.')
                        else
                          ...upcomingTasks.map(
                            (t) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.radio_button_unchecked, size: 20),
                              title: Text(t.title),
                              trailing: Text('${t.estimatedMinutes}m'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                final appsCard = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'ملخص استخدام التطبيقات' : 'Top Used Applications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (topApps.isEmpty)
                          Text(isAr
                              ? 'لم يتم تسجيل استخدام تطبيقات بعد.'
                              : 'No application usage recorded yet.')
                        else
                          ...topApps.take(5).map(
                                (e) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.apps_rounded, size: 20),
                                  title: Text(e.key),
                                  trailing: Text('${(e.value / 60).toStringAsFixed(1)}m'),
                                ),
                              ),
                      ],
                    ),
                  ),
                );

                if (twoCols) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: upcomingCard),
                      const SizedBox(width: 16),
                      Expanded(child: appsCard),
                    ],
                  );
                }
                return Column(
                  children: [upcomingCard, const SizedBox(height: 16), appsCard],
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_rounded, color: AzmTheme.accentAmber),
                title: Text(isAr ? 'توصية عزم الذكية' : 'AZM Smart Recommendation'),
                subtitle: Text(
                  upcomingTasks.isNotEmpty
                      ? (isAr
                          ? 'ابدأ بجلسة تركيز لمدة ${upcomingTasks.first.estimatedMinutes} دقيقة لمهمة "${upcomingTasks.first.title}".'
                          : 'Start a ${upcomingTasks.first.estimatedMinutes}m focus session on "${upcomingTasks.first.title}".')
                      : (isAr
                          ? 'أضف هدفًا ومهمة في صفحة الأهداف لبدء تتبع إنجازك الفعلي.'
                          : 'Add a goal and task in Goals & Tasks to begin tracking.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
