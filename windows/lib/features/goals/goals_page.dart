import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/goal_model.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/azm_repository.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  GoalStatus _filter = GoalStatus.active;

  @override
  Widget build(BuildContext context) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SegmentedButton<GoalStatus>(
                  segments: [
                    ButtonSegment(
                      value: GoalStatus.active,
                      label: Text(ar ? 'نشطة' : 'Active'),
                    ),
                    ButtonSegment(
                      value: GoalStatus.completed,
                      label: Text(ar ? 'مكتملة' : 'Completed'),
                    ),
                    ButtonSegment(
                      value: GoalStatus.postponed,
                      label: Text(ar ? 'مؤجلة' : 'Postponed'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (v) => setState(() => _filter = v.first),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddGoalDialog(context, ar),
                  icon: const Icon(Icons.add),
                  label: Text(ar ? 'إضافة هدف جديد' : 'New Goal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: goalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (goals) {
                  final filtered =
                      goals.where((g) => g.status == _filter).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        ar
                            ? 'لا توجد أهداف في هذا القسم حاليًا.'
                            : 'No goals in this tab yet.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final g = filtered[i];
                      final rem = g.remainingDays;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AzmColors.primary.withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.flag,
                                      color: AzmColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (g.subtitle.isNotEmpty)
                                          Text(
                                            g.subtitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (rem != null)
                                    Chip(
                                      label: Text(
                                        ar ? 'متبقي $rem يوم' : '${rem}d left',
                                      ),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (action) async {
                                      if (action == 'subtasks') {
                                        await _generateSubtasks(g, ar);
                                      } else if (action == 'complete') {
                                        await ref
                                            .read(goalsProvider.notifier)
                                            .save(
                                              g.copyWith(
                                                status: GoalStatus.completed,
                                                progress: 100,
                                              ),
                                            );
                                      } else if (action == 'postpone') {
                                        await ref
                                            .read(goalsProvider.notifier)
                                            .save(
                                              g.copyWith(
                                                status: GoalStatus.postponed,
                                              ),
                                            );
                                      } else if (action == 'delete') {
                                        await ref
                                            .read(goalsProvider.notifier)
                                            .remove(g.id);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'subtasks',
                                        child: Text(
                                          ar
                                              ? 'تقسيم لمهام ذكية'
                                              : 'Generate AI Subtasks',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'complete',
                                        child: Text(
                                          ar ? 'تحديد كمكتمل' : 'Mark Completed',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'postpone',
                                        child: Text(
                                          ar ? 'تأجيل' : 'Postpone',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(ar ? 'حذف' : 'Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: g.progress.toDouble(),
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      label: '${g.progress}%',
                                      onChanged: (val) {
                                        final intVal = val.round();
                                        ref.read(goalsProvider.notifier).save(
                                              g.copyWith(
                                                progress: intVal,
                                                status: intVal == 100
                                                    ? GoalStatus.completed
                                                    : g.status,
                                              ),
                                            );
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${g.progress}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AzmColors.emeraldDark,
                                    ),
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

  Future<void> _generateSubtasks(GoalModel goal, bool ar) async {
    final steps = ref
        .read(aiOrchestratorProvider)
        .suggestSubtasks(goal.title, arabic: ar);
    final today = AzmRepository.todayIso();
    for (var i = 0; i < steps.length; i++) {
      await ref.read(tasksProvider.notifier).save(
            TaskItemModel(
              id: 'tsk_${DateTime.now().microsecondsSinceEpoch}_$i',
              goalId: goal.id,
              title: steps[i],
              scheduledDate: today,
              priority: i == 0 ? TaskPriority.high : TaskPriority.medium,
              createdAt: DateTime.now(),
            ),
          );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ar
              ? 'تمت إضافة ${steps.length} مهام عملية للهدف!'
              : 'Added ${steps.length} actionable tasks!',
        ),
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context, bool ar) async {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    int days = 14;
    bool featured = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ar ? 'هدف جديد' : 'New Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: ar ? 'عنوان الهدف' : 'Goal Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subCtrl,
                decoration: InputDecoration(
                  labelText: ar ? 'وصف مختصر' : 'Subtitle',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(ar ? 'المدة (أيام):' : 'Days:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: days,
                    items: [7, 14, 21, 30, 60]
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (v) => setLocal(() => days = v ?? 14),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: featured,
                onChanged: (v) => setLocal(() => featured = v ?? false),
                title: Text(ar ? 'تثبيت كهدف رئيسي' : 'Set as Main Goal'),
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
                await ref.read(goalsProvider.notifier).save(
                      GoalModel(
                        id: 'gol_${DateTime.now().microsecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        subtitle: subCtrl.text.trim(),
                        category: 'learning',
                        targetDate: DateTime.now().add(Duration(days: days)),
                        isFeatured: featured,
                        createdAt: DateTime.now(),
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
