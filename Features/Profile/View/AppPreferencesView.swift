import SwiftUI

struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var languageManager = LanguageManager.shared
    @EnvironmentObject var unitSettings: UnitSettings
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("workoutReminders") private var workoutReminders = true
    @AppStorage("nutritionReminders") private var nutritionReminders = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                // Language Section
                Section {
                    LanguageSelector()
                        .environmentObject(languageManager)
                } header: {
                    SectionHeaderView(title: "settings.language".localized, icon: "globe")
                }
                
                // Units Section
                Section {
                    UnitSystemSelector(unitSystem: Binding(
                        get: { unitSettings.unitSystem.rawValue },
                        set: { unitSettings.unitSystem = UnitSystem(rawValue: $0) ?? .metric }
                    ))
                } header: {
                    SectionHeaderView(title: "settings.units".localized, icon: "ruler")
                }
                
                // Appearance Section
                Section {
                    AppearanceSettings()
                        .environmentObject(themeManager)
                } header: {
                    SectionHeaderView(title: "settings.theme".localized, icon: "paintbrush")
                }
                
                // Notifications Section
                Section {
                    NotificationSettings(
                        notificationsEnabled: $notificationsEnabled,
                        workoutReminders: $workoutReminders,
                        nutritionReminders: $nutritionReminders
                    )
                } header: {
                    SectionHeaderView(title: "settings.notifications".localized, icon: "bell")
                }
                
                // Audio & Haptic Section
                Section {
                    AudioHapticSettings(
                        soundEnabled: $soundEnabled,
                        hapticEnabled: $hapticEnabled
                    )
                } header: {
                    SectionHeaderView(title: "preferences.sound_effects".localized, icon: "speaker.wave.2")
                }
                
                // App Info Section
                Section {
                    AppInfoSection()
                } header: {
                    SectionHeaderView(title: "preferences.app_info".localized, icon: "info.circle")
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Language Selector
struct LanguageSelector: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingRestartAlert = false
    @State private var selectedLanguage: LanguageManager.Language?
    
    var body: some View {
        ForEach(LanguageManager.Language.allCases) { language in
            Button {
                guard languageManager.currentLanguage != language else { return }
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                selectedLanguage = language
                showingRestartAlert = true
                
            } label: {
                HStack {
                    Text(language.flag)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.displayName)
                            .foregroundColor(Color.textPrimary)
                            .fontWeight(.medium)
                        
                        if language == .system {
                            Text("preferences.auto_language".localized)
                                .font(.caption)
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if languageManager.currentLanguage == language {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.appPrimary)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .alert("language.change_title".localized, isPresented: $showingRestartAlert) {
            Button("language.change_cancel".localized, role: .cancel) {
                selectedLanguage = nil
            }
            Button("language.change_confirm".localized) {
                if let newLanguage = selectedLanguage {
                    languageManager.setLanguage(newLanguage)
                    print("🌍 Language changed to: \(newLanguage.displayName)")
                }
            }
        } message: {
            Text("language.change_message".localized)
        }
    }
}

// MARK: - Unit System Selector
struct UnitSystemSelector: View {
    @Binding var unitSystem: String
    
    private var units: [(String, String, String)] {
        [
            ("metric", "settings.metric".localized, "kg, cm, km"),
            ("imperial", "settings.imperial".localized, "lb, ft, mi")
        ]
    }
    
    var body: some View {
        ForEach(units, id: \.0) { system, name, description in
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    unitSystem = system
                }
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .foregroundColor(Color.textPrimary)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    if unitSystem == system {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.appPrimary)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettings: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    private var appearances: [(AppTheme, String, String)] {
        [
            (.system, "settings.system_theme".localized, "preferences.system_default".localized),
            (.light, "settings.light_mode".localized, "preferences.always_light".localized),
            (.dark, "settings.dark_mode".localized, "preferences.always_dark".localized)
        ]
    }
    
    var body: some View {
        ForEach(appearances, id: \.0) { theme, name, description in
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    themeManager.setTheme(theme)
                }
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack {
                    Image(systemName: theme.icon)
                        .foregroundColor(Color.appPrimary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .foregroundColor(Color.textPrimary)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    if themeManager.currentTheme == theme {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.appPrimary)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettings: View {
    @Binding var notificationsEnabled: Bool
    @Binding var workoutReminders: Bool
    @Binding var nutritionReminders: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Master notification toggle
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(notificationsEnabled ? Color.appPrimary : Color.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.allow_notifications".localized)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("preferences.notifications_all".localized)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
            
            if notificationsEnabled {
                Divider()
                    .padding(.vertical, 8)
                
                // Workout reminders
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(Color.trainingPrimary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.workout_reminders".localized)
                            .fontWeight(.medium)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("preferences.workout_reminders_desc".localized)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $workoutReminders)
                        .labelsHidden()
                }
                .padding(.vertical, 4)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Nutrition reminders
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(Color.nutritionPrimary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.nutrition_reminders".localized)
                            .fontWeight(.medium)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("preferences.nutrition_reminders_desc".localized)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $nutritionReminders)
                        .labelsHidden()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Audio & Haptic Settings
struct AudioHapticSettings: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticEnabled: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Sound settings
            HStack {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(soundEnabled ? Color.appPrimary : Color.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("preferences.sound_effects".localized)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("preferences.timer_sounds".localized)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $soundEnabled)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 8)
            
            // Haptic settings
            HStack {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundColor(hapticEnabled ? Color.appPrimary : Color.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("preferences.haptic_feedback".localized)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("preferences.vibration_feedback".localized)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $hapticEnabled)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - App Info Section
struct AppInfoSection: View {
    var body: some View {
        VStack(spacing: 0) {
            AppInfoRow(title: "settings.version".localized, value: "1.0.0")
            
            Divider()
                .padding(.vertical, 8)
            
            AppInfoRow(title: "Build", value: "100")
            
            Divider()
                .padding(.vertical, 8)
            
            Button {
                // TODO: Open privacy policy
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(Color.appPrimary)
                        .frame(width: 24)
                    
                    Text("settings.privacy_policy".localized)
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Button {
                // TODO: Open terms of service
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color.appPrimary)
                        .frame(width: 24)
                    
                    Text("settings.terms_of_service".localized)
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reusable Components
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.appPrimary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AppPreferencesView()
        .environmentObject(ThemeManager())
        .environmentObject(LanguageManager.shared)
}
