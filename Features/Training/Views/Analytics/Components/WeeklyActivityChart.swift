import SwiftUI
import Charts

struct WeeklyActivityChart: View {
    @Environment(\.theme) private var theme
    let activityData: [DailyActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Chart Title
            HStack {
                Text(TrainingKeys.Analytics.thisWeekActivity.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            
            // Chart
            Chart(activityData, id: \.dayName) { data in
                BarMark(
                    x: .value(TrainingKeys.Analytics.day.localized, data.dayName),
                    y: .value(TrainingKeys.Analytics.liftSessions.localized, data.liftSessions)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value(TrainingKeys.Analytics.day.localized, data.dayName),
                    y: .value(TrainingKeys.Analytics.cardioSessions.localized, data.cardioSessions)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 180)
            .chartYScale(domain: 0...3) // Max 3 sessions per day
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(theme.colors.textSecondary.opacity(0.2))
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.background(.clear)
            }
            
            // Legend
            HStack(spacing: theme.spacing.l) {
                Label(DashboardKeys.QuickActions.lift.localized, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .labelStyle(ChartLegendLabelStyle())
                
                Label(DashboardKeys.QuickActions.cardio.localized, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                    .labelStyle(ChartLegendLabelStyle())
                
                Spacer()
                
                // Total sessions this week
                if !activityData.isEmpty {
                    let totalSessions = activityData.reduce(0) { $0 + $1.totalSessions }
                    Text("\(totalSessions) sessions this week")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(.top, theme.spacing.s)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

// MARK: - Custom Legend Label Style
private struct ChartLegendLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 8))
            configuration.title
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Chart with data
        WeeklyActivityChart(activityData: [
            DailyActivity(date: Date(), dayName: "Mon", liftSessions: 1, cardioSessions: 0, totalSessions: 1),
            DailyActivity(date: Date(), dayName: "Tue", liftSessions: 0, cardioSessions: 1, totalSessions: 1),
            DailyActivity(date: Date(), dayName: "Wed", liftSessions: 1, cardioSessions: 1, totalSessions: 2),
            DailyActivity(date: Date(), dayName: "Thu", liftSessions: 0, cardioSessions: 0, totalSessions: 0),
            DailyActivity(date: Date(), dayName: "Fri", liftSessions: 1, cardioSessions: 0, totalSessions: 1),
            DailyActivity(date: Date(), dayName: "Sat", liftSessions: 0, cardioSessions: 1, totalSessions: 1),
            DailyActivity(date: Date(), dayName: "Sun", liftSessions: 0, cardioSessions: 0, totalSessions: 0)
        ])
        
        // Empty state - using separate EmptyActivityChart component
    }
    .padding()
}