#include "azm_monitor_plugin.h"

#include <psapi.h>
#include <vector>

AzmMonitorPlugin* AzmMonitorPlugin::active_instance_ = nullptr;

namespace {
std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return "";
  std::string out(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, out.data(), size, nullptr, nullptr);
  return out;
}
}  // namespace

AzmMonitorPlugin::AzmMonitorPlugin() {
  active_instance_ = this;
}

AzmMonitorPlugin::~AzmMonitorPlugin() {
  StopMonitoring();
  if (active_instance_ == this) {
    active_instance_ = nullptr;
  }
}

void AzmMonitorPlugin::RegisterWithMessenger(flutter::BinaryMessenger* messenger) {
  auto plugin = std::make_shared<AzmMonitorPlugin>();

  auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "azm_ai/activity_control", &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [plugin](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "startMonitoring") {
          bool capture_title = false;
          if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto it = args->find(flutter::EncodableValue("captureWindowTitle"));
            if (it != args->end()) {
              if (const auto* b = std::get_if<bool>(&it->second)) {
                capture_title = *b;
              }
            }
          }
          plugin->StartMonitoring(capture_title);
          result->Success(flutter::EncodableValue(true));
        } else if (call.method_name() == "stopMonitoring") {
          plugin->StopMonitoring();
          result->Success(flutter::EncodableValue(true));
        } else if (call.method_name() == "getIdleSeconds") {
          result->Success(flutter::EncodableValue(static_cast<int>(GetIdleSeconds())));
        } else {
          result->NotImplemented();
        }
      });

  auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      messenger, "azm_ai/activity_events", &flutter::StandardMethodCodec::GetInstance());

  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [plugin](const flutter::EncodableValue* arguments,
               std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        plugin->event_sink_ = std::move(events);
        HWND fg = GetForegroundWindow();
        if (fg != nullptr) {
          plugin->EmitForegroundWindow(fg);
        }
        return nullptr;
      },
      [plugin](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        plugin->event_sink_.reset();
        return nullptr;
      });

  event_channel->SetStreamHandler(std::move(handler));
}

void AzmMonitorPlugin::StartMonitoring(bool capture_window_title) {
  capture_window_title_ = capture_window_title;
  if (hook_ != nullptr) return;
  hook_ = SetWinEventHook(
      EVENT_SYSTEM_FOREGROUND,
      EVENT_SYSTEM_FOREGROUND,
      nullptr,
      WinEventProc,
      0,
      0,
      WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS);
}

void AzmMonitorPlugin::StopMonitoring() {
  if (hook_ != nullptr) {
    UnhookWinEvent(hook_);
    hook_ = nullptr;
  }
}

void CALLBACK AzmMonitorPlugin::WinEventProc(HWINEVENTHOOK hook,
                                             DWORD event,
                                             HWND hwnd,
                                             LONG id_object,
                                             LONG id_child,
                                             DWORD event_thread,
                                             DWORD event_time) {
  if (event == EVENT_SYSTEM_FOREGROUND && active_instance_ != nullptr && hwnd != nullptr) {
    active_instance_->EmitForegroundWindow(hwnd);
  }
}

DWORD AzmMonitorPlugin::GetIdleSeconds() {
  LASTINPUTINFO lii{};
  lii.cbSize = sizeof(LASTINPUTINFO);
  if (!GetLastInputInfo(&lii)) return 0;
  DWORD elapsed_ms = GetTickCount() - lii.dwTime;
  return elapsed_ms / 1000;
}

void AzmMonitorPlugin::EmitForegroundWindow(HWND hwnd) {
  if (!event_sink_) return;

  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0) return;

  std::string exe_path_utf8;
  std::string process_name = "unknown.exe";

  HANDLE h_proc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (h_proc != nullptr) {
    wchar_t path_buf[MAX_PATH] = {0};
    DWORD size = MAX_PATH;
    if (QueryFullProcessImageNameW(h_proc, 0, path_buf, &size)) {
      std::wstring full_path(path_buf, size);
      exe_path_utf8 = WideToUtf8(full_path);
      auto pos = exe_path_utf8.find_last_of("\\/");
      if (pos != std::string::npos) {
        process_name = exe_path_utf8.substr(pos + 1);
      } else {
        process_name = exe_path_utf8;
      }
    }
    CloseHandle(h_proc);
  }

  std::string title_utf8;
  if (capture_window_title_) {
    wchar_t title_buf[256] = {0};
    int len = GetWindowTextW(hwnd, title_buf, 256);
    if (len > 0) {
      title_utf8 = WideToUtf8(std::wstring(title_buf, len));
    }
  }

  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("processName")] = flutter::EncodableValue(process_name);
  payload[flutter::EncodableValue("processId")] = flutter::EncodableValue(static_cast<int>(pid));
  payload[flutter::EncodableValue("exePath")] = flutter::EncodableValue(exe_path_utf8);
  payload[flutter::EncodableValue("windowTitle")] = flutter::EncodableValue(title_utf8);
  payload[flutter::EncodableValue("isIdle")] = flutter::EncodableValue(false);

  event_sink_->Success(flutter::EncodableValue(payload));
}
