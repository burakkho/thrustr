import SwiftUI

// MARK: - Header
struct WorkoutHeaderView: View {
    let workoutName: String
    let startTime: Date
    let endTime: Date?
    let isActive: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.title2)
                        .fontWeight(.bold)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? theme.colors.success : theme.colors.textSecondary)
                            .frame(width: 8, height: 8)
                        Text(isActive ? LocalizationKeys.Training.Active.statusActive.localized : LocalizationKeys.Training.Active.statusCompleted.localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            Divider()
        }
        .background(theme.colors.backgroundPrimary)
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        if let end = endTime { return "\(start) - \(formatter.string(from: end))" }
        return start
    }
}

// MARK: - Empty State
struct EmptyWorkoutState: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.accent)
                .symbolEffect(.pulse)

            VStack(spacing: theme.spacing.m) {
                Text(LocalizationKeys.Training.Detail.emptyTitle.localized)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(LocalizationKeys.Training.Detail.emptySubtitle.localized)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Label(LocalizationKeys.Training.Detail.addPart.localized, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.m)
                    .background(theme.colors.accent)
                    .cornerRadius(12)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 60)
    }
}
