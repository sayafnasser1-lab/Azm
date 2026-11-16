import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/activity_model.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/providers/app_providers.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final ar = (settings?.languageCode ?? 'ar') == 'ar';
    final activities = ref.watch(activityProvider).valueOrNull ?? [];
    final rules = ref.watch(distractionRulesProvider).valueOrNull ?? [];
    final actNotifier = ref.read(activityProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: AzmColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        ar
                            ? 'حارس التركيز ومراقبة التشتت'
                            : 'Distraction Guard & Activity Monitor',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    PlatformCapabilities.supportsNativeWindowMonitor
                        ? (ar
                            ? 'متاح على Windows: يراقب التطبيق النشط فقط بموافقتك دون التقاط شاشة أو ضغطات مفاتيح.'
                            : 'Available on Windows: tracks active foreground app with consent (no screenshots or keylogging).')
                        : (ar
                            ? 'أنت تعمل على (${PlatformCapabilities.platformName(arabic: true)}). مراقبة نوافذ النظام التلقائية مخصصة لسطح مكتب Windows فقط، ويمكنك إدارة قواعد التركيز هنا بحرية.'
                            : 'Running on ${PlatformCapabilities.platformName(arabic: false)}. Automatic OS window hooks are Windows-only; you can still manage distraction rules here.'),
                  ),
                  if (PlatformCapabilities.supportsNativeWindowMonitor) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        ar
                            ? 'تفعيل مراقبة التطبيق النشط (Win32)'
                            : 'Enable Active Window Monitor',
                      ),
                      value: actNotifier.isMonitoring,
                      onChanged: (val) async {
                        final ok = await actNotifier.toggleMonitoring(
                          enable: val,
                          captureTitles: settings?.storeWindowTitles ?? false,
                        );
                        if (val && !ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ar
                                    ? 'إضافة Win32 غير مربوطة في runner بعد.'
                                    : 'Win32 native channel is not linked yet.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ar ? 'قواعد مقاومة التشتت' : 'Distraction Rules',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showAddRuleDialog(context, ref, ar),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(ar ? 'إضافة قاعدة' : 'Add Rule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (rules.isEmpty)
                    Text(
                      ar
                          ? 'لا توجد قواعد مضافة بعد (مثل: youtube.com أو discord.exe).'
                          : 'No rules added yet.',
                    )
                  else
                    ...rules.map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Switch(
                          value: r.isEnabled,
                          onChanged: (v) => ref
                              .read(distractionRulesProvider.notifier)
                              .save(r.copyWith(isEnabled: v)),
                        ),
                        title: Text(
                          r.targetName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${r.ruleType} • ${ar ? "المستوى" : "Level"} ${r.actionLevel}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref
                              .read(distractionRulesProvider.notifier)
                              .remove(r.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'سجل النشاط المرصود' : 'Recorded Activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (activities.isEmpty)
                    Text(
                      ar
                          ? 'لا توجد أحداث نشاط مسجلة حتى الآن.'
                          : 'No activity events recorded yet.',
                    )
                  else
                    ...activities.take(15).map(
                          (a) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(a.appName),
                            subtitle: Text('${a.category} • ${a.durationSeconds}s'),
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

  Future<void> _showAddRuleDialog(
    BuildContext context,
    WidgetRef ref,
    bool ar,
  ) async {
    final targetCtrl = TextEditingController();
    String ruleType = 'app';
    int level = 2;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ar ? 'قاعدة مقاومة تشتت' : 'New Distraction Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetCtrl,
                decoration: InputDecoration(
                  labelText: ar
                      ? 'اسم التطبيق أو الموقع (مثال: youtube.com)'
                      : 'App or domain',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  DropdownButton<String>(
                    value: ruleType,
                    items: const [
                      DropdownMenuItem(value: 'app', child: Text('App')),
                      DropdownMenuItem(value: 'domain', child: Text('Domain')),
                    ],
                    onChanged: (v) => setLocal(() => ruleType = v ?? 'app'),
                  ),
                  const Spacer(),
                  DropdownButton<int>(
                    value: level,
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(ar ? 'تنبيه لطيف' : 'Level 1: Alert'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(ar ? 'تأخير 10ث' : 'Level 2: Delay'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(ar ? 'تقييد صارم' : 'Level 3: Strict'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => level = v ?? 2),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (targetCtrl.text.trim().isEmpty) return;
                await ref.read(distractionRulesProvider.notifier).save(
                      DistractionRuleModel(
                        id: 'rul_${DateTime.now().microsecondsSinceEpoch}',
                        targetName: targetCtrl.text.trim(),
                        ruleType: ruleType,
                        actionLevel: level,
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(ar ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
