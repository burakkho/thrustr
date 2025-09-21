import SwiftUI

struct NutritionInsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let confidence: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Text(confidence)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(insight)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
    NutritionInsightCard(
        icon: "lightbulb.fill",
        title: "Recommendation",
        insight: "Add protein-rich snacks like Greek yogurt or nuts to boost your daily protein intake.",
        confidence: "High",
        color: .orange
    )
    .environment(\.theme, DefaultLightTheme())
}