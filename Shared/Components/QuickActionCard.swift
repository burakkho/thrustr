import SwiftUI

/**
 * Quick action card component for dashboard actions.
 *
 * Displays an actionable card with icon, title, subtitle, and tap handler.
 * Used for quick workout creation and navigation actions on dashboard.
 *
 * Features:
 * - Prominent icon with color coding
 * - Title and subtitle text hierarchy
 * - Tap action handling
 * - Consistent card styling
 * - Accessibility support
 */
struct QuickActionCard: View {
    @Environment(\.theme) private var theme

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(title)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

#Preview {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        QuickActionCard(
            title: "Quick Lift",
            subtitle: "Start strength training",
            icon: "dumbbell.fill",
            color: .strengthColor,
            action: {
                print("Quick Lift tapped")
            }
        )

        QuickActionCard(
            title: "Quick Cardio",
            subtitle: "Start cardio session",
            icon: "heart.fill",
            color: .cardioColor,
            action: {
                print("Quick Cardio tapped")
            }
        )

        QuickActionCard(
            title: "Create WOD",
            subtitle: "Build custom workout",
            icon: "flame.fill",
            color: .wodColor,
            action: {
                print("Create WOD tapped")
            }
        )

        QuickActionCard(
            title: "Browse Programs",
            subtitle: "Find structured programs",
            icon: "rectangle.3.group",
            color: .blue,
            action: {
                print("Browse Programs tapped")
            }
        )
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}