import Foundation
import UIKit
import UserNotifications

final class Reminder: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = Reminder()

    private let dailyKey = "daily.on"
    private let hourKey = "daily.hour"
    private let minuteKey = "daily.minute"
    private let dailyId = "daily"

    @Published var dailyOn: Bool {
        didSet {
            UserDefaults.standard.set(dailyOn, forKey: dailyKey)
            applyDaily()
        }
    }
    @Published var time: Date {
        didSet {
            UserDefaults.standard.set(Calendar.current.component(.hour, from: time), forKey: hourKey)
            UserDefaults.standard.set(Calendar.current.component(.minute, from: time), forKey: minuteKey)
            applyDaily()
        }
    }
    @Published var status: UNAuthorizationStatus = .notDetermined

    private override init() {
        let d = UserDefaults.standard
        dailyOn = d.bool(forKey: dailyKey)
        let h = d.object(forKey: hourKey) as? Int ?? 20
        let m = d.object(forKey: minuteKey) as? Int ?? 0
        time = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        super.init()

        UNUserNotificationCenter.current().delegate = self
        refreshStatus()
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { self.status = settings.authorizationStatus }
        }
    }

    func ask() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshStatus()
                if !granted { self.dailyOn = false }
                if granted { self.dailyOn = true }
            }
        }
    }

    func applyDaily() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyId])
        guard dailyOn else { return }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = "Logbuch"
        content.body = "Heute noch nichts eingetragen. Zwei Zeilen reichen."
        content.sound = .default

        center.add(UNNotificationRequest(
            identifier: dailyId,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        ))
    }

    /// Einmalige Erinnerung in `minutes`, Inhalt aus der Web-App.
    func later(title: String, body: String, minutes: Double, id: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(5, minutes * 60), repeats: false)
        ))
    }

    func test() {
        later(title: "Logbuch", body: "Benachrichtigungen laufen.", minutes: 0.05)
    }

    func openSystem() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
