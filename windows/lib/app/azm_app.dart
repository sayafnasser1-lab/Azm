import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/task_model.dart';
import '../core/providers/app_providers.dart';
import '../core/repositories/azm_repository.dart';
import '../features/activity/activity_page.dart';
import '../features/ai_assistant/ai_assistant_page.dart';
import '../features/analytics/analytics_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/focus/focus_page.dart';
import '../features/goals/goals_page.dart';
import '../features/habits_learning/habits_page.dart';
import '../features/settings/settings_page.dart';
import '../features/splash/splash_page.dart';
import '../features/tasks/tasks_page.dart';
import 'theme/azm_theme.dart';
import 'widgets/azm_adaptive_shell.dart';

class AzmApp extends ConsumerStatefulWidget {
  const AzmApp({super.key});

  @override
  ConsumerState<AzmApp> createState() => _AzmAppState();
}

class _AzmAppState extends ConsumerState<AzmApp> {
  bool _showSplash = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final lang = settings?.languageCode ?? 'ar';
    final isDark = settings?.isDarkMode ?? false;
    final ar = lang == 'ar';

    return MaterialApp(
      title: 'AZM AI | عزم',
      debugShowCheckedModeBanner: false,
      theme: AzmTheme.light(),
      darkTheme: AzmTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _showSplash
          ? SplashPage(
              arabic: ar,
              onFinished: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : AzmAdaptiveShell(
              selectedIndex: _selectedIndex,
              onSelect: (idx) => setState(() => _selectedIndex = idx),
              onQuickAdd: () => _showQuickAddDialog(context, ar),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  DashboardPage(
                    onNavigate: (idx) => setState(() => _selectedIndex = idx),
                  ),
                  const TasksPage(),
                  const GoalsPage(),
                  const FocusPage(),
                  const CalendarPage(),
                  const HabitsPage(),
                  const ActivityPage(),
                  const AiAssistantPage(),
                  const AnalyticsPage(),
                  const SettingsPage(),
                ],
              ),
            ),
    );
  }

  Future<void> _showQuickAddDialog(BuildContext context, bool ar) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'إضافة مهمة سريعة لليوم' : 'Quick Add Task'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: ar ? 'اكتب عنوان المهمة...' : 'Task title...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(tasksProvider.notifier).save(
                    TaskItemModel(
                      id: 'tsk_${DateTime.now().microsecondsSinceEpoch}',
                      title: ctrl.text.trim(),
                      scheduledDate: AzmRepository.todayIso(),
                      createdAt: DateTime.now(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ar ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
