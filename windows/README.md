# AZM AI (عزم) — تطبيق سطح المكتب (Flutter + Windows Native)

منظومة ذكية مستقلة لإدارة التركيز ومقاومة التشتت الرقمي، تعمل بمبدأ **Offline-First** مع مراقبة نشاط Windows بموافقة المستخدم، ومحرك ذكاء اصطناعي هجين (تحليل محلي دون إنترنت + دعم النماذج المحلية والسحابية).

## المعمارية والتقنيات
- **واجهة المستخدم والمنطق:** Flutter (Dart) مع `flutter_riverpod` وMaterial 3 ودعم كامل للعربية (RTL) والإنجليزية (LTR) والوضعين الداكن والفاتح.
- **قاعدة البيانات المحلية:** SQLite عبر `sqflite_common_ffi` بوضع `WAL` مع تفعيل `foreign_keys` ونظام `Migrations` والنسخ الاحتياطي.
- **التكامل الأصلي مع Windows:** إضافة C++ Win32 مدمجة في `windows/runner/azm_monitor_plugin.cpp` تعمل داخل جلسة المستخدم (User Session) وتستخدم:
  - `SetWinEventHook` (`EVENT_SYSTEM_FOREGROUND`) لمراقبة النوافذ النشطة بالأحداث.
  - `GetForegroundWindow` و`GetWindowThreadProcessId` و`QueryFullProcessImageNameW`.
  - `GetLastInputInfo` لاكتشاف فترات الخمول.
- **الخصوصية:** لا تسجيل لضغطات المفاتيح، لا لقطات شاشة، وعنوان النافذة معطل افتراضيًا (`store_window_titles = false`).

## متطلبات التشغيل على Windows
1. [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (`>= 3.24.0`).
2. Visual Studio 2022 مع حزمة **Desktop development with C++** (لبناء تطبيق Windows والإضافة الأصلية).
3. تشغيل الأوامر التالية داخل مجلد `azm_ai`:
```powershell
flutter create --platforms=windows .
flutter pub get
flutter run -d windows
```
> **ملاحظة:** لتفعيل إضافة `AzmMonitorPlugin` في مشروع Windows المُنشأ عبر `flutter create`، راجع التعليمات في `windows/runner/INTEGRATION_GUIDE.md`.

## الاختبارات
```powershell
flutter test
```
