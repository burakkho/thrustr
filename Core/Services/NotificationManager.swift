@preconcurrency import UserNotifications
import SwiftUI

// MARK: - Helper Enums
enum DayOfWeek: Int, CaseIterable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var calendarWeekday: Int {
        // iOS Calendar uses 1 = Sunday, 2 = Monday, etc.
        return self == .sunday ? 1 : rawValue + 1
    }
}

@MainActor
@Observable
final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var settings: UserNotificationSettings?
    
    /// Single source of truth for notification enablement
    var isEnabled: Bool {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return false }
        return settings?.isEnabled ?? true
    }
    
    /// Indicates if notifications are in provisional (silent) mode
    var isProvisional: Bool {
        return authorizationStatus == .provisional
    }
    
    /// User-friendly status description
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "notifications.status.not_determined".localized
        case .denied: return "notifications.status.denied".localized
        case .authorized: return "notifications.status.authorized".localized
        case .provisional: return "notifications.status.provisional".localized
        case .ephemeral: return "notifications.status.ephemeral".localized
        @unknown default: return "notifications.status.unknown".localized
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task { 
            await updateAuthorizationStatus() 
            startPermissionMonitoring()
        }
    }
    
    /// Monitors app state changes to update permission status
    private func startPermissionMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { 
                await self?.updateAuthorizationStatus() 
            }
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        #if DEBUG
        print("🔔 Requesting notification authorization...")
        #endif
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        await updateAuthorizationStatus()
        
        #if DEBUG
        print("🔔 Authorization granted: \(granted)")
        #endif
        
        if granted {
            await registerCategories()
            #if DEBUG
            print("🔔 Notification categories registered")
            #endif
        }
    }
    
    func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        #if DEBUG
        print("🔔 Notification authorization status: \(authorizationStatus.rawValue) (\(authorizationStatusString))")
        #endif
    }
    
    private var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    // MARK: - Categories Registration
    private func registerCategories() async {
        let categories: [UNNotificationCategory] = [
            UNNotificationCategory(
                identifier: NotificationType.workoutReminder.rawValue,
                actions: [],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: NotificationType.achievementUnlock.rawValue,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ]
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    // MARK: - Schedule Notifications
    func scheduleNotification<T: NotificationContent & Schedulable>(
        _ content: T,
        priority: NotificationPriority = .normal
    ) async throws {
        guard authorizationStatus == .authorized else { return }
        
        let request = createNotificationRequest(content, priority: priority)
        try await notificationCenter.add(request)
    }
    
    private func createNotificationRequest<T: NotificationContent & Schedulable>(
        _ content: T,
        priority: NotificationPriority
    ) -> UNNotificationRequest {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.categoryIdentifier = content.categoryIdentifier
        
        // Set priority
        switch priority {
        case .high:
            notificationContent.sound = .default
            notificationContent.badge = 1
        case .normal:
            notificationContent.sound = .default
        case .low:
            notificationContent.sound = nil
        }
        
        let trigger = createTrigger(for: content)
        return UNNotificationRequest(
            identifier: content.identifier,
            content: notificationContent,
            trigger: trigger
        )
    }
    
    private func createTrigger<T: NotificationContent & Schedulable>(
        for content: T
    ) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: content.triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: content.repeatInterval != nil
        )
        
        return trigger
    }
    
    // MARK: - Cancel Notifications
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Settings Integration
    
    /// Opens iOS Settings app to notification settings
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Checks if user can enable notifications via system settings
    var canEnableNotifications: Bool {
        authorizationStatus != .denied
    }
    
    // MARK: - Test Notification
    
    /// Schedule a test notification for immediate delivery (for testing purposes)
    func scheduleTestNotification() async throws {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Test Notification"
        content.body = "Your notification system is working perfectly!"
        content.categoryIdentifier = NotificationType.achievementUnlock.rawValue
        content.sound = authorizationStatus == .authorized ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        #if DEBUG
        print("🔔 Test notification scheduled for 2 seconds")
        #endif
    }
    
    // MARK: - Workout Reminders
    
    /// Schedule daily workout reminder notifications
    func scheduleWorkoutReminders() async throws {
        guard let settings = settings, settings.workoutRemindersEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing workout reminders
        await cancelNotifications(withPrefix: "workout-reminder")
        
        // Get preferred workout time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.preferredWorkoutTime)
        
        // Schedule for each enabled day
        for dayIndex in settings.workoutReminderDays {
            guard let weekday = DayOfWeek(rawValue: dayIndex) else { continue }
            
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday.calendarWeekday
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            let content = UNMutableNotificationContent()
            content.title = "🏋️‍♂️ " + "notifications.workout.title".localized
            content.body = "notifications.workout.body".localized
            content.categoryIdentifier = NotificationType.workoutReminder.rawValue
            content.sound = authorizationStatus == .authorized ? .default : nil
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "workout-reminder-\(dayIndex)",
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
        
        #if DEBUG
        print("🔔 Workout reminders scheduled for \(settings.workoutReminderDays.count) days")
        #endif
    }
    
    /// Schedule an achievement unlock notification
    func scheduleAchievementNotification(title: String, description: String, delay: TimeInterval = 1.0) async throws {
        guard let settings = settings, settings.achievementNotificationsEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 " + title
        content.body = description
        content.categoryIdentifier = NotificationType.achievementUnlock.rawValue
        content.sound = authorizationStatus == .authorized && settings.achievementSoundEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        #if DEBUG
        print("🔔 Achievement notification scheduled: \(title)")
        #endif
    }
    
    /// Schedule goal reminder notifications
    func scheduleGoalReminders() async throws {
        guard let settings = settings, settings.dailyGoalRemindersEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing goal reminders
        await cancelNotifications(withPrefix: "goal-reminder")
        
        // Schedule daily goal reminder
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.goalReminderTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 " + "notifications.goal.title".localized
        content.body = "notifications.goal.body".localized
        content.categoryIdentifier = NotificationType.goalReminder.rawValue
        content.sound = authorizationStatus == .authorized ? .default : nil
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "goal-reminder-daily",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        #if DEBUG
        print("🔔 Goal reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        #endif
    }
    
    /// Cancel notifications with a specific prefix
    private func cancelNotifications(withPrefix prefix: String) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = pendingRequests
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        #if DEBUG
        print("🔔 Cancelled \(identifiersToRemove.count) notifications with prefix '\(prefix)'")
        #endif
    }
    
    // MARK: - Badge Management
    
    /// Update app icon badge number
    func updateBadgeCount(_ count: Int) async {
        guard authorizationStatus == .authorized else { return }
        
        do {
            try await notificationCenter.setBadgeCount(count)
            #if DEBUG
            print("🔔 Badge count updated to: \(count)")
            #endif
        } catch {
            #if DEBUG
            print("🔔 Failed to update badge count: \(error)")
            #endif
        }
    }
    
    /// Clear app icon badge
    func clearBadge() async {
        await updateBadgeCount(0)
    }
    
    /// Increment badge count by one
    func incrementBadgeCount() async {
        guard authorizationStatus == .authorized else { return }
        
        // iOS 17+ doesn't provide a way to get current badge count
        // We'll increment by 1 from 0 base or track it separately if needed
        await updateBadgeCount(1)
    }
    
    /// Get current badge count (deprecated method, kept for compatibility)
    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
    var currentBadgeCount: Int {
        // Note: This is deprecated in iOS 17+, but keeping for backward compatibility
        UIApplication.shared.applicationIconBadgeNumber
    }
    
    // MARK: - Streak Alerts
    
    /// Schedule streak alert notifications to remind users before their streak breaks
    func scheduleStreakAlerts() async throws {
        guard let settings = settings, settings.streakAlertsEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing streak alerts
        await cancelNotifications(withPrefix: "streak-alert")
        
        // Calculate the time to send streak reminder
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let streakDeadline = calendar.startOfDay(for: tomorrow)
        
        // Schedule alert based on user's preference (hours before streak might break)
        guard let alertTime = calendar.date(
            byAdding: .hour, 
            value: -settings.streakReminderHours, 
            to: streakDeadline
        ) else { return }
        
        // Only schedule if alert time is in the future
        guard alertTime > now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 " + "notifications.streak.title".localized
        content.body = String(format: "notifications.streak.body".localized, settings.streakReminderHours)
        content.categoryIdentifier = NotificationType.streakAlert.rawValue
        content.sound = authorizationStatus == .authorized ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: alertTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "streak-alert-\(Int(alertTime.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        #if DEBUG
        print("🔔 Streak alert scheduled for \(alertTime) (\(settings.streakReminderHours) hours before deadline)")
        #endif
    }
    
    /// Schedule recurring daily streak check
    func scheduleRecurringStreakAlerts() async throws {
        guard let settings = settings, settings.streakAlertsEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing recurring streak alerts
        await cancelNotifications(withPrefix: "streak-recurring")
        
        // Calculate notification time (e.g., 8 PM daily)
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 " + "notifications.streak.daily_title".localized
        content.body = "notifications.streak.daily_body".localized
        content.categoryIdentifier = NotificationType.streakAlert.rawValue
        content.sound = authorizationStatus == .authorized ? .default : nil
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak-recurring-daily",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        #if DEBUG
        print("🔔 Recurring streak alerts scheduled for 8 PM daily")
        #endif
    }
}

// MARK: - Notification Errors
enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permission not granted"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        completionHandler()
    }
}