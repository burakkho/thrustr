import SwiftUI

struct LiftStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
}

#Preview {
    HStack(spacing: 12) {
        LiftStatCard(
            icon: "scalemass.fill",
            title: "Volume",
            value: "2.5 tons",
            color: .blue
        )

        LiftStatCard(
            icon: "number",
            title: "Sets",
            value: "24",
            color: .green
        )

        LiftStatCard(
            icon: "repeat",
            title: "Reps",
            value: "180",
            color: .orange
        )
    }
    .environment(\.theme, DefaultLightTheme())
}