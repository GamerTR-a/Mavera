import Flutter
import UIKit
import UserNotifications

/// KARAR (R3): Klasik (UIScene'siz) yaşam döngüsü. iOS uygulamayı Bluetooth durum
/// geri yüklemesiyle arka planda yeniden başlattığında sahne oluşturulmaz; klasik
/// yaşam döngüsünde Main.storyboard'daki FlutterViewController ve motoru
/// didFinishLaunching sırasında yüklenir, böylece Dart çekirdeği ekransız da çalışır.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "BackgroundTaskPlugin") {
      BackgroundTaskPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Kullanıcı uygulamayı yukarı kaydırarak kapatırsa iOS onu Bluetooth ile
  /// tekrar uyandırmaz: "Koruma durdu" bildirimi zamanlanır.
  override func applicationWillTerminate(_ application: UIApplication) {
    let content = UNMutableNotificationContent()
    content.title = "Koruma durdu"
    content.body = "Yeniden açmak için dokun."
    content.sound = .default
    if #available(iOS 15.0, *) {
      content.interruptionLevel = .timeSensitive
    }
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    // "302": Dart'taki AppNotificationKind.protectionStopped kimliği; açılışta oradan iptal edilir.
    let request = UNNotificationRequest(identifier: "302", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    super.applicationWillTerminate(application)
  }
}

// KARAR: Xcode projesine ayrı dosya eklemeden derlensin diye AppDelegate.swift içinde.

/// guvenyuzuk/background_task: alarm gönderimi için ek arka plan süresi
/// (`UIApplication.beginBackgroundTask` / `endBackgroundTask`).
final class BackgroundTaskPlugin: NSObject, FlutterPlugin {
  private var tasks: [Int: UIBackgroundTaskIdentifier] = [:]
  private var nextId = 1

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "guvenyuzuk/background_task", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(BackgroundTaskPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "begin":
      let id = nextId
      nextId += 1
      let task = UIApplication.shared.beginBackgroundTask(withName: "GuvenYuzukAlarm") { [weak self] in
        self?.end(id)
      }
      tasks[id] = task
      result(id)
    case "end":
      if let args = call.arguments as? [String: Any], let id = args["id"] as? Int {
        end(id)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func end(_ id: Int) {
    guard let task = tasks.removeValue(forKey: id) else { return }
    UIApplication.shared.endBackgroundTask(task)
  }
}

