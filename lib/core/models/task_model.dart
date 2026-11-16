enum TaskPriority { high, medium, low }

class TaskItemModel {
  final String id;
  final String? goalId;
  final String title;
  final String notes;
  final TaskPriority priority;
  final String scheduledDate; // YYYY-MM-DD
  final String? scheduledTime; // e.g., "09:00"
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const TaskItemModel({
    required this.id,
    this.goalId,
    required this.title,
    this.notes = '',
    this.priority = TaskPriority.medium,
    required this.scheduledDate,
    this.scheduledTime,
    this.estimatedMinutes = 25,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  TaskItemModel copyWith({
    String? goalId,
    String? title,
    String? notes,
    TaskPriority? priority,
    String? scheduledDate,
    String? scheduledTime,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TaskItemModel(
      id: id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'notes': notes,
        'priority': priority.name,
        'scheduled_date': scheduledDate,
        'scheduled_time': scheduledTime,
        'estimated_minutes': estimatedMinutes,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory TaskItemModel.fromMap(Map<String, dynamic> map) {
    final prioName = (map['priority'] ?? 'medium').toString();
    final prio = TaskPriority.values.firstWhere(
      (e) => e.name == prioName,
      orElse: () => TaskPriority.medium,
    );
    return TaskItemModel(
      id: (map['id'] ?? '').toString(),
      goalId: map['goal_id']?.toString(),
      title: (map['title'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      priority: prio,
      scheduledDate: (map['scheduled_date'] ?? '').toString(),
      scheduledTime: map['scheduled_time']?.toString(),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt() ?? 25,
      isCompleted: (map['is_completed'] == 1 || map['is_completed'] == true),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
