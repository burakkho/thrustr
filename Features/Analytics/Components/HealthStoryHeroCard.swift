import SwiftUI

// 🎯 HEALTH STORY HERO CARD
struct AnalyticsHealthStoryHeroCard: View {
    let user: User?
    @State private var viewModel: HealthStoryHeroCardViewModel?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateHealth = false

    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Health Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(healthStoryMessage)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()

                // Animated health icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.2), Color.red.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(animateHealth ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateHealth)

                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .scaleEffect(animateHealth ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateHealth)
                }
            }

            // Key Health Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                HealthStoryMetric(
                    icon: "figure.walk",
                    title: "Today's Steps",
                    value: formatSteps(viewModel?.todaySteps ?? 0),
                    color: .blue,
                    celebrationType: viewModel?.celebrationType ?? .none
                )

                HealthStoryMetric(
                    icon: "flame.fill",
                    title: "Active Calories",
                    value: formatCalories(viewModel?.todayActiveCalories ?? 0),
                    color: .orange,
                    celebrationType: viewModel?.celebrationType ?? .none
                )

                HealthStoryMetric(
                    icon: "heart.fill",
                    title: "Recovery Score",
                    value: "\(viewModel?.recoveryScore ?? 0)%",
                    color: .red,
                    celebrationType: (viewModel?.recoveryScore ?? 0) >= 85 ? .celebration : .none
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.red.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            if viewModel == nil {
                viewModel = HealthStoryHeroCardViewModel()
            }
            viewModel?.updateHealthStory(user: user)
            animateHealth = true
        }
    }

    // MARK: - Computed Properties

    private var healthStoryMessage: String {
        let steps = viewModel?.todaySteps ?? 0
        let calories = viewModel?.todayActiveCalories ?? 0
        let recovery = viewModel?.recoveryScore ?? 0

        if steps >= 10000 && recovery >= 85 {
            return "🌟 Exceptional day! You're crushing your health goals."
        } else if steps >= 7500 || recovery >= 70 {
            return "💪 Great progress! Your body is responding well."
        } else if steps == 0 && calories == 0 {
            return "Ready to start your wellness journey? Every step counts!"
        } else {
            return "🎯 Building healthy habits. Consistency is key to success."
        }
    }

    // calculateStepsCelebration moved to ViewModel

    private func calculateCaloriesCelebration() -> CelebrationType {
        guard let user = user else { return .none }
        let calories = viewModel?.todayActiveCalories ?? 0
        let goal = user.dailyCalorieGoal

        if calories >= goal * 1.2 { return .fire }
        if calories >= goal { return .celebration }
        if calories >= goal * 0.7 { return .progress }
        return .none
    }

    private func calculateRecoveryScore() -> Int {
        // Enhanced recovery calculation with multiple factors
        let heartRate = viewModel?.currentHeartRate ?? 70
        let steps = viewModel?.todaySteps ?? 0
        let activeCalories = viewModel?.todayActiveCalories ?? 0

        var score = 50 // Base score

        // Heart Rate Variability Assessment (30 points)
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

        // Weekly Pattern Assessment (10 points)
        let weeklyPatternScore = viewModel?.weeklyPatternScore ?? 0
        score += weeklyPatternScore

        // Day of Week Factor (10 points)
        let dayOfWeekScore = viewModel?.dayOfWeekScore ?? 0
        score += dayOfWeekScore

        return max(10, min(score, 100)) // Ensure score is between 10-100
    }

    private func calculateWeeklyPatternScore() -> Int {
        // Analyze past 7 days activity pattern
        let calendar = Calendar.current
        let today = Date()
        var totalSteps = 0.0
        var activeDays = 0

        for i in 0..<7 {
            guard calendar.date(byAdding: .day, value: -i, to: today) != nil else { continue }
            // In real implementation, we'd query HealthKit for historical data
            // For now, simulate based on current day pattern
            if i == 0 {
                totalSteps += viewModel?.todaySteps ?? 0
                if (viewModel?.todaySteps ?? 0) > 3000 { activeDays += 1 }
            }
        }

        let averageSteps = totalSteps / 7.0
        let activityConsistency = Double(activeDays) / 7.0

        if averageSteps >= 8000 && activityConsistency >= 0.6 {
            return 10 // Excellent pattern
        } else if averageSteps >= 5000 && activityConsistency >= 0.4 {
            return 7 // Good pattern
        } else {
            return 3 // Needs improvement
        }
    }

    private func calculateDayOfWeekScore() -> Int {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())

        // Sunday = 1, Monday = 2, etc.
        switch dayOfWeek {
        case 1: return 8 // Sunday - rest day
        case 2: return 6 // Monday - start of week
        case 3, 4, 5: return 5 // Tue-Thu - mid week
        case 6: return 6 // Friday - end of week
        case 7: return 8 // Saturday - weekend
        default: return 5
        }
    }

    // MARK: - Helper Methods
    private func formatSteps(_ steps: Double) -> String {
        if steps == 0 { return "0" }
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000)
        }
        return String(format: "%.0f", steps)
    }

    private func formatCalories(_ calories: Double) -> String {
        if calories == 0 { return "0" }
        return String(format: "%.0f", calories)
    }
}

#Preview {
    AnalyticsHealthStoryHeroCard(user: nil)
        .environment(UnitSettings.shared)
        .environment(ThemeManager())
        .padding()
}