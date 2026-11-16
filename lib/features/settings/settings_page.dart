import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/settings_model.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettingsModel();
    final ar = settings.languageCode == 'ar';
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                settings.userName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${settings.userRole} • ${PlatformCapabilities.storageEngineName}',
              ),
              trailing: TextButton(
                onPressed: () => _editProfile(context, settings, notifier, ar),
                child: Text(ar ? 'تعديل' : 'Edit'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(ar ? 'الوضع الليلي (Dark Mode)' : 'Dark Mode'),
                  value: settings.isDarkMode,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(isDarkMode: v)),
                ),
                ListTile(
                  title: Text(ar ? 'اللغة / Language' : 'Language'),
                  trailing: DropdownButton<String>(
                    value: settings.languageCode,
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        notifier.update(settings.copyWith(languageCode: v));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(ar ? 'محرك الذكاء الاصطناعي' : 'AI Provider'),
                  trailing: DropdownButton<String>(
                    value: settings.aiProviderMode,
                    items: [
                      DropdownMenuItem(
                        value: 'local_offline',
                        child: Text(ar ? 'محلي بدون إنترنت' : 'Local Offline'),
                      ),
                      const DropdownMenuItem(
                        value: 'ollama',
                        child: Text('Ollama (Local)'),
                      ),
                      DropdownMenuItem(
                        value: 'gemini_cloud',
                        child: Text(ar ? 'Gemini السحابي' : 'Gemini Cloud'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        notifier.update(settings.copyWith(aiProviderMode: v));
                      }
                    },
                  ),
                ),
                if (settings.aiProviderMode == 'gemini_cloud') ...[
                  SwitchListTile(
                    title: Text(
                      ar
                          ? 'موافقة صريحة لإرسال ملخص الجلسات لـ Gemini'
                          : 'Consent to send summary context to Gemini',
                    ),
                    value: settings.cloudAiConsent,
                    onChanged: (v) =>
                        notifier.update(settings.copyWith(cloudAiConsent: v)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: ar
                            ? 'مفتاح Gemini المؤقت للجلسة (لا يُحفظ على القرص)'
                            : 'Session-only Gemini API Key',
                      ),
                      onChanged: (v) =>
                          ref.read(runtimeGeminiKeyProvider.notifier).state = v,
                    ),
                  ),
                ],
                SwitchListTile(
                  title: Text(
                    ar
                        ? 'حفظ عناوين النوافذ (مغلق افتراضيًا للخصوصية)'
                        : 'Store Window Titles (Off by default)',
                  ),
                  value: settings.storeWindowTitles,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(storeWindowTitles: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(
                    ar ? 'تصدير نسخة احتياطية (JSON)' : 'Export JSON Backup',
                  ),
                  onTap: () async {
                    final json =
                        await ref.read(repositoryProvider).exportBackupJson();
                    await Clipboard.setData(ClipboardData(text: json));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ar
                              ? 'تم نسخ النسخة الاحتياطية JSON إلى الحافظة!'
                              : 'JSON backup copied to clipboard!',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    ar ? 'مسح كافة البيانات المحلية' : 'Clear All Local Data',
                  ),
                  onTap: () async {
                    await ref.read(repositoryProvider).clearAllData();
                    ref.invalidate(goalsProvider);
                    ref.invalidate(tasksProvider);
                    ref.invalidate(habitsProvider);
                    ref.invalidate(focusProvider);
                    ref.invalidate(calendarEventsProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ar ? 'تم مسح البيانات.' : 'All data cleared.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    AppSettingsModel settings,
    SettingsNotifier notifier,
    bool ar,
  ) async {
    final nameCtrl = TextEditingController(text: settings.userName);
    final roleCtrl = TextEditingController(text: settings.userRole);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'تعديل الملف الشخصي' : 'Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: ar ? 'الاسم' : 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleCtrl,
              decoration: InputDecoration(labelText: ar ? 'الوصف' : 'Role'),
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
              await notifier.update(
                settings.copyWith(
                  userName: nameCtrl.text.trim(),
                  userRole: roleCtrl.text.trim(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ar ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
