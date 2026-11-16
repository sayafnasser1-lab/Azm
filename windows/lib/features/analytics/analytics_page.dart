import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/focus_session_model.dart';
import '../../core/providers/app_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final sessions = ref.watch(focusProvider).valueOrNull ?? [];

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    final totalTasks = tasks.length;
    final rate =
        totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

    final completedSessions =
        sessions.where((s) => s.status == FocusStatus.completed).toList();
    final totalFocusMinutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s.actualFocusSeconds ~/ 60),
    );

    final avgGoalProgress = goals.isEmpty
        ? 0
        : (goals.fold<int>(0, (s, g) => s + g.progress) / goals.length).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: rate / 100,
                            strokeWidth: 11,
                            backgroundColor:
                                AzmColors.emerald.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(
                              AzmColors.emerald,
                            ),
                          ),
                        ),
                        Text(
                          '$rate%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'معدل الإنجاز الفعلي' : 'Completion Rate',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ar
                              ? 'مهام مكتملة: $completedTasks | متبقية: $pendingTasks'
                              : 'Completed: $completedTasks | Pending: $pendingTasks',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ar
                              ? 'إجمالي التركيز: $totalFocusMinutes دقيقة • متوسط تقدم الأهداف: $avgGoalProgress%'
                              : 'Total focus: ${totalFocusMinutes}m • Avg goal progress: $avgGoalProgress%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar
                        ? 'تطور دقائق التركيز في آخر الجلسات'
                        : 'Focus Minutes Trend',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (completedSessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          ar
                              ? 'أكمل أول جلسة تركيز ليظهر الرسم البياني.'
                              : 'Complete a focus session to see the chart.',
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: AzmColors.primary,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                              spots: List.generate(
                                completedSessions.take(10).length,
                                (i) {
                                  final list = completedSessions
                                      .take(10)
                                      .toList()
                                      .reversed
                                      .toList();
                                  return FlSpot(
                                    i.toDouble(),
                                    (list[i].actualFocusSeconds / 60.0),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
