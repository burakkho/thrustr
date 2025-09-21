import SwiftUI

struct AnalyticsHealthStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            // Celebration overlay
            celebrationOverlay
        )
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if celebrationType != .none {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: celebrationType.icon)
                        .font(.caption2)
                        .foregroundColor(celebrationType.color)
                        .scaleEffect(celebrationType.shouldAnimate ? celebrationType.scaleEffect : 1.0)
                        .animation(
                            celebrationType.shouldAnimate ?
                                .easeInOut(duration: celebrationType.animationDuration).repeatForever(autoreverses: true) :
                                .none,
                            value: celebrationType.shouldAnimate
                        )
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AnalyticsHealthStoryMetric(
            icon: "figure.walk",
            title: "Today's Steps",
            value: "8.5k",
            color: Color.blue,
            celebrationType: CelebrationType.progress
        )

        AnalyticsHealthStoryMetric(
            icon: "flame.fill",
            title: "Active Calories",
            value: "420",
            color: .orange,
            celebrationType: .celebration
        )

        AnalyticsHealthStoryMetric(
            icon: "heart.fill",
            title: "Recovery Score",
            value: "92%",
            color: .red,
            celebrationType: .fire
        )

        AnalyticsHealthStoryMetric(
            icon: "moon.fill",
            title: "Sleep Quality",
            value: "6.5h",
            color: .purple,
            celebrationType: .none
        )
    }
    .environment(ThemeManager())
    .padding()
}