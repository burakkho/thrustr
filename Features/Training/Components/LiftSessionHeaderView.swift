import SwiftUI

struct LiftSessionHeaderView: View {
    @Environment(\.theme) private var theme
    let workout: LiftWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Session \((workout.sessions?.count ?? 0) + 1)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    if let program = workout.program {
                        Text(program.localizedName)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }

                Spacer()

                if let lastPerformed = workout.lastPerformed {
                    VStack(alignment: .trailing) {
                        Text("Last workout")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text(lastPerformed, formatter: RelativeDateTimeFormatter())
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
}

#Preview {
    // This would need a mock LiftWorkout for preview
    Text("LiftSessionHeaderView Preview")
        .environment(\.theme, DefaultLightTheme())
}