import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // iOS 상태 복원이 Flutter와 충돌해서 재시작 시 크래시 발생 — 비활성화
  override func application(
    _ application: UIApplication,
    shouldRestoreSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }

  override func application(
    _ application: UIApplication,
    shouldSaveSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }
}
