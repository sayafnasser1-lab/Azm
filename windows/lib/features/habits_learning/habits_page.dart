import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/habit_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/azm_repository.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  ar ? 'العادات وتطوير الذات' : 'Habits & Personal Growth',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddHabitDialog(context, ref, ar),
                  icon: const Icon(Icons.add),
                  label: Text(ar ? 'عادة جديدة' : 'New Habit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: habitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (habits) {
                  if (habits.isEmpty) {
                    return Center(
                      child: Text(
                        ar
                            ? 'لا توجد عادات مضافة بعد (مثل: القراءة، الرياضة، المراجعة).'
                            : 'No habits added yet.',
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: habits.length,
                    itemBuilder: (ctx, i) {
                      final h = habits[i];
                      final color = Color(h.colorHex);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      h.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    onPressed: () => ref
                                        .read(habitsProvider.notifier)
                                        .remove(h.id),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: CircularProgressIndicator(
                                        value: h.ratio,
                                        strokeWidth: 7,
                                        backgroundColor:
                                            color.withValues(alpha: 0.15),
                                        valueColor:
                                            AlwaysStoppedAnimation(color),
                                      ),
                                    ),
                                    Text(
                                      '${h.completedToday}/${h.targetPerDay}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ar
                                        ? 'سلسلة: ${h.streakDays} يوم'
                                        : 'Streak: ${h.streakDays}d',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => ref
                                        .read(habitsProvider.notifier)
                                        .increment(h),
                                    child: Text(ar ? '+1 إنجاز' : '+1'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddHabitDialog(
    BuildContext context,
    WidgetRef ref,
    bool ar,
  ) async {
    final titleCtrl = TextEditingController();
    int target = 1;
    int colorHex = AzmColors.primary.toARGB32();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ar ? 'عادة يومية جديدة' : 'New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: ar ? 'اسم العادة' : 'Habit Name',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(ar ? 'الهدف اليومي:' : 'Daily Target:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: target,
                    items: [1, 2, 3, 4, 5, 8]
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) => setLocal(() => target = v ?? 1),
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
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(habitsProvider.notifier).save(
                      HabitModel(
                        id: 'hab_${DateTime.now().microsecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        iconName: 'read',
                        targetPerDay: target,
                        colorHex: colorHex,
                        lastUpdatedDate: AzmRepository.todayIso(),
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
