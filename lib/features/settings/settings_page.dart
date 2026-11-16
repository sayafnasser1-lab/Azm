import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_service.dart';
import '../../core/models/settings_model.dart';
import '../../core/providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? const UserSettingsModel();
    final isAr = settings.languageCode == 'ar';
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              isAr ? 'الإعدادات والخصوصية' : 'Settings & Privacy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(isAr ? 'اللغة' : 'Language'),
                    trailing: DropdownButton<String>(
                      value: settings.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text('العربية (RTL)')),
                        DropdownMenuItem(value: 'en', child: Text('English (LTR)')),
                      ],
                      onChanged: (v) {
                        if (v != null) notifier.updateSettings(settings.copyWith(languageCode: v));
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text(isAr ? 'الوضع الداكن' : 'Dark Mode'),
                    value: settings.isDarkMode,
                    onChanged: (v) => notifier.updateSettings(settings.copyWith(isDarkMode: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(isAr ? 'تفعيل مراقبة نشاط التطبيقات' : 'Enable Activity Monitoring'),
                    subtitle: Text(
                      isAr
                          ? 'لا تسجيل لضغطات المفاتيح أو كلمات المرور أو الشاشة'
                          : 'No keylogging, passwords, or screenshots ever recorded',
                    ),
                    value: settings.monitoringEnabled,
                    onChanged: (v) =>
                        notifier.updateSettings(settings.copyWith(monitoringEnabled: v)),
                  ),
                  SwitchListTile(
                    title: Text(isAr ? 'تخزين عنوان النافذة (اختياري)' : 'Store Window Titles (Optional)'),
                    subtitle: Text(
                      isAr
                          ? 'معطل افتراضيًا لحماية خصوصيتك'
                          : 'Disabled by default for data minimization',
                    ),
                    value: settings.storeWindowTitles,
                    onChanged: (v) =>
                        notifier.updateSettings(settings.copyWith(storeWindowTitles: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(isAr ? 'مزود الذكاء الاصطناعي' : 'AI Provider'),
                    trailing: DropdownButton<AiProviderType>(
                      value: settings.aiProvider,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: AiProviderType.offlineAnalyzer,
                          child: Text('Offline Local Analyzer'),
                        ),
                        DropdownMenuItem(
                          value: AiProviderType.ollamaLocal,
                          child: Text('Ollama (Local LLM)'),
                        ),
                        DropdownMenuItem(
                          value: AiProviderType.geminiCloud,
                          child: Text('Gemini Cloud (Consent Required)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) notifier.updateSettings(settings.copyWith(aiProvider: v));
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text(
                      isAr
                          ? 'الموافقة على إرسال ملخصات للذكاء الاصطناعي السحابي'
                          : 'Consent to send summaries to Cloud AI',
                    ),
                    value: settings.aiCloudConsent,
                    onChanged: (v) =>
                        notifier.updateSettings(settings.copyWith(aiCloudConsent: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_rounded),
                title: Text(isAr ? 'تصدير نسخة احتياطية محلية (JSON)' : 'Export Local JSON Backup'),
                onTap: () async {
                  final path = await DatabaseService.instance.exportBackupJson();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr ? 'تم حفظ النسخة الاحتياطية في: $path' : 'Backup saved to: $path',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
