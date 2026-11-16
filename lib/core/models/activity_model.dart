class ActivityEventModel {
  final String id;
  final String appName;
  final String? windowTitle;
  final String category; // productive, neutral, distracting
  final int durationSeconds;
  final bool isIdle;
  final DateTime recordedAt;

  const ActivityEventModel({
    required this.id,
    required this.appName,
    this.windowTitle,
    required this.category,
    required this.durationSeconds,
    this.isIdle = false,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'app_name': appName,
        'window_title': windowTitle,
        'category': category,
        'duration_seconds': durationSeconds,
        'is_idle': isIdle ? 1 : 0,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory ActivityEventModel.fromMap(Map<String, dynamic> map) =>
      ActivityEventModel(
        id: (map['id'] ?? '').toString(),
        appName: (map['app_name'] ?? 'unknown').toString(),
        windowTitle: map['window_title']?.toString(),
        category: (map['category'] ?? 'neutral').toString(),
        durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
        isIdle: (map['is_idle'] == 1 || map['is_idle'] == true),
        recordedAt: DateTime.tryParse((map['recorded_at'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class DistractionRuleModel {
  final String id;
  final String targetName; // e.g. discord.exe, youtube.com
  final String ruleType; // app, domain
  final int actionLevel; // 1=alert, 2=delay, 3=close_prompt
  final bool isEnabled;

  const DistractionRuleModel({
    required this.id,
    required this.targetName,
    this.ruleType = 'app',
    this.actionLevel = 2,
    this.isEnabled = true,
  });

  DistractionRuleModel copyWith({
    String? targetName,
    String? ruleType,
    int? actionLevel,
    bool? isEnabled,
  }) {
    return DistractionRuleModel(
      id: id,
      targetName: targetName ?? this.targetName,
      ruleType: ruleType ?? this.ruleType,
      actionLevel: actionLevel ?? this.actionLevel,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'target_name': targetName,
        'rule_type': ruleType,
        'action_level': actionLevel,
        'is_enabled': isEnabled ? 1 : 0,
      };

  factory DistractionRuleModel.fromMap(Map<String, dynamic> map) =>
      DistractionRuleModel(
        id: (map['id'] ?? '').toString(),
        targetName: (map['target_name'] ?? '').toString(),
        ruleType: (map['rule_type'] ?? 'app').toString(),
        actionLevel: (map['action_level'] as num?)?.toInt() ?? 2,
        isEnabled: (map['is_enabled'] == 1 || map['is_enabled'] == true),
      );
}
