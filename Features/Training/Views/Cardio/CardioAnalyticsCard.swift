import SwiftUI
import SwiftData

struct CardioAnalyticsCard: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    
    let sessions: [CardioSession]
    let currentUser: User?
    
    private var weeklyStats: (sessions: Int, distance: Double, calories: Int, avgPace: String) {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let weeklySessions = sessions.filter { session in
            session.isCompleted && calendar.isDate(session.startDate, equalTo: weekStart, toGranularity: .weekOfYear)
        }
        
        let totalDistance = weeklySessions.reduce(0.0) { $0 + $1.totalDistance }
        let totalCalories = weeklySessions.reduce(0) { $0 + ($1.totalCaloriesBurned ?? 0) }
        let sessionCount = weeklySessions.count
        
        // Calculate average pace
        let totalTime = weeklySessions.reduce(0.0) { $0 + Double($1.totalDuration) }
        let avgPace = totalDistance > 0 ? (totalTime / 60) / (totalDistance / 1000) : 0
        let avgPaceFormatted = avgPace > 0 ? UnitsFormatter.formatPace(minPerKm: avgPace, system: UnitSettings.shared.unitSystem) : "--"
        
        return (sessionCount, totalDistance, totalCalories, avgPaceFormatted)
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
                    
                    Text("Your cardio performance this week")
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
                    icon: "figure.run",
                    title: "Sessions",
                    value: "\(weeklyStats.sessions)",
                    subtitle: "this week",
                    color: theme.colors.accent
                )
                
                // Total Distance
                QuickStatCard(
                    icon: "ruler",
                    title: TrainingKeys.Cardio.distance.localized,
                    value: UnitsFormatter.formatDistance(meters: weeklyStats.distance, system: unitSettings.unitSystem),
                    subtitle: "total",
                    color: theme.colors.success
                )
                
                // Total Calories
                if weeklyStats.calories > 0 {
                    QuickStatCard(
                        icon: "flame.fill",
                        title: TrainingKeys.Cardio.calories.localized,
                        value: "\(weeklyStats.calories)",
                        subtitle: "burned",
                        color: .orange
                    )
                }
            }
            
            // Average Pace
            if weeklyStats.distance > 0 {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(theme.colors.textSecondary)
                    Text("Avg Pace: \(weeklyStats.avgPace)")
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
}


#Preview {
    let session1 = CardioSession()
    
    CardioAnalyticsCard(sessions: [session1], currentUser: User(name: "Test"))
        .environmentObject(UnitSettings.shared)
}