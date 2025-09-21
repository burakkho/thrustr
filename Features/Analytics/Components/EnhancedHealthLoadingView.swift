import SwiftUI

struct AnalyticsEnhancedHealthLoadingView: View {
    @State private var animateGradient = false
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 24) {
            // Animated brain icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.colors.accent, theme.colors.accent.opacity(0.6)],
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                )
                .scaleEffect(animateGradient ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: animateGradient
                )

            VStack(spacing: 8) {
                Text(LocalizationKeys.Health.Intelligence.loading_title.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(LocalizationKeys.Health.Intelligence.loading_subtitle.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Progress steps
            VStack(alignment: .leading, spacing: 8) {
                LoadingStep(text: LocalizationKeys.Health.Intelligence.loading_reading_data.localized, isActive: true)
                LoadingStep(text: LocalizationKeys.Health.Intelligence.loading_recovery_analysis.localized, isActive: animateGradient)
                LoadingStep(text: LocalizationKeys.Health.Intelligence.loading_fitness_assessment.localized, isActive: false)
                LoadingStep(text: LocalizationKeys.Health.Intelligence.loading_generating_insights.localized, isActive: false)
            }
            .padding(.top, 16)
        }
        .frame(height: 300)
        .onAppear {
            animateGradient = true
        }
    }
}

#Preview {
    AnalyticsEnhancedHealthLoadingView()
        .environment(\.theme, DefaultLightTheme())
}