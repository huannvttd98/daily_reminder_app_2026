import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/completion.dart';
import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../screens/edit_item_screen.dart';
import '../utils/date_utils.dart';
import 'category_icon.dart';

/// Một dòng lịch trong ngày: giờ, loại, ô tick hoàn thành.
class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({super.key, required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final item = occurrence.item;
    final done = provider.isDone(occurrence);
    // Không cho tick trước những ngày chưa tới.
    final canCheck = !occurrence.day.isAfter(dateOnly(DateTime.now()));

    return ListTile(
      leading: CategoryIcon(category: item.category),
      title: Text(
        item.title,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      subtitle: Text([
        '${formatMinute(occurrence.slot)} · ${item.category.label}',
        if (item.note.isNotEmpty) item.note,
      ].join('\n')),
      isThreeLine: item.note.isNotEmpty,
      trailing: Checkbox(
        value: done,
        onChanged: canCheck ? (_) => provider.toggleDone(occurrence) : null,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
      ),
    );
  }
}
