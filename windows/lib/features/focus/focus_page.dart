import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/focus_session_model.dart';
import '../../core/providers/app_providers.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  String _mode = 'pomodoro';
  int _plannedMinutes = 25;
  String? _selectedTaskId;

  String _fmt(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final sessionsAsync = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);
    final active = notifier.activeSession;
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      ar ? 'جلسة التركيز العميق' : 'Deep Focus Timer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (active == null) ...[
                      Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text(ar ? 'بومودورو 25د' : 'Pomodoro 25m'),
                            selected: _mode == 'pomodoro',
                            onSelected: (_) => setState(() {
                              _mode = 'pomodoro';
                              _plannedMinutes = 25;
                            }),
                          ),
                          ChoiceChip(
                            label: Text(ar ? 'عمل عميق 50د' : 'Deep Work 50m'),
                            selected: _mode == 'deep_work',
                            onSelected: (_) => setState(() {
                              _mode = 'deep_work';
                              _plannedMinutes = 50;
                            }),
                          ),
                          ChoiceChip(
                            label: Text(ar ? 'جلسة قصيرة 15د' : 'Sprint 15m'),
                            selected: _mode == 'sprint',
                            onSelected: (_) => setState(() {
                              _mode = 'sprint';
                              _plannedMinutes = 15;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (pendingTasks.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedTaskId,
                            decoration: InputDecoration(
                              labelText: ar
                                  ? 'ربط بمهمة (اختياري)'
                                  : 'Link to Task (optional)',
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(ar ? 'بدون مهمة محددة' : 'None'),
                              ),
                              ...pendingTasks.map(
                                (t) => DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(
                                    t.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedTaskId = v),
                          ),
                        ),
                      const SizedBox(height: 22),
                      Text(
                        '${_plannedMinutes.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: AzmColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => notifier.startSession(
                          mode: _mode,
                          plannedMinutes: _plannedMinutes,
                          taskId: _selectedTaskId,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(ar ? 'بدء الجلسة الآن' : 'Start Focus'),
                      ),
                    ] else ...[
                      Builder(
                        builder: (_) {
                          final remaining = active.computeRemainingSeconds();
                          final elapsed = active.computeLiveFocusSeconds();
                          final progress = (elapsed /
                                  (active.plannedMinutes * 60).clamp(1, 99999))
                              .clamp(0.0, 1.0);
                          return Column(
                            children: [
                              SizedBox(
                                width: 170,
                                height: 170,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 170,
                                      height: 170,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 10,
                                        backgroundColor: AzmColors.primary
                                            .withValues(alpha: 0.14),
                                      ),
                                    ),
                                    Text(
                                      _fmt(remaining),
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        notifier.pauseOrResume(active),
                                    icon: Icon(
                                      active.status == FocusStatus.running
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    label: Text(
                                      active.status == FocusStatus.running
                                          ? (ar ? 'إيقاف مؤقت' : 'Pause')
                                          : (ar ? 'استئناف' : 'Resume'),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        notifier.finishSession(active),
                                    icon: const Icon(Icons.check),
                                    label: Text(ar ? 'إنهاء وحفظ' : 'Complete'),
                                  ),
                                  TextButton(
                                    onPressed: () => notifier.finishSession(
                                      active,
                                      cancelled: true,
                                    ),
                                    child: Text(ar ? 'إلغاء' : 'Cancel'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ar ? 'سجل الجلسات الأخيرة' : 'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          ar
                              ? 'لم تسجل أي جلسات تركيز بعد.'
                              : 'No focus sessions recorded yet.',
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: list.take(10).map((s) {
                    final mins = s.actualFocusSeconds ~/ 60;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            s.status == FocusStatus.completed
                                ? Icons.check_circle
                                : Icons.timelapse,
                            color: s.status == FocusStatus.completed
                                ? AzmColors.emerald
                                : AzmColors.gold,
                          ),
                          title: Text(
                            '${s.mode} • $mins ${ar ? "دقيقة" : "min"}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            s.startedAt.toLocal().toString().substring(0, 16),
                          ),
                          trailing: Text(s.status.name),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
