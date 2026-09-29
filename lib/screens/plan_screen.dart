import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/completion.dart';
import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/category_icon.dart';
import '../widgets/item_tile.dart';
import 'edit_item_screen.dart';

/// Xem kế hoạch theo tuần / tháng.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = dateOnly(DateTime.now());
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final occurrences = provider.occurrencesOn(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Kế hoạch')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm lịch nhắc',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditItemScreen(initialDate: _selectedDay)),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Occurrence>(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Tháng',
              CalendarFormat.week: 'Tuần',
            },
            headerStyle: const HeaderStyle(formatButtonShowsNext: false),
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: provider.occurrencesOn,
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = dateOnly(selected);
              _focusedDay = focused;
            }),
            onFormatChanged: (format) => setState(() => _format = format),
            onPageChanged: (focused) => _focusedDay = focused,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                final categories = {for (final e in events) e.item.category}.toList()
                  ..sort((a, b) => a.index.compareTo(b.index));
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in categories)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                capitalize(DateFormat('EEEE, d/M/yyyy', 'vi').format(_selectedDay)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: occurrences.isEmpty
                ? const Center(child: Text('Không có lịch trong ngày này'))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [for (final o in occurrences) OccurrenceTile(occurrence: o)],
                  ),
          ),
        ],
      ),
    );
  }
}
