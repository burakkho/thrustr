import SwiftUI


struct AnalyticsVO2MaxVisualizationCard: View {
    let vo2Max: Double
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Health.Fitness.vo2_max_title.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)

            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("\(Int(vo2Max))")
                        .font(theme.typography.display1)
                        .fontWeight(.bold)
                        .foregroundColor(getVO2MaxColor())

                    Text(LocalizationKeys.Health.Fitness.vo2_max_unit.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                    Text(getVO2MaxCategory())
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(getVO2MaxColor())

                    Text(getVO2MaxDescription())
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            // VO2 Max scale visualization
            HStack {
                ForEach(VO2MaxRange.allCases, id: \.self) { range in
                    Rectangle()
                        .fill(range.color.opacity(isCurrentRange(range) ? 1.0 : 0.3))
                        .frame(height: 8)
                        .cornerRadius(2)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    private func getVO2MaxColor() -> Color {
        switch vo2Max {
        case 50...: return .green
        case 40..<50: return .blue
        case 30..<40: return .orange
        default: return .red
        }
    }

    private func getVO2MaxCategory() -> String {
        switch vo2Max {
        case 50...: return LocalizationKeys.Health.Fitness.vo2_excellent.localized
        case 40..<50: return LocalizationKeys.Health.Fitness.vo2_good.localized
        case 30..<40: return LocalizationKeys.Health.Fitness.vo2_fair.localized
        default: return LocalizationKeys.Health.Fitness.vo2_poor.localized
        }
    }

    private func getVO2MaxDescription() -> String {
        switch vo2Max {
        case 50...: return LocalizationKeys.Health.Fitness.vo2_athlete_level.localized
        case 40..<50: return LocalizationKeys.Health.Fitness.vo2_above_average.localized
        case 30..<40: return LocalizationKeys.Health.Fitness.vo2_average.localized
        default: return LocalizationKeys.Health.Fitness.vo2_below_average.localized
        }
    }

    private func isCurrentRange(_ range: VO2MaxRange) -> Bool {
        switch range {
        case .poor: return vo2Max < 30
        case .fair: return vo2Max >= 30 && vo2Max < 40
        case .good: return vo2Max >= 40 && vo2Max < 50
        case .excellent: return vo2Max >= 50
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnalyticsVO2MaxVisualizationCard(vo2Max: 45.5)
        AnalyticsVO2MaxVisualizationCard(vo2Max: 52.0)
        AnalyticsVO2MaxVisualizationCard(vo2Max: 28.5)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}