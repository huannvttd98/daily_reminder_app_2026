import 'package:daily_reminder_app/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly bỏ phần giờ', () {
    expect(dateOnly(DateTime(2024, 3, 5, 23, 59)), DateTime(2024, 3, 5));
  });

  test('isSameDate so ngày, bỏ qua giờ', () {
    expect(isSameDate(DateTime(2024, 3, 5, 1), DateTime(2024, 3, 5, 22)), isTrue);
    expect(isSameDate(DateTime(2024, 3, 5), DateTime(2024, 3, 6)), isFalse);
  });

  test('dateKey và parseDateKey đổi qua lại được', () {
    expect(dateKey(DateTime(2024, 3, 5)), '2024-03-05');
    expect(parseDateKey('2024-03-05'), DateTime(2024, 3, 5));
    final d = DateTime(2024, 12, 31);
    expect(parseDateKey(dateKey(d)), d);
  });

  test('formatMinute', () {
    expect(formatMinute(0), '00:00');
    expect(formatMinute(7 * 60 + 5), '07:05');
    expect(formatMinute(1439), '23:59');
  });

  test('weekdayShort', () {
    expect(weekdayShort(DateTime.monday), 'T2');
    expect(weekdayShort(DateTime.saturday), 'T7');
    expect(weekdayShort(DateTime.sunday), 'CN');
  });

  test('capitalize', () {
    expect(capitalize(''), '');
    expect(capitalize('thứ hai'), 'Thứ hai');
  });
}
