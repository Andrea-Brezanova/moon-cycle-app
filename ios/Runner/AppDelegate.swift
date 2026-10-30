import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminders (flutter_local_notifications) also show while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PrivacyShield") {
      PrivacyShield.shared.register(with: registrar.messenger())
    }
  }
}

/// Covers the app with a plain opaque view the moment it stops being active,
/// so the picture iOS keeps for the app switcher shows nothing. Off unless the
/// user turns "Hide app in app switcher" on; the Dart side sends the setting.
final class PrivacyShield {
  static let shared = PrivacyShield()
  private static let defaultsKey = "privacyShieldEnabled"
  private static let coverTag = 0x4D43  // "MC"

  /// The setting is kept on the phone so the shield works from the first
  /// moment of a cold start, before Flutter has sent it.
  private(set) var enabled: Bool =
    UserDefaults.standard.bool(forKey: PrivacyShield.defaultsKey)

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "app.mooncycle/privacy_shield", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled", let on = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.enabled = on
      UserDefaults.standard.set(on, forKey: PrivacyShield.defaultsKey)
      if !on { self?.hide() }
      result(nil)
    }
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(show), name: UIApplication.willResignActiveNotification,
      object: nil)
    center.addObserver(
      self, selector: #selector(hide), name: UIApplication.didBecomeActiveNotification,
      object: nil)
  }

  private var windows: [UIWindow] {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
  }

  @objc private func show() {
    guard enabled else { return }
    for window in windows where window.viewWithTag(PrivacyShield.coverTag) == nil {
      let cover = UIView(frame: window.bounds)
      cover.tag = PrivacyShield.coverTag
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      cover.backgroundColor = .systemBackground
      window.addSubview(cover)
    }
  }

  @objc private func hide() {
    for window in windows {
      window.viewWithTag(PrivacyShield.coverTag)?.removeFromSuperview()
    }
  }
}
