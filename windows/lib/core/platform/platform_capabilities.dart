import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// يحدد قدرات المنصة الحالية بدقة دون استيراد dart:io أو dart:ffi
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isWeb => kIsWeb;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isMobile => isAndroid || isIOS;

  /// مراقبة النوافذ الفعلية عبر Win32 متاحة حاليًا على Windows Desktop فقط
  static bool get supportsNativeWindowMonitor => isWindows;

  /// محرك التخزين المحلي المستخدم
  static String get storageEngineName {
    if (isWeb) return 'Web Local Storage';
    if (isDesktop) return 'SQLite FFI (Desktop)';
    return 'SQLite (Mobile)';
  }

  static String platformName({bool arabic = true}) {
    if (isWeb) return arabic ? 'الويب (المتصفح)' : 'Web';
    if (isWindows) return arabic ? 'ويندوز' : 'Windows';
    if (isAndroid) return arabic ? 'أندرويد' : 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return arabic ? 'غير معروف' : 'Unknown';
  }
}
