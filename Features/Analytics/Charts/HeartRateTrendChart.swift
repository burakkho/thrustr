import SwiftUI

struct AnalyticsHeartRateTrendChart: View {
    let heartRateHistory: [HealthDataPoint]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(LocalizationKeys.Health.heart_rate.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(LocalizationKeys.Analytics.this_week.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Heart rate zones
            VStack(spacing: 8) {
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text(LocalizationKeys.Health.Heart.resting_bpm.localized)
                        .font(theme.typography.body)
                    Spacer()
                }

                HStack {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text(LocalizationKeys.Health.Heart.active_bpm.localized)
                        .font(theme.typography.body)
                    Spacer()
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

#Preview {
    let mockDataPoints = [
        HealthDataPoint(date: Date(), value: 65),
        HealthDataPoint(date: Date(), value: 68),
        HealthDataPoint(date: Date(), value: 62)
    ]

    HeartRateTrendChart(heartRateHistory: mockDataPoints)
        .environment(\.theme, DefaultLightTheme())
}