import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';
import '../models/focus_session_model.dart';
import '../models/settings_model.dart';
import '../repositories/azm_repository.dart';

class ActiveWindowSnapshot {
  final String processName;
  final int processId;
  final String? exePath;
  final String? windowTitle;
  final bool isIdle;
  final DateTime timestamp;

  const ActiveWindowSnapshot({
    required this.processName,
    required this.processId,
    this.exePath,
    this.windowTitle,
    required this.isIdle,
    required this.timestamp,
  });
}

class DistractionAlertEvent {
  final TrackedApplication app;
  final ControlLevel level;
  final int secondsSpentToday;
  final String message;

  const DistractionAlertEvent({
    required this.app,
    required this.level,
    required this.secondsSpentToday,
    required this.message,
  });
}

class ActivityMonitorService {
  static const MethodChannel _controlChannel = MethodChannel('azm_ai/activity_control');
  static const EventChannel _eventChannel = EventChannel('azm_ai/activity_events');

  final AzmRepository _repo;
  StreamSubscription<dynamic>? _nativeSub;
  Timer? _fallbackIdleTimer;

  ActiveWindowSnapshot? _currentSnapshot;
  bool _isRunning = false;

  final _currentWindowController = StreamController<ActiveWindowSnapshot?>.broadcast();
  final _alertController = StreamController<DistractionAlertEvent>.broadcast();

  Stream<ActiveWindowSnapshot?> get currentWindowStream => _currentWindowController.stream;
  Stream<DistractionAlertEvent> get distractionAlertStream => _alertController.stream;
  bool get isRunning => _isRunning;
  ActiveWindowSnapshot? get currentSnapshot => _currentSnapshot;

  ActivityMonitorService(this._repo);

