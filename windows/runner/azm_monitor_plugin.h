#ifndef AZM_MONITOR_PLUGIN_H_
#define AZM_MONITOR_PLUGIN_H_

#include <flutter/binary_messenger.h>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <string>

class AzmMonitorPlugin {
 public:
  static void RegisterWithMessenger(flutter::BinaryMessenger* messenger);

  AzmMonitorPlugin();
  ~AzmMonitorPlugin();

 private:
  void StartMonitoring(bool capture_window_title);
  void StopMonitoring();
  void EmitForegroundWindow(HWND hwnd);
  static void CALLBACK WinEventProc(HWINEVENTHOOK hook,
                                    DWORD event,
                                    HWND hwnd,
                                    LONG id_object,
                                    LONG id_child,
                                    DWORD event_thread,
                                    DWORD event_time);
  static DWORD GetIdleSeconds();

  HWINEVENTHOOK hook_ = nullptr;
  bool capture_window_title_ = false;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  static AzmMonitorPlugin* active_instance_;
};

#endif  // AZM_MONITOR_PLUGIN_H_
