enum AiProviderType { offlineAnalyzer, ollamaLocal, geminiCloud }

class UserSettingsModel {
  final String languageCode; // 'ar' | 'en'
  final bool isDarkMode;
  final bool monitoringEnabled;
  final bool storeWindowTitles; // افتراضيًا false لحماية الخصوصية
  final int idleThresholdSec;
  final int retentionDays;
  final AiProviderType aiProvider;
  final bool aiCloudConsent;
  final String ollamaEndpoint;
  final String ollamaModel;
  final String geminiApiKey;

  const UserSettingsModel({
    this.languageCode = 'ar',
    this.isDarkMode = true,
    this.monitoringEnabled = true,
    this.storeWindowTitles = false,
    this.idleThresholdSec = 180,
    this.retentionDays = 90,
    this.aiProvider = AiProviderType.offlineAnalyzer,
    this.aiCloudConsent = false,
    this.ollamaEndpoint = 'http://localhost:11434',
    this.ollamaModel = 'llama3.1',
    this.geminiApiKey = '',
  });

  UserSettingsModel copyWith({
    String? languageCode,
    bool? isDarkMode,
    bool? monitoringEnabled,
    bool? storeWindowTitles,
    int? idleThresholdSec,
    int? retentionDays,
    AiProviderType? aiProvider,
    bool? aiCloudConsent,
    String? ollamaEndpoint,
    String? ollamaModel,
    String? geminiApiKey,
  }) {
    return UserSettingsModel(
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
      storeWindowTitles: storeWindowTitles ?? this.storeWindowTitles,
      idleThresholdSec: idleThresholdSec ?? this.idleThresholdSec,
      retentionDays: retentionDays ?? this.retentionDays,
      aiProvider: aiProvider ?? this.aiProvider,
      aiCloudConsent: aiCloudConsent ?? this.aiCloudConsent,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}

class AiMessageModel {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final String providerLabel;
  final DateTime createdAt;

  const AiMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.providerLabel,
    required this.createdAt,
  });
}
