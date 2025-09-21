import SwiftUI

/**
 * Recent activity row component for displaying workout sessions.
 *
 * Shows workout type, name, completion date, and duration in a compact row format.
 * Used in dashboard recent activity sections and workout history lists.
 *
 * Features:
 * - Workout type icon with color coding
 * - Session name and relative date display
 * - Duration formatting
 * - Consistent spacing and typography
 * - Service-based formatting utilities
 */
struct RecentActivityRow: View {
    @Environment(\.theme) private var theme

    let session: any WorkoutSession

    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Workout type icon
            Image(systemName: workoutTypeIcon)
                .font(.body)
                .foregroundColor(workoutTypeColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutName)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(formattedRelativeDate)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Text(formattedDuration)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.s)
    }

    // MARK: - Computed Properties

    private var workoutTypeIcon: String {
        TrainingDashboardService.getWorkoutTypeIcon(for: session)
    }

    private var workoutTypeColor: Color {
        switch TrainingDashboardService.getWorkoutTypeColor(for: session) {
        case .strength:
            return .strengthColor
        case .cardio:
            return .cardioColor
        case .wod:
            return .gray
        }
    }

    private var formattedDuration: String {
        TrainingDashboardService.formatShortDuration(session.sessionDuration)
    }

    private var formattedRelativeDate: String {
        TrainingDashboardService.formatAbbreviatedRelativeDate(
            session.completedAt ?? session.startDate
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        // Mock sessions for preview
        RecentActivityRow(session: MockLiftSession())
        RecentActivityRow(session: MockCardioSession())
        Divider()
        RecentActivityRow(session: MockLiftSession())
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}

// MARK: - Mock Data for Preview

private struct MockLiftSession: WorkoutSession {
    var id: UUID = UUID()
    var workoutName: String = "Upper Body Strength"
    var startDate: Date = Date().addingTimeInterval(-3600)
    var completedAt: Date? = Date()
    var sessionDuration: TimeInterval = 3600 // 1 hour
    var isCompleted: Bool = true
}

private struct MockCardioSession: WorkoutSession {
    var id: UUID = UUID()
    var workoutName: String = "Morning Run"
    var startDate: Date = Date().addingTimeInterval(-7200)
    var completedAt: Date? = Date().addingTimeInterval(-3600)
    var sessionDuration: TimeInterval = 1800 // 30 minutes
    var isCompleted: Bool = true
}