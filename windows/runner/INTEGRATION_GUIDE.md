# دليل ربط إضافة المراقبة الأصلية `AzmMonitorPlugin` على Windows

1. بعد تنفيذ `flutter create --platforms=windows .` داخل مجلد `azm_ai`، أضف الملفين `azm_monitor_plugin.h` و`azm_monitor_plugin.cpp` إلى `windows/runner/CMakeLists.txt`.
2. في ملف `windows/runner/flutter_window.cpp` داخل `FlutterWindow::OnCreate()`:
```cpp
#include "azm_monitor_plugin.h"
// بعد RegisterPlugins(flutter_controller_->engine());
AzmMonitorPlugin::RegisterWithMessenger(
    flutter_controller_->engine()->messenger());
```
3. أعد البناء عبر `flutter run -d windows`.
