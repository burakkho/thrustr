import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query private var users: [User]
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @State private var errorHandler = ErrorHandlingService.shared
    @State private var viewModel: ProfileViewModel?

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
                VStack(spacing: 32) {
                    // 🎯 HERO SECTION - Primary Focus (Profile + Strength Level + CTA)
                    if let viewModel = viewModel {
                        ProfileHeaderCard(user: currentUser, viewModel: viewModel)
                    }
                    
                    // ⚡ QUICK ACTIONS - Essential Daily Actions  
                    if let user = currentUser {
                        AthleteProfileCard(user: user)
                    }
                    
                    // 💚 HEALTH STORY - Today's Health Data with Progress
                    if let user = currentUser {
                        HealthDashboardCard(user: user)
                    }
                    
                    // 🏆 ACHIEVEMENT SHOWCASE - Recent Accomplishments
                    if let viewModel = viewModel {
                        AchievementShowcaseSection(viewModel: viewModel)
                    }
                    
                    // 📊 PROGRESSIVE SECTIONS - Expandable Advanced Features
                    VStack(spacing: 20) {
                        // 📈 PROGRESS - Analytics & Tracking (Expandable)
                        ExpandableProgressSection(
                            showingWeightEntry: $showingWeightEntry,
                            showingProgressPhotos: $showingProgressPhotos
                        )
                        
                        // 🔧 ADVANCED - Power User Features (Collapsed by Default)
                        AdvancedFeaturesSection(
                            showingAccount: $showingAccountSheet,
                            user: currentUser
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("profile.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        CloudSyncIndicator()
                            .environment(cloudSyncManager)
                        
                        Button(action: { showingPreferencesSheet = true }) {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .accessibilityLabel("settings.app_preferences".localized)
                    }
                }
            }
            .background(theme.colors.backgroundPrimary)
        }
        .onAppear {
            // Initialize ViewModel with modern dependency injection pattern
            if viewModel == nil {
                viewModel = ProfileViewModel()
            }

            // Load profile data
            if let viewModel = viewModel {
                loadProfileData(viewModel: viewModel)
            }
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

    // MARK: - Private Methods

    private func loadProfileData(viewModel: ProfileViewModel) {
        // Load required data for ViewModel using SwiftData queries
        let healthKitService = HealthKitService.shared

        // Pass SwiftData query results to ViewModel
        viewModel.loadProfileData(
            user: currentUser,
            healthKitService: healthKitService,
            liftSessions: [],
            nutritionEntries: [],
            weightEntries: []
        )
    }
}

// MARK: - Achievement Showcase Section
struct AchievementShowcaseSection: View {
    let viewModel: ProfileViewModel
    @Environment(\.theme) private var theme
    
    var body: some View {
        if viewModel.hasAchievements {
            VStack(spacing: 16) {
                // Section Header
                HStack {
                    Text("profile.recent_achievements".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    NavigationLink(destination: AchievementsView()) {
                        Text("common.view_all".localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
                .padding(.horizontal, 4)
                
                // Achievement Display - Showcase Style with titles
                HStack(spacing: 20) {
                    ForEach(Array(viewModel.showcaseAchievements.enumerated()), id: \.element.id) { index, achievement in
                        VStack(spacing: 8) {
                            NavigationLink(destination: AchievementsView()) {
                                AchievementBadge(achievement: achievement, size: .showcase)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Achievement title below badge
                            VStack(spacing: 2) {
                                Text(achievement.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                if achievement.isCompleted {
                                    Text("profile.completed".localized)
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                } else {
                                    Text("\(Int(achievement.progressPercentage * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    // Next achievement preview
                    if viewModel.additionalAchievementsCount > 0 {
                        VStack(spacing: 4) {
                            Text("+\\(viewModel.additionalAchievementsCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.accent)

                            Text("profile.more_achievements".localized)
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .onTapGesture {
                            // Navigate to achievements view
                        }
                    }
                }
                .padding()
                .background(theme.colors.cardBackground)
                .cornerRadius(theme.radius.l)
                .shadow(color: theme.shadows.card, radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Profile Header Card (Modern with Achievements)
struct ProfileHeaderCard: View {
    let user: User?
    let viewModel: ProfileViewModel
    
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(TabRouter.self) private var tabRouter
    
    @State private var showingStrengthTest = false
    @State private var showingNavyCalculator = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 🎯 HERO PROFILE - Center Focus with Activity Rings
            VStack(spacing: 20) {
                // Enhanced Profile Photo with Activity Rings - Larger Size
                HealthActivityProfilePhoto(user: user)
                    .scaleEffect(1.2)
                
                // Minimal User Info - Name + Strength Level Only
                VStack(spacing: 8) {
                    Text(user?.name ?? "common.user".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    // Strength Level with CTA
                    if let user = user {
                        strengthLevelDisplay(user: user)
                    }
                }
            }
        }
        .padding(24)
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .shadow(color: theme.shadows.card, radius: 6, x: 0, y: 3)
        .onAppear {
            // HealthKit data refresh handled by ViewModel
            viewModel.refreshHealthData(healthKitService: HealthKitService.shared)
        }
        .fullScreenCover(isPresented: $showingStrengthTest) {
            if let user = user {
                StrengthTestView(user: user, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showingNavyCalculator) {
            NavigationView {
                if let user = user {
                    NavyMethodCalculatorView(user: user)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func strengthLevelDisplay(user: User) -> some View {
        VStack(spacing: 12) {
            if viewModel.strengthLevelString != "--" {
                // Strength Level Badge
                Text(viewModel.strengthLevelString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.strengthLevelColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.strengthLevelColor.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(viewModel.strengthLevelColor.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Navigation to Test Results
                Button(action: {
                    tabRouter.selected = 1  // Training tab
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                        Text("profile.view_progress".localized)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.accent)
                }
            } else {
                // Take Test CTA
                Button(action: {
                    showingStrengthTest = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(DashboardKeys.Profile.takeTest.localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("profile.unlock_strength_level".localized)
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(theme.radius.l)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
                    isPressed = pressing
                    if pressing {
                        HapticManager.shared.impact(.light)
                    }
                })
            }
        }
    }
    
    @State private var isPressed = false
    
    
    
    
}


// MARK: - Health Metric Cell (Compact)
struct HealthMetricCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}


// MARK: - Essentials Section (Most-used Daily Actions)
struct EssentialsSection: View {
    @Binding var showingPersonalInfo: Bool
    @Binding var showingWeightEntry: Bool
    @Binding var showingMeasurements: Bool
    @Binding var showingPreferences: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            SectionHeader(
                icon: "bolt.fill",
                title: "Essentials",
                color: .orange
            )
            
            // Essential Actions - Clean and Focused
            VStack(spacing: 1) {
                SettingsRow(
                    icon: "person.fill",
                    title: "profile.personal_info".localized,
                    subtitle: "profile.personal_info_subtitle".localized,
                    action: { showingPersonalInfo = true }
                )
                
                SettingsRow(
                    icon: "ruler.fill",
                    title: "profile.measurements".localized,
                    subtitle: "profile.measurements_subtitle".localized,
                    action: { showingMeasurements = true }
                )
                
                
                SettingsRow(
                    icon: "gear",
                    title: "settings.app_preferences".localized,
                    subtitle: "profile.settings_subtitle".localized,
                    action: { showingPreferences = true }
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Expandable Progress Section
struct ExpandableProgressSection: View {
    @Query private var users: [User]
    @State private var isExpanded = false
    @Environment(\.theme) private var theme
    @Binding var showingWeightEntry: Bool
    @Binding var showingProgressPhotos: Bool
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Expandable Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                SectionHeaderExpandable(
                    title: "profile.progress_analytics".localized,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                VStack(spacing: 1) {
                    // Weight Entry
                    Button(action: { showingWeightEntry = true }) {
                        SettingsRowContent(
                            icon: "scalemass.fill",
                            title: "profile.log_weight".localized,
                            subtitle: "profile.track_weight_changes".localized
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Progress Photos
                    Button(action: { showingProgressPhotos = true }) {
                        SettingsRowContent(
                            icon: "camera.fill",
                            title: "profile.progress_photos".localized,
                            subtitle: "profile.visual_progress_tracking".localized
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                    
                    // Training Goals Navigation
                    if let user = currentUser {
                        NavigationLink(destination: TrainingGoalsView(user: user)) {
                            SettingsRowContent(
                                icon: "target",
                                title: "Training Goals",
                                subtitle: "Set your workout and fitness targets"
                            )
                        }
                        
                        NavigationLink(destination: NutritionGoalsView(user: user)) {
                            SettingsRowContent(
                                icon: "leaf.fill",
                                title: NutritionKeys.Goals.nutritionGoals.localized,
                                subtitle: "Set your daily nutrition targets"
                            )
                        }
                    }
                    
                    NavigationLink(destination: GoalTrackingView()) {
                        SettingsRowContent(
                            icon: "chart.bar.xaxis",
                            title: "profile.goal_tracking".localized,
                            subtitle: "profile.goals_subtitle".localized
                        )
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Advanced Features Section
struct AdvancedFeaturesSection: View {
    @Binding var showingAccount: Bool
    let user: User?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                SectionHeaderExpandable(
                    title: "profile.advanced_features".localized,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 1) {
                    NavigationLink(destination: FitnessCalculatorsView()) {
                        SettingsRowContent(
                            icon: "function",
                            title: "calculators.title".localized,
                            subtitle: "calculators.subtitle".localized
                        )
                    }
                    
                    NavigationLink(destination: HealthKitSyncView()) {
                        HealthIntegrationRowContent()
                    }
                    
                    SettingsRow(
                        icon: "person.badge.key.fill",
                        title: "profile.account_management".localized,
                        subtitle: "profile.account_subtitle".localized,
                        action: { showingAccount = true }
                    )
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Section Headers
struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct SectionHeaderExpandable: View {
    let title: String
    let isExpanded: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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

// MARK: - Health Integration Row
struct HealthIntegrationRowContent: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: healthKitService.isAuthorized ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(healthKitService.isAuthorized ? .green : .blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("profile.health_integration".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(healthKitService.isAuthorized ? "health.sync_active".localized : "profile.health_integration_subtitle".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if healthKitService.isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - HealthKit Sync View
struct HealthKitSyncView: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @State private var isRefreshing = false
    
    var body: some View {
        Group {
            if healthKitService.isAuthorized {
                // Show sync management interface
                authorizedView
            } else {
                // Show authorization interface
                HealthKitAuthorizationView()
            }
        }
    }
    
    private var authorizedView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Sync Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text("health.sync_enabled".localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("health.data_syncing".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .cardStyle()
                    
                    // Data Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("health.today_data".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            DataSummaryCell(
                                icon: "figure.walk",
                                value: String(format: "%.0f", healthKitService.todaySteps),
                                label: "health.steps".localized,
                                color: .blue
                            )
                            
                            DataSummaryCell(
                                icon: "flame.fill",
                                value: String(format: "%.0f", healthKitService.todayActiveCalories),
                                label: "health.calories".localized,
                                color: .orange
                            )
                            
                            DataSummaryCell(
                                icon: "scalemass.fill",
                                value: healthKitService.currentWeight != nil ? String(format: "%.1f kg", healthKitService.currentWeight!) : "--",
                                label: "health.weight".localized,
                                color: .green
                            )
                            
                            DataSummaryCell(
                                icon: "heart.fill",
                                value: healthKitService.restingHeartRate != nil ? String(format: "%.0f bpm", healthKitService.restingHeartRate!) : "--",
                                label: "health.resting_hr".localized,
                                color: .red
                            )
                        }
                    }
                    .cardStyle()
                    
                    // Manual Sync Button
                    Button(action: {
                        Task {
                            isRefreshing = true
                            await healthKitService.readTodaysData()
                            isRefreshing = false
                        }
                    }) {
                        HStack {
                            if isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            Text("health.refresh_data".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.backgroundSecondary)
                        .foregroundColor(theme.colors.textPrimary)
                        .cornerRadius(theme.radius.m)
                    }
                    .disabled(isRefreshing)
                    
                    // Re-authorization Button
                    NavigationLink(destination: HealthKitAuthorizationView()) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("health.manage_permissions".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(theme.colors.accent)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.m)
                                .stroke(theme.colors.accent, lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("health.sync_settings".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Data Summary Cell
struct DataSummaryCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let switchToAnalyticsTab = Notification.Name("switchToAnalyticsTab")
}

#Preview {
    ProfileView()
}
