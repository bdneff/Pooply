//
//  NotificationService.swift
//  Pooply
//
//  Manages local push notifications for daily reminders
//

import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isEnabled: Bool = false
    @Published var reminderHour: Int = 9   // Default 9 AM
    @Published var reminderMinute: Int = 0

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let notificationsEnabled = "pooply_notificationsEnabled"
        static let reminderHour = "pooply_reminderHour"
        static let reminderMinute = "pooply_reminderMinute"
    }

    private enum Identifiers {
        static let dailyReminder = "pooply_daily_reminder"
    }

    private init() {
        // Load saved preferences
        isEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        let savedHour = defaults.integer(forKey: Keys.reminderHour)
        reminderHour = savedHour == 0 && !defaults.bool(forKey: Keys.notificationsEnabled) ? 9 : savedHour
        reminderMinute = defaults.integer(forKey: Keys.reminderMinute)

        // Verify system permission matches our state
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    @MainActor
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus != .authorized {
            isEnabled = false
            defaults.set(false, forKey: Keys.notificationsEnabled)
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Enable / Disable

    @MainActor
    func enableDailyReminder(hour: Int, minute: Int) async {
        let granted = await requestPermission()
        guard granted else {
            isEnabled = false
            return
        }

        reminderHour = hour
        reminderMinute = minute
        isEnabled = true

        // Persist
        defaults.set(true, forKey: Keys.notificationsEnabled)
        defaults.set(hour, forKey: Keys.reminderHour)
        defaults.set(minute, forKey: Keys.reminderMinute)

        // Schedule
        await scheduleDailyReminder()
    }

    @MainActor
    func disableReminder() {
        isEnabled = false
        defaults.set(false, forKey: Keys.notificationsEnabled)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifiers.dailyReminder]
        )
    }

    // MARK: - Update Time

    @MainActor
    func updateReminderTime(hour: Int, minute: Int) async {
        reminderHour = hour
        reminderMinute = minute
        defaults.set(hour, forKey: Keys.reminderHour)
        defaults.set(minute, forKey: Keys.reminderMinute)

        if isEnabled {
            await scheduleDailyReminder()
        }
    }

    // MARK: - Scheduling

    private func scheduleDailyReminder() async {
        // Remove existing
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifiers.dailyReminder]
        )

        let content = UNMutableNotificationContent()
        content.title = "Time to log!"
        content.body = randomReminderMessage()
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifiers.dailyReminder,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func randomReminderMessage() -> String {
        let messages = [
            "How's your gut feeling today? Take a moment to log.",
            "Your gut health journey continues — don't forget to log today!",
            "Quick check-in: have you logged today?",
            "Consistency is key! Log your poop to track your progress.",
            "Your gut will thank you. Time for a quick log!",
            "Stay on top of your digestive health — log now."
        ]
        return messages.randomElement() ?? messages[0]
    }
}
