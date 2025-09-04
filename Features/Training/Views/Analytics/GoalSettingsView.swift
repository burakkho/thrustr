import SwiftUI
import SwiftData

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    
    let user: User
    
    @State private var monthlySessionGoal: Int
    @State private var monthlyDistanceGoal: Double // in km for UI
    @State private var weeklyLiftGoal: Int
    @State private var weeklyCardioGoal: Int
    @State private var weeklyDistanceGoal: Double // in km for UI
    
    init(user: User) {
        self.user = user
        self._monthlySessionGoal = State(initialValue: user.monthlySessionGoal)
        
        // Note: We can't access @EnvironmentObject in init, so we'll use default metric values
        // and convert them in onAppear based on actual unit system
        let monthlyDistanceDisplay: Double = user.monthlyDistanceGoal / 1000 // meters to km
        let weeklyDistanceDisplay: Double = user.weeklyDistanceGoal / 1000   // meters to km
        
        self._monthlyDistanceGoal = State(initialValue: monthlyDistanceDisplay)
        self._weeklyLiftGoal = State(initialValue: user.weeklyLiftGoal)
        self._weeklyCardioGoal = State(initialValue: user.weeklyCardioGoal)
        self._weeklyDistanceGoal = State(initialValue: weeklyDistanceDisplay)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.xl) {
                // Header Info
                VStack(spacing: theme.spacing.s) {
                    Text(TrainingKeys.Goals.setMonthlyGoals.localized)
                        .font(theme.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(TrainingKeys.Goals.trackProgress.localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.l)
                
                VStack(spacing: theme.spacing.xl) {
                    // Monthly Goals Section
                    goalSectionHeader("📅 " + TrainingKeys.Analytics.monthlyGoals.localized, TrainingKeys.Analytics.monthlyGoalsDesc.localized)
                    
                    goalSettingCard(
                        title: TrainingKeys.Goals.trainingSessions.localized,
                        description: TrainingKeys.GoalsDesc.workoutSessionsPerMonth.localized,
                        icon: "calendar",
                        color: theme.colors.accent,
                        value: $monthlySessionGoal,
                        range: 4...40,
                        step: 2,
                        suffix: " " + TrainingKeys.Units.sessions.localized
                    )
                    
                    goalSettingCardDouble(
                        title: TrainingKeys.Goals.cardioDistance.localized,
                        description: TrainingKeys.GoalsDesc.totalRunningCyclingDistance.localized,
                        icon: "figure.run",
                        color: Color.cardioColor,
                        value: $monthlyDistanceGoal,
                        range: unitSettings.unitSystem == .metric ? 10.0...200.0 : 6.0...124.0, // 10-200km = 6-124mi
                        step: unitSettings.unitSystem == .metric ? 5.0 : 3.0, // 5km = 3mi
                        suffix: " " + UnitsFormatter.distanceUnitShort(system: unitSettings.unitSystem)
                    )
                    
                    Divider()
                        .padding(.vertical, theme.spacing.m)
                    
                    // Weekly Goals Section (Dashboard)
                    goalSectionHeader("🎯 " + TrainingKeys.Analytics.weeklyGoals.localized, TrainingKeys.Analytics.weeklyGoalsDesc.localized)
                    
                    goalSettingCard(
                        title: TrainingKeys.Goals.liftSessions.localized,
                        description: TrainingKeys.Goals.weeklyTarget.localized,
                        icon: "dumbbell.fill",
                        color: Color.blue,
                        value: $weeklyLiftGoal,
                        range: 1...7,
                        step: 1,
                        suffix: " " + TrainingKeys.Units.sessions.localized
                    )
                    
                    goalSettingCard(
                        title: TrainingKeys.Goals.cardioSessions.localized,
                        description: TrainingKeys.Goals.cardioTarget.localized,
                        icon: "figure.run",
                        color: Color.green,
                        value: $weeklyCardioGoal,
                        range: 1...7,
                        step: 1,
                        suffix: " " + TrainingKeys.Units.sessions.localized
                    )
                    
                    goalSettingCardDouble(
                        title: TrainingKeys.Goals.weeklyDistance.localized,
                        description: TrainingKeys.Goals.cardioTarget.localized,
                        icon: "location.fill",
                        color: Color.orange,
                        value: $weeklyDistanceGoal,
                        range: unitSettings.unitSystem == .metric ? 2.0...50.0 : 1.2...31.0, // 2-50km = 1.2-31mi
                        step: unitSettings.unitSystem == .metric ? 2.5 : 1.5, // 2.5km = 1.5mi
                        suffix: " " + UnitsFormatter.distanceUnitShort(system: unitSettings.unitSystem)
                    )
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveGoals) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text(TrainingKeys.Goals.saveGoals.localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(theme.spacing.l)
                    .background(theme.colors.accent)
                    .cornerRadius(theme.radius.m)
                }
                .padding(.bottom, theme.spacing.xl)
            }
            .padding(.horizontal, theme.spacing.l)
            .navigationTitle(CommonKeys.Navigation.trainingGoals.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(CommonKeys.Onboarding.Common.cancel.localized) { dismiss() }
                }
            }
            .onAppear {
                // Convert distance values based on unit system when view appears
                if unitSettings.unitSystem == .imperial {
                    monthlyDistanceGoal = UnitsConverter.metersToMiles(user.monthlyDistanceGoal)
                    weeklyDistanceGoal = UnitsConverter.metersToMiles(user.weeklyDistanceGoal)
                }
            }
        }
    }
    
    private func goalSettingCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack(spacing: theme.spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Slider and Value
            VStack(spacing: theme.spacing.s) {
                HStack {
                    Text("\(value.wrappedValue)\(suffix)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Spacer()
                }
                
                Slider(value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
                    .accentColor(color)
                
                HStack {
                    Text("\(range.lowerBound)")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("\(range.upperBound)")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func formatValue<T: Numeric>(_ value: T) -> String {
        if let intValue = value as? Int {
            return "\(intValue)"
        } else if let doubleValue = value as? Double {
            return String(format: "%.0f", doubleValue)
        }
        return "\(value)"
    }
    
    private func goalSettingCardDouble(
        title: String,
        description: String,
        icon: String,
        color: Color,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack(spacing: theme.spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Slider and Value
            VStack(spacing: theme.spacing.s) {
                HStack {
                    Text("\(Int(value.wrappedValue))\(suffix)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Spacer()
                }
                
                Slider(value: value, in: range, step: step)
                    .accentColor(color)
                
                HStack {
                    Text("\(Int(range.lowerBound))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("\(Int(range.upperBound))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func saveGoals() {
        print("💾 Save goals button tapped")
        // Update monthly goals
        user.monthlySessionGoal = monthlySessionGoal
        
        // Convert distance goals from display units to storage units (meters)
        let monthlyDistanceInMeters: Double
        let weeklyDistanceInMeters: Double
        
        switch unitSettings.unitSystem {
        case .metric:
            monthlyDistanceInMeters = monthlyDistanceGoal * 1000 // km to meters
            weeklyDistanceInMeters = weeklyDistanceGoal * 1000   // km to meters
        case .imperial:
            monthlyDistanceInMeters = UnitsConverter.milesToMeters(monthlyDistanceGoal)
            weeklyDistanceInMeters = UnitsConverter.milesToMeters(weeklyDistanceGoal)
        }
        
        user.monthlyDistanceGoal = monthlyDistanceInMeters
        
        // Update weekly goals
        user.weeklyLiftGoal = weeklyLiftGoal
        user.weeklyCardioGoal = weeklyCardioGoal
        user.weeklyDistanceGoal = weeklyDistanceInMeters
        
        // Recalculate goal completion rate
        let calendar = Calendar.current
        let _ = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        // This is a simplified calculation - in production, we'd use AnalyticsService
        // For now, just reset to 0 to trigger recalculation
        user.goalCompletionRate = 0.0
        
        // Save changes
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error - in production, show error toast
            print("Failed to save goals: \(error)")
        }
    }
    
    private func goalSectionHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.typography.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            Text(subtitle)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    let user = User(name: "Test User")
    container.mainContext.insert(user)
    
    return GoalSettingsView(user: user)
        .modelContainer(container)
}