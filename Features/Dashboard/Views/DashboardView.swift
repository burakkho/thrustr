import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @Query private var users: [User]
    @Query private var workouts: [Workout]
    @Query private var nutritionEntries: [NutritionEntry]
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var userService = UserService()
    @StateObject private var workoutService = WorkoutService()
    
    @State private var showingWeightEntry = false
    @State private var isLoading = true
    @State private var showStepsInfo = false
    @State private var showCaloriesInfo = false
    
    private var currentUser: User {
        users.first ?? createDefaultUser()
    }
    
    private var recentWorkouts: [Workout] {
        workouts.sorted { $0.startTime > $1.startTime }.prefix(5).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    welcomeSection
                    
                    // Health Stats Grid (2x2)
                    healthStatsGrid
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Workouts
                    recentWorkoutsSection
                    
                    // Weekly Progress
                    weeklyProgressSection
                }
                .padding()
            }
            .navigationTitle(LocalizationKeys.Dashboard.title.localized)
            .background(theme.colors.backgroundPrimary)
            .refreshable {
                await refreshHealthData()
            }
            .sheet(isPresented: $showingWeightEntry) {
                WeightEntryView(user: currentUser)
            }
        }
        .overlay(alignment: .center) {
            if isLoading {
                ZStack {
                    Color.overlayLoading.ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .onChange(of: workouts) { _, _ in
            // Recompute weekly stats when workouts change (finish/delete/new)
            workoutService.loadWorkoutStats(workouts: workouts)
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // ✅ LOCALIZED: Welcome message with user name fallback
                    Text(LocalizationKeys.Dashboard.welcome.localized(with: currentUser.name.isEmpty ? LocalizationKeys.Common.user.localized : currentUser.name))
                        .font(.title2.bold())
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(LocalizationKeys.Dashboard.howFeeling.localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Profile Picture or Initials
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.10))
                        .frame(width: 50, height: 50)
                    
                    // ✅ LOCALIZED: User initials with fallback
                    Text(String((currentUser.name.isEmpty ? LocalizationKeys.Common.user.localized : currentUser.name).prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
        .padding()
        .dashboardWelcomeCardStyle()
    }
    
    // MARK: - Health Stats Grid (2x2)
    private var healthStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.s), count: 2), spacing: theme.spacing.s) {
            QuickStatCard(
                icon: "figure.walk",
                title: LocalizationKeys.Dashboard.Stats.today.localized,
                value: formatSteps(healthKitService.todaySteps),
                subtitle: LocalizationKeys.Dashboard.Stats.steps.localized,
                color: .blue,
                borderlessLight: true
            )
            QuickStatCard(
                icon: "flame.fill",
                title: LocalizationKeys.Dashboard.Stats.calories.localized,
                value: formatCalories(healthKitService.todayCalories),
                subtitle: LocalizationKeys.Dashboard.Stats.kcal.localized,
                color: .orange,
                borderlessLight: true
            )
            QuickStatCard(
                icon: "scalemass.fill",
                title: LocalizationKeys.Dashboard.Stats.weight.localized,
                value: currentUser.displayWeight,
                subtitle: LocalizationKeys.Dashboard.Stats.lastMeasurement.localized,
                color: .green,
                borderlessLight: true
            )
            QuickStatCard(
                icon: "heart.fill",
                title: LocalizationKeys.Dashboard.Stats.bmi.localized,
                value: String(format: "%.1f", currentUser.bmi),
                subtitle: currentUser.bmiCategory,
                color: .red,
                borderlessLight: true
            )
        }
    }
    
    // MARK: - Quick Actions (Using Shared Components)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Dashboard.quickActions.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.s) {
                // Start Workout
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.startWorkout.localized,
                    icon: "dumbbell.fill",
                    description: LocalizationKeys.Dashboard.Actions.startWorkoutDesc.localized,
                    color: .blue,
                    borderlessLight: true
                ) {
                    tabRouter.selected = 1
                }
                
                // Log Weight
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.logWeight.localized,
                    icon: "scalemass.fill",
                    description: LocalizationKeys.Dashboard.Actions.logWeightDesc.localized,
                    color: .green,
                    borderlessLight: true
                ) {
                    showingWeightEntry = true
                }
                
                // Nutrition Tracking
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.nutrition.localized,
                    icon: "fork.knife",
                    description: LocalizationKeys.Dashboard.Actions.nutritionDesc.localized,
                    color: .orange,
                    borderlessLight: true
                ) {
                    tabRouter.selected = 2
                }
            }
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(LocalizationKeys.Dashboard.recentWorkouts.localized)
                    .font(.headline)
                
                Spacer()
                
                if !recentWorkouts.isEmpty {
                    Button(LocalizationKeys.Dashboard.seeAll.localized) {
                        // Navigate to workout history
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if recentWorkouts.isEmpty {
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "dumbbell")
                        .font(.largeTitle)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(LocalizationKeys.Dashboard.NoWorkouts.title.localized)
                        .font(.headline)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(LocalizationKeys.Dashboard.NoWorkouts.subtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        tabRouter.selected = 1
                    }) {
                        Text(LocalizationKeys.Dashboard.Actions.startWorkout.localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .dashboardSurfaceStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentWorkouts, id: \.id) { workout in
                            WorkoutCard(workout: workout)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Progress Section
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Dashboard.thisWeek.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.m) {
                // Workout Count
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.workoutCount.localized)
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(workoutService.weeklyWorkoutCount)")
                            .font(.title.bold())
                            .foregroundColor(theme.colors.accent)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(theme.colors.accent)
                        .font(.title2)
                }
                
                Divider()
                
                // Total Volume
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.totalVolume.localized)
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(Int(workoutService.weeklyVolume)) kg")
                            .font(.title.bold())
                            .foregroundColor(theme.colors.success)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(theme.colors.success)
                        .font(.title2)
                }
                
                Divider()
                
                // Total Time
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.totalTime.localized)
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(formatDuration(workoutService.weeklyDuration))
                            .font(.title.bold())
                            .foregroundColor(theme.colors.warning)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .foregroundColor(theme.colors.warning)
                        .font(.title2)
                }
            }
            .padding()
            .dashboardSurfaceStyle()
        }
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() async {
        isLoading = true
        
        // Request HealthKit permissions and load data via service
        _ = await healthKitService.requestPermissions()
        userService.setModelContext(modelContext)
        await refreshHealthData()
        
        // Load workout statistics
        workoutService.loadWorkoutStats(workouts: workouts)
        
        isLoading = false
    }
    
    private func refreshHealthData() async {
        userService.setModelContext(modelContext)
        await userService.syncWithHealthKit(user: currentUser)
    }

    private func todayConsumedCalories() -> Double {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        return nutritionEntries.filter { $0.date >= startOfDay && $0.date < endOfDay }
            .reduce(0) { $0 + $1.calories }
    }

    private func todayWorkoutDuration() -> TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        let todays = workouts.filter { $0.startTime >= startOfDay && $0.startTime < endOfDay }
        let total = todays.reduce(0.0) { partial, workout in
            if let end = workout.endTime { return partial + end.timeIntervalSince(workout.startTime) }
            return partial + TimeInterval(workout.totalDuration)
        }
        return total
    }
    
    private func createDefaultUser() -> User {
        let user = User()
        modelContext.insert(user)
        return user
    }
    
    private func formatSteps(_ steps: Double?) -> String {
        guard let steps = steps else { return "0" }
        return NumberFormatter.localizedString(from: NSNumber(value: Int(steps)), number: .decimal)
    }
    
    private func formatCalories(_ calories: Double?) -> String {
        guard let calories = calories else { return "0" }
        return String(format: "%.0f", calories)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)\(LocalizationKeys.Dashboard.Time.hours.localized) \(minutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        } else {
            return "\(minutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        }
    }
}

