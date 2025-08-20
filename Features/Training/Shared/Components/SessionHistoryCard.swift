import SwiftUI

struct SessionHistoryCard: View {
    @Environment(\.theme) private var theme
    let workoutName: String
    let date: Date
    let duration: TimeInterval?
    let primaryMetric: SessionMetric
    let secondaryMetrics: [SessionMetric]
    let achievements: [String]
    let feeling: WorkoutFeeling?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutName)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        HStack(spacing: theme.spacing.s) {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            if let duration = duration {
                                Text("•")
                                    .foregroundColor(theme.colors.textSecondary)
                                Text(formatDuration(duration))
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Achievements Badge
                    if !achievements.isEmpty {
                        achievementBadge
                    }
                }
                
                // Metrics
                HStack(spacing: theme.spacing.xl) {
                    // Primary Metric (larger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(primaryMetric.value)
                            .font(theme.typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        Text(primaryMetric.label)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Secondary Metrics
                    ForEach(secondaryMetrics.prefix(2)) { metric in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric.value)
                                .font(theme.typography.body)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.textPrimary)
                            Text(metric.label)
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Feeling
                if let feeling = feeling {
                    HStack(spacing: theme.spacing.s) {
                        Text(feeling.emoji)
                            .font(.body)
                        Text(feeling.description)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer()
                        
                        if let note = feeling.note {
                            Text(note)
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                                .italic()
                                .lineLimit(1)
                        }
                    }
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                }
            }
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var achievementBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: achievements.contains("PR") ? "trophy.fill" : "star.fill")
                .font(.title3)
                .foregroundColor(achievements.contains("PR") ? theme.colors.warning : theme.colors.success)
            
            if achievements.count == 1 {
                Text(achievements[0])
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textSecondary)
            } else {
                Text("\(achievements.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

struct SessionMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String?
    
    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }
}

struct WorkoutFeeling {
    let emoji: String
    let description: String
    let note: String?
    
    init(emoji: String, description: String, note: String? = nil) {
        self.emoji = emoji
        self.description = description
        self.note = note
    }
    
    static func from(rating: Int, note: String? = nil) -> WorkoutFeeling {
        switch rating {
        case 1:
            return WorkoutFeeling(emoji: "😫", description: "Exhausted", note: note)
        case 2:
            return WorkoutFeeling(emoji: "😓", description: "Tough", note: note)
        case 3:
            return WorkoutFeeling(emoji: "😊", description: "Good", note: note)
        case 4:
            return WorkoutFeeling(emoji: "💪", description: "Strong", note: note)
        case 5:
            return WorkoutFeeling(emoji: "🔥", description: "Amazing", note: note)
        default:
            return WorkoutFeeling(emoji: "😐", description: "Normal", note: note)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SessionHistoryCard(
            workoutName: "Push Day - Chest Focus",
            date: Date(),
            duration: 3600,
            primaryMetric: SessionMetric(label: "Total Volume", value: "12,500 kg"),
            secondaryMetrics: [
                SessionMetric(label: "Sets", value: "24"),
                SessionMetric(label: "Reps", value: "186")
            ],
            achievements: ["PR", "Streak"],
            feeling: WorkoutFeeling.from(rating: 4, note: "Felt strong today"),
            onTap: { print("History card tapped") }
        )
        
        SessionHistoryCard(
            workoutName: "5K Run",
            date: Date().addingTimeInterval(-86400),
            duration: 1560,
            primaryMetric: SessionMetric(label: "Distance", value: "5.0 km"),
            secondaryMetrics: [
                SessionMetric(label: "Pace", value: "5:12"),
                SessionMetric(label: "Calories", value: "312")
            ],
            achievements: [],
            feeling: WorkoutFeeling.from(rating: 3),
            onTap: { print("History card tapped") }
        )
    }
    .padding()
}