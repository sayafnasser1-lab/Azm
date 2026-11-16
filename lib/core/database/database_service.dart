import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<String> getDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    await Directory(dir.path).create(recursive: true);
    return p.join(dir.path, 'azm_ai.db');
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final dbPath = await getDatabasePath();

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
          await db.execute('PRAGMA journal_mode = WAL;');
        },
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        language_code TEXT NOT NULL DEFAULT 'ar',
        is_dark_mode INTEGER NOT NULL DEFAULT 1,
        monitoring_enabled INTEGER NOT NULL DEFAULT 1,
        store_window_titles INTEGER NOT NULL DEFAULT 0,
        idle_threshold_sec INTEGER NOT NULL DEFAULT 180,
        retention_days INTEGER NOT NULL DEFAULT 90,
        ai_provider TEXT NOT NULL DEFAULT 'offlineAnalyzer',
        ai_cloud_consent INTEGER NOT NULL DEFAULT 0,
        ollama_endpoint TEXT NOT NULL DEFAULT 'http://localhost:11434',
        ollama_model TEXT NOT NULL DEFAULT 'llama3.1',
        gemini_api_key TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        parent_goal_id TEXT REFERENCES goals(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        why_reason TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active',
        target_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        estimated_minutes INTEGER NOT NULL DEFAULT 25,
        due_at TEXT,
        status TEXT NOT NULL DEFAULT 'todo',
        completed_at TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT REFERENCES tasks(id) ON DELETE SET NULL,
        mode TEXT NOT NULL DEFAULT 'deepWork',
        planned_minutes INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        last_paused_at TEXT,
        paused_total_sec INTEGER NOT NULL DEFAULT 0,
        actual_focus_sec INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'running',
        interruption_count INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE focus_breaks (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL REFERENCES focus_sessions(id) ON DELETE CASCADE,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        duration_sec INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE application_categories (
        slug TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        productivity_weight REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE applications (
        id TEXT PRIMARY KEY,
        process_name TEXT NOT NULL UNIQUE,
        exe_path TEXT,
        display_name TEXT NOT NULL,
        category_slug TEXT NOT NULL REFERENCES application_categories(slug),
        is_user_verified INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE activity_records (
        id TEXT PRIMARY KEY,
        application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
        window_title_masked TEXT,
        started_at TEXT NOT NULL,
        ended_at TEXT NOT NULL,
        duration_sec INTEGER NOT NULL,
        is_idle INTEGER NOT NULL DEFAULT 0,
        focus_session_id TEXT REFERENCES focus_sessions(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE distraction_rules (
        id TEXT PRIMARY KEY,
        application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
        rule_type TEXT NOT NULL,
        action_level TEXT NOT NULL,
        session_mode TEXT,
        daily_limit_min INTEGER,
        is_enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE website_rules (
        id TEXT PRIMARY KEY,
        domain_pattern TEXT NOT NULL UNIQUE,
        rule_type TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        related_entity_id TEXT,
        created_at TEXT NOT NULL,
        read_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE ai_conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ai_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        provider_label TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE daily_summaries (
        date TEXT PRIMARY KEY,
        total_focus_sec INTEGER NOT NULL DEFAULT 0,
        total_distraction_sec INTEGER NOT NULL DEFAULT 0,
        total_idle_sec INTEGER NOT NULL DEFAULT 0,
        completed_tasks_count INTEGER NOT NULL DEFAULT 0,
        top_app_id TEXT REFERENCES applications(id) ON DELETE SET NULL
      );
    ''');

    // Indexes للأداء العالي
    await db.execute('CREATE INDEX idx_tasks_goal_status ON tasks(goal_id, status);');
    await db.execute('CREATE INDEX idx_activity_started_at ON activity_records(started_at);');
    await db.execute('CREATE INDEX idx_focus_started_at ON focus_sessions(started_at);');

    // البيانات الأساسية المرجعية (التصنيفات والمستخدم المحلي الافتراضي)
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'local_user',
      'display_name': 'المستخدم المحلي',
      'created_at': now,
    });
    await db.insert('user_settings', {
      'id': 'default_settings',
      'user_id': 'local_user',
      'updated_at': now,
    });

    final categories = [
      {'slug': 'productive', 'name_ar': 'إنتاجية', 'name_en': 'Productive', 'productivity_weight': 1.0},
      {'slug': 'educational', 'name_ar': 'تعليمية', 'name_en': 'Educational', 'productivity_weight': 0.9},
      {'slug': 'neutral', 'name_ar': 'محايدة', 'name_en': 'Neutral', 'productivity_weight': 0.0},
      {'slug': 'entertainment', 'name_ar': 'ترفيهية', 'name_en': 'Entertainment', 'productivity_weight': -0.5},
      {'slug': 'distracting', 'name_ar': 'مشتتة', 'name_en': 'Distracting', 'productivity_weight': -1.0},
    ];
    for (final cat in categories) {
      await db.insert('application_categories', cat);
    }
  }

  /// تصدير نسخة احتياطية كاملة بصيغة JSON محليًا
  Future<String> exportBackupJson() async {
    final db = await database;
    final tables = [
      'users',
      'user_settings',
      'goals',
      'tasks',
      'focus_sessions',
      'focus_breaks',
      'applications',
      'activity_records',
      'distraction_rules',
      'website_rules',
      'ai_conversations',
      'ai_messages',
    ];
    final Map<String, dynamic> exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'schema_version': 1,
      'tables': <String, dynamic>{},
    };
    for (final table in tables) {
      exportData['tables'][table] = await db.query(table);
    }
    final dir = await getApplicationSupportDirectory();
    final backupFile = File(p.join(
      dir.path,
      'azm_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    ));
    await backupFile.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
    return backupFile.path;
  }

  /// تطبيق سياسة الاحتفاظ بالبيانات وحذف سجلات النشاط الأقدم من المدة المحددة
  Future<int> enforceRetentionPolicy(int retentionDays) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();
    return db.delete(
      'activity_records',
      where: 'ended_at < ?',
      whereArgs: [cutoff],
    );
  }
}
