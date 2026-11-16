enum GoalStatus { active, completed, archived }

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, completed, overdue }

class GoalModel {
  final String id;
  final String? parentGoalId;
  final String title;
  final String whyReason;
  final GoalStatus status;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    this.parentGoalId,
    required this.title,
    required this.whyReason,
    required this.status,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalModel.fromMap(Map<String, Object?> map) {
    return GoalModel(
      id: map['id'] as String,
      parentGoalId: map['parent_goal_id'] as String?,
      title: map['title'] as String,
      whyReason: (map['why_reason'] as String?) ?? '',
      status: GoalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'parent_goal_id': parentGoalId,
        'title': title,
        'why_reason': whyReason,
        'status': status.name,
        'target_date': targetDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class TaskModel {
  final String id;
  final String goalId;
  final String title;
  final String description;
  final TaskPriority priority;
  final int estimatedMinutes;
  final DateTime? dueAt;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.goalId,
    required this.title,
    this.description = '',
    required this.priority,
    required this.estimatedMinutes,
    this.dueAt,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });

  bool get isOverdue =>
      status != TaskStatus.completed &&
      dueAt != null &&
      dueAt!.isBefore(DateTime.now());

  factory TaskModel.fromMap(Map<String, Object?> map) {
    return TaskModel(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      estimatedMinutes: (map['estimated_minutes'] as int?) ?? 25,
      dueAt: map['due_at'] != null
          ? DateTime.tryParse(map['due_at'] as String)
          : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'estimated_minutes': estimatedMinutes,
        'due_at': dueAt?.toIso8601String(),
        'status': status.name,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
