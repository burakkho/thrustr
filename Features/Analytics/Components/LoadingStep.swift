import SwiftUI

struct AnalyticsLoadingStep: View {
    let text: String
    let isActive: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? theme.colors.accent : theme.colors.backgroundSecondary)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)

            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(isActive ? theme.colors.textPrimary : theme.colors.textSecondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        AnalyticsLoadingStep(text: "Reading health data", isActive: true)
        AnalyticsLoadingStep(text: "Analyzing recovery patterns", isActive: true)
        AnalyticsLoadingStep(text: "Assessing fitness levels", isActive: false)
        AnalyticsLoadingStep(text: "Generating insights", isActive: false)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}