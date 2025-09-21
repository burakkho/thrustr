import SwiftUI

struct AnalyticsFeatureBullet: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        AnalyticsFeatureBullet(icon: "heart.fill", text: "Recovery & performance patterns", color: .red)
        AnalyticsFeatureBullet(icon: "figure.strengthtraining.traditional", text: "Fitness level assessment", color: .blue)
        AnalyticsFeatureBullet(icon: "chart.line.uptrend.xyaxis", text: "Trend analysis & predictions", color: .green)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}