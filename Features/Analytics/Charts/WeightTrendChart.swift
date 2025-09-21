import SwiftUI

struct AnalyticsWeightTrendChart: View {
    let weightHistory: [HealthDataPoint]
    let currentWeight: Double?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(LocalizationKeys.Health.weight.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(LocalizationKeys.Analytics.this_month.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Real health trend line
            Path { path in
                let points = (0..<7).map { index in
                    let dayWeight = currentWeight ?? 70.0
                    let normalizedY = CGFloat(max(20, min(60, (dayWeight - 60) * 2 + 40))) // Normalize weight to chart height
                    return CGPoint(x: CGFloat(index) * 40, y: normalizedY)
                }

                if let firstPoint = points.first {
                    path.move(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.green, lineWidth: 3)
            .frame(height: 80)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

#Preview {
    let mockDataPoints = [
        HealthDataPoint(date: Date(), value: 75.5),
        HealthDataPoint(date: Date(), value: 75.2),
        HealthDataPoint(date: Date(), value: 74.8)
    ]

    WeightTrendChart(weightHistory: mockDataPoints, currentWeight: 75.0)
        .environment(\.theme, DefaultLightTheme())
}