  Future<void> start({required UserSettingsModel settings}) async {
    if (_isRunning || !settings.monitoringEnabled) return;
    _isRunning = true;

    if (Platform.isWindows) {
      try {
        await _controlChannel.invokeMethod('startMonitoring', {
          'idleThresholdSec': settings.idleThresholdSec,
          'captureWindowTitle': settings.storeWindowTitles,
        });

        _nativeSub = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) async {
            if (event is Map) {
              await _handleNativeEvent(Map<String, dynamic>.from(event), settings);
            }
          },
          onError: (_) {
            // في حال عدم ربط الإضافة الأصلية بعد، لا ينهار التطبيق
          },
        );
      } on MissingPluginException {
        // الإضافة الأصلية غير مفعّلة في بيئة الاختبار الحالية
      }
    }

    // مؤقت احتياطي منخفض التكرار (كل 15 ثانية) لتحديث المدة وفحص الخمول
    _fallbackIdleTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (Platform.isWindows) {
        try {
          final idleSec = await _controlChannel.invokeMethod<int>('getIdleSeconds') ?? 0;
          if (_currentSnapshot != null &&
              idleSec >= settings.idleThresholdSec &&
              !_currentSnapshot!.isIdle) {
            await _commitCurrentSegment(DateTime.now(), settings);
            _currentSnapshot = ActiveWindowSnapshot(
              processName: _currentSnapshot!.processName,
              processId: _currentSnapshot!.processId,
              exePath: _currentSnapshot!.exePath,
              windowTitle: null,
              isIdle: true,
              timestamp: DateTime.now(),
            );
            _currentWindowController.add(_currentSnapshot);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    final settings = await _repo.getSettings();
    await _commitCurrentSegment(DateTime.now(), settings);
    _currentSnapshot = null;
    _currentWindowController.add(null);

    await _nativeSub?.cancel();
    _nativeSub = null;
    _fallbackIdleTimer?.cancel();
    _fallbackIdleTimer = null;

    if (Platform.isWindows) {
      try {
        await _controlChannel.invokeMethod('stopMonitoring');
      } catch (_) {}
    }
  }

  Future<void> _handleNativeEvent(
    Map<String, dynamic> event,
    UserSettingsModel settings,
  ) async {
    final now = DateTime.now();
    await _commitCurrentSegment(now, settings);

    final rawTitle = event['windowTitle'] as String?;
    final sanitizedTitle = settings.storeWindowTitles ? _sanitizeTitle(rawTitle) : null;

    final next = ActiveWindowSnapshot(
      processName: (event['processName'] as String?) ?? 'unknown.exe',
      processId: (event['processId'] as int?) ?? 0,
      exePath: event['exePath'] as String?,
      windowTitle: sanitizedTitle,
      isIdle: (event['isIdle'] as bool?) ?? false,
      timestamp: now,
    );

    _currentSnapshot = next;
    _currentWindowController.add(next);

    if (!next.isIdle) {
      await _evaluateDistractionRules(next);
    }
  }

  Future<void> _commitCurrentSegment(DateTime endTime, UserSettingsModel settings) async {
    final prev = _currentSnapshot;
    if (prev == null) return;
    final durationSec = endTime.difference(prev.timestamp).inSeconds;
    if (durationSec < 1) return;

    final app = await _repo.upsertApplication(
      processName: prev.processName,
      exePath: prev.exePath,
    );
    final activeSession = await _repo.getActiveFocusSession();

    await _repo.insertActivityRecord(
      applicationId: app.id,
      windowTitleMasked: settings.storeWindowTitles ? prev.windowTitle : null,
      startedAt: prev.timestamp,
      endedAt: endTime,
      durationSec: durationSec,
      isIdle: prev.isIdle,
      focusSessionId: activeSession?.id,
    );
  }

  Future<void> _evaluateDistractionRules(ActiveWindowSnapshot snapshot) async {
    final app = await _repo.upsertApplication(
      processName: snapshot.processName,
      exePath: snapshot.exePath,
    );
    final activeSession = await _repo.getActiveFocusSession();
    final rules = await _repo.getDistractionRules();

    final matchingRules = rules.where(
      (r) => r.isEnabled && r.applicationId == app.id,
    );

    final isDistracting = app.category == AppCategory.distracting;
    if (matchingRules.isEmpty && !isDistracting) return;

    final level = matchingRules.isNotEmpty
        ? matchingRules.first.actionLevel
        : ControlLevel.level1Alert;

    if (activeSession != null && activeSession.status == FocusSessionStatus.running) {
      await _repo.updateFocusSession(
        FocusSessionModel(
          id: activeSession.id,
          taskId: activeSession.taskId,
          mode: activeSession.mode,
          plannedMinutes: activeSession.plannedMinutes,
          startedAt: activeSession.startedAt,
          endedAt: activeSession.endedAt,
          lastPausedAt: activeSession.lastPausedAt,
          pausedTotalSec: activeSession.pausedTotalSec,
          actualFocusSec: activeSession.actualFocusSec,
          status: activeSession.status,
          interruptionCount: activeSession.interruptionCount + 1,
        ),
      );
    }

    _alertController.add(
      DistractionAlertEvent(
        app: app,
        level: level,
        secondsSpentToday: 0,
        message: 'تنبيه تركيز: تم رصد الانتقال إلى ${app.displayName}',
      ),
    );
  }

  /// إخفاء أي عناوين قد تحتوي على كلمات حساسة أو نوافذ تصفح خفي
  String? _sanitizeTitle(String? title) {
    if (title == null || title.trim().isEmpty) return null;
    final lower = title.toLowerCase();
    const sensitiveKeywords = ['inprivate', 'incognito', 'password', 'bank', 'otp'];
    for (final word in sensitiveKeywords) {
      if (lower.contains(word)) return '[محجوب للخصوصية]';
    }
    return title.length > 80 ? '${title.substring(0, 80)}...' : title;
  }

  void dispose() {
    _nativeSub?.cancel();
    _fallbackIdleTimer?.cancel();
    _currentWindowController.close();
    _alertController.close();
  }
}
