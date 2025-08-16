import SwiftUI

struct WeeklyProgressSection: View {
    @Environment(\.theme) private var theme
    let stats: WeeklyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Dashboard.thisWeek.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.m) {
                WorkoutCountStat(count: stats.workoutCount)
                
                Divider()
                
                TotalVolumeStat(volume: stats.totalVolume)
                
                Divider()
                
                TotalTimeStat(duration: stats.totalDuration)
            }
            .padding()
            .dashboardSurfaceStyle()
        }
    }
}

// MARK: - Individual Stat Components
private struct WorkoutCountStat: View {
    @Environment(\.theme) private var theme
    let count: Int
    
    var body: some View {
        WeeklyStatRow(
            title: LocalizationKeys.Dashboard.Weekly.workoutCount.localized,
            value: "\(count)",
            icon: "dumbbell.fill",
            color: theme.colors.accent
        )
    }
}

private struct TotalVolumeStat: View {
    @Environment(\.theme) private var theme
    let volume: Double
    
    var body: some View {
        WeeklyStatRow(
            title: LocalizationKeys.Dashboard.Weekly.totalVolume.localized,
            value: "\(Int(volume)) kg",
            icon: "scalemass.fill",
            color: theme.colors.success
        )
    }
}

private struct TotalTimeStat: View {
    @Environment(\.theme) private var theme
    let duration: TimeInterval
    
    var body: some View {
        WeeklyStatRow(
            title: LocalizationKeys.Dashboard.Weekly.totalTime.localized,
            value: formatDuration(duration),
            icon: "clock.fill",
            color: theme.colors.warning
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)\(LocalizationKeys.Dashboard.Time.hours.localized) \(minutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        } else {
            return "\(minutes)\(LocalizationKeys.Dashboard.Time.minutes.localized)"
        }
    }
}

// MARK: - Weekly Stat Row Component
private struct WeeklyStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
        }
    }
}

#Preview {
    let stats = WeeklyStats(
        workoutCount: 4,
        totalVolume: 2500.0,
        totalDuration: 7200 // 2 hours
    )
    
    return WeeklyProgressSection(stats: stats)
        .padding()
}