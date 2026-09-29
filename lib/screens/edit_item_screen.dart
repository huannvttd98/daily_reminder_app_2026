import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/category_icon.dart';

/// Thêm mới (item == null) hoặc sửa một lịch nhắc.
class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, this.item, this.initialDate});

  final ReminderItem? item;

  /// Ngày mặc định khi chọn "Một lần" (vd ngày đang chọn ở màn Kế hoạch).
  final DateTime? initialDate;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  static const _intervalOptions = [30, 60, 90, 120, 180];

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late ReminderCategory _category;
  late TimeOfDay _start;
  late bool _useInterval;
  late int _interval;
  late TimeOfDay _end;
  late RepeatType _repeat;
  late Set<int> _weekdays;
  late DateTime _date;
  late bool _enabled;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final now = DateTime.now();
    _category = item?.category ?? ReminderCategory.workout;
    _titleController.text = item?.title ?? '';
    _noteController.text = item?.note ?? '';
    _start = _toTime(item?.startMinute ?? ((now.hour + 1) % 24) * 60);
    _useInterval = item?.isInterval ?? false;
    _interval = item?.intervalMinutes ?? 120;
    _end = _toTime(item?.endMinute ?? 20 * 60);
    _repeat = item?.repeatType ?? RepeatType.daily;
    _weekdays = {...?item?.weekdays};
    if (_weekdays.isEmpty) _weekdays = {(widget.initialDate ?? now).weekday};
    _date = dateOnly(item?.date ?? widget.initialDate ?? now);
    _enabled = item?.enabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static TimeOfDay _toTime(int minuteOfDay) =>
      TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60);

  static int _toMinute(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _intervalLabel(int m) {
    if (m < 60) return '$m phút';
    if (m % 60 == 0) return '${m ~/ 60} tiếng';
    return '${m ~/ 60} tiếng ${m % 60} phút';
  }

  void _selectCategory(ReminderCategory c) {
    _category = c;
    // Uống nước thường là nhắc lặp trong ngày.
    if (c == ReminderCategory.water && !_isEditing) {
      _useInterval = true;
      if (_titleController.text.trim().isEmpty) _titleController.text = 'Uống một cốc nước';
    }
  }

  Future<void> _pickTime(TimeOfDay initial, void Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    String? error;
    if (title.isEmpty) {
      error = 'Hãy nhập tên lịch nhắc';
    } else if (_repeat == RepeatType.weekly && _weekdays.isEmpty) {
      error = 'Chọn ít nhất một thứ trong tuần';
    } else if (_useInterval && _toMinute(_end) <= _toMinute(_start)) {
      error = 'Giờ kết thúc phải sau giờ bắt đầu';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final provider = context.read<ReminderProvider>();
    final navigator = Navigator.of(context);
    await provider.saveItem(ReminderItem(
      id: widget.item?.id,
      category: _category,
      title: title,
      note: _noteController.text.trim(),
      startMinute: _toMinute(_start),
      endMinute: _useInterval ? _toMinute(_end) : null,
      intervalMinutes: _useInterval ? _interval : null,
      repeatType: _repeat,
      weekdays: _repeat == RepeatType.weekly ? (_weekdays.toList()..sort()) : const [],
      date: _repeat == RepeatType.once ? _date : null,
      enabled: _enabled,
      createdAt: widget.item?.createdAt ?? DateTime.now(),
    ));
    navigator.pop();
  }

  Future<void> _delete() async {
    final item = widget.item!;
    final provider = context.read<ReminderProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch nhắc?'),
        content: Text('"${item.title}" và lịch sử hoàn thành của nó sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await provider.deleteItem(item.id!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge;
    final intervalOptions = {..._intervalOptions, _interval}.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa lịch nhắc' : 'Thêm lịch nhắc'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Xóa',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Loại', style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ReminderCategory.values)
                ChoiceChip(
                  avatar: Icon(c.icon, size: 18, color: c.color),
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _selectCategory(c)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tên',
              hintText: 'VD: Chạy bộ 30 phút',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tùy chọn)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(_useInterval ? 'Bắt đầu' : 'Giờ nhắc'),
            trailing: Text(_start.format(context), style: theme.textTheme.titleMedium),
            onTap: () => _pickTime(_start, (t) => _start = t),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc lặp lại trong ngày'),
            subtitle: const Text('VD: uống nước mỗi 2 tiếng'),
            value: _useInterval,
            onChanged: (v) => setState(() => _useInterval = v),
          ),
          if (_useInterval) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: const Text('Mỗi'),
              trailing: DropdownButton<int>(
                value: _interval,
                items: [
                  for (final m in intervalOptions)
                    DropdownMenuItem(value: m, child: Text(_intervalLabel(m))),
                ],
                onChanged: (v) => setState(() => _interval = v ?? _interval),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Kết thúc'),
              trailing: Text(_end.format(context), style: theme.textTheme.titleMedium),
              onTap: () => _pickTime(_end, (t) => _end = t),
            ),
          ],
          const SizedBox(height: 8),
          Text('Lặp lại', style: labelStyle),
          const SizedBox(height: 8),
          SegmentedButton<RepeatType>(
            segments: [
              for (final r in RepeatType.values) ButtonSegment(value: r, label: Text(r.label)),
            ],
            selected: {_repeat},
            onSelectionChanged: (s) => setState(() => _repeat = s.first),
          ),
          const SizedBox(height: 12),
          if (_repeat == RepeatType.weekly)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
                  FilterChip(
                    label: Text(weekdayShort(wd)),
                    selected: _weekdays.contains(wd),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _weekdays.add(wd);
                      } else {
                        _weekdays.remove(wd);
                      }
                    }),
                  ),
              ],
            ),
          if (_repeat == RepeatType.once)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Ngày'),
              trailing: Text(
                DateFormat('d/M/yyyy').format(_date),
                style: theme.textTheme.titleMedium,
              ),
              onTap: _pickDate,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bật nhắc nhở'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
