import SwiftUI
import SwiftData

struct NutritionStoryHeroCard: View {
    let nutritionEntries: [NutritionEntry]
    @State private var viewModel: NutritionStoryHeroCardViewModel?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateNutrition = false

    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Nutrition Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(nutritionStoryMessage)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()

                // Animated nutrition icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(animateNutrition ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateNutrition)

                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .scaleEffect(animateNutrition ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateNutrition)
                }
            }

            // Key Nutrition Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                NutritionStoryMetric(
                    icon: "flame.fill",
                    title: "Avg Calories",
                    value: "\(viewModel?.avgCalories ?? 0)kcal",
                    color: .orange,
                    celebrationType: viewModel?.celebrationType ?? .none
                )

                NutritionStoryMetric(
                    icon: "chart.bar.fill",
                    title: "Logged Days",
                    value: "\(viewModel?.loggedDays ?? 0)/7",
                    color: .blue,
                    celebrationType: (viewModel?.loggedDays ?? 0) >= 6 ? .celebration : .none
                )

                NutritionStoryMetric(
                    icon: "target",
                    title: "Consistency",
                    value: "\(viewModel?.consistencyScore ?? 0)%",
                    color: .green,
                    celebrationType: (viewModel?.consistencyScore ?? 0) >= 80 ? .fire : .none
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.green.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            if viewModel == nil {
                viewModel = NutritionStoryHeroCardViewModel()
            }
            viewModel?.updateNutritionStory(entries: nutritionEntries)
            animateNutrition = true
        }
    }

    // MARK: - Computed Properties

    private var nutritionStoryMessage: String {
        NutritionAnalyticsService.generateNutritionStoryMessage(from: nutritionEntries)
    }

    // Business logic moved to NutritionStoryHeroCardViewModel

    // calculateCaloriesCelebration moved to ViewModel
}

#Preview {
    NutritionStoryHeroCard(nutritionEntries: [])
        .environment(\.theme, DefaultLightTheme())
        .environment(UnitSettings.shared)
}