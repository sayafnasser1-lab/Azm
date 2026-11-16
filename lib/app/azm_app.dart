import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../features/activity/activity_page.dart';
import '../features/ai_assistant/ai_assistant_page.dart';
import '../features/analytics/analytics_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/distraction_control/distraction_control_page.dart';
import '../features/focus/focus_page.dart';
import '../features/goals/goals_tasks_page.dart';
import '../features/settings/settings_page.dart';
import 'l10n/app_strings.dart';
import 'theme/azm_theme.dart';

class AzmApp extends ConsumerWidget {
  const AzmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    final isAr = (settings?.languageCode ?? 'ar') == 'ar';
    final isDark = settings?.isDarkMode ?? true;

    return MaterialApp(
      title: 'AZM AI — عزم',
      debugShowCheckedModeBanner: false,
      theme: AzmTheme.lightTheme(),
      darkTheme: AzmTheme.darkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(isAr ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AzmShell(),
    );
  }
}

class AzmShell extends ConsumerStatefulWidget {
  const AzmShell({super.key});

  @override
  ConsumerState<AzmShell> createState() => _AzmShellState();
}

class _AzmShellState extends ConsumerState<AzmShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final monitor = ref.read(activityMonitorServiceProvider);
    monitor.distractionAlertStream.listen((alert) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AzmTheme.alertCoral,
          content: Text(alert.message, style: const TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isAr = (settings?.languageCode ?? 'ar') == 'ar';
    final monitoringOn = settings?.monitoringEnabled ?? true;
    final s = AppStrings(isAr);

    final pages = const [
      DashboardPage(),
      GoalsTasksPage(),
      FocusPage(),
      ActivityPage(),
      DistractionControlPage(),
      AiAssistantPage(),
      AnalyticsPage(),
      SettingsPage(),
    ];

    final navItems = [
      (Icons.dashboard_rounded, s.navDashboard),
      (Icons.flag_rounded, s.navGoals),
      (Icons.timer_rounded, s.navFocus),
      (Icons.monitor_heart_rounded, s.navActivity),
      (Icons.shield_rounded, s.navRules),
      (Icons.auto_awesome_rounded, s.navAi),
      (Icons.bar_chart_rounded, s.navAnalytics),
      (Icons.settings_rounded, s.navSettings),
    ];

    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            minExtendedWidth: 220,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 10),
                        Text(
                          s.appName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  if (isWide) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (monitoringOn ? AzmTheme.brightTeal : Colors.grey)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            monitoringOn ? Icons.visibility : Icons.visibility_off,
                            size: 14,
                            color: monitoringOn ? AzmTheme.brightTeal : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            monitoringOn ? s.monitoringOn : s.monitoringOff,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.$1),
                    label: Text(item.$2),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}
