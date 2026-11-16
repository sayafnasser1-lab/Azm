import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/app_providers.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  int _tab = 0; // 0=Today, 1=This Week, 2=Planned
  DateTime _selectedDate = DateTime.now();

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text(ar ? 'اليوم' : 'Today')),
                    ButtonSegment(
                      value: 1,
                      label: Text(ar ? 'هذا الأسبوع' : 'This Week'),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(ar ? 'المخطط' : 'Planned'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (v) => setState(() => _tab = v.first),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddTaskDialog(context, ar),
                  icon: const Icon(Icons.add),
                  label: Text(ar ? 'إضافة مهمة' : 'Add Task'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tab == 0)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() =>
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                      ),
                      Text(
                        _iso(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() =>
                            _selectedDate = _selectedDate.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (tasks) {
                  final selIso = _iso(_selectedDate);
                  final weekEnd = _iso(_selectedDate.add(const Duration(days: 7)));
                  final filtered = tasks.where((t) {
                    if (_tab == 0) return t.scheduledDate == selIso;
                    if (_tab == 1) {
                      return t.scheduledDate.compareTo(selIso) >= 0 &&
                          t.scheduledDate.compareTo(weekEnd) <= 0;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        ar
                            ? 'لا توجد مهام في هذا العرض. أضف مهمة للبدء.'
                            : 'No tasks in this view yet.',
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final t = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: t.isCompleted,
                            activeColor: AzmColors.emerald,
                            onChanged: (_) =>
                                ref.read(tasksProvider.notifier).toggle(t),
                          ),
                          title: Text(
                            t.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: t.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            '${t.scheduledDate} • ${t.scheduledTime ?? "--:--"} • ${t.estimatedMinutes}m',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                ref.read(tasksProvider.notifier).remove(t.id),
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

  Future<void> _showAddTaskDialog(BuildContext context, bool ar) async {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00');
    int mins = 25;
    TaskPriority prio = TaskPriority.medium;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ar ? 'مهمة جديدة' : 'New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: ar ? 'عنوان المهمة' : 'Task Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: ar ? 'الوقت (مثال 09:00)' : 'Time (e.g. 09:00)',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(ar ? 'المدة:' : 'Duration:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: mins,
                    items: [15, 25, 45, 60, 90]
                        .map((m) => DropdownMenuItem(value: m, child: Text('${m}m')))
                        .toList(),
                    onChanged: (v) => setLocal(() => mins = v ?? 25),
                  ),
                  const Spacer(),
                  DropdownButton<TaskPriority>(
                    value: prio,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => prio = v ?? TaskPriority.medium),
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
                await ref.read(tasksProvider.notifier).save(
                      TaskItemModel(
                        id: 'tsk_${DateTime.now().microsecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        scheduledDate: _iso(_selectedDate),
                        scheduledTime: timeCtrl.text.trim(),
                        estimatedMinutes: mins,
                        priority: prio,
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
