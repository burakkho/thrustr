import SwiftUI
import SwiftData
import UserNotifications

struct NotificationSettingsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) var notificationManager
    
    @Query private var notificationSettings: [UserNotificationSettings]
    
    private var settings: UserNotificationSettings {
        notificationSettings.first ?? createDefaultSettings()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Toggle - uses NotificationManager as single source of truth
            VStack(spacing: 12) {
                NotificationToggleRow(
                    title: "notifications.enabled".localized,
                    subtitle: notificationManager.statusDescription,
                    isOn: Binding(
                        get: { notificationManager.isEnabled },
                        set: { newValue in
                            if newValue && notificationManager.authorizationStatus == .notDetermined {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                }
                            }
                            settings.isEnabled = newValue
                        }
                    ),
                    icon: "bell.fill",
                    color: .blue
                )
                
                // Show upgrade option for provisional notifications
                if notificationManager.isProvisional && notificationManager.isEnabled {
                    Button(action: {
                        Task {
                            await requestFullAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("notifications.upgrade.title".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("notifications.upgrade.description".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Test notification button (Debug only)
                #if DEBUG
                if notificationManager.isEnabled {
                    Button(action: {
                        Task {
                            do {
                                try await notificationManager.scheduleTestNotification()
                            } catch {
                                print("🔔 Test notification failed: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .foregroundColor(.green)
                            Text("Send Test Notification")
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                #endif
            }
            
            // Show Settings button if permissions denied
            if notificationManager.authorizationStatus == .denied {
                Button(action: {
                    notificationManager.openNotificationSettings()
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("notifications.open_settings".localized)
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if notificationManager.isEnabled {
                Divider()
                
                // Workout Reminders
                NotificationToggleRow(
                    title: "notifications.workout_reminders".localized,
                    subtitle: "notifications.workout_desc".localized,
                    isOn: Binding(
                        get: { settings.workoutRemindersEnabled },
                        set: { settings.workoutRemindersEnabled = $0 }
                    ),
                    icon: "dumbbell.fill",
                    color: .orange
                )
                
                // Achievement Notifications
                NotificationToggleRow(
                    title: "notifications.achievements".localized,
                    subtitle: "notifications.achievements_desc".localized,
                    isOn: Binding(
                        get: { settings.achievementNotificationsEnabled },
                        set: { settings.achievementNotificationsEnabled = $0 }
                    ),
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                // Goal Reminders
                NotificationToggleRow(
                    title: "notifications.goals".localized,
                    subtitle: "notifications.goals_desc".localized,
                    isOn: Binding(
                        get: { settings.dailyGoalRemindersEnabled },
                        set: { settings.dailyGoalRemindersEnabled = $0 }
                    ),
                    icon: "target",
                    color: .green
                )
            }
        }
        .onAppear {
            notificationManager.settings = settings
        }
        .onChange(of: settings.workoutRemindersEnabled) { _, newValue in
            if newValue {
                Task {
                    try? await notificationManager.scheduleWorkoutReminders()
                }
            }
        }
        .onChange(of: settings.dailyGoalRemindersEnabled) { _, newValue in
            if newValue {
                Task {
                    try? await notificationManager.scheduleGoalReminders()
                }
            }
        }
    }
    
    private func createDefaultSettings() -> UserNotificationSettings {
        let newSettings = UserNotificationSettings()
        modelContext.insert(newSettings)
        return newSettings
    }
    
    /// Request full authorization to upgrade from provisional
    private func requestFullAuthorization() async {
        do {
            // Request full authorization (without provisional)
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            
            _ = await MainActor.run {
                Task {
                    await notificationManager.updateAuthorizationStatus()
                }
            }
            
            #if DEBUG
            print("🔔 Full authorization requested, granted: \(granted)")
            #endif
        } catch {
            #if DEBUG
            print("🔔 Full authorization request failed: \(error)")
            #endif
        }
    }
}

// MARK: - Toggle Row Component
struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}