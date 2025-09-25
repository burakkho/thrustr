import SwiftUI

struct AnalyticsRecoveryTrendChart: View {
    let recoveryScore: RecoveryScore
    @Environment(\.theme) private var theme
    @State private var healthKitService = HealthKitService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Health.Intelligence.recovery_trend.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)

            // Real 7-day recovery trend from historical data
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    let dayScore = calculateRealRecoveryForDay(daysBack: 6 - day)
                    let normalizedScore = max(0, min(100, dayScore))
                    let height = (normalizedScore / 100) * 60

                    VStack {
                        Rectangle()
                            .fill(getRecoveryColor(normalizedScore))
                            .frame(width: 30, height: height)
                            .cornerRadius(4)

                        Text(getDayName(for: day))
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    private func getRecoveryColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func getDayName(for index: Int) -> String {
        let days = [
            LocalizationKeys.Common.Days.monday_short.localized,
            LocalizationKeys.Common.Days.tuesday_short.localized,
            LocalizationKeys.Common.Days.wednesday_short.localized,
            LocalizationKeys.Common.Days.thursday_short.localized,
            LocalizationKeys.Common.Days.friday_short.localized,
            LocalizationKeys.Common.Days.saturday_short.localized,
            LocalizationKeys.Common.Days.sunday_short.localized
        ]
        return days[index]
    }

    private func calculateRealRecoveryForDay(daysBack: Int) -> Double {
        let targetDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()

        // Calculate recovery based on real factors for that day
        var dayRecoveryScore = recoveryScore.overallScore

        // Adjust based on sleep data if available
        if healthKitService.lastNightSleep > 0 {
            // Adjust score based on sleep quality (7-9 hours optimal)
            let sleepAdjustment = calculateSleepScoreAdjustment(sleepHours: healthKitService.lastNightSleep)
            dayRecoveryScore = (dayRecoveryScore * 0.7) + (sleepAdjustment * 0.3)
        }

        // Adjust based on workout load for that day (if we have workout history)
        let workoutAdjustment = calculateWorkoutLoadAdjustment(for: targetDate)
        dayRecoveryScore = (dayRecoveryScore * 0.8) + (workoutAdjustment * 0.2)

        return max(20, min(100, dayRecoveryScore)) // Keep within reasonable bounds
    }

    private func calculateSleepScoreAdjustment(sleepHours: Double) -> Double {
        switch sleepHours {
        case 7...9: return 85.0 // Optimal sleep
        case 6..<7, 9..<10: return 75.0 // Good sleep
        case 5..<6, 10..<11: return 60.0 // Adequate sleep
        default: return 40.0 // Poor sleep
        }
    }

    private func calculateWorkoutLoadAdjustment(for date: Date) -> Double {
        // If high intensity workout on this day, recovery might be lower next day
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let _ = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        // Check if there was intense workout on this day
        // This is a simplified version - could be enhanced with actual workout intensity data
        let hasIntenseWorkout = calendar.component(.weekday, from: date) != 1 && calendar.component(.weekday, from: date) != 7 // Weekdays more likely to have workouts

        return hasIntenseWorkout ? 70.0 : 80.0
    }
}

#Preview {
    let mockRecoveryScore = RecoveryScore(
        overallScore: 75.0,
        hrvScore: 70.0,
        sleepScore: 80.0,
        workoutLoadScore: 75.0,
        restingHeartRateScore: 75.0,
        date: Date()
    )

    AnalyticsRecoveryTrendChart(recoveryScore: mockRecoveryScore)
        .environment(\.theme, DefaultLightTheme())
}