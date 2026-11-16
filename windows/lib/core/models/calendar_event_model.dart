class CalendarEventModel {
  final String id;
  final String title;
  final String description;
  final String eventDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String category; // focus, exam, meeting, study

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.eventDate,
    this.startTime = '09:00',
    this.category = 'focus',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'event_date': eventDate,
        'start_time': startTime,
        'category': category,
      };

  factory CalendarEventModel.fromMap(Map<String, dynamic> map) =>
      CalendarEventModel(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        eventDate: (map['event_date'] ?? '').toString(),
        startTime: (map['start_time'] ?? '09:00').toString(),
        category: (map['category'] ?? 'focus').toString(),
      );
}
