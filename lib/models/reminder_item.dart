import '../utils/date_utils.dart';

enum ReminderCategory { workout, meal, water, activity }

extension ReminderCategoryLabel on ReminderCategory {
  String get label => switch (this) {
        ReminderCategory.workout => 'Tập luyện',
        ReminderCategory.meal => 'Ăn uống',
        ReminderCategory.water => 'Uống nước',
        ReminderCategory.activity => 'Hoạt động',
      };
}

enum RepeatType { once, daily, weekly }

extension RepeatTypeLabel on RepeatType {
  String get label => switch (this) {
        RepeatType.once => 'Một lần',
        RepeatType.daily => 'Hằng ngày',
        RepeatType.weekly => 'Theo thứ',
      };
}

class ReminderItem {
  const ReminderItem({
    this.id,
    required this.category,
    required this.title,
    this.note = '',
    required this.startMinute,
    this.endMinute,
    this.intervalMinutes,
    this.repeatType = RepeatType.daily,
    this.weekdays = const [],
    this.date,
    this.enabled = true,
    required this.createdAt,
  });

  final int? id;
  final ReminderCategory category;
  final String title;
  final String note;

  /// Giờ nhắc, tính bằng phút trong ngày (0..1439).
  final int startMinute;

  /// Chỉ dùng khi nhắc lặp trong ngày (vd uống nước mỗi 2 tiếng).
  final int? endMinute;
  final int? intervalMinutes;

  final RepeatType repeatType;

  /// DateTime.monday..DateTime.sunday, dùng khi repeatType == weekly.
  final List<int> weekdays;

  /// Dùng khi repeatType == once.
  final DateTime? date;

  final bool enabled;
  final DateTime createdAt;

  bool get isInterval =>
      intervalMinutes != null && intervalMinutes! > 0 && endMinute != null && endMinute! > startMinute;

  /// Các mốc giờ nhắc trong một ngày (phút trong ngày).
  List<int> get slots {
    if (!isInterval) return [startMinute];
    return [for (var m = startMinute; m <= endMinute!; m += intervalMinutes!) m];
  }

  bool occursOn(DateTime day) {
    final d = dateOnly(day);
    return switch (repeatType) {
      RepeatType.once => date != null && isSameDate(date!, d),
      RepeatType.daily => !d.isBefore(dateOnly(createdAt)),
      RepeatType.weekly => !d.isBefore(dateOnly(createdAt)) && weekdays.contains(d.weekday),
    };
  }

  String get scheduleText {
    final time = isInterval
        ? '${formatMinute(startMinute)}–${formatMinute(endMinute!)}, mỗi $intervalMinutes phút'
        : formatMinute(startMinute);
    final repeat = switch (repeatType) {
      RepeatType.once => date == null ? 'một lần' : 'ngày ${date!.day}/${date!.month}/${date!.year}',
      RepeatType.daily => 'hằng ngày',
      RepeatType.weekly => weekdays.map(weekdayShort).join(', '),
    };
    return '$time · $repeat';
  }

  ReminderItem copyWith({int? id, bool? enabled}) => ReminderItem(
        id: id ?? this.id,
        category: category,
        title: title,
        note: note,
        startMinute: startMinute,
        endMinute: endMinute,
        intervalMinutes: intervalMinutes,
        repeatType: repeatType,
        weekdays: weekdays,
        date: date,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category.name,
        'title': title,
        'note': note,
        'start_minute': startMinute,
        'end_minute': endMinute,
        'interval_minutes': intervalMinutes,
        'repeat_type': repeatType.name,
        'weekdays': weekdays.join(','),
        'date': date == null ? null : dateKey(date!),
        'enabled': enabled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReminderItem.fromMap(Map<String, Object?> m) {
    final weekdaysRaw = m['weekdays'] as String? ?? '';
    final dateRaw = m['date'] as String?;
    return ReminderItem(
      id: m['id'] as int?,
      category: ReminderCategory.values.byName(m['category'] as String),
      title: m['title'] as String,
      note: m['note'] as String? ?? '',
      startMinute: m['start_minute'] as int,
      endMinute: m['end_minute'] as int?,
      intervalMinutes: m['interval_minutes'] as int?,
      repeatType: RepeatType.values.byName(m['repeat_type'] as String),
      weekdays: weekdaysRaw.isEmpty ? const [] : weekdaysRaw.split(',').map(int.parse).toList(),
      date: dateRaw == null ? null : parseDateKey(dateRaw),
      enabled: (m['enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
