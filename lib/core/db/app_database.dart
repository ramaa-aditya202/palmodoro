import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const schemaVersion = 1;
  static const defaultPresetId = 'preset-classic-pomodoro';

  static Future<Database> open({String? inMemoryPath}) async {
    final dbPath = inMemoryPath ??
        p.join(await getDatabasesPath(), 'pomodoro_offline.db');

    return openDatabase(
      dbPath,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchemaV1(db);
      },
    );
  }

  static Future<void> _createSchemaV1(Database db) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'folder',
        parent_id TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE labels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'tag',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        project_id TEXT,
        parent_id TEXT,
        priority INTEGER NOT NULL DEFAULT 4,
        due_at INTEGER,
        schedule_kind TEXT NOT NULL DEFAULT 'allDay',
        duration_minutes INTEGER,
        recurrence_interval INTEGER,
        recurrence_unit TEXT,
        estimated_pomodoros INTEGER NOT NULL DEFAULT 0,
        completed_pomodoros INTEGER NOT NULL DEFAULT 0,
        kanban_status TEXT NOT NULL DEFAULT 'todo',
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        reminder_at INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_labels (
        task_id TEXT NOT NULL,
        label_id TEXT NOT NULL,
        PRIMARY KEY (task_id, label_id),
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (label_id) REFERENCES labels(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE task_dependencies (
        blocker_task_id TEXT NOT NULL,
        blocked_task_id TEXT NOT NULL,
        PRIMARY KEY (blocker_task_id, blocked_task_id),
        FOREIGN KEY (blocker_task_id) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (blocked_task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_presets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        work_seconds INTEGER NOT NULL,
        short_break_seconds INTEGER NOT NULL,
        long_break_seconds INTEGER NOT NULL,
        intervals_before_long_break INTEGER NOT NULL,
        auto_start_breaks INTEGER NOT NULL DEFAULT 0,
        auto_start_work INTEGER NOT NULL DEFAULT 0,
        allow_pause INTEGER NOT NULL DEFAULT 1,
        strict_mode INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_runs (
        id TEXT PRIMARY KEY,
        preset_id TEXT NOT NULL,
        task_id TEXT,
        status TEXT NOT NULL,
        completed_work_intervals INTEGER NOT NULL DEFAULT 0,
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_intervals (
        id TEXT PRIMARY KEY,
        run_id TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        sequence_index INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        started_at INTEGER,
        paused_at INTEGER,
        accumulated_paused_seconds INTEGER NOT NULL DEFAULT 0,
        ended_at INTEGER,
        FOREIGN KEY (run_id) REFERENCES focus_runs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'check',
        project_id TEXT,
        weekdays_csv TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        target_per_day INTEGER NOT NULL DEFAULT 1,
        day_period TEXT NOT NULL DEFAULT 'anytime',
        reminder_minutes INTEGER,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_check_ins (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        day_epoch_ms INTEGER NOT NULL,
        day_period TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('focus_presets', {
      'id': defaultPresetId,
      'name': 'Classic Pomodoro',
      'work_seconds': 1500,
      'short_break_seconds': 300,
      'long_break_seconds': 900,
      'intervals_before_long_break': 4,
      'auto_start_breaks': 0,
      'auto_start_work': 0,
      'allow_pause': 1,
      'strict_mode': 0,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });
  }
}
