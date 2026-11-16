import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/providers/app_providers.dart';
import '../l10n/app_strings.dart';
import '../theme/azm_colors.dart';
import 'azm_brand_logo.dart';

class AzmNavDestination {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AzmNavDestination({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AzmAdaptiveShell extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;
  final VoidCallback? onQuickAdd;

  const AzmAdaptiveShell({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final ar = (settings?.languageCode ?? 'ar') == 'ar';
    final s = AppStrings(ar);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final pendingCount = tasks.where((t) => !t.isCompleted).length;

    final destinations = [
      AzmNavDestination(
        index: 0,
        label: s.navDashboard,
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
      ),
      AzmNavDestination(
        index: 1,
        label: s.navTasks,
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
      ),
      AzmNavDestination(
        index: 2,
        label: s.navGoals,
        icon: Icons.flag_outlined,
        selectedIcon: Icons.flag,
      ),
      AzmNavDestination(
        index: 3,
        label: s.navFocus,
        icon: Icons.timer_outlined,
        selectedIcon: Icons.timer,
      ),
      AzmNavDestination(
        index: 4,
        label: s.navCalendar,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
      ),
      AzmNavDestination(
        index: 5,
        label: s.navHabits,
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
      ),
      AzmNavDestination(
        index: 6,
        label: s.navActivity,
        icon: Icons.shield_outlined,
        selectedIcon: Icons.shield,
      ),
      AzmNavDestination(
        index: 7,
        label: s.navAi,
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy,
      ),
      AzmNavDestination(
        index: 8,
        label: s.navAnalytics,
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
      ),
      AzmNavDestination(
        index: 9,
        label: s.navSettings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // وضع سطح المكتب والويب (>= 1050px) - مستوحى من NovaNest
        if (width >= 1050) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopSidebar(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelect: onSelect,
                  pendingTasksCount: pendingCount,
                  userName: settings?.userName ?? 'سياف',
                  userRole: settings?.userRole ?? 'مستخدم عزم',
                  ar: ar,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopTopBar(
                        s: s,
                        onQuickAdd: onQuickAdd,
                        platformName: PlatformCapabilities.platformName(arabic: ar),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // وضع التابلت (700px - 1049px)
        if (width >= 700) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelect,
                  labelType: NavigationRailLabelType.selected,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: AzmBrandLogo(size: 38),
                  ),
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        // وضع الجوال (< 700px) - مستوحى من تصميم عزم للجوال
        // 5 تبويبات رئيسية في الأسفل: الرئيسية، مهامي، التقويم، المساعد، والمزيد
        final mobileIndices = [0, 1, 4, 7, 8];
        final currentMobilePos = mobileIndices.indexOf(selectedIndex);
        final barIndex = currentMobilePos >= 0 ? currentMobilePos : 4;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              children: [
                const AzmBrandLogo(size: 32),
                const SizedBox(width: 10),
                Text(
                  destinations[selectedIndex].label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              if (onQuickAdd != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onQuickAdd,
                  tooltip: s.addNew,
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => onSelect(9),
                tooltip: s.navSettings,
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: barIndex,
            onDestinationSelected: (pos) {
              if (pos == 4) {
                _showMobileMoreSheet(context, destinations, onSelect, ar);
              } else {
                onSelect(mobileIndices[pos]);
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: s.navDashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline),
                selectedIcon: const Icon(Icons.check_circle),
                label: s.navTasks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: s.navCalendar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.smart_toy_outlined),
                selectedIcon: const Icon(Icons.smart_toy),
                label: s.navAi,
              ),
              NavigationDestination(
                icon: const Icon(Icons.apps_outlined),
                selectedIcon: const Icon(Icons.apps),
                label: ar ? 'المزيد' : 'More',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMobileMoreSheet(
    BuildContext context,
    List<AzmNavDestination> destinations,
    ValueChanged<int> onSelect,
    bool ar,
  ) {
    final moreItems = destinations.where((d) => [2, 3, 5, 6, 8, 9].contains(d.index));
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: moreItems.map((d) {
              return SizedBox(
                width: 104,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(d.index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(d.selectedIcon, color: AzmColors.primary),
                        const SizedBox(height: 6),
                        Text(
                          d.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final List<AzmNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final int pendingTasksCount;
  final String userName;
  final String userRole;
  final bool ar;

  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.pendingTasksCount,
    required this.userName,
    required this.userRole,
    required this.ar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AzmColors.darkSurface : AzmColors.lightSurface;
    final border = isDark ? AzmColors.darkBorder : AzmColors.lightBorder;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: bg,
        border: BorderDirectional(
          end: BorderSide(color: border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              children: [
                const AzmBrandLogo(size: 38),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'عزم | AZM' : 'AZM AI',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ar ? 'منظم حياتك الذكي' : 'Smart Focus System',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AzmColors.darkTextMuted
                                : AzmColors.lightTextMuted,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: destinations.length - 1,
              itemBuilder: (ctx, i) {
                final d = destinations[i];
                final active = selectedIndex == d.index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selected: active,
                    selectedTileColor: isDark
                        ? AzmColors.primary.withValues(alpha: 0.22)
                        : AzmColors.primarySoft,
                    leading: Icon(
                      active ? d.selectedIcon : d.icon,
                      color: active ? AzmColors.primary : null,
                      size: 20,
                    ),
                    title: Text(
                      d.label,
                      style: TextStyle(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AzmColors.primary : null,
                      ),
                    ),
                    trailing: (d.index == 1 && pendingTasksCount > 0)
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AzmColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingTasksCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AzmColors.primary,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => onSelect(d.index),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: selectedIndex == 9,
                  selectedTileColor: isDark
                      ? AzmColors.primary.withValues(alpha: 0.22)
                      : AzmColors.primarySoft,
                  leading: const Icon(Icons.settings_outlined, size: 20),
                  title: Text(destinations[9].label),
                  onTap: () => onSelect(9),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AzmColors.darkBg : AzmColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AzmColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0] : 'ع',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              userRole,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  final AppStrings s;
  final VoidCallback? onQuickAdd;
  final String platformName;

  const _DesktopTopBar({
    required this.s,
    required this.onQuickAdd,
    required this.platformName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AzmColors.darkSurface : AzmColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AzmColors.darkBorder : AzmColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AzmColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.devices, size: 15, color: AzmColors.emeraldDark),
                const SizedBox(width: 6),
                Text(
                  platformName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AzmColors.emeraldDark,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (onQuickAdd != null)
            ElevatedButton.icon(
              onPressed: onQuickAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.ar ? 'إضافة سريعة' : 'New'),
            ),
        ],
      ),
    );
  }
}
