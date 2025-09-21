import SwiftUI

/**
 * Compact pill-style statistic display component.
 *
 * Used for displaying key metrics in a compact, visually appealing format.
 * Typically used in hero cards or summary sections where space is limited.
 *
 * Features:
 * - Icon + value + label layout
 * - Optimized for light text on dark backgrounds
 * - Compact spacing for dense information display
 * - Consistent theming with design system
 */
struct StatPill: View {
    @Environment(\.theme) private var theme

    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .background(.white.opacity(0.15))
        .cornerRadius(theme.radius.xs)
    }
}

#Preview {
    HStack {
        StatPill(
            icon: "clock",
            value: "45m",
            label: "Duration"
        )

        StatPill(
            icon: "calendar",
            value: "Today",
            label: "When"
        )
    }
    .padding()
    .background(Color.green)
    .environment(\.theme, DefaultLightTheme())
}