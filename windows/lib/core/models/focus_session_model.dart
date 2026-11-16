enum FocusStatus { running, paused, completed, cancelled }

class FocusSessionModel {
  final String id;
  final String? taskId;
  final String mode; // pomodoro, deep_work, custom
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int pausedSeconds;
  final DateTime? pauseStartedAt;
  final int actualFocusSeconds;
  final FocusStatus status;
  final String notes;

  const FocusSessionModel({
    required this.id,
    this.taskId,
    required this.mode,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.pausedSeconds = 0,
    this.pauseStartedAt,
    this.actualFocusSeconds = 0,
    this.status = FocusStatus.running,
    this.notes = '',
  });

  /// حساب وقت التركيز الفعلي بالاعتماد على ساعة النظام (Wall-Clock)
  int computeLiveFocusSeconds([DateTime? now]) {
    if (status == FocusStatus.completed || status == FocusStatus.cancelled) {
      return actualFocusSeconds;
    }
    final current = (now ?? DateTime.now()).toUtc();
    final startUtc = startedAt.toUtc();
    final totalElapsed = current.difference(startUtc).inSeconds;
    int currentPause = pausedSeconds;
    if (status == FocusStatus.paused && pauseStartedAt != null) {
      currentPause += current.difference(pauseStartedAt!.toUtc()).inSeconds;
    }
    final active = totalElapsed - currentPause;
    return active < 0 ? 0 : active;
  }

  int computeRemainingSeconds([DateTime? now]) {
    final target = plannedMinutes * 60;
    final rem = target - computeLiveFocusSeconds(now);
    return rem < 0 ? 0 : rem;
  }

  FocusSessionModel copyWith({
    DateTime? endedAt,
    int? pausedSeconds,
    DateTime? pauseStartedAt,
    bool clearPauseStartedAt = false,
    int? actualFocusSeconds,
    FocusStatus? status,
    String? notes,
  }) {
    return FocusSessionModel(
      id: id,
      taskId: taskId,
      mode: mode,
      plannedMinutes: plannedMinutes,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      pauseStartedAt:
          clearPauseStartedAt ? null : (pauseStartedAt ?? this.pauseStartedAt),
      actualFocusSeconds: actualFocusSeconds ?? this.actualFocusSeconds,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'task_id': taskId,
        'mode': mode,
        'planned_minutes': plannedMinutes,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'paused_seconds': pausedSeconds,
        'pause_started_at': pauseStartedAt?.toUtc().toIso8601String(),
        'actual_focus_seconds': actualFocusSeconds,
        'status': status.name,
        'notes': notes,
      };

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    final sName = (map['status'] ?? 'completed').toString();
    final s = FocusStatus.values.firstWhere(
      (e) => e.name == sName,
      orElse: () => FocusStatus.completed,
    );
    return FocusSessionModel(
      id: (map['id'] ?? '').toString(),
      taskId: map['task_id']?.toString(),
      mode: (map['mode'] ?? 'pomodoro').toString(),
      plannedMinutes: (map['planned_minutes'] as num?)?.toInt() ?? 25,
      startedAt: DateTime.tryParse((map['started_at'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      endedAt: map['ended_at'] != null
          ? DateTime.tryParse(map['ended_at'].toString())
          : null,
      pausedSeconds: (map['paused_seconds'] as num?)?.toInt() ?? 0,
      pauseStartedAt: map['pause_started_at'] != null
          ? DateTime.tryParse(map['pause_started_at'].toString())
          : null,
      actualFocusSeconds:
          (map['actual_focus_seconds'] as num?)?.toInt() ?? 0,
      status: s,
      notes: (map['notes'] ?? '').toString(),
    );
  }
}
