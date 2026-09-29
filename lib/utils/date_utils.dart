/// Bỏ phần giờ, giữ ngày theo giờ địa phương.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 'yyyy-MM-dd' — dùng làm khóa lưu DB.
String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

DateTime parseDateKey(String s) {
  final parts = s.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Phút trong ngày → 'HH:mm'.
String formatMinute(int minuteOfDay) => '${_two(minuteOfDay ~/ 60)}:${_two(minuteOfDay % 60)}';

/// DateTime.monday..sunday → T2..CN
String weekdayShort(int weekday) => weekday == DateTime.sunday ? 'CN' : 'T${weekday + 1}';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _two(int n) => n.toString().padLeft(2, '0');
