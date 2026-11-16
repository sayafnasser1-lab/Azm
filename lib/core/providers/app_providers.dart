import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../models/focus_session_model.dart';
import '../models/goal_model.dart';
import '../models/settings_model.dart';
import '../repositories/azm_repository.dart';
import '../services/activity_monitor_service.dart';
import '../services/ai/ai_provider.dart';

final repositoryProvider = Provider<AzmRepository>((ref) => AzmRepository());

final activityMonitorServiceProvider = Provider<ActivityMonitorService>((ref) {
  final service = ActivityMonitorService(ref.watch(repositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

final aiOrchestratorProvider = Provider<AiOrchestrator>((ref) {
  return AiOrchestrator(ref.watch(repositoryProvider));
});

// ===================== SETTINGS =====================

class SettingsNotifier extends AsyncNotifier<UserSettingsModel> {
  @override
  Future<UserSettingsModel> build() async {
    final settings = await ref.read(repositoryProvider).getSettings();
    final monitor = ref.read(activityMonitorServiceProvider);
    if (settings.monitoringEnabled) {
      unawaited(monitor.start(settings: settings));
    }
    return settings;
  }

  Future<void> updateSettings(UserSettingsModel next) async {
    await ref.read(repositoryProvider).saveSettings(next);
    state = AsyncData(next);
    final monitor = ref.read(activityMonitorServiceProvider);
    if (next.monitoringEnabled) {
      await monitor.start(settings: next);
    } else {
      await monitor.stop();
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, UserSettingsModel>(
  SettingsNotifier.new,
);

// ===================== GOALS & TASKS =====================

class GoalsNotifier extends AsyncNotifier<List<GoalModel>> {
  @override
  Future<List<GoalModel>> build() => ref.read(repositoryProvider).getGoals();

  Future<void> addGoal({
    required String title,
    String whyReason = '',
    String? parentGoalId,
    DateTime? targetDate,
  }) async {
    await ref.read(repositoryProvider).createGoal(
          title: title,
          whyReason: whyReason,
          parentGoalId: parentGoalId,
          targetDate: targetDate,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteGoal(String id) async {
    await ref.read(repositoryProvider).deleteGoal(id);
    ref.invalidateSelf();
    ref.invalidate(tasksProvider);
  }
}

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<GoalModel>>(
  GoalsNotifier.new,
);

class TasksNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() => ref.read(repositoryProvider).getTasks();

  Future<void> addTask({
    required String goalId,
    required String title,
    TaskPriority priority = TaskPriority.medium,
    int estimatedMinutes = 25,
    DateTime? dueAt,
  }) async {
    await ref.read(repositoryProvider).createTask(
          goalId: goalId,
          title: title,
          priority: priority,
          estimatedMinutes: estimatedMinutes,
          dueAt: dueAt,
        );
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(TaskModel task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.todo
        : TaskStatus.completed;
    await ref.read(repositoryProvider).updateTaskStatus(task.id, nextStatus);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String id) async {
    await ref.read(repositoryProvider).deleteTask(id);
    ref.invalidateSelf();
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<TaskModel>>(
  TasksNotifier.new,
);

// ===================== FOCUS CONTROLLER =====================

class FocusController extends AsyncNotifier<FocusSessionModel?> {
  Timer? _ticker;
  final _tickController = StreamController<DateTime>.broadcast();

  Stream<DateTime> get tickStream => _tickController.stream;

  @override
  Future<FocusSessionModel?> build() async {
    ref.onDispose(() {
      _ticker?.cancel();
      _tickController.close();
    });
    final active = await ref.read(repositoryProvider).getActiveFocusSession();
    if (active != null && active.status == FocusSessionStatus.running) {
      _startTicker();
    }
    return active;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickController.add(DateTime.now());
    });
  }

  Future<void> startSession({
    String? taskId,
    FocusMode mode = FocusMode.deepWork,
    required int plannedMinutes,
  }) async {
    final session = await ref.read(repositoryProvider).startFocusSession(
          taskId: taskId,
          mode: mode,
          plannedMinutes: plannedMinutes,
        );
    state = AsyncData(session);
    _startTicker();
  }

  Future<void> pauseSession() async {
    final current = state.valueOrNull;
    if (current == null || current.status != FocusSessionStatus.running) return;
    final updated = FocusSessionModel(
      id: current.id,
      taskId: current.taskId,
      mode: current.mode,
      plannedMinutes: current.plannedMinutes,
      startedAt: current.startedAt,
      lastPausedAt: DateTime.now(),
      pausedTotalSec: current.pausedTotalSec,
      actualFocusSec: current.actualFocusSec,
      status: FocusSessionStatus.paused,
      interruptionCount: current.interruptionCount,
    );
    await ref.read(repositoryProvider).updateFocusSession(updated);
    state = AsyncData(updated);
    _ticker?.cancel();
  }

  Future<void> resumeSession() async {
    final current = state.valueOrNull;
    if (current == null || current.status != FocusSessionStatus.paused) return;
    final pausedDuration = current.lastPausedAt != null
        ? DateTime.now().difference(current.lastPausedAt!).inSeconds
        : 0;
    final updated = FocusSessionModel(
      id: current.id,
      taskId: current.taskId,
      mode: current.mode,
      plannedMinutes: current.plannedMinutes,
      startedAt: current.startedAt,
      lastPausedAt: null,
      pausedTotalSec: current.pausedTotalSec + pausedDuration,
      actualFocusSec: current.actualFocusSec,
      status: FocusSessionStatus.running,
      interruptionCount: current.interruptionCount,
    );
    await ref.read(repositoryProvider).updateFocusSession(updated);
    state = AsyncData(updated);
    _startTicker();
  }

  Future<FocusSessionModel?> finishSession({bool cancelled = false}) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    final now = DateTime.now();
    final actualSec = current.computeLiveFocusSeconds(now);
    final updated = FocusSessionModel(
      id: current.id,
      taskId: current.taskId,
      mode: current.mode,
      plannedMinutes: current.plannedMinutes,
      startedAt: current.startedAt,
      endedAt: now,
      pausedTotalSec: current.pausedTotalSec,
      actualFocusSec: actualSec,
      status: cancelled ? FocusSessionStatus.cancelled : FocusSessionStatus.completed,
      interruptionCount: current.interruptionCount,
    );
    await ref.read(repositoryProvider).updateFocusSession(updated);
    _ticker?.cancel();
    state = const AsyncData(null);
    ref.invalidate(recentFocusSessionsProvider);
    return updated;
  }
}

final focusControllerProvider =
    AsyncNotifierProvider<FocusController, FocusSessionModel?>(FocusController.new);

final recentFocusSessionsProvider = FutureProvider<List<FocusSessionModel>>((ref) {
  return ref.read(repositoryProvider).getRecentFocusSessions();
});

// ===================== ACTIVITY & RULES =====================

final applicationsProvider = FutureProvider<List<TrackedApplication>>((ref) {
  return ref.read(repositoryProvider).getApplications();
});

final recentActivityProvider = FutureProvider<List<ActivityRecordModel>>((ref) {
  return ref.read(repositoryProvider).getRecentActivity();
});

final distractionRulesProvider = FutureProvider<List<DistractionRuleModel>>((ref) {
  return ref.read(repositoryProvider).getDistractionRules();
});

final websiteRulesProvider = FutureProvider<List<WebsiteRuleModel>>((ref) {
  return ref.read(repositoryProvider).getWebsiteRules();
});

final aiMessagesProvider = FutureProvider<List<AiMessageModel>>((ref) {
  return ref.read(repositoryProvider).getAiMessages();
});
