import SwiftUI

struct EmptyIntelligenceView: View {
    @Environment(\.theme) private var theme
    @State private var animatePulse = false
    @State private var showingHealthKitAuth = false
    @State private var healthKitService = HealthKitService.shared

    var body: some View {
        VStack(spacing: 32) {
            // Enhanced visual - Animated brain with gradient
            VStack(spacing: 20) {
                ZStack {
                    // Background gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.accent.opacity(0.1), theme.colors.accent.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animatePulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animatePulse)

                    // Brain icon with gradient
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.colors.accent, theme.colors.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animatePulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animatePulse)
                }
            }

            // Story-driven messaging
            VStack(spacing: 16) {
                Text(LocalizationKeys.Health.Intelligence.ready_unlock_title.localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text(LocalizationKeys.Health.Intelligence.connect_data_message.localized)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 6) {
                        FeatureBullet(icon: "heart.fill", text: LocalizationKeys.Health.Intelligence.feature_recovery.localized, color: .red)
                        FeatureBullet(icon: "figure.strengthtraining.traditional", text: LocalizationKeys.Health.Intelligence.feature_fitness.localized, color: .blue)
                        FeatureBullet(icon: "chart.line.uptrend.xyaxis", text: LocalizationKeys.Health.Intelligence.feature_trends.localized, color: .green)
                        FeatureBullet(icon: "lightbulb.fill", text: LocalizationKeys.Health.Intelligence.feature_ai_recommendations.localized, color: .orange)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)

            // Actionable CTA
            VStack(spacing: 12) {
                if !healthKitService.isAuthorized {
                    // Primary CTA - HealthKit Connection
                    Button(action: {
                        showingHealthKitAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizationKeys.Health.Intelligence.connect_apple_health.localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text(LocalizationKeys.Health.Intelligence.enable_insights.localized)
                                    .font(.caption)
                                    .opacity(0.9)
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: theme.colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(animatePulse ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animatePulse)
                } else {
                    // Alternative CTA - Manual refresh
                    Button(action: {
                        // Trigger manual health intelligence generation
                        Task {
                            // This would trigger a reload of the parent view
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text(LocalizationKeys.Health.Intelligence.generate_insights.localized)
                        }
                        .font(.headline)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                // Helper text
                Text(LocalizationKeys.Health.Intelligence.privacy_message.localized)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
        .onAppear {
            animatePulse = true
        }
        .sheet(isPresented: $showingHealthKitAuth) {
            HealthKitAuthorizationView()
        }
    }
}

#Preview {
    EmptyIntelligenceView()
        .environment(\.theme, DefaultLightTheme())
}