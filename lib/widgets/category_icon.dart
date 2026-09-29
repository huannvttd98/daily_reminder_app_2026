import 'package:flutter/material.dart';

import '../models/reminder_item.dart';

extension ReminderCategoryStyle on ReminderCategory {
  IconData get icon => switch (this) {
        ReminderCategory.workout => Icons.fitness_center,
        ReminderCategory.meal => Icons.restaurant,
        ReminderCategory.water => Icons.water_drop,
        ReminderCategory.activity => Icons.event_note,
      };

  Color get color => switch (this) {
        ReminderCategory.workout => Colors.deepOrange,
        ReminderCategory.meal => Colors.green,
        ReminderCategory.water => Colors.blue,
        ReminderCategory.activity => Colors.purple,
      };
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.radius = 20});

  final ReminderCategory category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: category.color.withValues(alpha: 0.15),
      child: Icon(category.icon, color: category.color, size: radius),
    );
  }
}
