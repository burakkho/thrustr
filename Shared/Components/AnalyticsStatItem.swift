import SwiftUI

/**
 * Analytics-specific stat item component with subtitle support.
 *
 * Designed for Analytics components that need to display additional
 * context information below the main value.
 */
struct AnalyticsStatItem: View {
    @Environment(\.theme) private var theme

    let title: String
    let value: String
    let subtitle: String?
    let color: Color?

    init(title: String, value: String, subtitle: String? = nil, color: Color? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)

            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(color ?? theme.colors.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AnalyticsStatItem(
            title: "Average Pace",
            value: "5:30 min/km"
        )

        AnalyticsStatItem(
            title: "Top Speed",
            value: "10.8 km/h",
            subtitle: "personal best",
            color: .blue
        )

        AnalyticsStatItem(
            title: "Calories Burned",
            value: "245 kcal",
            subtitle: "this session",
            color: .orange
        )
    }
    .padding()
}