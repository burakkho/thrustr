import SwiftUI

struct HealthStatsGrid: View {
    @Environment(\.theme) private var theme
    let user: User
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.s), count: 2), 
            spacing: theme.spacing.s
        ) {
            StepsStatCard(steps: user.healthKitSteps)
            CaloriesStatCard(calories: user.healthKitCalories)
            WeightStatCard(weight: user.displayWeight)
            BMIStatCard(bmi: user.bmi, category: user.bmiCategory)
        }
    }
}

// MARK: - Individual Stat Cards
private struct StepsStatCard: View {
    let steps: Double?
    
    var body: some View {
        QuickStatCard(
            icon: "figure.walk",
            title: LocalizationKeys.Dashboard.Stats.today.localized,
            value: formatSteps(steps),
            subtitle: LocalizationKeys.Dashboard.Stats.steps.localized,
            color: .blue,
            borderlessLight: true
        )
    }
    
    private func formatSteps(_ steps: Double?) -> String {
        guard let steps = steps else { return "0" }
        return NumberFormatter.localizedString(from: NSNumber(value: Int(steps)), number: .decimal)
    }
}

private struct CaloriesStatCard: View {
    let calories: Double?
    
    var body: some View {
        QuickStatCard(
            icon: "flame.fill",
            title: LocalizationKeys.Dashboard.Stats.calories.localized,
            value: formatCalories(calories),
            subtitle: LocalizationKeys.Dashboard.Stats.kcal.localized,
            color: .orange,
            borderlessLight: true
        )
    }
    
    private func formatCalories(_ calories: Double?) -> String {
        guard let calories = calories else { return "0" }
        return String(format: "%.0f", calories)
    }
}

private struct WeightStatCard: View {
    let weight: String
    
    var body: some View {
        QuickStatCard(
            icon: "scalemass.fill",
            title: LocalizationKeys.Dashboard.Stats.weight.localized,
            value: weight,
            subtitle: LocalizationKeys.Dashboard.Stats.lastMeasurement.localized,
            color: .green,
            borderlessLight: true
        )
    }
}

private struct BMIStatCard: View {
    let bmi: Double
    let category: String
    
    var body: some View {
        QuickStatCard(
            icon: "heart.fill",
            title: LocalizationKeys.Dashboard.Stats.bmi.localized,
            value: String(format: "%.1f", bmi),
            subtitle: category,
            color: .red,
            borderlessLight: true
        )
    }
}

#Preview {
    let user = User()
    user.currentWeight = 75.0
    user.height = 180
    user.calculateMetrics()
    
    return HealthStatsGrid(user: user)
        .padding()
}