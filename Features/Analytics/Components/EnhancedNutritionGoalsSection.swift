import SwiftUI
import SwiftData

struct EnhancedNutritionGoalsSection: View {
    let nutritionEntries: [NutritionEntry]
    @State private var viewModel: NutritionStoryHeroCardViewModel?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Nutrition Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: Text("Goal Settings")) {
                    Text("Edit Goals")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)

            // Goals Progress Cards
            VStack(spacing: 12) {
                NutritionGoalCard(
                    icon: "flame.fill",
                    title: "Daily Calories",
                    current: viewModel?.avgCalories ?? 0,
                    target: 2000,
                    unit: "kcal",
                    color: .orange
                )

                NutritionGoalCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "Protein Intake",
                    current: Int(NutritionAnalyticsService.calculateAverageProtein(from: nutritionEntries)),
                    target: 150,
                    unit: "g",
                    color: .red
                )

                NutritionGoalCard(
                    icon: "chart.bar.fill",
                    title: "Logging Streak",
                    current: viewModel?.loggedDays ?? 0,
                    target: 7,
                    unit: "days",
                    color: .green
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = NutritionStoryHeroCardViewModel()
            }
            viewModel?.updateNutritionStory(entries: nutritionEntries)
        }
    }
}

#Preview {
    EnhancedNutritionGoalsSection(nutritionEntries: [])
        .environment(\.theme, DefaultLightTheme())
}