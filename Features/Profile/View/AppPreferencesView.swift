import SwiftUI

struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage = "tr"
    @AppStorage("unitSystem") private var unitSystem = "metric"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("workoutReminders") private var workoutReminders = true
    @AppStorage("nutritionReminders") private var nutritionReminders = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("darkModePreference") private var darkModePreference = "system"
    
    var body: some View {
        NavigationView {
            List {
                // Language Section
                Section {
                    LanguageSelector(selectedLanguage: $selectedLanguage)
                } header: {
                    SectionHeaderView(title: "Dil", icon: "globe")
                }
                
                // Units Section
                Section {
                    UnitSystemSelector(unitSystem: $unitSystem)
                } header: {
                    SectionHeaderView(title: "Birimler", icon: "ruler")
                }
                
                // Notifications Section
                Section {
                    NotificationSettings(
                        notificationsEnabled: $notificationsEnabled,
                        workoutReminders: $workoutReminders,
                        nutritionReminders: $nutritionReminders
                    )
                } header: {
                    SectionHeaderView(title: "Bildirimler", icon: "bell")
                }
                
                // Audio & Haptic Section
                Section {
                    AudioHapticSettings(
                        soundEnabled: $soundEnabled,
                        hapticEnabled: $hapticEnabled
                    )
                } header: {
                    SectionHeaderView(title: "Ses ve Titreşim", icon: "speaker.wave.2")
                }
                
                // Appearance Section
                Section {
                    AppearanceSettings(darkModePreference: $darkModePreference)
                } header: {
                    SectionHeaderView(title: "Görünüm", icon: "paintbrush")
                }
                
                // App Info Section
                Section {
                    AppInfoSection()
                } header: {
                    SectionHeaderView(title: "Uygulama Bilgisi", icon: "info.circle")
                }
            }
            .navigationTitle("Tercihler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
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
    @Binding var selectedLanguage: String
    
    private let languages = [
        ("tr", "Türkçe", "🇹🇷"),
        ("en", "English", "🇺🇸")
    ]
    
    var body: some View {
        ForEach(languages, id: \.0) { code, name, flag in
            Button {
                selectedLanguage = code
            } label: {
                HStack {
                    Text(flag)
                        .font(.title2)
                    
                    Text(name)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedLanguage == code {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Unit System Selector
struct UnitSystemSelector: View {
    @Binding var unitSystem: String
    
    private let units = [
        ("metric", "Metrik", "kg, cm, km"),
        ("imperial", "İngiliz", "lb, ft, mi")
    ]
    
    var body: some View {
        ForEach(units, id: \.0) { system, name, description in
            Button {
                unitSystem = system
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if unitSystem == system {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
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
                    .foregroundColor(notificationsEnabled ? .blue : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bildirimleri Etkinleştir")
                        .fontWeight(.medium)
                    
                    Text("Tüm bildirimleri aç/kapat")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Antrenman Hatırlatıcıları")
                            .fontWeight(.medium)
                        
                        Text("Dinlenme timer'ı ve antrenman önerileri")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Beslenme Hatırlatıcıları")
                            .fontWeight(.medium)
                        
                        Text("Öğün zamanları ve su içme hatırlatmaları")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                    .foregroundColor(soundEnabled ? .blue : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ses Efektleri")
                        .fontWeight(.medium)
                    
                    Text("Timer sesleri ve bildirim sesleri")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    .foregroundColor(hapticEnabled ? .blue : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic Feedback")
                        .fontWeight(.medium)
                    
                    Text("Titreşim geri bildirimleri")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $hapticEnabled)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettings: View {
    @Binding var darkModePreference: String
    
    private let appearances = [
        ("system", "Sistem", "Cihaz ayarını takip et"),
        ("light", "Açık", "Her zaman açık tema"),
        ("dark", "Koyu", "Her zaman koyu tema")
    ]
    
    var body: some View {
        ForEach(appearances, id: \.0) { mode, name, description in
            Button {
                darkModePreference = mode
            } label: {
                HStack {
                    Image(systemName: iconForMode(mode))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if darkModePreference == mode {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private func iconForMode(_ mode: String) -> String {
        switch mode {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - App Info Section
struct AppInfoSection: View {
    var body: some View {
        VStack(spacing: 0) {
            AppInfoRow(title: "Versiyon", value: "1.0.0")
            
            Divider()
                .padding(.vertical, 8)
            
            AppInfoRow(title: "Build", value: "100")
            
            Divider()
                .padding(.vertical, 8)
            
            Button {
                // Open privacy policy
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Gizlilik Politikası")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Button {
                // Open terms of service
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Kullanım Şartları")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
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
                .foregroundColor(.blue)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AppPreferencesView()
}
