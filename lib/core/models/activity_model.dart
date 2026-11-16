enum AppCategory {
  productive,
  educational,
  neutral,
  entertainment,
  distracting,
}

enum RuleType { allow, limit, block }

enum ControlLevel { level1Alert, level2Warning, level3ProcessControl }

class TrackedApplication {
  final String id;
  final String processName;
  final String? exePath;
  final String displayName;
  final AppCategory category;
  final bool isUserVerified;

  const TrackedApplication({
    required this.id,
    required this.processName,
    this.exePath,
    required this.displayName,
    required this.category,
    required this.isUserVerified,
  });

  factory TrackedApplication.fromMap(Map<String, Object?> map) {
    return TrackedApplication(
      id: map['id'] as String,
      processName: map['process_name'] as String,
      exePath: map['exe_path'] as String?,
      displayName: map['display_name'] as String,
      category: AppCategory.values.firstWhere(
        (e) => e.name == map['category_slug'],
        orElse: () => AppCategory.neutral,
      ),
      isUserVerified: (map['is_user_verified'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'process_name': processName,
        'exe_path': exePath,
        'display_name': displayName,
        'category_slug': category.name,
        'is_user_verified': isUserVerified ? 1 : 0,
      };
}

class ActivityRecordModel {
  final String id;
  final String applicationId;
  final String processName;
  final String displayName;
  final AppCategory category;
  final String? windowTitleMasked;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final bool isIdle;
  final String? focusSessionId;

  const ActivityRecordModel({
    required this.id,
    required this.applicationId,
    required this.processName,
    required this.displayName,
    required this.category,
    this.windowTitleMasked,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required this.isIdle,
    this.focusSessionId,
  });
}

class DistractionRuleModel {
  final String id;
  final String applicationId;
  final String processName;
  final String displayName;
  final RuleType ruleType;
  final ControlLevel actionLevel;
  final String? sessionMode;
  final int? dailyLimitMin;
  final bool isEnabled;

  const DistractionRuleModel({
    required this.id,
    required this.applicationId,
    required this.processName,
    required this.displayName,
    required this.ruleType,
    required this.actionLevel,
    this.sessionMode,
    this.dailyLimitMin,
    required this.isEnabled,
  });
}

class WebsiteRuleModel {
  final String id;
  final String domainPattern;
  final RuleType ruleType;
  final bool isEnabled;

  const WebsiteRuleModel({
    required this.id,
    required this.domainPattern,
    required this.ruleType,
    required this.isEnabled,
  });
}
