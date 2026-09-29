import '../utils/date_utils.dart';
import 'reminder_item.dart';

/// Một lần hoàn thành: item nào, ngày nào, mốc giờ nào.
class Completion {
  const Completion({required this.itemId, required this.date, required this.slot});

  final int itemId;
  final DateTime date;
  final int slot;

  String get key => '$itemId|${dateKey(date)}|$slot';
}

/// Một lần xuất hiện của item trong một ngày cụ thể.
class Occurrence {
  const Occurrence({required this.item, required this.day, required this.slot});

  final ReminderItem item;
  final DateTime day;
  final int slot;

  Completion get completion => Completion(itemId: item.id!, date: day, slot: slot);
}

class DayStat {
  const DayStat(this.done, this.total);

  final int done;
  final int total;

  double get rate => total == 0 ? 0 : done / total;
  bool get isComplete => total > 0 && done == total;
}
