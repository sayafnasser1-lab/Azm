import 'package:flutter/services.dart';
import 'activity_bridge.dart';
import 'platform_capabilities.dart';

class _IoActivityBridge implements ActivityBridge {
  static const MethodChannel _control = MethodChannel('azm_ai/activity_control');
  static const EventChannel _events = EventChannel('azm_ai/activity_events');

  @override
  Future<bool> isNativeMonitorAvailable() async {
    if (!PlatformCapabilities.supportsNativeWindowMonitor) return false;
    try {
      final res = await _control.invokeMethod<bool>('ping');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> startNativeMonitor({bool captureWindowTitle = false}) async {
    if (!PlatformCapabilities.supportsNativeWindowMonitor) return false;
    try {
      final started = await _control.invokeMethod<bool>('startMonitor', {
        'captureWindowTitle': captureWindowTitle,
      });
      return started ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stopNativeMonitor() async {
    if (!PlatformCapabilities.supportsNativeWindowMonitor) return;
    try {
      await _control.invokeMethod<void>('stopMonitor');
    } on MissingPluginException {
      // آمن في حال عدم ربط الإضافة الأصلية بعد
    } on PlatformException {
      // تجاهل آمن عند الإيقاف
    }
  }

  @override
  Stream<Map<String, dynamic>> nativeActivityStream() {
    if (!PlatformCapabilities.supportsNativeWindowMonitor) {
      return const Stream<Map<String, dynamic>>.empty();
    }
    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    }).handleError((_) {});
  }
}

ActivityBridge createActivityBridge() => _IoActivityBridge();
