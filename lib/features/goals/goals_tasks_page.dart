import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/models/goal_model.dart';
import '../../core/providers/app_providers.dart';

class GoalsTasksPage extends ConsumerStatefulWidget {
  const GoalsTasksPage({super.key});

  @override
  ConsumerState<GoalsTasksPage> createState() => _GoalsTasksPageState();
}

class _GoalsTasksPageState extends ConsumerState<GoalsTasksPage> {
  String _filter = 'all'; // all | completed | overdue

  @override
  Widget build(BuildContext context) {
    final isAr = (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];

    final filteredTasks = tasks.where((t) {
      if (_filter == 'completed') return t.status == TaskStatus.completed;
      if (_filter == 'overdue') return t.isOverdue;
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'الأهداف والمهام' : 'Goals & Tasks',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddGoalDialog(context, isAr),
                  icon: const Icon(Icons.add),
                  label: Text(isAr ? 'هدف جديد' : 'New Goal'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: goals.isEmpty ? null : () => _showAddTaskDialog(context, isAr, goals),
                  icon: const Icon(Icons.add_task),
                  label: Text(isAr ? 'مهمة جديدة' : 'New Task'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'all', label: Text(isAr ? 'الكل (${tasks.length})' : 'All')),
                ButtonSegment(
                  value: 'completed',
                  label: Text(isAr ? 'المكتملة' : 'Completed'),
                ),
                ButtonSegment(
                  value: 'overdue',
                  label: Text(isAr ? 'المتأخرة' : 'Overdue'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: goals.isEmpty
                  ? Center(
                      child: Text(
                        isAr
                            ? 'ابدأ بإنشاء هدفك الرئيسي الأول وحدد سبب أهميته.'
                            : 'Create your first main goal and define why it matters.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final goalTasks =
                            filteredTasks.where((t) => t.goalId == goal.id).toList();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.flag_rounded, color: AzmTheme.brightTeal),
                            title: Text(
                              goal.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: goal.whyReason.isNotEmpty
                                ? Text('${isAr ? "السبب:" : "Why:"} ${goal.whyReason}')
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AzmTheme.alertCoral),
                              onPressed: () =>
                                  ref.read(goalsProvider.notifier).deleteGoal(goal.id),
                            ),
                            children: [
                              if (goalTasks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    isAr ? 'لا توجد مهام مطابقة لهذا الهدف.' : 'No matching tasks.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ...goalTasks.map(
                                  (task) => ListTile(
                                    leading: Checkbox(
                                      value: task.status == TaskStatus.completed,
                                      onChanged: (_) =>
                                          ref.read(tasksProvider.notifier).toggleComplete(task),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.status == TaskStatus.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${task.priority.name.toUpperCase()} • ${task.estimatedMinutes}m'
                                      '${task.isOverdue ? (isAr ? " • متأخرة" : " • Overdue") : ""}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          ref.read(tasksProvider.notifier).deleteTask(task.id),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context, bool isAr) async {
    final titleCtrl = TextEditingController();
    final whyCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إنشاء هدف رئيسي' : 'Create Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: isAr ? 'عنوان الهدف' : 'Goal Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: whyCtrl,
              decoration: InputDecoration(labelText: isAr ? 'لماذا هذا الهدف مهم؟' : 'Why it matters'),
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
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(goalsProvider.notifier).addGoal(
                    title: titleCtrl.text.trim(),
                    whyReason: whyCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    bool isAr,
    List<GoalModel> goals,
  ) async {
    final titleCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '25');
    String selectedGoalId = goals.first.id;
    TaskPriority selectedPriority = TaskPriority.medium;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(isAr ? 'إضافة مهمة جديدة' : 'Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedGoalId,
                items: goals
                    .map((g) => DropdownMenuItem(value: g.id, child: Text(g.title)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedGoalId = v ?? selectedGoalId),
                decoration: InputDecoration(labelText: isAr ? 'الهدف المرتبط' : 'Parent Goal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: isAr ? 'عنوان المهمة' : 'Task Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isAr ? 'المدة المتوقعة (دقائق)' : 'Est. Minutes'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                value: selectedPriority,
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedPriority = v ?? selectedPriority),
                decoration: InputDecoration(labelText: isAr ? 'الأولوية' : 'Priority'),
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
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(tasksProvider.notifier).addTask(
                      goalId: selectedGoalId,
                      title: titleCtrl.text.trim(),
                      priority: selectedPriority,
                      estimatedMinutes: int.tryParse(minCtrl.text) ?? 25,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isAr ? 'إضافة' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
