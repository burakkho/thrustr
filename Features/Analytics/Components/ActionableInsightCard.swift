import SwiftUI

struct AnalyticsActionableInsightCard: View {
    let insight: HealthInsight
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        cardContent
            .frame(maxWidth: .infinity, idealHeight: 140)
            .padding(theme.spacing.m)
            .background(cardBackground)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .contentShape(Rectangle())
            .onTapGesture(perform: handleTap)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: handlePressState)
    }

    private var cardContent: some View {
        VStack(spacing: 12) {
            headerSection
            contentSection
            actionSection
        }
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: priorityIcon)
                .font(.title2)
                .foregroundColor(priorityColor)

            Spacer()

            Text(priorityText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(priorityColor))
        }
    }

    private var contentSection: some View {
        VStack(spacing: 6) {
            Text(insight.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(insight.message)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
    }

    private var actionSection: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.caption)
            Text(CommonKeys.Analytics.tapToExplore.localized)
                .font(.caption2)
        }
        .foregroundColor(priorityColor.opacity(0.8))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.radius.m)
            .fill(theme.colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(priorityColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: isPressed ? priorityColor.opacity(0.3) : Color.black.opacity(0.1),
                radius: isPressed ? 6 : 2,
                y: isPressed ? 3 : 1
            )
    }

    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        action()
    }

    private func handlePressState(_ pressing: Bool) {
        isPressed = pressing
    }

    // MARK: - Computed Properties
    private var priorityColor: Color {
        switch insight.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private var priorityIcon: String {
        switch insight.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "lightbulb.fill"
        }
    }

    private var priorityText: String {
        switch insight.priority {
        case .high: return "Urgent"
        case .medium: return "Medium"
        case .low: return "Info"
        }
    }
}

struct AnalyticsCompactInsightCard: View {
    let insight: HealthInsight
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(priorityColor.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 4, height: 4)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    Text(insight.message)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(12)
            .background(theme.colors.backgroundSecondary)
            .cornerRadius(8)
        }
        .buttonStyle(PressableStyle())
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview {
    let mockInsight = HealthInsight(
        type: .recovery,
        title: "Poor Sleep Quality Detected",
        message: "Your sleep duration was below optimal for 3 consecutive nights. Consider adjusting bedtime routine.",
        priority: .high,
        date: Date(),
        actionable: true,
        action: "Try going to bed 30 minutes earlier tonight"
    )

    VStack(spacing: 16) {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            AnalyticsActionableInsightCard(insight: mockInsight) {
                print("Insight tapped")
            }

            AnalyticsActionableInsightCard(insight: mockInsight) {
                print("Insight tapped")
            }
        }

        AnalyticsCompactInsightCard(insight: mockInsight) {
            print("Compact insight tapped")
        }
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}