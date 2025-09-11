import SwiftUI
import SwiftData

struct LiftAnalyticsCard: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    let sessions: [LiftSession]
    let currentUser: User?
    
    private var weeklyStats: (sessions: Int, volume: Double, sets: Int, avgDuration: TimeInterval) {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let weeklySessions = sessions.filter { session in
            session.isCompleted && session.startDate >= weekStart
        }
        
        let totalVolume = weeklySessions.reduce(into: 0.0) { $0 += $1.totalVolume }
        let totalSets = weeklySessions.reduce(into: 0) { $0 += $1.totalSets }
        let sessionCount = weeklySessions.count
        
        // Calculate average duration
        let totalDuration = weeklySessions.reduce(0.0) { $0 + ($1.endDate?.timeIntervalSince($1.startDate) ?? 0) }
        let avgDuration = sessionCount > 0 ? totalDuration / Double(sessionCount) : 0
        
        return (sessionCount, totalVolume, totalSets, avgDuration)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Summary")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Your strength training progress this week")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
            }
            
            // Stats Grid
            HStack(spacing: theme.spacing.m) {
                // Sessions Count
                QuickStatCard(
                    icon: "dumbbell.fill",
                    title: "Sessions",
                    value: "\(weeklyStats.sessions)",
                    subtitle: "this week",
                    color: .strengthColor
                )
                
                // Total Volume
                QuickStatCard(
                    icon: "chart.bar.fill",
                    title: "Volume",
                    value: formatVolume(weeklyStats.volume),
                    subtitle: "lifted",
                    color: theme.colors.success
                )
                
                // Total Sets
                if weeklyStats.sets > 0 {
                    QuickStatCard(
                        icon: "list.number",
                        title: "Sets",
                        value: "\(weeklyStats.sets)",
                        subtitle: "completed",
                        color: .orange
                    )
                }
            }
            
            // Average Duration
            if weeklyStats.sessions > 0 {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(theme.colors.textSecondary)
                    Text("Avg Duration: \(formatDuration(weeklyStats.avgDuration))")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume == 0 { return "0" }
        
        let volumeInKg = unitSettings.unitSystem == .metric ? volume : volume * 2.20462
        let unit = unitSettings.unitSystem == .metric ? "kg" : "lbs"
        
        if volumeInKg >= 1000 {
            return String(format: "%.1fk%@", volumeInKg / 1000, unit)
        } else {
            return String(format: "%.0f%@", volumeInKg, unit)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

#Preview {
    let mockWorkout = LiftWorkout(name: "Test Workout")
    let session1 = LiftSession(workout: mockWorkout)
    
    LiftAnalyticsCard(sessions: [session1], currentUser: nil)
        .environment(UnitSettings.shared)
}