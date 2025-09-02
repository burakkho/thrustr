import SwiftData
import Foundation

@Model
final class UserNotificationSettings {
    // MARK: - General Settings
    var isEnabled: Bool = true
    var lastUpdated: Date = Date()
    
    // MARK: - Workout Reminders
    var workoutRemindersEnabled: Bool = true
    var preferredWorkoutTime: Date = {
        let calendar = Calendar.current
        let components = DateComponents(hour: 18, minute: 0) // 6 PM default
        return calendar.date(from: components) ?? Date()
    }()
    var workoutReminderDays: [Int] = [1, 2, 3, 4, 5] // Monday to Friday
    
    // MARK: - Achievement Notifications
    var achievementNotificationsEnabled: Bool = true
    var achievementSoundEnabled: Bool = true
    
    // MARK: - Goal Reminders
    var dailyGoalRemindersEnabled: Bool = true
    var weeklyGoalRemindersEnabled: Bool = true
    var goalReminderTime: Date = {
        let calendar = Calendar.current
        let components = DateComponents(hour: 20, minute: 0) // 8 PM default
        return calendar.date(from: components) ?? Date()
    }()
    
    // MARK: - Streak Alerts
    var streakAlertsEnabled: Bool = true
    var streakReminderHours: Int = 2 // Hours before streak might break
    
    init() {}
    
    // MARK: - Convenience Methods
    func isNotificationTypeEnabled(_ type: NotificationType) -> Bool {
        switch type {
        case .workoutReminder:
            return workoutRemindersEnabled
        case .achievementUnlock:
            return achievementNotificationsEnabled
        case .goalReminder:
            return dailyGoalRemindersEnabled || weeklyGoalRemindersEnabled
        case .streakAlert:
            return streakAlertsEnabled
        }
    }
}