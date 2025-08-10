import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @Query private var users: [User]
    @Query private var workouts: [Workout]
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var workoutService = WorkoutService()
    
    @State private var showingWeightEntry = false
    @State private var isLoading = true
    
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
                    
                    // Health Stats Grid
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
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // ✅ LOCALIZED: Welcome message with user name fallback
                    Text(LocalizationKeys.Dashboard.welcome.localized(with: currentUser.name.isEmpty ? LocalizationKeys.Common.user.localized : currentUser.name))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text(LocalizationKeys.Dashboard.howFeeling.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile Picture or Initials
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    // ✅ LOCALIZED: User initials with fallback
                    Text(String((currentUser.name.isEmpty ? LocalizationKeys.Common.user.localized : currentUser.name).prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Health Stats Grid (Using Shared Components)
    private var healthStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            // Steps
            QuickStatCard(
                icon: "figure.walk",
                title: LocalizationKeys.Dashboard.Stats.today.localized,
                value: formatSteps(healthKitService.todaySteps),
                subtitle: LocalizationKeys.Dashboard.Stats.steps.localized,
                color: .blue
            )
            
            // Calories
            QuickStatCard(
                icon: "flame.fill",
                title: LocalizationKeys.Dashboard.Stats.calories.localized,
                value: formatCalories(healthKitService.todayCalories),
                subtitle: LocalizationKeys.Dashboard.Stats.kcal.localized,
                color: .orange
            )
            
            // Weight
            QuickStatCard(
                icon: "scalemass.fill",
                title: LocalizationKeys.Dashboard.Stats.weight.localized,
                value: currentUser.displayWeight,
                subtitle: LocalizationKeys.Dashboard.Stats.lastMeasurement.localized,
                color: .green
            )
            
            // BMI
            QuickStatCard(
                icon: "heart.fill",
                title: LocalizationKeys.Dashboard.Stats.bmi.localized,
                value: String(format: "%.1f", currentUser.bmi),
                subtitle: currentUser.bmiCategory,
                color: .red
            )
        }
    }
    
    // MARK: - Quick Actions (Using Shared Components)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.Dashboard.quickActions.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Start Workout
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.startWorkout.localized,
                    icon: "dumbbell.fill",
                    description: LocalizationKeys.Dashboard.Actions.startWorkoutDesc.localized,
                    color: .blue
                ) {
                    tabRouter.selected = 1
                }
                
                // Log Weight
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.logWeight.localized,
                    icon: "scalemass.fill",
                    description: LocalizationKeys.Dashboard.Actions.logWeightDesc.localized,
                    color: .green
                ) {
                    showingWeightEntry = true
                }
                
                // Nutrition Tracking
                GuideSection(
                    title: LocalizationKeys.Dashboard.Actions.nutrition.localized,
                    icon: "fork.knife",
                    description: LocalizationKeys.Dashboard.Actions.nutritionDesc.localized,
                    color: .orange
                ) {
                    tabRouter.selected = 2
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizationKeys.Dashboard.NoWorkouts.title.localized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizationKeys.Dashboard.NoWorkouts.subtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentWorkouts, id: \.id) { workout in
                            WorkoutCard(workout: workout)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Weekly Progress Section
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.Dashboard.thisWeek.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Workout Count
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.workoutCount.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(workoutService.weeklyWorkoutCount)")
                            .font(.title.bold())
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                Divider()
                
                // Total Volume
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.totalVolume.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(workoutService.weeklyVolume)) kg")
                            .font(.title.bold())
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                Divider()
                
                // Total Time
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizationKeys.Dashboard.Weekly.totalTime.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(workoutService.weeklyDuration))
                            .font(.title.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() async {
        isLoading = true
        
        // Request HealthKit permissions and load data
        _ = await healthKitService.requestPermissions()
        await refreshHealthData()
        
        // Load workout statistics
        workoutService.loadWorkoutStats(workouts: workouts)
        
        isLoading = false
    }
    
    private func refreshHealthData() async {
        await healthKitService.readTodaysData()
        
        // Update user with HealthKit data
        currentUser.updateHealthKitData(
            steps: healthKitService.todaySteps,
            calories: healthKitService.todayCalories,
            weight: healthKitService.currentWeight
        )
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .frame(width: 200)
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        // ✅ LOCALIZED: Use current locale instead of hardcoded Turkish
        formatter.locale = Locale.current
        return formatter.string(from: date)
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

#Preview {
    DashboardView()
        .modelContainer(for: [User.self, Workout.self, Exercise.self, Food.self, NutritionEntry.self])
}
