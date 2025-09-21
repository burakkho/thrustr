import SwiftUI

struct AnalyticsHealthLoadingView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(LocalizationKeys.Common.HealthKit.loadingMessage.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
    }
}

#Preview {
    AnalyticsHealthLoadingView()
        .environment(\.theme, DefaultLightTheme())
}