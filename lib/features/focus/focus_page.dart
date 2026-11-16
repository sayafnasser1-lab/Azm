import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/models/focus_session_model.dart';
import '../../core/providers/app_providers.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  String? _selectedTaskId;
  int _plannedMinutes = 25;
  FocusMode _mode = FocusMode.deepWork;

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final activeSession = ref.watch(focusControllerProvider).valueOrNull;
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final recentSessions = ref.watch(recentFocusSessionsProvider).valueOrNull ?? [];
    final controller = ref.read(focusControllerProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              isAr ? 'نظام جلسات التركيز' : 'Focus Sessions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'مؤقت مرتبط بساعة النظام وقاعدة البيانات لضمان الدقة حتى عند إغلاق التطبيق'
                  : 'Wall-clock persisted timer in SQLite — survives window close & restart',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: activeSession == null
                    ? Column(
                        children: [
                          DropdownButtonFormField<String?>(
                            value: _selectedTaskId,
                            decoration: InputDecoration(
                              labelText: isAr ? 'المهمة المرتبطة (اختياري)' : 'Linked Task (Optional)',
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(isAr ? 'جلسة تركيز حرة' : 'Free Focus Session'),
                              ),
                              ...tasks.map(
                                (t) => DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(t.title),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _selectedTaskId = v),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<FocusMode>(
                                  value: _mode,
                                  decoration: InputDecoration(labelText: isAr ? 'نمط الجلسة' : 'Mode'),
                                  items: FocusMode.values
                                      .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _mode = v ?? _mode),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _plannedMinutes,
                                  decoration: InputDecoration(labelText: isAr ? 'المدة' : 'Duration'),
                                  items: const [15, 25, 45, 60, 90]
                                      .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                                      .toList(),
                                  onChanged: (v) => setState(() => _plannedMinutes = v ?? 25),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => controller.startSession(
                              taskId: _selectedTaskId,
                              mode: _mode,
                              plannedMinutes: _plannedMinutes,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(isAr ? 'بدء جلسة التركيز' : 'Start Focus Session'),
                          ),
                        ],
                      )
                    : StreamBuilder<DateTime>(
                        stream: controller.tickStream,
                        initialData: DateTime.now(),
                        builder: (context, snap) {
                          final now = snap.data ?? DateTime.now();
                          final remaining = activeSession.computeRemainingSeconds(now);
                          final liveFocus = activeSession.computeLiveFocusSeconds(now);
                          final progress = (liveFocus / (activeSession.plannedMinutes * 60))
                              .clamp(0.0, 1.0);

                          return Column(
                            children: [
                              Text(
                                activeSession.status == FocusSessionStatus.paused
                                    ? (isAr ? 'متوقفة مؤقتًا' : 'Paused')
                                    : (isAr ? 'جاري التركيز...' : 'Focusing...'),
                                style: TextStyle(
                                  color: activeSession.status == FocusSessionStatus.paused
                                      ? AzmTheme.accentAmber
                                      : AzmTheme.brightTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 10,
                                    ),
                                    Center(
                                      child: Text(
                                        _formatDuration(remaining),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isAr
                                    ? 'التركيز الفعلي: ${_formatDuration(liveFocus)} • الانقطاعات: ${activeSession.interruptionCount}'
                                    : 'Actual Focus: ${_formatDuration(liveFocus)} • Interruptions: ${activeSession.interruptionCount}',
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                children: [
                                  if (activeSession.status == FocusSessionStatus.running)
                                    OutlinedButton.icon(
                                      onPressed: controller.pauseSession,
                                      icon: const Icon(Icons.pause),
                                      label: Text(isAr ? 'إيقاف مؤقت' : 'Pause'),
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: controller.resumeSession,
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(isAr ? 'استئناف' : 'Resume'),
                                    ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final finished = await controller.finishSession();
                                      if (finished != null && context.mounted) {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(isAr ? 'ملخص الجلسة' : 'Session Summary'),
                                            content: Text(
                                              isAr
                                                  ? 'التركيز الفعلي: ${finished.actualFocusSec ~/ 60} دقيقة\nالانقطاعات: ${finished.interruptionCount}'
                                                  : 'Actual focus: ${finished.actualFocusSec ~/ 60}m\nInterruptions: ${finished.interruptionCount}',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: Text(isAr ? 'حسنًا' : 'OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check),
                                    label: Text(isAr ? 'إنهاء الجلسة' : 'Complete'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'سجل الجلسات الأخيرة' : 'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (recentSessions.isEmpty)
              Text(isAr ? 'لم تبدأ أي جلسات بعد.' : 'No sessions recorded yet.')
            else
              ...recentSessions.take(8).map(
                    (s) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.history_rounded),
                        title: Text('${s.mode.name} • ${s.plannedMinutes}m'),
                        subtitle: Text(
                          '${isAr ? "الفعلي:" : "Actual:"} ${s.actualFocusSec ~/ 60}m • ${s.status.name}',
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
