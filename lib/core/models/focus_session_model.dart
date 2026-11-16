enum FocusSessionStatus { running, paused, onBreak, completed, cancelled }

enum FocusMode { deepWork, study, quickSprint, custom }

class FocusSessionModel {
  final String id;
  final String? taskId;
  final FocusMode mode;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? lastPausedAt;
  final int pausedTotalSec;
  final int actualFocusSec;
  final FocusSessionStatus status;
  final int interruptionCount;

  const FocusSessionModel({
    required this.id,
    this.taskId,
    required this.mode,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.lastPausedAt,
    required this.pausedTotalSec,
    required this.actualFocusSec,
    required this.status,
    required this.interruptionCount,
  });

  /// يحسب الثواني الفعلية للتركيز بالاعتماد على ساعة النظام الحقيقية
  /// لضمان عدم فقدان الدقة عند إغلاق الواجهة أو إعادة التشغيل.
  int computeLiveFocusSeconds(DateTime now) {
    if (status == FocusSessionStatus.completed ||
        status == FocusSessionStatus.cancelled) {
      return actualFocusSec;
    }
    final referenceEnd =
        (status == FocusSessionStatus.paused || status == FocusSessionStatus.onBreak) &&
                lastPausedAt != null
            ? lastPausedAt!
            : now;
    final totalElapsed = referenceEnd.difference(startedAt).inSeconds;
    final net = totalElapsed - pausedTotalSec;
    return net < 0 ? 0 : net;
  }

  int computeRemainingSeconds(DateTime now) {
    final targetSec = plannedMinutes * 60;
    final remaining = targetSec - computeLiveFocusSeconds(now);
    return remaining < 0 ? 0 : remaining;
  }

  factory FocusSessionModel.fromMap(Map<String, Object?> map) {
    return FocusSessionModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      mode: FocusMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => FocusMode.deepWork,
      ),
      plannedMinutes: map['planned_minutes'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.tryParse(map['ended_at'] as String)
          : null,
      lastPausedAt: map['last_paused_at'] != null
          ? DateTime.tryParse(map['last_paused_at'] as String)
          : null,
      pausedTotalSec: (map['paused_total_sec'] as int?) ?? 0,
      actualFocusSec: (map['actual_focus_sec'] as int?) ?? 0,
      status: FocusSessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FocusSessionStatus.running,
      ),
      interruptionCount: (map['interruption_count'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'mode': mode.name,
        'planned_minutes': plannedMinutes,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'last_paused_at': lastPausedAt?.toIso8601String(),
        'paused_total_sec': pausedTotalSec,
        'actual_focus_sec': actualFocusSec,
        'status': status.name,
        'interruption_count': interruptionCount,
      };
}
