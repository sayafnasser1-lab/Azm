import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/activity_model.dart';
import '../../models/focus_session_model.dart';
import '../../models/goal_model.dart';
import '../../models/settings_model.dart';
import '../../repositories/azm_repository.dart';

class AiContextSnapshot {
  final List<GoalModel> goals;
  final List<TaskModel> tasks;
  final List<FocusSessionModel> sessions;
  final List<ActivityRecordModel> activities;

  const AiContextSnapshot({
    required this.goals,
    required this.tasks,
    required this.sessions,
    required this.activities,
  });

  String toGroundedSummary({required bool isArabic}) {
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdueTasks = tasks.where((t) => t.isOverdue).length;
    final totalFocusMin = sessions.fold<int>(0, (s, e) => s + (e.actualFocusSec ~/ 60));
    final totalInterruptions = sessions.fold<int>(0, (s, e) => s + e.interruptionCount);

    final Map<String, int> appSeconds = {};
    int distractionSec = 0;
    for (final act in activities) {
      if (act.isIdle) continue;
      appSeconds[act.displayName] = (appSeconds[act.displayName] ?? 0) + act.durationSec;
      if (act.category == AppCategory.distracting) {
        distractionSec += act.durationSec;
      }
    }
    final topApps = appSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAppSummary = topApps
        .take(3)
        .map((e) => '${e.key} (${(e.value / 60).toStringAsFixed(1)}m)')
        .join(', ');

    if (isArabic) {
      return 'البيانات الفعلية المسجلة: الأهداف=${goals.length}، المهام=${tasks.length} (المكتمل=$completedTasks، المتأخر=$overdueTasks)، '
          'إجمالي دقائق التركيز=$totalFocusMin، الانقطاعات=$totalInterruptions، '
          'دقائق التشتت=${(distractionSec / 60).toStringAsFixed(1)}، '
          'أكثر التطبيقات استخدامًا: ${topAppSummary.isEmpty ? "لا توجد سجلات بعد" : topAppSummary}.';
    }
    return 'Recorded local data: Goals=${goals.length}, Tasks=${tasks.length} (Completed=$completedTasks, Overdue=$overdueTasks), '
        'FocusMinutes=$totalFocusMin, Interruptions=$totalInterruptions, '
        'DistractionMinutes=${(distractionSec / 60).toStringAsFixed(1)}, '
        'TopApps: ${topAppSummary.isEmpty ? "No records yet" : topAppSummary}.';
  }
}

abstract class AiProvider {
  String get providerLabel;
  bool get requiresInternet;
  Future<String> ask({
    required String prompt,
    required AiContextSnapshot context,
    required bool isArabic,
  });
}

/// محلل سلوكي محلي يعمل 100% دون إنترنت استنادًا إلى بيانات SQLite الحقيقية فقط
class LocalBehavioralAnalyzer implements AiProvider {
  @override
  String get providerLabel => 'AZM Local Analyzer (Offline)';

  @override
  bool get requiresInternet => false;

  @override
  Future<String> ask({
    required String prompt,
    required AiContextSnapshot context,
    required bool isArabic,
  }) async {
    final completed = context.tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = context.tasks.where((t) => t.status != TaskStatus.completed).toList();
    final overdue = pending.where((t) => t.isOverdue).toList();
    final totalFocusMin =
        context.sessions.fold<int>(0, (s, e) => s + (e.actualFocusSec ~/ 60));
    final interruptions =
        context.sessions.fold<int>(0, (s, e) => s + e.interruptionCount);

    final Map<String, int> appSeconds = {};
    final Map<int, int> focusByHour = {};
    int distractionSec = 0;

    for (final act in context.activities) {
      if (act.isIdle) continue;
      appSeconds[act.displayName] = (appSeconds[act.displayName] ?? 0) + act.durationSec;
      if (act.category == AppCategory.distracting) {
        distractionSec += act.durationSec;
      }
    }

    for (final s in context.sessions) {
      final h = s.startedAt.hour;
      focusByHour[h] = (focusByHour[h] ?? 0) + s.actualFocusSec;
    }

    final sortedApps = appSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedHours = focusByHour.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (context.tasks.isEmpty && context.sessions.isEmpty && context.activities.isEmpty) {
      return isArabic
          ? 'لا توجد بيانات مسجلة بعد في قاعدة البيانات المحلية. ابدأ بإضافة هدف ومهمة أو تشغيل جلسة تركيز وسأحلل أداءك الفعلي بدقة.'
          : 'No local records found yet. Add a goal/task or start a focus session so I can analyze your real performance.';
    }

    final buffer = StringBuffer();
    if (isArabic) {
      buffer.writeln('تحليل محلي (دون إنترنت) مستند إلى بياناتك الفعلية:');
      buffer.writeln('• المهام: $completed مكتملة من أصل ${context.tasks.length} (متأخر: ${overdue.length}).');
      buffer.writeln('• التركيز: $totalFocusMin دقيقة مسجلة، مع $interruptions انقطاعًا.');
      if (sortedApps.isNotEmpty) {
        final top = sortedApps.first;
        buffer.writeln('• أكثر تطبيق استهلاكًا للوقت: ${top.key} (${(top.value / 60).toStringAsFixed(1)} دقيقة).');
      }
      if (distractionSec > 0) {
        buffer.writeln('• وقت التشتت المرصود: ${(distractionSec / 60).toStringAsFixed(1)} دقيقة.');
      }
      if (sortedHours.isNotEmpty) {
        buffer.writeln('• أفضل ساعة تركيز مسجلة لديك: الساعة ${sortedHours.first.key}:00.');
      }
      if (pending.isNotEmpty) {
        pending.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        buffer.writeln('• التوصية العملية الآن: ابدأ بمهمة "${pending.first.title}" (المدة المقدرة: ${pending.first.estimatedMinutes} دقيقة).');
      }
    } else {
      buffer.writeln('Offline Local Analysis based strictly on your recorded data:');
      buffer.writeln('• Tasks: $completed/${context.tasks.length} completed (${overdue.length} overdue).');
      buffer.writeln('• Focus: $totalFocusMin minutes recorded, $interruptions interruptions.');
      if (sortedApps.isNotEmpty) {
        final top = sortedApps.first;
        buffer.writeln('• Top app: ${top.key} (${(top.value / 60).toStringAsFixed(1)} min).');
      }
      if (sortedHours.isNotEmpty) {
        buffer.writeln('• Peak focus hour: ${sortedHours.first.key}:00.');
      }
      if (pending.isNotEmpty) {
        pending.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        buffer.writeln('• Recommended next task: "${pending.first.title}" (${pending.first.estimatedMinutes} min).');
      }
    }
    return buffer.toString().trim();
  }
}

