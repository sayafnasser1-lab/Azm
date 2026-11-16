import 'package:flutter_test/flutter_test.dart';
import 'package:azm_ai/core/models/focus_session_model.dart';
import 'package:azm_ai/core/models/goal_model.dart';
import 'package:azm_ai/core/services/ai/local_analyzer.dart';

void main() {
  group('AZM AI Cross-Platform Core Tests', () {
    test('Wall-clock focus timer excludes paused duration accurately', () {
      final start = DateTime.utc(2026, 11, 17, 10, 0, 0);
      final session = FocusSessionModel(
        id: 'fs_1',
        mode: 'pomodoro',
        plannedMinutes: 25,
        startedAt: start,
        pausedSeconds: 120,
        status: FocusStatus.running,
      );
      final now = DateTime.utc(2026, 11, 17, 10, 10, 0); // 600s elapsed
      expect(session.computeLiveFocusSeconds(now), 480);
      expect(session.computeRemainingSeconds(now), 1500 - 480);
    });

    test('GoalModel remainingDays returns accurate difference', () {
      final now = DateTime.now();
      final goal = GoalModel(
        id: 'g_1',
        title: 'إتقان Flutter',
        subtitle: 'بناء تطبيق عزم',
        category: 'coding',
        targetDate: DateTime(now.year, now.month, now.day).add(
          const Duration(days: 12),
        ),
        createdAt: now,
      );
      expect(goal.remainingDays, 12);
    });

    test('LocalBehavioralAnalyzer reports zero fake data when empty', () {
      const analyzer = LocalBehavioralAnalyzer();
      final reply = analyzer.analyze(
        prompt: 'اقترح خطة لهدفي',
        goals: const [],
        tasks: const [],
        habits: const [],
        sessions: const [],
        activities: const [],
        arabic: true,
      );
      expect(reply.contains('لا توجد أهداف نشطة'), isTrue);
    });
  });
}
