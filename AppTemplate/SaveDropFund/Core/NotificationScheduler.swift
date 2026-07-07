import Foundation
import UserNotifications

enum NotificationPreferenceKey: String, CaseIterable {
    case dropReminders
    case newChallenges
    case goalMilestones
    case savingsTips
    case weeklySummary

    var title: String {
        switch self {
        case .dropReminders: "Drop Reminders"
        case .newChallenges: "New Challenges"
        case .goalMilestones: "Goal Milestones"
        case .savingsTips: "Savings Tips"
        case .weeklySummary: "Weekly Summary"
        }
    }

    var subtitle: String {
        switch self {
        case .dropReminders: "Daily prompts to make your savings drop"
        case .newChallenges: "Be notified when a new challenge unlocks"
        case .goalMilestones: "Celebrate every 25% goal progress"
        case .savingsTips: "Weekly money-saving ideas"
        case .weeklySummary: "Your savings recap every Sunday"
        }
    }

    var defaultValue: Bool {
        switch self {
        case .savingsTips: false
        default: true
        }
    }
}

@MainActor
enum NotificationPreferences {
    static func isEnabled(_ key: NotificationPreferenceKey) -> Bool {
        if UserDefaults.standard.object(forKey: key.rawValue) == nil {
            return key.defaultValue
        }
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func setEnabled(_ enabled: Bool, for key: NotificationPreferenceKey) {
        UserDefaults.standard.set(enabled, forKey: key.rawValue)
    }
}

enum NotificationScheduler {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    @MainActor static func scheduleChallengeReminder(challenge: Challenge) {
        guard NotificationPreferences.isEnabled(.newChallenges) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Challenge Check-In"
        content.body = challenge.conditionText
        content.sound = .default

        let triggerDate = challenge.dueDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: challenge.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    @MainActor static func scheduleDropReminder() {
        guard NotificationPreferences.isEnabled(.dropReminders) else { return }

        var components = DateComponents()
        components.hour = 19
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Time for a Drop"
        content.body = "Convert today's savings into balls and fund your goals."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dropReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    @MainActor static func scheduleWeeklySummary() {
        guard NotificationPreferences.isEnabled(.weeklySummary) else { return }

        var components = DateComponents()
        components.weekday = 1
        components.hour = 10

        let content = UNMutableNotificationContent()
        content.title = "Weekly Summary"
        content.body = "See how your savings grew this week."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklySummary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    @MainActor static func notifyGoalMilestone(goalName: String, percent: Int) {
        guard NotificationPreferences.isEnabled(.goalMilestones) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal Milestone!"
        content.body = "\(goalName) reached \(percent)% — keep going!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone-\(goalName)-\(percent)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
