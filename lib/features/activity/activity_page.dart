import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/activity_monitor_service.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isAr = (settings?.languageCode ?? 'ar') == 'ar';
    final monitor = ref.watch(activityMonitorServiceProvider);
    final activities = ref.watch(recentActivityProvider).valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'مراقبة نشاط Windows' : 'AZM Activity Monitor',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: settings?.monitoringEnabled ?? true,
                  onChanged: (val) async {
                    if (settings == null) return;
                    await ref
                        .read(settingsProvider.notifier)
                        .updateSettings(settings.copyWith(monitoringEnabled: val));
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(repositoryProvider).clearActivityHistory();
                    ref.invalidate(recentActivityProvider);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, color: AzmTheme.alertCoral),
                  label: Text(isAr ? 'مسح السجل' : 'Clear History'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<ActiveWindowSnapshot?>(
              stream: monitor.currentWindowStream,
              initialData: monitor.currentSnapshot,
              builder: (context, snap) {
                final cur = snap.data;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      cur == null ? Icons.pause_circle_outline : Icons.desktop_windows_rounded,
                      color: AzmTheme.brightTeal,
                    ),
                    title: Text(
                      cur != null
                          ? '${cur.processName} (PID: ${cur.processId})'
                          : (isAr
                              ? 'في انتظار أحداث Windows Native Helper'
                              : 'Waiting for Windows Native Helper events'),
                    ),
                    subtitle: Text(
                      cur?.isIdle == true
                          ? (isAr ? 'الحالة: خمول' : 'Status: Idle')
                          : (isAr
                              ? 'تقليل البيانات مفعل • لا تسجيل لضغطات المفاتيح أو الشاشة'
                              : 'Data minimization active • No keylogging or screenshots'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'سجل الانتقالات واستخدام التطبيقات' : 'Application Transition Log',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: activities.isEmpty
                  ? Center(
                      child: Text(
                        isAr
                            ? 'لا توجد سجلات نشاط محفوظة بعد.'
                            : 'No activity records stored yet.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              act.isIdle ? Icons.bedtime_outlined : Icons.apps_rounded,
                              color: act.isIdle ? Colors.grey : AzmTheme.brightTeal,
                            ),
                            title: Text('${act.displayName} (${act.processName})'),
                            subtitle: Text(
                              '${act.category.name} • ${act.durationSec}s'
                              '${act.windowTitleMasked != null ? " • ${act.windowTitleMasked}" : ""}',
                            ),
                            trailing: Text(
                              '${act.startedAt.hour.toString().padLeft(2, '0')}:${act.startedAt.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
