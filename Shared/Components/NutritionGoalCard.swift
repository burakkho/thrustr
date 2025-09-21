import SwiftUI

struct NutritionGoalCard: View {
    let icon: String
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            // Title and progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Text("\(current)/\(target) \(unit)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textSecondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.backgroundSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * min(Double(current) / Double(target), 1.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NutritionGoalCard(
        icon: "flame.fill",
        title: "Daily Calories",
        current: 1800,
        target: 2000,
        unit: "kcal",
        color: .orange
    )
    .environment(\.theme, DefaultLightTheme())
}