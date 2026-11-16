import 'activity_bridge.dart';

class _StubActivityBridge implements ActivityBridge {
  @override
  Future<bool> isNativeMonitorAvailable() async => false;

  @override
  Future<bool> startNativeMonitor({bool captureWindowTitle = false}) async =>
      false;

  @override
  Future<void> stopNativeMonitor() async {}

  @override
  Stream<Map<String, dynamic>> nativeActivityStream() =>
      const Stream<Map<String, dynamic>>.empty();
}

ActivityBridge createActivityBridge() => _StubActivityBridge();
