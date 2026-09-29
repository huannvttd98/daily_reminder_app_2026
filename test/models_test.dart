import 'package:daily_reminder_app/models/completion.dart';
import 'package:daily_reminder_app/models/reminder_item.dart';
import 'package:flutter_test/flutter_test.dart';

// 2024-01-01 là thứ Hai.
final monday = DateTime(2024, 1, 1);

ReminderItem item({
  RepeatType repeatType = RepeatType.daily,
  List<int> weekdays = const [],
  DateTime? date,
  int startMinute = 7 * 60,
  int? endMinute,
  int? intervalMinutes,
}) =>
    ReminderItem(
      id: 1,
      category: ReminderCategory.water,
      title: 'Uống nước',
      startMinute: startMinute,
      endMinute: endMinute,
      intervalMinutes: intervalMinutes,
      repeatType: repeatType,
      weekdays: weekdays,
      date: date,
      createdAt: monday.add(const Duration(hours: 10)),
    );

void main() {
  group('occursOn', () {
    test('daily: từ ngày tạo trở đi, không có ngày trước đó', () {
      final i = item();
      expect(i.occursOn(monday.subtract(const Duration(days: 1))), isFalse);
      expect(i.occursOn(monday), isTrue); // tạo lúc 10h vẫn tính cả ngày đó
      expect(i.occursOn(monday.add(const Duration(days: 30))), isTrue);
    });

    test('weekly: chỉ các thứ đã chọn', () {
      final i = item(repeatType: RepeatType.weekly, weekdays: [DateTime.monday, DateTime.wednesday]);
      expect(i.occursOn(monday), isTrue);
      expect(i.occursOn(monday.add(const Duration(days: 1))), isFalse); // T3
      expect(i.occursOn(monday.add(const Duration(days: 2))), isTrue); // T4
      expect(i.occursOn(monday.add(const Duration(days: 7))), isTrue);
      expect(i.occursOn(monday.subtract(const Duration(days: 5))), isFalse); // T4 trước ngày tạo
    });

    test('once: chỉ đúng ngày đã đặt', () {
      final i = item(repeatType: RepeatType.once, date: DateTime(2024, 1, 3));
      expect(i.occursOn(DateTime(2024, 1, 3, 18)), isTrue);
      expect(i.occursOn(DateTime(2024, 1, 4)), isFalse);
      expect(item(repeatType: RepeatType.once).occursOn(monday), isFalse);
    });
  });

  group('slots', () {
    test('nhắc một lần trong ngày', () {
      expect(item().slots, [7 * 60]);
      expect(item().isInterval, isFalse);
    });

    test('nhắc lặp: 8h–12h mỗi 2 tiếng', () {
      final i = item(startMinute: 8 * 60, endMinute: 12 * 60, intervalMinutes: 120);
      expect(i.isInterval, isTrue);
      expect(i.slots, [480, 600, 720]);
    });

    test('giờ kết thúc trước giờ bắt đầu thì coi như không lặp', () {
      final i = item(startMinute: 12 * 60, endMinute: 8 * 60, intervalMinutes: 60);
      expect(i.isInterval, isFalse);
      expect(i.slots, [720]);
    });
  });

  group('toMap / fromMap', () {
    test('weekly giữ nguyên dữ liệu', () {
      final i = item(
        repeatType: RepeatType.weekly,
        weekdays: [1, 3, 7],
        startMinute: 480,
        endMinute: 720,
        intervalMinutes: 60,
      );
      final back = ReminderItem.fromMap(i.toMap());
      expect(back.toMap(), i.toMap());
      expect(back.weekdays, [1, 3, 7]);
    });

    test('once giữ nguyên ngày, weekdays rỗng', () {
      final i = item(repeatType: RepeatType.once, date: DateTime(2024, 2, 29));
      final back = ReminderItem.fromMap(i.toMap());
      expect(back.date, DateTime(2024, 2, 29));
      expect(back.weekdays, isEmpty);
      expect(back.toMap(), i.toMap());
    });

    test('enabled lưu thành 0/1', () {
      final off = item().copyWith(enabled: false);
      expect(off.toMap()['enabled'], 0);
      expect(ReminderItem.fromMap(off.toMap()).enabled, isFalse);
    });
  });

  test('scheduleText', () {
    expect(item().scheduleText, '07:00 · hằng ngày');
    expect(
      item(repeatType: RepeatType.weekly, weekdays: [1, 7]).scheduleText,
      '07:00 · T2, CN',
    );
    expect(
      item(startMinute: 480, endMinute: 600, intervalMinutes: 60).scheduleText,
      '08:00–10:00, mỗi 60 phút · hằng ngày',
    );
  });

  group('Completion / DayStat', () {
    test('key của Completion', () {
      expect(Completion(itemId: 5, date: DateTime(2024, 1, 2), slot: 480).key, '5|2024-01-02|480');
    });

    test('DayStat', () {
      expect(const DayStat(0, 0).rate, 0);
      expect(const DayStat(0, 0).isComplete, isFalse);
      expect(const DayStat(1, 4).rate, 0.25);
      expect(const DayStat(3, 3).isComplete, isTrue);
    });
  });
}
