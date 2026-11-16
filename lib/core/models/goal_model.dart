enum GoalStatus { active, completed, postponed }

class GoalModel {
  final String id;
  final String title;
  final String subtitle;
  final String category; // learning, coding, health, career, spiritual
  final GoalStatus status;
  final int progress; // 0..100
  final DateTime? targetDate;
  final bool isFeatured;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.status = GoalStatus.active,
    this.progress = 0,
    this.targetDate,
    this.isFeatured = false,
    required this.createdAt,
  });

  int? get remainingDays {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    return target.difference(today).inDays;
  }

  GoalModel copyWith({
    String? title,
    String? subtitle,
    String? category,
    GoalStatus? status,
    int? progress,
    DateTime? targetDate,
    bool? isFeatured,
  }) {
    return GoalModel(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      status: status ?? this.status,
      progress: (progress ?? this.progress).clamp(0, 100),
      targetDate: targetDate ?? this.targetDate,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'status': status.name,
        'progress': progress,
        'target_date': targetDate?.toIso8601String(),
        'is_featured': isFeatured ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    final statusName = (map['status'] ?? 'active').toString();
    final status = GoalStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => GoalStatus.active,
    );
    return GoalModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      category: (map['category'] ?? 'learning').toString(),
      status: status,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'].toString())
          : null,
      isFeatured: (map['is_featured'] == 1 || map['is_featured'] == true),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
