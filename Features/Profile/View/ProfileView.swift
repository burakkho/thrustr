import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query private var users: [User]
    @EnvironmentObject private var unitSettings: UnitSettings
    @StateObject private var errorHandler = ErrorHandlingService.shared
    
    @State private var showingPersonalInfoSheet = false
    @State private var showingPreferencesSheet = false
    @State private var showingAccountSheet = false
    @State private var showingWeightEntry = false
    @State private var showingMeasurementsEntry = false
    @State private var showingProgressPhotos = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Header Card
                    UserHeaderCard(user: currentUser)
                    
                    // Athlete Profile Card
                    if let user = currentUser {
                        AthleteProfileCard(user: user)
                    }
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        // Lifetime Achievements Section
                        if let user = currentUser {
                            LifetimeAchievementsSection(user: user)
                        }
                        
                        ProgressAnalyticsSection()
                        
                        BodyTrackingSection(
                            showingWeightEntry: $showingWeightEntry,
                            showingMeasurements: $showingMeasurementsEntry,
                            showingPhotos: $showingProgressPhotos
                        )
                        
                        PersonalSettingsSection(
                            showingPersonalInfo: $showingPersonalInfoSheet,
                            showingAccount: $showingAccountSheet
                        )
                        
                        FitnessCalculatorsSection()
                        
                        AppPreferencesSection(
                            showingPreferences: $showingPreferencesSheet
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("profile.title".localized)
            .background(theme.colors.backgroundPrimary)
        }
        .sheet(isPresented: $showingPersonalInfoSheet) {
            if let user = currentUser {
                PersonalInfoEditView(user: user)
            }
        }
        .sheet(isPresented: $showingPreferencesSheet) {
            AppPreferencesView()
        }
        .sheet(isPresented: $showingAccountSheet) {
            if let user = currentUser {
                AccountManagementView(user: user)
            }
        }
        .sheet(isPresented: $showingWeightEntry) {
            if let user = currentUser {
                WeightEntrySheet(user: user)
            }
        }
        .sheet(isPresented: $showingMeasurementsEntry) {
            if let user = currentUser {
                BodyMeasurementsView(user: user)
            }
        }
        .sheet(isPresented: $showingProgressPhotos) {
            ProgressPhotosView()
        }
        .toast($errorHandler.toastMessage, type: errorHandler.toastType)
    }
}

// MARK: - User Header Card
struct UserHeaderCard: View {
    let user: User?
    @EnvironmentObject private var unitSettings: UnitSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo with Logo Background
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    ZStack {
                        // App Logo as background
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .opacity(0.3)
                        
                        // User initials on top
                        Text(user?.name.prefix(1).uppercased() ?? "U")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "common.user".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let user = user {
                    let heightText = UnitsFormatter.formatHeight(cm: user.height, system: unitSettings.unitSystem)
                    let weightText = UnitsFormatter.formatWeight(kg: user.currentWeight, system: unitSettings.unitSystem)
                    Text("\(user.age) \("profile.age".localized) • \(heightText) • \(weightText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(user.fitnessGoalEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


// MARK: - Settings Sections
struct PersonalSettingsSection: View {
    @Binding var showingPersonalInfo: Bool
    @Binding var showingAccount: Bool
    
    var body: some View {
        SettingsSection(title: "profile.personal_info".localized) {
            SettingsRow(
                icon: "person.fill",
                title: "profile.personal_info".localized,
                subtitle: "profile.personal_info_subtitle".localized,
                action: { showingPersonalInfo = true }
            )
            
            SettingsRow(
                icon: "person.badge.key.fill",
                title: "profile.account_management".localized,
                subtitle: "profile.account_subtitle".localized,
                action: { showingAccount = true }
            )
        }
    }
}

struct BodyTrackingSection: View {
    @Binding var showingWeightEntry: Bool
    @Binding var showingMeasurements: Bool
    @Binding var showingPhotos: Bool
    
    var body: some View {
        SettingsSection(title: "profile.body_tracking".localized) {
            SettingsRow(
                icon: "scalemass.fill",
                title: "profile.weight_tracking".localized,
                subtitle: "profile.weight_subtitle".localized,
                action: { showingWeightEntry = true }
            )
            
            SettingsRow(
                icon: "ruler.fill",
                title: "profile.measurements".localized,
                subtitle: "profile.measurements_subtitle".localized,
                action: { showingMeasurements = true }
            )
            
            SettingsRow(
                icon: "camera.fill",
                title: "profile.progress_photos".localized,
                subtitle: "profile.photos_subtitle".localized,
                action: { showingPhotos = true }
            )
        }
    }
}

struct FitnessCalculatorsSection: View {
    var body: some View {
        SettingsSection(title: "calculators.fitness_calculators".localized) {
            NavigationLink(destination: FitnessCalculatorsView()) {
                SettingsRowContent(
                    icon: "function",
                    title: "calculators.title".localized,
                    subtitle: "1RM, FFMI, Navy Method"
                )
            }
        }
    }
}

struct AppPreferencesSection: View {
    @Binding var showingPreferences: Bool
    
    var body: some View {
        SettingsSection(title: "settings.app_preferences".localized) {
            SettingsRow(
                icon: "gear",
                title: "profile.settings".localized,
                subtitle: "profile.settings_subtitle".localized,
                action: { showingPreferences = true }
            )
        }
    }
}

struct ProgressAnalyticsSection: View {
    var body: some View {
        SettingsSection(title: "analytics.progress_analytics".localized) {
            NavigationLink(destination: ProgressChartsView()) {
                SettingsRowContent(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "profile.progress_charts".localized,
                    subtitle: "profile.charts_subtitle".localized
                )
            }
            
            NavigationLink(destination: AchievementsView()) {
                SettingsRowContent(
                    icon: "trophy.fill",
                    title: "analytics.achievements".localized,
                    subtitle: "profile.achievements_subtitle".localized
                )
            }
            
            NavigationLink(destination: GoalTrackingView()) {
                SettingsRowContent(
                    icon: "target",
                    title: "profile.goal_tracking".localized,
                    subtitle: "profile.goals_subtitle".localized
                )
            }
        }
    }
}

// MARK: - Reusable Components (No changes needed)
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
