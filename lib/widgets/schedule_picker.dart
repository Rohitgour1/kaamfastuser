import 'package:flutter/material.dart';

Future<DateTime?> pickSchedule(
  BuildContext context, {
  DateTime? initial,
}) async {
  final earliest = DateTime.now().add(const Duration(hours: 1));
  var seed = initial ?? earliest;
  if (seed.isBefore(earliest)) seed = earliest;

  final date = await showDatePicker(
    context: context,
    initialDate: seed,
    firstDate: DateTime(earliest.year, earliest.month, earliest.day),
    lastDate: DateTime.now().add(const Duration(days: 30)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(seed),
  );
  if (time == null) return null;

  var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (picked.isBefore(earliest)) picked = earliest;
  return picked;
}

String formatScheduleWindow(DateTime start) {
  final end = start.add(const Duration(hours: 2));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(start.year, start.month, start.day);
  final dayLabel = day == today
      ? 'Today'
      : day == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : '${_months[start.month - 1]} ${start.day}';
  return '$dayLabel, ${_ampm(start)} - ${_ampm(end)}';
}

String formatSchedule(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  return '${_months[d.month - 1]} ${d.day} · $h:$m $ampm';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _ampm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}
