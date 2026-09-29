import '../models/reminder_item.dart';

/// Dữ liệu gợi ý cho lần mở app đầu tiên.
List<ReminderItem> sampleItems(DateTime now) => [
      ReminderItem(
        category: ReminderCategory.workout,
        title: 'Tập thể dục buổi sáng',
        note: 'Khởi động 5 phút, chạy bộ 20 phút',
        startMinute: 6 * 60 + 30,
        repeatType: RepeatType.weekly,
        weekdays: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
        createdAt: now,
      ),
      ReminderItem(
        category: ReminderCategory.meal,
        title: 'Bữa sáng',
        startMinute: 7 * 60,
        createdAt: now,
      ),
      ReminderItem(
        category: ReminderCategory.meal,
        title: 'Bữa trưa',
        startMinute: 12 * 60,
        createdAt: now,
      ),
      ReminderItem(
        category: ReminderCategory.meal,
        title: 'Bữa tối',
        startMinute: 19 * 60,
        createdAt: now,
      ),
      ReminderItem(
        category: ReminderCategory.water,
        title: 'Uống một cốc nước',
        startMinute: 8 * 60,
        endMinute: 20 * 60,
        intervalMinutes: 120,
        createdAt: now,
      ),
      ReminderItem(
        category: ReminderCategory.activity,
        title: 'Chuẩn bị đi ngủ',
        note: 'Tắt màn hình, đọc sách',
        startMinute: 22 * 60 + 30,
        createdAt: now,
      ),
    ];
