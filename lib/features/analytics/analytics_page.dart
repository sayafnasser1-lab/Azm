import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/models/activity_model.dart';
import '../../core/providers/app_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final sessions = ref.watch(recentFocusSessionsProvider).valueOrNull ?? [];
    final activities = ref.watch(recentActivityProvider).valueOrNull ?? [];

    final Map<AppCategory, int> categorySec = {
      for (final c in AppCategory.values) c: 0,
    };
    for (final act in activities) {
      if (!act.isIdle) {
        categorySec[act.category] = (categorySec[act.category] ?? 0) + act.durationSec;
      }
    }

    final totalSec = categorySec.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              isAr ? 'التقارير والتحليلات' : 'Analytics & Reports',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'توزيع الوقت حسب تصنيف التطبيقات' : 'Time Distribution by Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: totalSec == 0
                          ? Center(
                              child: Text(isAr
                                  ? 'لا توجد بيانات نشاط كافية للرسم البياني بعد.'
                                  : 'Not enough activity data to chart yet.'),
                            )
                          : BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                barGroups: AppCategory.values.asMap().entries.map((entry) {
                                  final minutes = (categorySec[entry.value] ?? 0) / 60.0;
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: minutes,
                                        width: 24,
                                        color: entry.value == AppCategory.distracting
                                            ? AzmTheme.alertCoral
                                            : AzmTheme.brightTeal,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, _) {
                                        final idx = val.toInt();
                                        if (idx < 0 || idx >= AppCategory.values.length) {
                                          return const SizedBox();
                                        }
                                        return Text(
                                          AppCategory.values[idx].name,
                                          style: const TextStyle(fontSize: 11),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights_rounded, color: AzmTheme.brightTeal),
                title: Text(isAr ? 'إجمالي جلسات التركيز المسجلة' : 'Total Recorded Focus Sessions'),
                trailing: Text(
                  '${sessions.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
