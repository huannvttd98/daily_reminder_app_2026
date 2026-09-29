import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../widgets/category_icon.dart';
import 'edit_item_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final provider = context.read<ReminderProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?'),
        content: const Text('Tất cả lịch nhắc và lịch sử hoàn thành sẽ bị xóa, không khôi phục được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) await provider.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const _SectionTitle('Nhắc nhở theo loại'),
          for (final c in ReminderCategory.values)
            SwitchListTile(
              secondary: CategoryIcon(category: c),
              title: Text(c.label),
              value: provider.isCategoryNotifyEnabled(c),
              onChanged: (v) => provider.setCategoryNotify(c, v),
            ),
          const _SectionTitle('Quyền'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Cho phép thông báo'),
            subtitle: const Text('Cần bật để nhận nhắc nhở'),
            onTap: provider.requestNotificationPermission,
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Nhắc đúng giờ (Android)'),
            subtitle: const Text('Nếu không bật, Android có thể nhắc trễ vài phút'),
            onTap: provider.requestExactAlarmPermission,
          ),
          _SectionTitle('Tất cả lịch nhắc (${items.length})'),
          for (final item in items)
            ListTile(
              leading: CategoryIcon(category: item.category),
              title: Text(item.title),
              subtitle: Text(item.scheduleText),
              trailing: Switch(
                value: item.enabled,
                onChanged: (v) => provider.setItemEnabled(item, v),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
              ),
            ),
          const _SectionTitle('Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa toàn bộ dữ liệu'),
            onTap: () => _confirmClear(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
