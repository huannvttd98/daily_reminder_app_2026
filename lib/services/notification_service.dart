import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_item.dart';
import '../utils/date_utils.dart';

/// Lên lịch / hủy thông báo nhắc cho từng ReminderItem.
///
/// ID thông báo = itemId * 1000 + chỉ số, nên hủy được đúng các thông báo
/// của một item khi sửa/xóa nó.
class NotificationService {
  static const _idsPerItem = 1000;
  static const _channelId = 'reminders';

  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    // Bấm vào thông báo chỉ cần mở app — tab mặc định đã là "Hôm nay".
    await _plugin.initialize(settings);
  }

  Future<void> requestNotificationPermission() async {
    await _android?.requestNotificationsPermission();
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Android 12+: mở màn cài đặt để cho phép nhắc đúng giờ.
  Future<void> requestExactAlarmPermission() async {
    await _android?.requestExactAlarmsPermission();
  }

  Future<void> rescheduleAll(
    List<ReminderItem> items,
    bool Function(ReminderCategory) categoryEnabled,
  ) async {
    await _plugin.cancelAll();
    final mode = await _scheduleMode();
    for (final item in items) {
      await _schedule(item, categoryEnabled(item.category), mode);
    }
  }

  Future<void> scheduleItem(ReminderItem item, {required bool categoryEnabled}) async {
    await cancelItem(item.id!);
    await _schedule(item, categoryEnabled, await _scheduleMode());
  }

  Future<void> cancelItem(int itemId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id ~/ _idsPerItem == itemId) await _plugin.cancel(request.id);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _schedule(ReminderItem item, bool categoryEnabled, AndroidScheduleMode mode) async {
    if (item.id == null || !item.enabled || !categoryEnabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Nhắc nhở',
        channelDescription: 'Nhắc lịch tập, ăn uống và việc trong ngày',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final title = '${item.category.label}: ${item.title}';
    final now = tz.TZDateTime.now(tz.local);
    var index = 0;

    Future<void> add(tz.TZDateTime when, DateTimeComponents? match, int slot) async {
      if (index >= _idsPerItem) return;
      final id = item.id! * _idsPerItem + index++;
      final body = item.note.isNotEmpty ? item.note : 'Đến giờ rồi (${formatMinute(slot)})';
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: mode,
        matchDateTimeComponents: match,
      );
    }

    for (final slot in item.slots) {
      final hour = slot ~/ 60;
      final minute = slot % 60;
      switch (item.repeatType) {
        case RepeatType.once:
          final d = item.date;
          if (d == null) continue;
          final when = tz.TZDateTime(tz.local, d.year, d.month, d.day, hour, minute);
          if (when.isAfter(now)) await add(when, null, slot);
        case RepeatType.daily:
          await add(_nextInstance(now, hour, minute), DateTimeComponents.time, slot);
        case RepeatType.weekly:
          for (final weekday in item.weekdays) {
            await add(
              _nextInstance(now, hour, minute, weekday: weekday),
              DateTimeComponents.dayOfWeekAndTime,
              slot,
            );
          }
      }
    }
  }

  tz.TZDateTime _nextInstance(tz.TZDateTime now, int hour, int minute, {int? weekday}) {
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (!when.isAfter(now) || (weekday != null && when.weekday != weekday)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
