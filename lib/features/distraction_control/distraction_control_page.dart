import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/models/activity_model.dart';
import '../../core/providers/app_providers.dart';

class DistractionControlPage extends ConsumerStatefulWidget {
  const DistractionControlPage({super.key});

  @override
  ConsumerState<DistractionControlPage> createState() => _DistractionControlPageState();
}

class _DistractionControlPageState extends ConsumerState<DistractionControlPage> {
  final _domainCtrl = TextEditingController();

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final apps = ref.watch(applicationsProvider).valueOrNull ?? [];
    final rules = ref.watch(distractionRulesProvider).valueOrNull ?? [];
    final webRules = ref.watch(websiteRulesProvider).valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'مقاومة التشتت وتصنيف التطبيقات' : 'Distraction Control & App Categories',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddAppDialog(context, isAr),
                  icon: const Icon(Icons.add),
                  label: Text(isAr ? 'إضافة تطبيق' : 'Add App'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'تصنيف التطبيقات (5 فئات)' : 'Application Categorization (5 Categories)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (apps.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isAr
                        ? 'لم تُكتشف تطبيقات بعد. أضف تطبيقًا يدويًا أو فعّل مراقبة النشاط.'
                        : 'No applications tracked yet. Add an app manually or enable monitoring.',
                  ),
                ),
              )
            else
              ...apps.map(
                (app) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.apps_rounded),
                    title: Text(app.displayName),
                    subtitle: Text(app.processName),
                    trailing: DropdownButton<AppCategory>(
                      value: app.category,
                      underline: const SizedBox(),
                      items: AppCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: (cat) async {
                        if (cat == null) return;
                        await ref.read(repositoryProvider).updateApplicationCategory(app.id, cat);
                        ref.invalidate(applicationsProvider);
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'قواعد التطبيقات النشطة' : 'Application Rules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (rules.isEmpty)
              Text(isAr ? 'لا توجد قواعد مخصصة بعد.' : 'No custom app rules yet.')
            else
              ...rules.map(
                (r) => Card(
                  child: SwitchListTile(
                    title: Text('${r.displayName} (${r.ruleType.name})'),
                    subtitle: Text(r.actionLevel.name),
                    value: r.isEnabled,
                    onChanged: (val) async {
                      await ref.read(repositoryProvider).toggleDistractionRule(r.id, val);
                      ref.invalidate(distractionRulesProvider);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'قواعد المواقع (قائمة الحجب/التنبيه)' : 'Website Rules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainCtrl,
                    decoration: InputDecoration(
                      hintText: isAr ? 'مثال: youtube.com' : 'e.g. youtube.com',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    if (_domainCtrl.text.trim().isEmpty) return;
                    await ref
                        .read(repositoryProvider)
                        .addWebsiteRule(_domainCtrl.text, RuleType.block);
                    _domainCtrl.clear();
                    ref.invalidate(websiteRulesProvider);
                  },
                  child: Text(isAr ? 'إضافة نطاق' : 'Add Domain'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...webRules.map(
              (w) => Card(
                child: ListTile(
                  leading: const Icon(Icons.public_off_rounded, color: AzmTheme.accentAmber),
                  title: Text(w.domainPattern),
                  subtitle: Text(w.ruleType.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AzmTheme.alertCoral),
                    onPressed: () async {
                      await ref.read(repositoryProvider).deleteWebsiteRule(w.id);
                      ref.invalidate(websiteRulesProvider);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAppDialog(BuildContext context, bool isAr) async {
    final procCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    AppCategory category = AppCategory.distracting;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(isAr ? 'إضافة تطبيق للتصنيف' : 'Add Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: procCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم العملية (مثال: chrome.exe)' : 'Process Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: isAr ? 'الاسم المعروض' : 'Display Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppCategory>(
                value: category,
                items: AppCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (procCtrl.text.trim().isEmpty) return;
                final repo = ref.read(repositoryProvider);
                final app = await repo.upsertApplication(
                  processName: procCtrl.text.trim(),
                  displayName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                );
                await repo.updateApplicationCategory(app.id, category);
                ref.invalidate(applicationsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
