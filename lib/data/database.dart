import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/completion.dart';
import '../models/reminder_item.dart';
import '../utils/date_utils.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'daily_reminder.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            start_minute INTEGER NOT NULL,
            end_minute INTEGER,
            interval_minutes INTEGER,
            repeat_type TEXT NOT NULL,
            weekdays TEXT NOT NULL DEFAULT '',
            date TEXT,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE completions(
            item_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            slot INTEGER NOT NULL,
            done_at TEXT NOT NULL,
            PRIMARY KEY(item_id, date, slot)
          )''');
        await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    return AppDatabase._(db);
  }

  Future<List<ReminderItem>> getItems() async {
    final rows = await _db.query('items', orderBy: 'start_minute, id');
    return rows.map(ReminderItem.fromMap).toList();
  }

  Future<int> insertItem(ReminderItem item) => _db.insert('items', item.toMap()..remove('id'));

  Future<void> updateItem(ReminderItem item) async {
    await _db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(int id) async {
    await _db.transaction((txn) async {
      await txn.delete('completions', where: 'item_id = ?', whereArgs: [id]);
      await txn.delete('items', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Set<String>> getCompletionKeys() async {
    final rows = await _db.query('completions');
    return rows
        .map((r) => Completion(
              itemId: r['item_id'] as int,
              date: parseDateKey(r['date'] as String),
              slot: r['slot'] as int,
            ).key)
        .toSet();
  }

  Future<void> setCompletion(Completion c, bool done) async {
    if (done) {
      await _db.insert(
        'completions',
        {
          'item_id': c.itemId,
          'date': dateKey(c.date),
          'slot': c.slot,
          'done_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _db.delete(
        'completions',
        where: 'item_id = ? AND date = ? AND slot = ?',
        whereArgs: [c.itemId, dateKey(c.date), c.slot],
      );
    }
  }

  Future<Map<String, String>> getSettings() async {
    final rows = await _db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> setSetting(String key, String value) async {
    await _db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Xóa lịch nhắc + lịch sử, giữ cài đặt (để không tự tạo lại dữ liệu mẫu).
  Future<void> clearAll() async {
    await _db.transaction((txn) async {
      await txn.delete('completions');
      await txn.delete('items');
    });
  }
}
