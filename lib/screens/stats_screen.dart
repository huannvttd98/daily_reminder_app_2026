import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/completion.dart';
import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/category_icon.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final days = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i)];
    final dayStats = [for (final d in days) provider.statFor(d)];
    final week = provider.statForDays(days);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                  label: 'Chuỗi ngày',
                  value: '${provider.streak} ngày',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.insights,
                  color: theme.colorScheme.primary,
                  label: '7 ngày qua',
                  value: '${(week.rate * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tỉ lệ hoàn thành 7 ngày', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: dayStats[i].rate * 100,
                        width: 18,
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                ],
                gridData: const FlGridData(drawVerticalLine: false, horizontalInterval: 25),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) =>
                          Text('${value.toInt()}%', style: theme.textTheme.bodySmall),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          weekdayShort(days[value.toInt()].weekday),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Theo loại (7 ngày)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final c in ReminderCategory.values)
            _CategoryRow(category: c, stat: provider.statForDays(days, category: c)),
          const SizedBox(height: 24),
          Text('Lịch sử', style: theme.textTheme.titleMedium),
          for (var i = days.length - 1; i >= 0; i--)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                dayStats[i].isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: dayStats[i].isComplete ? Colors.green : Colors.grey,
              ),
              title: Text(capitalize(DateFormat('EEEE, d/M', 'vi').format(days[i]))),
              trailing: Text(
                dayStats[i].total == 0 ? '—' : '${dayStats[i].done}/${dayStats[i].total}',
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.stat});

  final ReminderCategory category;
  final DayStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CategoryIcon(category: category, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category.label)),
                    Text(stat.total == 0 ? '—' : '${stat.done}/${stat.total}'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: stat.rate, color: category.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
