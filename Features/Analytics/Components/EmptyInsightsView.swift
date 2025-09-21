import SwiftUI

struct EmptyInsightsView: View {
    @Environment(\.theme) private var theme
    @State private var animateSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            // Enhanced success state - Animated celebration
            VStack(spacing: 16) {
                ZStack {
                    // Success gradient background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateSuccess ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateSuccess)

                    // Animated checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(animateSuccess ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateSuccess)
                }

                // Success message
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Health.Intelligence.all_clear_title.localized)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(LocalizationKeys.Health.Intelligence.all_clear_message.localized)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }

            // Positive reinforcement - What this means
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)

                        Text(LocalizationKeys.Health.Intelligence.this_means.localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textSecondary)

                        Spacer()
                    }

                    VStack(spacing: 4) {
                        PositiveIndicator(text: LocalizationKeys.Health.Intelligence.recovery_optimal.localized)
                        PositiveIndicator(text: LocalizationKeys.Health.Intelligence.fitness_stable.localized)
                        PositiveIndicator(text: LocalizationKeys.Health.Intelligence.no_concerns.localized)
                    }
                }
                .padding(16)
                .background(theme.colors.backgroundSecondary.opacity(0.5))
                .cornerRadius(12)
            }

            // Next steps - Actionable guidance
            VStack(spacing: 8) {
                Text(LocalizationKeys.Health.Intelligence.keep_great_work.localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(LocalizationKeys.Health.Intelligence.monitoring_message.localized)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .onAppear {
            animateSuccess = true
        }
    }
}

#Preview {
    EmptyInsightsView()
        .environment(\.theme, DefaultLightTheme())
}