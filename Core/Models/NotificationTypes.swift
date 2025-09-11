import Foundation

// MARK: - Notification Types
enum NotificationType: String, CaseIterable, Sendable {
    case workoutReminder = "workout_reminder"
    case achievementUnlock = "achievement_unlock" 
    case goalReminder = "goal_reminder"
    case streakAlert = "streak_alert"
}

// MARK: - Notification Content Protocol
protocol NotificationContent {
    var identifier: String { get }
    var title: String { get }
    var body: String { get }
    var categoryIdentifier: String { get }
}

// MARK: - Schedulable Protocol
protocol Schedulable {
    var triggerDate: Date { get }
    var repeatInterval: NotificationRepeatInterval? { get }
}

// MARK: - Repeat Intervals
enum NotificationRepeatInterval: Sendable {
    case daily
    case weekly
    case custom(TimeInterval)
}

// MARK: - Notification Priority
enum NotificationPriority: Sendable {
    case low
    case normal
    case high
}