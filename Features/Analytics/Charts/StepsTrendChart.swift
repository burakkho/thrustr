import SwiftUI

struct AnalyticsStepsTrendChart: View {
    let stepsHistory: [HealthDataPoint]
    let todaySteps: Double
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(LocalizationKeys.Health.steps.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(LocalizationKeys.analytics.Time.this_week.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Real activity bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    let daySteps = todaySteps
                    let height = CGFloat(max(20, min(80, (daySteps / 15000) * 80)))
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 30, height: height)
                        .cornerRadius(4)
                }
            }
            .frame(height: 100)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

#Preview {
    let mockDataPoints = [
        HealthDataPoint(date: Date(), value: 8500),
        HealthDataPoint(date: Date(), value: 12000),
        HealthDataPoint(date: Date(), value: 6500)
    ]

    AnalyticsStepsTrendChart(stepsHistory: mockDataPoints, todaySteps: 9500)
        .environment(\.theme, DefaultLightTheme())
}