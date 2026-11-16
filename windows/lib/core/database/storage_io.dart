import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqf;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'storage_driver.dart';

/// محرك SQLite أصلي يعمل على Windows/Linux/macOS (عبر FFI) و Android/iOS (عبر sqflite)
class _IoStorageDriver implements AzmStorageDriver {
  Database? _db;
  static const _dbName = 'azm_ai_v2.db';
  static const _dbVersion = 1;

  static const List<String> _tables = [
    'goals',
    'tasks',
    'habits',
    'focus_sessions',
    'calendar_events',
    'activity_events',
    'distraction_rules',
    'chat_threads',
    'chat_messages',
    'app_settings',
  ];

  @override
  Future<void> init() async {
    if (_db != null && _db!.isOpen) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final dbPath = p.join(dir.path, _dbName);
      _db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
        ),
      );
    } else {
      final dirPath = await sqf.getDatabasesPath();
      final dbPath = p.join(dirPath, _dbName);
      _db = await sqf.openDatabase(
        dbPath,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {
      // بعض أجهزة أندرويد القديمة لا تدعم WAL في مسارات معينة
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        target_date TEXT,
        is_featured INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        goal_id TEXT,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        scheduled_date TEXT NOT NULL,
        scheduled_time TEXT,
        estimated_minutes INTEGER NOT NULL DEFAULT 25,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        target_per_day INTEGER NOT NULL DEFAULT 1,
        completed_today INTEGER NOT NULL DEFAULT 0,
        streak_days INTEGER NOT NULL DEFAULT 0,
        color_hex INTEGER NOT NULL,
        last_updated_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        mode TEXT NOT NULL,
        planned_minutes INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        paused_seconds INTEGER NOT NULL DEFAULT 0,
        pause_started_at TEXT,
        actual_focus_seconds INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        event_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'focus'
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_events (
        id TEXT PRIMARY KEY,
        app_name TEXT NOT NULL,
        window_title TEXT,
        category TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        is_idle INTEGER NOT NULL DEFAULT 0,
        recorded_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE distraction_rules (
        id TEXT PRIMARY KEY,
        target_name TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        action_level INTEGER NOT NULL DEFAULT 2,
        is_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_threads (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        thread_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        json_payload TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_tasks_date ON tasks(scheduled_date)',
    );
    await db.execute(
      'CREATE INDEX idx_focus_started ON focus_sessions(started_at)',
    );
    await db.execute(
      'CREATE INDEX idx_activity_recorded ON activity_events(recorded_at)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_msg_thread ON chat_messages(thread_id, created_at)',
    );
  }

  Future<Database> get _database async {
    await init();
    return _db!;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? orderBy,
  }) async {
    final db = await _database;
    return db.query(table, orderBy: orderBy);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final db = await _database;
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteById(String table, String id) async {
    final db = await _database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(table);
      for (final r in rows) {
        await txn.insert(
          table,
          r,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<int> deleteOlderThan(
    String table,
    String column,
    String isoCutoff,
  ) async {
    final db = await _database;
    return db.delete(
      table,
      where: '$column < ?',
      whereArgs: [isoCutoff],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
      }
    });
  }
}

AzmStorageDriver createStorageDriver() => _IoStorageDriver();
