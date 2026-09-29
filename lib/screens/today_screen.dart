import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/item_tile.dart';
import 'edit_item_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final today = dateOnly(DateTime.now());
    final occurrences = provider.occurrencesOn(today);
    final stat = provider.statFor(today);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hôm nay')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm lịch nhắc',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditItemScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capitalize(DateFormat('EEEE, d MMMM', 'vi').format(today)),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: stat.rate, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(stat.total == 0
                      ? 'Hôm nay chưa có lịch nào'
                      : 'Đã xong ${stat.done}/${stat.total} việc'),
                ],
              ),
            ),
          ),
          if (occurrences.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Bấm + để thêm lịch tập, bữa ăn hoặc việc cần làm.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final o in occurrences) OccurrenceTile(occurrence: o),
        ],
      ),
    );
  }
}
