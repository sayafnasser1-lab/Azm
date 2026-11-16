import 'activity_bridge_stub.dart'
    if (dart.library.io) 'activity_bridge_io.dart';

/// جسر مراقبة النشاط متعدد الأنظمة
/// على Windows يتصل بـ Win32 MethodChannel، وعلى بقية الأنظمة يعمل بأمان دون أخطاء
abstract class ActivityBridge {
  factory ActivityBridge() => createActivityBridge();

  Future<bool> isNativeMonitorAvailable();
  Future<bool> startNativeMonitor({bool captureWindowTitle = false});
  Future<void> stopNativeMonitor();
  Stream<Map<String, dynamic>> nativeActivityStream();
}