/// مزود نموذج محلي عبر Ollama (يعمل محليًا على الجهاز)
class OllamaAiProvider implements AiProvider {
  final String endpoint;
  final String model;

  OllamaAiProvider({required this.endpoint, required this.model});

  @override
  String get providerLabel => 'Ollama ($model)';

  @override
  bool get requiresInternet => false;

  @override
  Future<String> ask({
    required String prompt,
    required AiContextSnapshot context,
    required bool isArabic,
  }) async {
    final uri = Uri.parse('$endpoint/api/generate');
    final grounded = context.toGroundedSummary(isArabic: isArabic);
    final fullPrompt = isArabic
        ? 'أنت مساعد عزم للتركيز. أجب باختصار ودقة اعتمادًا فقط على البيانات التالية دون اختلاق أرقام:\n$grounded\n\nسؤال المستخدم: $prompt'
        : 'You are AZM focus assistant. Answer concisely based ONLY on these real metrics without inventing numbers:\n$grounded\n\nUser question: $prompt';

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'model': model, 'prompt': fullPrompt, 'stream': false}),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Ollama HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['response'] as String?)?.trim() ?? '';
  }
}

/// مزود سحابي عبر Gemini API (يعمل فقط عند موافقة المستخدم الصريحة)
class GeminiCloudProvider implements AiProvider {
  final String apiKey;

  GeminiCloudProvider({required this.apiKey});

  @override
  String get providerLabel => 'Gemini Cloud AI';

  @override
  bool get requiresInternet => true;

  @override
  Future<String> ask({
    required String prompt,
    required AiContextSnapshot context,
    required bool isArabic,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Missing Gemini API Key');
    }
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );
    final grounded = context.toGroundedSummary(isArabic: isArabic);
    final systemText = isArabic
        ? 'أنت مساعد عزم (AZM AI). أجب اعتمادًا فقط على الملخص الرقمي التالي ولا تخترع أي إحصائيات:\n$grounded'
        : 'You are AZM AI. Answer strictly from this real summary without fabricating metrics:\n$grounded';

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$systemText\n\n$prompt'}
                ]
              }
            ]
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Gemini HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final text = candidates?.firstOrNull?['content']?['parts']?.firstOrNull?['text'] as String?;
    return text?.trim() ?? '';
  }
}

class AiOrchestrator {
  final AzmRepository _repo;
  final LocalBehavioralAnalyzer _offline = LocalBehavioralAnalyzer();

  AiOrchestrator(this._repo);

  Future<({String answer, String providerLabel})> askQuestion(String prompt) async {
    final settings = await _repo.getSettings();
    final isArabic = settings.languageCode == 'ar';

    final goals = await _repo.getGoals();
    final tasks = await _repo.getTasks();
    final sessions = await _repo.getRecentFocusSessions(limit: 50);
    final activities = await _repo.getRecentActivity(limit: 200);

    final snapshot = AiContextSnapshot(
      goals: goals,
      tasks: tasks,
      sessions: sessions,
      activities: activities,
    );

    AiProvider provider = _offline;
    if (settings.aiProvider == AiProviderType.ollamaLocal) {
      provider = OllamaAiProvider(
        endpoint: settings.ollamaEndpoint,
        model: settings.ollamaModel,
      );
    } else if (settings.aiProvider == AiProviderType.geminiCloud &&
        settings.aiCloudConsent &&
        settings.geminiApiKey.isNotEmpty) {
      provider = GeminiCloudProvider(apiKey: settings.geminiApiKey);
    }

    try {
      final answer = await provider.ask(
        prompt: prompt,
        context: snapshot,
        isArabic: isArabic,
      );
      return (answer: answer, providerLabel: provider.providerLabel);
    } catch (e) {
      // في حال تعذر المزود الخارجي أو المحلي، نعود بأمان للمحلل الإحصائي مع توضيح السبب
      final fallback = await _offline.ask(
        prompt: prompt,
        context: snapshot,
        isArabic: isArabic,
      );
      final note = isArabic
          ? 'تعذر الاتصال بمزود (${provider.providerLabel})؛ تم استخدام التحليل المحلي:\n\n'
          : 'Could not reach ${provider.providerLabel}; fell back to offline analyzer:\n\n';
      return (answer: '$note$fallback', providerLabel: _offline.providerLabel);
    }
  }
}
