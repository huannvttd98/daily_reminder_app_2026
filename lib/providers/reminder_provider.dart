import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/sample_data.dart';
import '../models/completion.dart';
import '../models/reminder_item.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';

/// State chung của app: lịch nhắc, trạng thái hoàn thành, cài đặt và thống kê.
class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  List<ReminderItem> _items = [];
  Set<String> _doneKeys = {};
  Map<String, String> _settings = {};

  List<ReminderItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _settings = await _db.getSettings();
    if (_settings['seeded'] == null) {
      for (final item in sampleItems(DateTime.now())) {
        await _db.insertItem(item);
      }
      await _setSetting('seeded', '1');
    }
    _items = await _db.getItems();
    _doneKeys = await _db.getCompletionKeys();
    notifyListeners();
    await _rescheduleAll();
  }

  // ---------- Lịch nhắc ----------

  Future<void> saveItem(ReminderItem item) async {
    var saved = item;
    if (item.id == null) {
      saved = item.copyWith(id: await _db.insertItem(item));
    } else {
      await _db.updateItem(item);
    }
    _items = await _db.getItems();
    notifyListeners();
    await _guard(() => _notifications.scheduleItem(
          saved,
          categoryEnabled: isCategoryNotifyEnabled(saved.category),
        ));
  }

  Future<void> setItemEnabled(ReminderItem item, bool enabled) =>
      saveItem(item.copyWith(enabled: enabled));

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    _items = await _db.getItems();
    _doneKeys = await _db.getCompletionKeys();
    notifyListeners();
    await _guard(() => _notifications.cancelItem(id));
  }

  Future<void> clearAll() async {
    await _db.clearAll();
    _items = [];
    _doneKeys = {};
    notifyListeners();
    await _guard(_notifications.cancelAll);
  }

  // ---------- Hoàn thành ----------

  List<Occurrence> occurrencesOn(DateTime day) {
    final d = dateOnly(day);
    final result = [
      for (final item in _items)
        if (item.enabled && item.occursOn(d))
          for (final slot in item.slots) Occurrence(item: item, day: d, slot: slot),
    ];
    result.sort((a, b) => a.slot.compareTo(b.slot));
    return result;
  }

  bool isDone(Occurrence o) => _doneKeys.contains(o.completion.key);

  Future<void> toggleDone(Occurrence o) async {
    final done = !isDone(o);
    await _db.setCompletion(o.completion, done);
    if (done) {
      _doneKeys.add(o.completion.key);
    } else {
      _doneKeys.remove(o.completion.key);
    }
    notifyListeners();
  }

  // ---------- Thống kê ----------

  DayStat statFor(DateTime day, {ReminderCategory? category}) {
    final list = occurrencesOn(day).where((o) => category == null || o.item.category == category);
    return DayStat(list.where(isDone).length, list.length);
  }

  DayStat statForDays(List<DateTime> days, {ReminderCategory? category}) {
    var done = 0;
    var total = 0;
    for (final day in days) {
      final s = statFor(day, category: category);
      done += s.done;
      total += s.total;
    }
    return DayStat(done, total);
  }

  /// Số ngày liên tiếp hoàn thành hết. Hôm nay chưa xong thì không làm đứt chuỗi;
  /// ngày không có lịch thì bỏ qua.
  int get streak {
    final today = dateOnly(DateTime.now());
    var count = statFor(today).isComplete ? 1 : 0;
    for (var i = 1; i <= 365; i++) {
      final s = statFor(DateTime(today.year, today.month, today.day - i));
      if (s.total == 0) continue;
      if (!s.isComplete) break;
      count++;
    }
    return count;
  }

  // ---------- Cài đặt / quyền ----------

  bool isCategoryNotifyEnabled(ReminderCategory c) => _settings['notify_${c.name}'] != '0';

  Future<void> setCategoryNotify(ReminderCategory c, bool enabled) async {
    await _setSetting('notify_${c.name}', enabled ? '1' : '0');
    notifyListeners();
    await _rescheduleAll();
  }

  Future<void> requestNotificationPermission() =>
      _guard(_notifications.requestNotificationPermission);

  Future<void> requestExactAlarmPermission() async {
    await _guard(_notifications.requestExactAlarmPermission);
    await _rescheduleAll();
  }

  Future<void> _setSetting(String key, String value) async {
    await _db.setSetting(key, value);
    _settings[key] = value;
  }

  Future<void> _rescheduleAll() =>
      _guard(() => _notifications.rescheduleAll(_items, isCategoryNotifyEnabled));

  /// Lỗi lên lịch thông báo không được làm hỏng thao tác lưu dữ liệu.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}
