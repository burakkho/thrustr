import SwiftUI

struct HealthInsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let confidence: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Text(confidence)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(insight)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Alternative Insight Card Styles

struct HealthInsightCardCompact: View {
    let icon: String
    let title: String
    let insight: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // Icon container
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(insight)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct HealthInsightCardDetailed: View {
    let icon: String
    let title: String
    let insight: String
    let confidence: String
    let color: Color
    let metric: String?
    let trend: String?
    @Environment(\.theme) private var theme

    init(
        icon: String,
        title: String,
        insight: String,
        confidence: String,
        color: Color,
        metric: String? = nil,
        trend: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.insight = insight
        self.confidence = confidence
        self.color = color
        self.metric = metric
        self.trend = trend
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and confidence
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)

                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()

                confidenceBadge
            }

            // Metric row (if provided)
            if let metric = metric {
                HStack {
                    Text("Current Value")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Spacer()

                    Text(metric)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }

            // Trend row (if provided)
            if let trend = trend {
                HStack {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Spacer()

                    Text(trend)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }

            // Insight text
            Text(insight)
                .font(.body)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var confidenceBadge: some View {
        Text(confidence)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Standard insight cards
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            HealthInsightCard(
                icon: "brain.head.profile",
                title: "Recovery Status",
                insight: "Excellent recovery markers. Your body is well-rested and ready for training.",
                confidence: "High",
                color: .purple
            )

            HealthInsightCard(
                icon: "heart.text.square",
                title: "Activity Pattern",
                insight: "Solid activity level. You're on track for health goals.",
                confidence: "Medium",
                color: .blue
            )

            HealthInsightCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Health Trend",
                insight: "Positive trend in daily activity. Keep up the momentum!",
                confidence: "High",
                color: .green
            )

            HealthInsightCard(
                icon: "lightbulb.fill",
                title: "Recommendation",
                insight: "Great work! Add strength training for complete fitness.",
                confidence: "Medium",
                color: .orange
            )
        }

        // Compact insight cards
        VStack(spacing: 8) {
            HealthInsightCardCompact(
                icon: "figure.walk",
                title: "Daily Steps",
                insight: "You're 2,500 steps away from your daily goal",
                color: .blue
            )

            HealthInsightCardCompact(
                icon: "bed.double.fill",
                title: "Sleep Quality",
                insight: "Great sleep streak! 7+ hours for 5 days",
                color: .purple
            )
        }

        // Detailed insight card
        HealthInsightCardDetailed(
            icon: "heart.fill",
            title: "Cardiovascular Health",
            insight: "Your resting heart rate has improved by 5% over the past month. This indicates enhanced cardiovascular fitness and better recovery. Continue your current exercise routine and focus on consistent sleep patterns.",
            confidence: "High",
            color: .red,
            metric: "62 BPM",
            trend: "↓ Improving"
        )
    }
    .environment(ThemeManager())
    .padding()
}