// MARK: - Workout Card Component
struct WorkoutCard: View {
    let workout: Workout
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("d MMM")
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // ✅ LOCALIZED: Workout name with fallback
                Text(workout.name ?? LocalizationKeys.Dashboard.Workout.defaultName.localized)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // ✅ DATE FORMATTING: Format workout date
                Text(formatWorkoutDate(workout.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationKeys.Dashboard.Workout.duration.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // ✅ FIXED: workout.totalDuration is Int (seconds), convert to TimeInterval
                    Text(formatWorkoutDuration(TimeInterval(workout.totalDuration)))
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizationKeys.Dashboard.Workout.volume.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // ✅ OK: workout.totalVolume is computed property (Double)
                    Text("\(Int(workout.totalVolume)) kg")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .dashboardSurfaceStyle()
        .frame(width: 200)
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        WorkoutCard.dateFormatter.string(from: date)
    }
    
    private func formatWorkoutDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)\(LocalizationKeys.Dashboard.Time.hours.localized) \(remainingMinutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        } else {
            return "\(minutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        }
    }
}

// MARK: - Dashboard Light-Only Styling Helpers
private struct DashboardSurfaceStyle: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .padding(theme.spacing.m)
                .background(theme.colors.cardBackground)
                .cornerRadius(14)
                .shadow(color: Color.shadowLight, radius: 4, y: 1)
        } else {
            content.cardStyle()
        }
    }
}

private extension View {
    func dashboardSurfaceStyle() -> some View { modifier(DashboardSurfaceStyle()) }
}

private struct DashboardWelcomeCardStyle: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.m)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.shadowLight, radius: shadowRadius, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
    }
    private var isLight: Bool { colorScheme == .light }
    private var backgroundColor: Color {
        // Beyaz yüzeye geri dön: her iki modda da cardBackground
        return theme.colors.cardBackground
    }
    private var strokeColor: Color { isLight ? Color(.systemGray5) : Color.white.opacity(0.18) }
    private var strokeWidth: CGFloat { isLight ? 1.0 : 2.0 }
    private var shadowRadius: CGFloat { isLight ? 4.0 : 2.0 }
}

private extension View {
    func dashboardWelcomeCardStyle() -> some View { modifier(DashboardWelcomeCardStyle()) }
}

// MARK: - Weight Entry View
struct WeightEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    
    @State private var newWeight: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(LocalizationKeys.Dashboard.WeightEntry.title.localized)
                    .font(.title2.bold())
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Dashboard.WeightEntry.label.localized)
                        .font(.headline)
                    
                    TextField(LocalizationKeys.Dashboard.WeightEntry.placeholder.localized, text: $newWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button(LocalizationKeys.Dashboard.WeightEntry.save.localized) {
                    if let weight = Double(newWeight.replacingOccurrences(of: ",", with: ".")), weight > 0 {
                        user.currentWeight = weight
                        user.calculateMetrics()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWeight.isEmpty)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Dashboard.WeightEntry.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            newWeight = String(format: "%.1f", user.currentWeight)
        }
    }
}

// MARK: - Inline Health Stat Strip Components (to avoid project file edits)
struct DashboardHealthStatStripItem: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

struct DashboardHealthStatStripPlaceholder: View {
    @Environment(\.theme) private var theme
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .foregroundColor(theme.colors.accent)
                .font(.title2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .cardStyle()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [User.self, Workout.self, Exercise.self, Food.self, NutritionEntry.self])
}
