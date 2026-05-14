import Foundation
import UserNotifications
import UIKit

final class NotificationManager {
    static let shared = NotificationManager()
    private let nextReminderKey = "nextHydrationReminderTimestamp"
    private init() {}
    func sendTestIn5Seconds() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "AquaSave"
            content.body = "TEST ✅ se vedi questo, le notifiche funzionano"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(
                identifier: "test_notification",
                content: content,
                trigger: trigger
            )

            center.add(request, withCompletionHandler: nil)
        }
    }
    private let reminderID = "smart_hydration_reminder"

    /// Pianifica una notifica solo tra startHour e endHour.
    /// Se il reminder cadrebbe fuori fascia, viene spostato al prossimo orario valido.
    func scheduleSmartReminder(
        intervalMinutes: Int,
        startHour: Int = 8,
        endHour: Int = 1
    ) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            center.removePendingNotificationRequests(withIdentifiers: [self.reminderID])

            let calendar = Calendar.current
            let now = Date()

            var fireDate = now.addingTimeInterval(TimeInterval(intervalMinutes * 60))
            let hour = calendar.component(.hour, from: fireDate)

            let isWithinWindow: Bool

            if startHour < endHour {
                isWithinWindow = hour >= startHour && hour < endHour
            } else {
                isWithinWindow = hour >= startHour || hour < endHour
            }

            if !isWithinWindow {
                if hour >= endHour && hour < startHour {
                    fireDate = calendar.date(
                        bySettingHour: startHour,
                        minute: 0,
                        second: 0,
                        of: fireDate
                    ) ?? fireDate
                }
            }
            
            UserDefaults.standard.set(fireDate.timeIntervalSince1970, forKey: self.nextReminderKey)

            let seconds = max(10, fireDate.timeIntervalSinceNow)

            let content = UNMutableNotificationContent()
            content.title = "AquaSave"
            content.body = "Non bevi da un po’ — idratati 💧"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: seconds,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: self.reminderID,
                content: content,
                trigger: trigger
            )

            center.add(request, withCompletionHandler: nil)
        }
    }

    func cancelSmartReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }

    func openSystemSettings() {
        DispatchQueue.main.async {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers

    private func nextValidReminderDate(
        from baseDate: Date,
        intervalMinutes: Int,
        startHour: Int,
        endHour: Int
    ) -> Date {
        let calendar = Calendar.current
        let candidate = baseDate.addingTimeInterval(TimeInterval(intervalMinutes * 60))

        let hour = calendar.component(.hour, from: candidate)

        if hour >= startHour && hour < endHour {
            return candidate
        }

        if hour >= endHour {
            // domani alle startHour
            let nextDay = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            return calendar.date(
                bySettingHour: startHour,
                minute: 0,
                second: 0,
                of: nextDay
            ) ?? candidate
        } else {
            // oggi alle startHour
            return calendar.date(
                bySettingHour: startHour,
                minute: 0,
                second: 0,
                of: candidate
            ) ?? candidate
        }
    }
    func getNextReminderDate() -> Date? {
        let ts = UserDefaults.standard.double(forKey: nextReminderKey)
        guard ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
}


