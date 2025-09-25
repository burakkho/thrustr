import SwiftUI

// 💫 ENHANCED HEALTH RINGS SECTION
struct AnalyticsEnhancedHealthRingsSection: View {
    let user: User?
    @State private var viewModel: EnhancedHealthRingsSectionViewModel?
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateRings = false

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.healthActivityRings.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: Text("Health Detail")) {
                    Text(CommonKeys.Analytics.viewDetails.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)

            // Animated Health Rings
            HStack(spacing: 40) {
                // Steps Ring
                AnimatedHealthRing(
                    progress: stepsProgress,
                    title: "Steps",
                    value: formatSteps(healthKitService.todaySteps),
                    goal: "10k",
                    color: .blue,
                    animate: animateRings
                )

                // Calories Ring
                AnimatedHealthRing(
                    progress: caloriesProgress,
                    title: "Calories",
                    value: formatCalories(healthKitService.todayActiveCalories),
                    goal: formatCalorieGoal(),
                    color: .orange,
                    animate: animateRings
                )

                // Heart Rate Ring (using recovery score)
                AnimatedHealthRing(
                    progress: Double(viewModel?.recoveryScore ?? 0) / 100.0,
                    title: "Recovery",
                    value: "\(viewModel?.recoveryScore ?? 0)%",
                    goal: "85%",
                    color: .red,
                    animate: animateRings
                )
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = EnhancedHealthRingsSectionViewModel()
            }
            viewModel?.updateHealthRings(user: user)
            withAnimation(.easeInOut(duration: 1.5)) {
                animateRings = true
            }
        }
    }

    // MARK: - Helper Methods

    private var stepsProgress: Double {
        min(healthKitService.todaySteps / 10000.0, 1.0)
    }

    private var caloriesProgress: Double {
        guard let user = user else { return 0 }
        return min(healthKitService.todayActiveCalories / user.dailyCalorieGoal, 1.0)
    }

    private func formatSteps(_ steps: Double) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000)
        }
        return String(format: "%.0f", steps)
    }

    private func formatCalories(_ calories: Double) -> String {
        String(format: "%.0f", calories)
    }

    private func formatCalorieGoal() -> String {
        guard let user = user else { return "2000" }
        if user.dailyCalorieGoal >= 1000 {
            return String(format: "%.1fk", user.dailyCalorieGoal / 1000)
        }
        return String(format: "%.0f", user.dailyCalorieGoal)
    }

    // calculateRecoveryScore moved to EnhancedHealthRingsSectionViewModel
    private func calculateRecoveryScore_OLD() -> Int {
        // Enhanced recovery calculation with multiple factors
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps
        let activeCalories = healthKitService.todayActiveCalories

        var score = 50 // Base score

        // Heart Rate Assessment (30 points)
        let heartRateScore: Int
        switch heartRate {
        case 0..<50: heartRateScore = 30 // Athletic level
        case 50..<60: heartRateScore = 25 // Excellent
        case 60..<70: heartRateScore = 20 // Good
        case 70..<80: heartRateScore = 15 // Average
        case 80..<90: heartRateScore = 10 // Below average
        default: heartRateScore = 5 // Poor
        }
        score += heartRateScore

        // Activity Balance Assessment (20 points)
        let activityScore: Int
        if steps >= 12000 && activeCalories >= 600 {
            activityScore = 20 // Optimal activity
        } else if steps >= 8000 && activeCalories >= 400 {
            activityScore = 15 // Good activity
        } else if steps >= 5000 && activeCalories >= 200 {
            activityScore = 10 // Moderate activity
        } else if steps < 2000 && activeCalories < 100 {
            activityScore = 20 // Complete rest (good for recovery)
        } else {
            activityScore = 5 // Poor balance
        }
        score += activityScore

        return max(10, min(score, 100)) // Ensure score is between 10-100
    }
}

#Preview {
    AnalyticsEnhancedHealthRingsSection(user: nil)
        .environment(UnitSettings.shared)
        .environment(ThemeManager())
        .padding()
}