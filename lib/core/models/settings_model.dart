import 'dart:convert';

class AppSettingsModel {
  final String userName;
  final String userRole;
  final String languageCode; // ar, en
  final bool isDarkMode;
  final bool activityMonitorConsent;
  final bool storeWindowTitles; // false افتراضيًا لحماية الخصوصية
  final int dataRetentionDays;
  final String aiProviderMode; // local_offline, ollama, gemini_cloud
  final bool cloudAiConsent;
  final String ollamaEndpoint;
  final String ollamaModel;
  final int defaultPomodoroMinutes;
  final int defaultDeepWorkMinutes;

  const AppSettingsModel({
    this.userName = 'سياف',
    this.userRole = 'مستخدم عزم',
    this.languageCode = 'ar',
    this.isDarkMode = false,
    this.activityMonitorConsent = false,
    this.storeWindowTitles = false,
    this.dataRetentionDays = 30,
    this.aiProviderMode = 'local_offline',
    this.cloudAiConsent = false,
    this.ollamaEndpoint = 'http://localhost:11434',
    this.ollamaModel = 'llama3.2',
    this.defaultPomodoroMinutes = 25,
    this.defaultDeepWorkMinutes = 50,
  });

  AppSettingsModel copyWith({
    String? userName,
    String? userRole,
    String? languageCode,
    bool? isDarkMode,
    bool? activityMonitorConsent,
    bool? storeWindowTitles,
    int? dataRetentionDays,
    String? aiProviderMode,
    bool? cloudAiConsent,
    String? ollamaEndpoint,
    String? ollamaModel,
    int? defaultPomodoroMinutes,
    int? defaultDeepWorkMinutes,
  }) {
    return AppSettingsModel(
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      activityMonitorConsent:
          activityMonitorConsent ?? this.activityMonitorConsent,
      storeWindowTitles: storeWindowTitles ?? this.storeWindowTitles,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      aiProviderMode: aiProviderMode ?? this.aiProviderMode,
      cloudAiConsent: cloudAiConsent ?? this.cloudAiConsent,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      defaultPomodoroMinutes:
          defaultPomodoroMinutes ?? this.defaultPomodoroMinutes,
      defaultDeepWorkMinutes:
          defaultDeepWorkMinutes ?? this.defaultDeepWorkMinutes,
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'user_name': userName,
        'user_role': userRole,
        'language_code': languageCode,
        'is_dark_mode': isDarkMode,
        'activity_monitor_consent': activityMonitorConsent,
        'store_window_titles': storeWindowTitles,
        'data_retention_days': dataRetentionDays,
        'ai_provider_mode': aiProviderMode,
        'cloud_ai_consent': cloudAiConsent,
        'ollama_endpoint': ollamaEndpoint,
        'ollama_model': ollamaModel,
        'default_pomodoro_minutes': defaultPomodoroMinutes,
        'default_deep_work_minutes': defaultDeepWorkMinutes,
      };

  String toJsonString() => jsonEncode(toJsonMap());

  factory AppSettingsModel.fromJsonMap(Map<String, dynamic> map) =>
      AppSettingsModel(
        userName: (map['user_name'] ?? 'سياف').toString(),
        userRole: (map['user_role'] ?? 'مستخدم عزم').toString(),
        languageCode: (map['language_code'] ?? 'ar').toString(),
        isDarkMode: map['is_dark_mode'] == true,
        activityMonitorConsent: map['activity_monitor_consent'] == true,
        storeWindowTitles: map['store_window_titles'] == true,
        dataRetentionDays: (map['data_retention_days'] as num?)?.toInt() ?? 30,
        aiProviderMode: (map['ai_provider_mode'] ?? 'local_offline').toString(),
        cloudAiConsent: map['cloud_ai_consent'] == true,
        ollamaEndpoint:
            (map['ollama_endpoint'] ?? 'http://localhost:11434').toString(),
        ollamaModel: (map['ollama_model'] ?? 'llama3.2').toString(),
        defaultPomodoroMinutes:
            (map['default_pomodoro_minutes'] as num?)?.toInt() ?? 25,
        defaultDeepWorkMinutes:
            (map['default_deep_work_minutes'] as num?)?.toInt() ?? 50,
      );
}
