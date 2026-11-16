import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/storage_driver.dart';
import '../models/activity_model.dart';
import '../models/calendar_event_model.dart';
import '../models/chat_model.dart';
import '../models/focus_session_model.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/settings_model.dart';
import '../models/task_model.dart';
import '../platform/activity_bridge.dart';
import '../repositories/azm_repository.dart';
import '../services/ai/ai_orchestrator.dart';

final storageDriverProvider = Provider<AzmStorageDriver>((ref) {
  return AzmStorageDriver();
});

final repositoryProvider = Provider<AzmRepository>((ref) {
  return AzmRepository(ref.watch(storageDriverProvider));
});

final activityBridgeProvider = Provider<ActivityBridge>((ref) {
  return ActivityBridge();
});

final aiOrchestratorProvider = Provider<AiOrchestrator>((ref) {
  return AiOrchestrator();
});

/// مفتاح Gemini في الذاكرة المؤقتة للجلسة فقط (لا يُحفظ في القاعدة)
final runtimeGeminiKeyProvider = StateProvider<String>((ref) => '');

// ---------------- Settings ----------------
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettingsModel>> {
  final AzmRepository _repo;
  SettingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      await _repo.init();
      state = AsyncValue.data(await _repo.getSettings());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(AppSettingsModel settings) async {
    state = AsyncValue.data(settings);
    await _repo.saveSettings(settings);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettingsModel>>(
  (ref) => SettingsNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Goals ----------------
class GoalsNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  final AzmRepository _repo;
  GoalsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getGoals());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(GoalModel goal) async {
    await _repo.upsertGoal(goal);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteGoal(id);
    await load();
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<GoalModel>>>(
  (ref) => GoalsNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Tasks ----------------
class TasksNotifier extends StateNotifier<AsyncValue<List<TaskItemModel>>> {
  final AzmRepository _repo;
  TasksNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getTasks());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(TaskItemModel task) async {
    await _repo.upsertTask(task);
    await load();
  }

  Future<void> toggle(TaskItemModel task) async {
    final next = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await _repo.upsertTask(next);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteTask(id);
    await load();
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskItemModel>>>(
  (ref) => TasksNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Habits ----------------
class HabitsNotifier extends StateNotifier<AsyncValue<List<HabitModel>>> {
  final AzmRepository _repo;
  HabitsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getHabits());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(HabitModel habit) async {
    await _repo.upsertHabit(habit);
    await load();
  }

  Future<void> increment(HabitModel habit) async {
    final today = AzmRepository.todayIso();
    final nextCount = (habit.completedToday + 1).clamp(0, habit.targetPerDay);
    final reachedTarget =
        habit.completedToday < habit.targetPerDay && nextCount == habit.targetPerDay;
    final next = habit.copyWith(
      completedToday: nextCount,
      streakDays: reachedTarget ? habit.streakDays + 1 : habit.streakDays,
      lastUpdatedDate: today,
    );
    await _repo.upsertHabit(next);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteHabit(id);
    await load();
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<HabitModel>>>(
  (ref) => HabitsNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Focus Sessions ----------------
class FocusNotifier extends StateNotifier<AsyncValue<List<FocusSessionModel>>> {
  final AzmRepository _repo;
  Timer? _ticker;
  int tickCounter = 0;

  FocusNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final list = await _repo.getFocusSessions();
      state = AsyncValue.data(list);
      _syncTicker(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  FocusSessionModel? get activeSession {
    final list = state.valueOrNull;
    if (list == null) return null;
    for (final s in list) {
      if (s.status == FocusStatus.running || s.status == FocusStatus.paused) {
        return s;
      }
    }
    return null;
  }

  void _syncTicker(List<FocusSessionModel> list) {
    final hasRunning = list.any((s) => s.status == FocusStatus.running);
    if (hasRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        tickCounter++;
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncValue.data(List<FocusSessionModel>.from(current));
        }
      });
    } else if (!hasRunning && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> startSession({
    required String mode,
    required int plannedMinutes,
    String? taskId,
  }) async {
    final active = activeSession;
    if (active != null) {
      await finishSession(active, cancelled: true);
    }
    final session = FocusSessionModel(
      id: 'fs_${DateTime.now().microsecondsSinceEpoch}',
      taskId: taskId,
      mode: mode,
      plannedMinutes: plannedMinutes,
      startedAt: DateTime.now().toUtc(),
      status: FocusStatus.running,
    );
    await _repo.upsertFocusSession(session);
    await load();
  }

  Future<void> pauseOrResume(FocusSessionModel session) async {
    final now = DateTime.now().toUtc();
    if (session.status == FocusStatus.running) {
      await _repo.upsertFocusSession(
        session.copyWith(
          status: FocusStatus.paused,
          pauseStartedAt: now,
        ),
      );
    } else if (session.status == FocusStatus.paused) {
      final addedPause = session.pauseStartedAt != null
          ? now.difference(session.pauseStartedAt!.toUtc()).inSeconds
          : 0;
      await _repo.upsertFocusSession(
        session.copyWith(
          status: FocusStatus.running,
          pausedSeconds: session.pausedSeconds + (addedPause < 0 ? 0 : addedPause),
          clearPauseStartedAt: true,
        ),
      );
    }
    await load();
  }

  Future<void> finishSession(
    FocusSessionModel session, {
    bool cancelled = false,
  }) async {
    final now = DateTime.now().toUtc();
    final actual = session.computeLiveFocusSeconds(now);
    await _repo.upsertFocusSession(
      session.copyWith(
        endedAt: now,
        actualFocusSeconds: actual,
        status: cancelled ? FocusStatus.cancelled : FocusStatus.completed,
        clearPauseStartedAt: true,
      ),
    );
    await load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final focusProvider =
    StateNotifierProvider<FocusNotifier, AsyncValue<List<FocusSessionModel>>>(
  (ref) => FocusNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Calendar Events ----------------
class CalendarEventsNotifier
    extends StateNotifier<AsyncValue<List<CalendarEventModel>>> {
  final AzmRepository _repo;
  CalendarEventsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getCalendarEvents());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(CalendarEventModel event) async {
    await _repo.upsertCalendarEvent(event);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteCalendarEvent(id);
    await load();
  }
}

final calendarEventsProvider = StateNotifierProvider<CalendarEventsNotifier,
    AsyncValue<List<CalendarEventModel>>>(
  (ref) => CalendarEventsNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Activity & Distraction Rules ----------------
class ActivityNotifier
    extends StateNotifier<AsyncValue<List<ActivityEventModel>>> {
  final AzmRepository _repo;
  final ActivityBridge _bridge;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool isMonitoring = false;

  ActivityNotifier(this._repo, this._bridge)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getActivityEvents());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleMonitoring({
    required bool enable,
    required bool captureTitles,
  }) async {
    if (!enable) {
      await _sub?.cancel();
      _sub = null;
      await _bridge.stopNativeMonitor();
      isMonitoring = false;
      await load();
      return false;
    }

    final available = await _bridge.isNativeMonitorAvailable();
    if (!available) {
      isMonitoring = false;
      return false;
    }

    final ok =
        await _bridge.startNativeMonitor(captureWindowTitle: captureTitles);
    if (ok) {
      isMonitoring = true;
      await _sub?.cancel();
      _sub = _bridge.nativeActivityStream().listen((raw) async {
        final app = (raw['appName'] ?? 'unknown').toString();
        final dur = (raw['durationSeconds'] as num?)?.toInt() ?? 5;
        final idle = raw['isIdle'] == true;
        final title = captureTitles ? raw['windowTitle']?.toString() : null;
        await logManualOrNativeEvent(
          appName: app,
          windowTitle: title,
          durationSeconds: dur,
          isIdle: idle,
        );
      });
    }
    return ok;
  }

  Future<void> logManualOrNativeEvent({
    required String appName,
    String? windowTitle,
    required int durationSeconds,
    bool isIdle = false,
  }) async {
    final lower = appName.toLowerCase();
    String category = 'neutral';
    if (lower.contains('code') ||
        lower.contains('studio') ||
        lower.contains('azm') ||
        lower.contains('word') ||
        lower.contains('terminal')) {
      category = 'productive';
    } else if (lower.contains('youtube') ||
        lower.contains('discord') ||
        lower.contains('tiktok') ||
        lower.contains('steam') ||
        lower.contains('instagram')) {
      category = 'distracting';
    }
    await _repo.insertActivityEvent(
      ActivityEventModel(
        id: 'act_${DateTime.now().microsecondsSinceEpoch}',
        appName: appName,
        windowTitle: windowTitle,
        category: category,
        durationSeconds: durationSeconds,
        isIdle: isIdle,
        recordedAt: DateTime.now().toUtc(),
      ),
    );
    await load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, AsyncValue<List<ActivityEventModel>>>(
  (ref) => ActivityNotifier(
    ref.watch(repositoryProvider),
    ref.watch(activityBridgeProvider),
  ),
);

class DistractionRulesNotifier
    extends StateNotifier<AsyncValue<List<DistractionRuleModel>>> {
  final AzmRepository _repo;
  DistractionRulesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getDistractionRules());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(DistractionRuleModel rule) async {
    await _repo.upsertDistractionRule(rule);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteDistractionRule(id);
    await load();
  }
}

final distractionRulesProvider = StateNotifierProvider<DistractionRulesNotifier,
    AsyncValue<List<DistractionRuleModel>>>(
  (ref) => DistractionRulesNotifier(ref.watch(repositoryProvider)),
);

// ---------------- Chat Threads ----------------
class ChatThreadsNotifier
    extends StateNotifier<AsyncValue<List<ChatThreadModel>>> {
  final AzmRepository _repo;
  ChatThreadsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repo.getChatThreads());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ChatThreadModel> createThread(String title) async {
    final t = ChatThreadModel(
      id: 'thr_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      updatedAt: DateTime.now(),
    );
    await _repo.upsertChatThread(t);
    await load();
    return t;
  }

  Future<void> togglePin(ChatThreadModel thread) async {
    await _repo.upsertChatThread(thread.copyWith(isPinned: !thread.isPinned));
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deleteChatThread(id);
    await load();
  }
}

final chatThreadsProvider = StateNotifierProvider<ChatThreadsNotifier,
    AsyncValue<List<ChatThreadModel>>>(
  (ref) => ChatThreadsNotifier(ref.watch(repositoryProvider)),
);
