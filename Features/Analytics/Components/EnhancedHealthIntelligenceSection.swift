import SwiftUI

// 🧠 ENHANCED HEALTH INTELLIGENCE SECTION
struct AnalyticsEnhancedHealthIntelligenceSection: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("AI Health Intelligence")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: HealthIntelligenceView()) {
                    Text("Full Report")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)

            // AI Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                HealthInsightCard(
                    icon: "brain.head.profile",
                    title: "Recovery Status",
                    insight: generateRecoveryInsight(),
                    confidence: "High",
                    color: .purple
                )

                HealthInsightCard(
                    icon: "heart.text.square",
                    title: "Activity Pattern",
                    insight: generateActivityInsight(),
                    confidence: "Medium",
                    color: .blue
                )

                HealthInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Health Trend",
                    insight: generateTrendInsight(),
                    confidence: "High",
                    color: .green
                )

                HealthInsightCard(
                    icon: "lightbulb.fill",
                    title: "Recommendation",
                    insight: generateRecommendation(),
                    confidence: "Medium",
                    color: .orange
                )
            }
        }
    }

    // MARK: - AI Insight Generation

    private func generateRecoveryInsight() -> String {
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps

        if heartRate < 60 && steps >= 8000 {
            return "Excellent recovery markers. Your body is well-rested."
        } else if heartRate < 70 {
            return "Good recovery status. Consider maintaining current habits."
        } else {
            return "Recovery could improve. Focus on sleep and stress management."
        }
    }

    private func generateActivityInsight() -> String {
        let steps = healthKitService.todaySteps
        let _ = healthKitService.todayActiveCalories

        if steps >= 12000 {
            return "High activity day! You're exceeding recommended levels."
        } else if steps >= 8000 {
            return "Solid activity level. You're on track for health goals."
        } else if steps < 3000 {
            return "Low activity detected. Consider adding movement breaks."
        } else {
            return "Moderate activity. Small increases can boost wellness."
        }
    }

    private func generateTrendInsight() -> String {
        // Simplified trend analysis
        let currentSteps = healthKitService.todaySteps

        if currentSteps >= 10000 {
            return "Positive trend in daily activity. Keep up the momentum!"
        } else if currentSteps >= 5000 {
            return "Steady progress observed. Gradual improvements are key."
        } else {
            return "Room for improvement in activity levels detected."
        }
    }

    private func generateRecommendation() -> String {
        let steps = healthKitService.todaySteps
        let heartRate = healthKitService.restingHeartRate ?? 70

        if steps < 5000 {
            return "Try adding 10-minute walks after meals."
        } else if heartRate > 75 {
            return "Consider stress reduction techniques like meditation."
        } else if steps >= 10000 {
            return "Great work! Add strength training for complete fitness."
        } else {
            return "Increase daily steps by 1000 for optimal health benefits."
        }
    }
}

#Preview {
    AnalyticsEnhancedHealthIntelligenceSection()
        .environment(ThemeManager())
        .padding()
}