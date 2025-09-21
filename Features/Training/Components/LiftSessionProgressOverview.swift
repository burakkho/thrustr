import SwiftUI

struct LiftSessionProgressOverview: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) private var unitSettings
    let session: LiftSession?

    var body: some View {
        HStack(spacing: theme.spacing.m) {
            LiftStatCard(
                icon: "scalemass.fill",
                title: "Volume",
                value: UnitsFormatter.formatWeight(kg: session?.totalVolume ?? 0, system: unitSettings.unitSystem),
                color: theme.colors.accent
            )

            LiftStatCard(
                icon: "number",
                title: "Sets",
                value: "\(session?.totalSets ?? 0)",
                color: theme.colors.success
            )

            LiftStatCard(
                icon: "repeat",
                title: "Reps",
                value: "\(session?.totalReps ?? 0)",
                color: theme.colors.warning
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    LiftSessionProgressOverview(session: nil)
        .environment(\.theme, DefaultLightTheme())
        .environment(UnitSettings.shared)
}