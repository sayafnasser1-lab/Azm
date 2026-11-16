import '../../models/activity_model.dart';
import '../../models/focus_session_model.dart';
import '../../models/goal_model.dart';
import '../../models/habit_model.dart';
import '../../models/settings_model.dart';
import '../../models/task_model.dart';
import 'cloud_ai_client.dart';
import 'local_analyzer.dart';

class AiOrchestrator {
  final LocalBehavioralAnalyzer _local = const LocalBehavioralAnalyzer();
  final CloudAiClient _cloud = const CloudAiClient();

  Future<String> generateReply({
    required String userPrompt,
    required AppSettingsModel settings,
    required List<GoalModel> goals,
    required List<TaskItemModel> tasks,
    required List<HabitModel> habits,
    required List<FocusSessionModel> sessions,
    required List<ActivityEventModel> activities,
    String? runtimeGeminiApiKey,
  }) async {
    final arabic = settings.languageCode == 'ar';

    if (settings.aiProviderMode == 'ollama') {
      final contextPrompt = _buildContextPrompt(
        userPrompt: userPrompt,
        goals: goals,
        tasks: tasks,
        sessions: sessions,
        arabic: arabic,
      );
      final res = await _cloud.askOllama(
        endpoint: settings.ollamaEndpoint,
        model: settings.ollamaModel,
        prompt: contextPrompt,
      );
      if (res != null && res.isNotEmpty) return res;
    } else if (settings.aiProviderMode == 'gemini_cloud' &&
        settings.cloudAiConsent &&
        runtimeGeminiApiKey != null &&
        runtimeGeminiApiKey.trim().isNotEmpty) {
      final contextPrompt = _buildContextPrompt(
        userPrompt: userPrompt,
        goals: goals,
        tasks: tasks,
        sessions: sessions,
        arabic: arabic,
      );
      final res = await _cloud.askGemini(
        apiKey: runtimeGeminiApiKey,
        prompt: contextPrompt,
      );
      if (res != null && res.isNotEmpty) return res;
    }

    return _local.analyze(
      prompt: userPrompt,
      goals: goals,
      tasks: tasks,
      habits: habits,
      sessions: sessions,
      activities: activities,
      arabic: arabic,
    );
  }

  List<String> suggestSubtasks(String goalTitle, {bool arabic = true}) =>
      _local.suggestSubtasksForGoal(goalTitle, arabic: arabic);

  String _buildContextPrompt({
    required String userPrompt,
    required List<GoalModel> goals,
    required List<TaskItemModel> tasks,
    required List<FocusSessionModel> sessions,
    required bool arabic,
  }) {
    final activeGoals = goals
        .where((g) => g.status == GoalStatus.active)
        .map((g) => '${g.title} (${g.progress}%)')
        .take(5)
        .join(', ');
    final pending = tasks.where((t) => !t.isCompleted).length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final focusMin = sessions
        .where((s) => s.status == FocusStatus.completed)
        .fold<int>(0, (s, e) => s + (e.actualFocusSeconds ~/ 60));

    return 'You are AZM AI (عزم), a focused productivity assistant. '
        'Reply concisely in ${arabic ? 'Arabic' : 'English'}.\n'
        'User context: Active goals=[$activeGoals], Tasks completed=$completed, '
        'Pending=$pending, Total focus=${focusMin}m.\n'
        'User question: $userPrompt';
  }
}
