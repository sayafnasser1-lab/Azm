import 'dart:convert';
import '../database/storage_driver.dart';
import '../models/activity_model.dart';
import '../models/calendar_event_model.dart';
import '../models/chat_model.dart';
import '../models/focus_session_model.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';
import '../models/settings_model.dart';
import '../models/task_model.dart';

class AzmRepository {
  final AzmStorageDriver _storage;

  AzmRepository(this._storage);

  Future<void> init() => _storage.init();

  static String todayIso() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  // ---------------- Settings ----------------
  Future<AppSettingsModel> getSettings() async {
    final rows = await _storage.getAll('app_settings');
    if (rows.isEmpty) return const AppSettingsModel();
    final payload = rows.first['json_payload']?.toString();
    if (payload == null || payload.isEmpty) return const AppSettingsModel();
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return AppSettingsModel.fromJsonMap(decoded);
      }
      if (decoded is Map) {
        return AppSettingsModel.fromJsonMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const AppSettingsModel();
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    await _storage.upsert('app_settings', {
      'id': 'main',
      'json_payload': settings.toJsonString(),
    });
  }

  // ---------------- Goals ----------------
  Future<List<GoalModel>> getGoals() async {
    final rows = await _storage.getAll('goals', orderBy: 'created_at DESC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<void> upsertGoal(GoalModel goal) =>
      _storage.upsert('goals', goal.toMap());

  Future<void> deleteGoal(String id) => _storage.deleteById('goals', id);

  // ---------------- Tasks ----------------
  Future<List<TaskItemModel>> getTasks() async {
    final rows =
        await _storage.getAll('tasks', orderBy: 'scheduled_date ASC');
    return rows.map(TaskItemModel.fromMap).toList();
  }

  Future<void> upsertTask(TaskItemModel task) =>
      _storage.upsert('tasks', task.toMap());

  Future<void> deleteTask(String id) => _storage.deleteById('tasks', id);

  // ---------------- Habits ----------------
  Future<List<HabitModel>> getHabits() async {
    final rows = await _storage.getAll('habits');
    final today = todayIso();
    final list = <HabitModel>[];
    for (final row in rows) {
      var habit = HabitModel.fromMap(row);
      if (habit.lastUpdatedDate != today && habit.completedToday > 0) {
        habit = habit.copyWith(
          completedToday: 0,
          lastUpdatedDate: today,
        );
        await _storage.upsert('habits', habit.toMap());
      }
      list.add(habit);
    }
    return list;
  }

  Future<void> upsertHabit(HabitModel habit) =>
      _storage.upsert('habits', habit.toMap());

  Future<void> deleteHabit(String id) => _storage.deleteById('habits', id);

  // ---------------- Focus Sessions ----------------
  Future<List<FocusSessionModel>> getFocusSessions() async {
    final rows =
        await _storage.getAll('focus_sessions', orderBy: 'started_at DESC');
    return rows.map(FocusSessionModel.fromMap).toList();
  }

  Future<void> upsertFocusSession(FocusSessionModel session) =>
      _storage.upsert('focus_sessions', session.toMap());

  // ---------------- Calendar Events ----------------
  Future<List<CalendarEventModel>> getCalendarEvents() async {
    final rows =
        await _storage.getAll('calendar_events', orderBy: 'event_date ASC');
    return rows.map(CalendarEventModel.fromMap).toList();
  }

  Future<void> upsertCalendarEvent(CalendarEventModel event) =>
      _storage.upsert('calendar_events', event.toMap());

  Future<void> deleteCalendarEvent(String id) =>
      _storage.deleteById('calendar_events', id);

  // ---------------- Activity & Distraction Rules ----------------
  Future<List<ActivityEventModel>> getActivityEvents() async {
    final rows =
        await _storage.getAll('activity_events', orderBy: 'recorded_at DESC');
    return rows.map(ActivityEventModel.fromMap).toList();
  }

  Future<void> insertActivityEvent(ActivityEventModel event) =>
      _storage.upsert('activity_events', event.toMap());

  Future<List<DistractionRuleModel>> getDistractionRules() async {
    final rows = await _storage.getAll('distraction_rules');
    return rows.map(DistractionRuleModel.fromMap).toList();
  }

  Future<void> upsertDistractionRule(DistractionRuleModel rule) =>
      _storage.upsert('distraction_rules', rule.toMap());

  Future<void> deleteDistractionRule(String id) =>
      _storage.deleteById('distraction_rules', id);

  // ---------------- Chat Threads & Messages ----------------
  Future<List<ChatThreadModel>> getChatThreads() async {
    final rows =
        await _storage.getAll('chat_threads', orderBy: 'updated_at DESC');
    return rows.map(ChatThreadModel.fromMap).toList();
  }

  Future<void> upsertChatThread(ChatThreadModel thread) =>
      _storage.upsert('chat_threads', thread.toMap());

  Future<void> deleteChatThread(String id) async {
    await _storage.deleteById('chat_threads', id);
    final msgs = await getChatMessages(id);
    for (final m in msgs) {
      await _storage.deleteById('chat_messages', m.id);
    }
  }

  Future<List<ChatMessageModel>> getChatMessages(String threadId) async {
    final rows =
        await _storage.getAll('chat_messages', orderBy: 'created_at ASC');
    return rows
        .map(ChatMessageModel.fromMap)
        .where((m) => m.threadId == threadId)
        .toList();
  }

  Future<void> insertChatMessage(ChatMessageModel msg) =>
      _storage.upsert('chat_messages', msg.toMap());

  // ---------------- Retention & Backup ----------------
  Future<int> applyRetentionPolicy(int days) async {
    if (days <= 0) return 0;
    final cutoff = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    return _storage.deleteOlderThan('activity_events', 'recorded_at', cutoff);
  }

  Future<String> exportBackupJson() async {
    final data = {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'version': 2,
      'settings': (await getSettings()).toJsonMap(),
      'goals': (await getGoals()).map((e) => e.toMap()).toList(),
      'tasks': (await getTasks()).map((e) => e.toMap()).toList(),
      'habits': (await getHabits()).map((e) => e.toMap()).toList(),
      'focus_sessions':
          (await getFocusSessions()).map((e) => e.toMap()).toList(),
      'calendar_events':
          (await getCalendarEvents()).map((e) => e.toMap()).toList(),
      'distraction_rules':
          (await getDistractionRules()).map((e) => e.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> clearAllData() => _storage.clearAll();
}
