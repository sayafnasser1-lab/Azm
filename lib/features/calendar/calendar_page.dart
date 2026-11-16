import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/calendar_event_model.dart';
import '../../core/providers/app_providers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDay = DateTime.now();

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final events = ref.watch(calendarEventsProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final selIso = _iso(_selectedDay);

    final dayEvents = events.where((e) => e.eventDate == selIso).toList();
    final dayTasks = tasks.where((t) => t.scheduledDate == selIso).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          ar ? 'التقويم' : 'Calendar',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEventDialog(context, ar),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(ar ? 'حدث جديد' : 'Add Event'),
                        ),
                      ],
                    ),
                    CalendarDatePicker(
                      initialDate: _selectedDay,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      onDateChanged: (d) => setState(() => _selectedDay = d),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ar ? 'أحداث ومهام يوم $selIso' : 'Schedule for $selIso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (dayEvents.isEmpty && dayTasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      ar
                          ? 'لا توجد أحداث أو مهام مجدولة في هذا اليوم.'
                          : 'No events or tasks on this date.',
                    ),
                  ),
                ),
              ),
            ...dayEvents.map(
              (ev) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AzmColors.primarySoft,
                      child: Icon(Icons.event, color: AzmColors.primary),
                    ),
                    title: Text(
                      ev.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${ev.startTime} • ${ev.description}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(calendarEventsProvider.notifier)
                          .remove(ev.id),
                    ),
                  ),
                ),
              ),
            ),
            ...dayTasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      t.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: AzmColors.emerald,
                    ),
                    title: Text(t.title),
                    subtitle: Text('${t.scheduledTime ?? "--:--"} • ${t.estimatedMinutes}m'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEventDialog(BuildContext context, bool ar) async {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10:00');
    final descCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'إضافة حدث' : 'New Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: ar ? 'عنوان الحدث' : 'Title',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeCtrl,
              decoration: InputDecoration(
                labelText: ar ? 'الوقت' : 'Start Time',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: ar ? 'التفاصيل' : 'Description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(calendarEventsProvider.notifier).save(
                    CalendarEventModel(
                      id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      eventDate: _iso(_selectedDay),
                      startTime: timeCtrl.text.trim(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ar ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
