import 'package:azm_ai/core/models/focus_session_model.dart';
import 'package:azm_ai/core/models/goal_model.dart';
import 'package:azm_ai/core/services/ai/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusSessionModel Wall-Clock Accuracy', () {
    test('calculates live focus seconds accurately excluding paused time', () {
      final start = DateTime(2026, 11, 16, 10, 0, 0);
      final now = DateTime(2026, 11, 16, 10, 15, 0); // 900s elapsed

      final session = FocusSessionModel(
        id: 'focus_1',
        mode: FocusMode.deepWork,
        plannedMinutes: 25,
        startedAt: start,
        pausedTotalSec: 120, // 2 minutes paused
        actualFocusSec: 0,
        status: FocusSessionStatus.running,
        interruptionCount: 0,
      );

      expect(session.computeLiveFocusSeconds(now), 780); // 13 minutes
      expect(session.computeRemainingSeconds(now), 720); // 12 minutes left
    });
  });

  group('LocalBehavioralAnalyzer Groundedness', () {
    test('returns honest empty-state guidance when no records exist', () async {
      final analyzer = LocalBehavioralAnalyzer();
      const emptyContext = AiContextSnapshot(
        goals: [],
        tasks: [],
        sessions: [],
        activities: [],
      );

      final result = await analyzer.ask(
        prompt: 'لماذا لم أحقق هدفي اليوم؟',
        context: emptyContext,
        isArabic: true,
      );

      expect(result.contains('لا توجد بيانات مسجلة بعد'), isTrue);
    });

    test('computes real task and focus metrics without fabrication', () async {
      final analyzer = LocalBehavioralAnalyzer();
      final now = DateTime.now();
      final context = AiContextSnapshot(
        goals: [
          GoalModel(
            id: 'g1',
            title: 'إتقان Flutter',
            whyReason: 'بناء تطبيق عزم',
            status: GoalStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tasks: [
          TaskModel(
            id: 't1',
            goalId: 'g1',
            title: 'تصميم قاعدة البيانات',
            priority: TaskPriority.high,
            estimatedMinutes: 30,
            status: TaskStatus.completed,
            createdAt: now,
          ),
          TaskModel(
            id: 't2',
            goalId: 'g1',
            title: 'اختبار المؤقت',
            priority: TaskPriority.urgent,
            estimatedMinutes: 20,
            status: TaskStatus.todo,
            createdAt: now,
          ),
        ],
        sessions: [],
        activities: [],
      );

      final result = await analyzer.ask(
        prompt: 'ما الذي يجب أن أبدأ به الآن؟',
        context: context,
        isArabic: true,
      );

      expect(result.contains('1 مكتملة من أصل 2'), isTrue);
      expect(result.contains('اختبار المؤقت'), isTrue);
    });
  });
}
