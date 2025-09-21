import SwiftUI

struct NutritionStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                if celebrationType != .none {
                    Image(systemName: celebrationType.icon)
                        .font(.caption)
                        .foregroundColor(celebrationType.color)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
    }

}

#Preview {
    HStack(spacing: 12) {
        NutritionStoryMetric(
            icon: "flame.fill",
            title: "Avg Calories",
            value: "1850kcal",
            color: Color.orange,
            celebrationType: CelebrationType.fire
        )

        NutritionStoryMetric(
            icon: "chart.bar.fill",
            title: "Logged Days",
            value: "6/7",
            color: Color.blue,
            celebrationType: .celebration
        )

        NutritionStoryMetric(
            icon: "target",
            title: "Consistency",
            value: "86%",
            color: Color.green,
            celebrationType: .none
        )
    }
    .environment(\.theme, DefaultLightTheme())
}