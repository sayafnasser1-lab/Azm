import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_service.dart';
import '../models/activity_model.dart';
import '../models/focus_session_model.dart';
import '../models/goal_model.dart';
import '../models/settings_model.dart';

class AzmRepository {
  final DatabaseService _dbService;

  AzmRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  Future<Database> get _db => _dbService.database;

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  // ===================== SETTINGS =====================

  Future<UserSettingsModel> getSettings() async {
    final db = await _db;
    final rows = await db.query('user_settings', where: 'id = ?', whereArgs: ['default_settings']);
    if (rows.isEmpty) return const UserSettingsModel();
    final row = rows.first;
    return UserSettingsModel(
      languageCode: row['language_code'] as String? ?? 'ar',
      isDarkMode: (row['is_dark_mode'] as int? ?? 1) == 1,
      monitoringEnabled: (row['monitoring_enabled'] as int? ?? 1) == 1,
      storeWindowTitles: (row['store_window_titles'] as int? ?? 0) == 1,
      idleThresholdSec: row['idle_threshold_sec'] as int? ?? 180,
      retentionDays: row['retention_days'] as int? ?? 90,
      aiProvider: AiProviderType.values.firstWhere(
        (e) => e.name == row['ai_provider'],
        orElse: () => AiProviderType.offlineAnalyzer,
      ),
      aiCloudConsent: (row['ai_cloud_consent'] as int? ?? 0) == 1,
      ollamaEndpoint: row['ollama_endpoint'] as String? ?? 'http://localhost:11434',
      ollamaModel: row['ollama_model'] as String? ?? 'llama3.1',
      geminiApiKey: row['gemini_api_key'] as String? ?? '',
    );
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    final db = await _db;
    await db.update(
      'user_settings',
      {
        'language_code': settings.languageCode,
        'is_dark_mode': settings.isDarkMode ? 1 : 0,
        'monitoring_enabled': settings.monitoringEnabled ? 1 : 0,
        'store_window_titles': settings.storeWindowTitles ? 1 : 0,
        'idle_threshold_sec': settings.idleThresholdSec,
        'retention_days': settings.retentionDays,
        'ai_provider': settings.aiProvider.name,
        'ai_cloud_consent': settings.aiCloudConsent ? 1 : 0,
        'ollama_endpoint': settings.ollamaEndpoint,
        'ollama_model': settings.ollamaModel,
        'gemini_api_key': settings.geminiApiKey,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: ['default_settings'],
    );
  }

  // ===================== GOALS & TASKS =====================

  Future<List<GoalModel>> getGoals() async {
    final db = await _db;
    final rows = await db.query('goals', orderBy: 'created_at DESC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<GoalModel> createGoal({
    required String title,
    String whyReason = '',
    String? parentGoalId,
    DateTime? targetDate,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final goal = GoalModel(
      id: _newId('goal'),
      parentGoalId: parentGoalId,
      title: title,
      whyReason: whyReason,
      status: GoalStatus.active,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
    final map = goal.toMap()..['user_id'] = 'local_user';
    await db.insert('goals', map);
    return goal;
  }

  Future<void> deleteGoal(String goalId) async {
    final db = await _db;
    await db.delete('goals', where: 'id = ?', whereArgs: [goalId]);
  }

  Future<List<TaskModel>> getTasks({String? goalId}) async {
    final db = await _db;
    final rows = goalId != null
        ? await db.query('tasks', where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'created_at DESC')
        : await db.query('tasks', orderBy: 'created_at DESC');
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel> createTask({
    required String goalId,
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    int estimatedMinutes = 25,
    DateTime? dueAt,
  }) async {
    final db = await _db;
    final task = TaskModel(
      id: _newId('task'),
      goalId: goalId,
      title: title,
      description: description,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      dueAt: dueAt,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
    );
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final db = await _db;
    await db.update(
      'tasks',
      {
        'status': status.name,
        'completed_at': status == TaskStatus.completed ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // ===================== FOCUS SESSIONS =====================

  Future<FocusSessionModel?> getActiveFocusSession() async {
    final db = await _db;
    final rows = await db.query(
      'focus_sessions',
      where: "status IN ('running', 'paused', 'onBreak')",
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FocusSessionModel.fromMap(rows.first);
  }

  Future<FocusSessionModel> startFocusSession({
    String? taskId,
    FocusMode mode = FocusMode.deepWork,
    required int plannedMinutes,
  }) async {
    final db = await _db;
    final session = FocusSessionModel(
      id: _newId('focus'),
      taskId: taskId,
      mode: mode,
      plannedMinutes: plannedMinutes,
      startedAt: DateTime.now(),
      pausedTotalSec: 0,
      actualFocusSec: 0,
      status: FocusSessionStatus.running,
      interruptionCount: 0,
    );
    await db.insert('focus_sessions', session.toMap());
    return session;
  }

  Future<FocusSessionModel> updateFocusSession(FocusSessionModel session) async {
    final db = await _db;
    await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
    return session;
  }

  Future<List<FocusSessionModel>> getRecentFocusSessions({int limit = 20}) async {
    final db = await _db;
    final rows = await db.query(
      'focus_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(FocusSessionModel.fromMap).toList();
  }

  // ===================== APPLICATIONS & ACTIVITY =====================

  Future<TrackedApplication> upsertApplication({
    required String processName,
    String? exePath,
    String? displayName,
  }) async {
    final db = await _db;
    final existing = await db.query(
      'applications',
      where: 'process_name = ?',
      whereArgs: [processName],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return TrackedApplication.fromMap(existing.first);
    }

    final app = TrackedApplication(
      id: _newId('app'),
      processName: processName,
      exePath: exePath,
      displayName: displayName ?? processName.replaceAll('.exe', ''),
      category: AppCategory.neutral,
      isUserVerified: false,
    );
    await db.insert('applications', app.toMap());
    return app;
  }

  Future<List<TrackedApplication>> getApplications() async {
    final db = await _db;
    final rows = await db.query('applications', orderBy: 'display_name ASC');
    return rows.map(TrackedApplication.fromMap).toList();
  }

  Future<void> updateApplicationCategory(String appId, AppCategory category) async {
    final db = await _db;
    await db.update(
      'applications',
      {'category_slug': category.name, 'is_user_verified': 1},
      where: 'id = ?',
      whereArgs: [appId],
    );
  }

  Future<void> insertActivityRecord({
    required String applicationId,
    String? windowTitleMasked,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSec,
    required bool isIdle,
    String? focusSessionId,
  }) async {
    if (durationSec <= 0) return;
    final db = await _db;
    await db.insert('activity_records', {
      'id': _newId('act'),
      'application_id': applicationId,
      'window_title_masked': windowTitleMasked,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_sec': durationSec,
      'is_idle': isIdle ? 1 : 0,
      'focus_session_id': focusSessionId,
    });
  }

  Future<List<ActivityRecordModel>> getRecentActivity({int limit = 100}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT ar.*, a.process_name, a.display_name, a.category_slug
      FROM activity_records ar
      JOIN applications a ON a.id = ar.application_id
      ORDER BY ar.started_at DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((row) {
      return ActivityRecordModel(
        id: row['id'] as String,
        applicationId: row['application_id'] as String,
        processName: row['process_name'] as String,
        displayName: row['display_name'] as String,
        category: AppCategory.values.firstWhere(
          (e) => e.name == row['category_slug'],
          orElse: () => AppCategory.neutral,
        ),
        windowTitleMasked: row['window_title_masked'] as String?,
        startedAt: DateTime.parse(row['started_at'] as String),
        endedAt: DateTime.parse(row['ended_at'] as String),
        durationSec: row['duration_sec'] as int,
        isIdle: (row['is_idle'] as int? ?? 0) == 1,
        focusSessionId: row['focus_session_id'] as String?,
      );
    }).toList();
  }

  Future<void> clearActivityHistory() async {
    final db = await _db;
    await db.delete('activity_records');
  }

  // ===================== RULES =====================

  Future<List<DistractionRuleModel>> getDistractionRules() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT dr.*, a.process_name, a.display_name
      FROM distraction_rules dr
      JOIN applications a ON a.id = dr.application_id
    ''');
    return rows.map((row) {
      return DistractionRuleModel(
        id: row['id'] as String,
        applicationId: row['application_id'] as String,
        processName: row['process_name'] as String,
        displayName: row['display_name'] as String,
        ruleType: RuleType.values.firstWhere(
          (e) => e.name == row['rule_type'],
          orElse: () => RuleType.limit,
        ),
        actionLevel: ControlLevel.values.firstWhere(
          (e) => e.name == row['action_level'],
          orElse: () => ControlLevel.level1Alert,
        ),
        sessionMode: row['session_mode'] as String?,
        dailyLimitMin: row['daily_limit_min'] as int?,
        isEnabled: (row['is_enabled'] as int? ?? 1) == 1,
      );
    }).toList();
  }

  Future<void> saveDistractionRule({
    required String applicationId,
    required RuleType ruleType,
    required ControlLevel actionLevel,
    String? sessionMode,
    int? dailyLimitMin,
  }) async {
    final db = await _db;
    await db.insert('distraction_rules', {
      'id': _newId('rule'),
      'application_id': applicationId,
      'rule_type': ruleType.name,
      'action_level': actionLevel.name,
      'session_mode': sessionMode,
      'daily_limit_min': dailyLimitMin,
      'is_enabled': 1,
    });
  }

  Future<void> toggleDistractionRule(String ruleId, bool enabled) async {
    final db = await _db;
    await db.update(
      'distraction_rules',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  Future<List<WebsiteRuleModel>> getWebsiteRules() async {
    final db = await _db;
    final rows = await db.query('website_rules', orderBy: 'domain_pattern ASC');
    return rows
        .map((r) => WebsiteRuleModel(
              id: r['id'] as String,
              domainPattern: r['domain_pattern'] as String,
              ruleType: RuleType.values.firstWhere(
                (e) => e.name == r['rule_type'],
                orElse: () => RuleType.block,
              ),
              isEnabled: (r['is_enabled'] as int? ?? 1) == 1,
            ))
        .toList();
  }

  Future<void> addWebsiteRule(String domainPattern, RuleType ruleType) async {
    final db = await _db;
    await db.insert(
      'website_rules',
      {
        'id': _newId('web'),
        'domain_pattern': domainPattern.trim().toLowerCase(),
        'rule_type': ruleType.name,
        'is_enabled': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWebsiteRule(String id) async {
    final db = await _db;
    await db.delete('website_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== AI CHAT HISTORY =====================

  Future<void> saveAiMessage({
    required String role,
    required String content,
    required String providerLabel,
  }) async {
    final db = await _db;
    final conv = await db.query('ai_conversations', limit: 1);
    final convId = conv.isNotEmpty ? conv.first['id'] as String : 'default_conv';
    if (conv.isEmpty) {
      await db.insert('ai_conversations', {
        'id': convId,
        'title': 'AZM Assistant',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await db.insert('ai_messages', {
      'id': _newId('msg'),
      'conversation_id': convId,
      'role': role,
      'content': content,
      'provider_label': providerLabel,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AiMessageModel>> getAiMessages() async {
    final db = await _db;
    final rows = await db.query('ai_messages', orderBy: 'created_at ASC', limit: 100);
    return rows
        .map((r) => AiMessageModel(
              id: r['id'] as String,
              role: r['role'] as String,
              content: r['content'] as String,
              providerLabel: r['provider_label'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }
}
