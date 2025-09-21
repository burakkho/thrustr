import SwiftUI

struct AnalyticsPositiveIndicator: View {
    let text: String
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.caption2)
                .foregroundColor(.green)

            Text(text)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        AnalyticsPositiveIndicator(text: "Recovery levels are optimal")
        AnalyticsPositiveIndicator(text: "Fitness trends are stable")
        AnalyticsPositiveIndicator(text: "No concerning patterns detected")
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}