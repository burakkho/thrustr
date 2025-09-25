import SwiftUI
import SwiftData

struct EnhancedNutritionInsightsSection: View {
    let weeklyData: [DayData]
    let nutritionEntries: [NutritionEntry]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.nutritionIntelligence.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 4)

            // AI Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                NutritionInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Eating Pattern",
                    insight: generateEatingPatternInsight(),
                    confidence: "High",
                    color: .blue
                )

                NutritionInsightCard(
                    icon: "leaf.fill",
                    title: "Macro Balance",
                    insight: generateMacroBalanceInsight(),
                    confidence: "Medium",
                    color: .green
                )

                NutritionInsightCard(
                    icon: "target",
                    title: "Goal Progress",
                    insight: generateGoalProgressInsight(),
                    confidence: "High",
                    color: .purple
                )

                NutritionInsightCard(
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

    private func generateEatingPatternInsight() -> String {
        NutritionAnalyticsService.generateEatingPatternInsight(from: weeklyData)
    }

    private func generateMacroBalanceInsight() -> String {
        NutritionAnalyticsService.generateMacroBalanceInsight(from: weeklyData)
    }

    private func generateGoalProgressInsight() -> String {
        NutritionAnalyticsService.generateGoalProgressInsight(from: weeklyData)
    }

    private func generateRecommendation() -> String {
        NutritionAnalyticsService.generateNutritionRecommendation(from: weeklyData)
    }
}

#Preview {
    EnhancedNutritionInsightsSection(
        weeklyData: [
            DayData(date: Date(), dayName: "Mon", calories: 1800, protein: 120, carbs: 200, fat: 60),
            DayData(date: Date(), dayName: "Tue", calories: 2100, protein: 140, carbs: 220, fat: 70)
        ],
        nutritionEntries: []
    )
    .environment(\.theme, DefaultLightTheme())
}