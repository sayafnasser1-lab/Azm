class HabitModel {
  final String id;
  final String title;
  final String iconName; // workout, read, hydrate, sleep, code, quran
  final int targetPerDay;
  final int completedToday;
  final int streakDays;
  final int colorHex;
  final String lastUpdatedDate; // YYYY-MM-DD

  const HabitModel({
    required this.id,
    required this.title,
    required this.iconName,
    this.targetPerDay = 1,
    this.completedToday = 0,
    this.streakDays = 0,
    this.colorHex = 0xFF4338CA,
    required this.lastUpdatedDate,
  });

  double get ratio =>
      targetPerDay <= 0 ? 0 : (completedToday / targetPerDay).clamp(0.0, 1.0);

  HabitModel copyWith({
    String? title,
    String? iconName,
    int? targetPerDay,
    int? completedToday,
    int? streakDays,
    int? colorHex,
    String? lastUpdatedDate,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      completedToday: completedToday ?? this.completedToday,
      streakDays: streakDays ?? this.streakDays,
      colorHex: colorHex ?? this.colorHex,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon_name': iconName,
        'target_per_day': targetPerDay,
        'completed_today': completedToday,
        'streak_days': streakDays,
        'color_hex': colorHex,
        'last_updated_date': lastUpdatedDate,
      };

  factory HabitModel.fromMap(Map<String, dynamic> map) => HabitModel(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        iconName: (map['icon_name'] ?? 'read').toString(),
        targetPerDay: (map['target_per_day'] as num?)?.toInt() ?? 1,
        completedToday: (map['completed_today'] as num?)?.toInt() ?? 0,
        streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
        colorHex: (map['color_hex'] as num?)?.toInt() ?? 0xFF4338CA,
        lastUpdatedDate: (map['last_updated_date'] ?? '').toString(),
      );
}
