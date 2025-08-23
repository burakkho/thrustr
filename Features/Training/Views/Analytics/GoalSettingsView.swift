import SwiftUI
import SwiftData

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let user: User
    
    @State private var monthlySessionGoal: Int
    @State private var monthlyDistanceGoal: Double // in km for UI
    
    init(user: User) {
        self.user = user
        self._monthlySessionGoal = State(initialValue: user.monthlySessionGoal)
        self._monthlyDistanceGoal = State(initialValue: user.monthlyDistanceGoal / 1000) // Convert to km
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.xl) {
                // Header Info
                VStack(spacing: theme.spacing.s) {
                    Text("Set Your Monthly Goals")
                        .font(theme.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Track your progress with personalized monthly targets")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.l)
                
                VStack(spacing: theme.spacing.xl) {
                    // Session Goal
                    goalSettingCard(
                        title: "Training Sessions",
                        description: "How many workout sessions per month?",
                        icon: "calendar",
                        color: theme.colors.accent,
                        value: $monthlySessionGoal,
                        range: 4...40,
                        step: 2,
                        suffix: " sessions"
                    )
                    
                    // Distance Goal
                    goalSettingCardDouble(
                        title: "Cardio Distance",
                        description: "Total running/cycling distance per month",
                        icon: "figure.run",
                        color: Color.cardioColor,
                        value: $monthlyDistanceGoal,
                        range: 10.0...200.0,
                        step: 5.0,
                        suffix: " km"
                    )
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveGoals) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Save Goals")
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
            .navigationTitle("Monthly Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
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
        // Update user goals
        user.monthlySessionGoal = monthlySessionGoal
        user.monthlyDistanceGoal = monthlyDistanceGoal * 1000 // Convert back to meters
        
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    let user = User(name: "Test User")
    container.mainContext.insert(user)
    
    return GoalSettingsView(user: user)
        .modelContainer(container)
}