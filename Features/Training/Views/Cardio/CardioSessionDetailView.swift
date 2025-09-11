import SwiftUI
import SwiftData

struct CardioSessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    let session: CardioSession
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header Stats
                    headerStatsSection
                    
                    
                    // Detailed Metrics
                    detailedMetricsSection
                    
                    // Performance Analysis
                    performanceSection
                    
                    // Notes Section
                    if let notes = session.sessionNotes, !notes.isEmpty {
                        notesSection
                    }
                }
                .padding(.vertical, theme.spacing.m)
            }
            .navigationTitle(session.workoutName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonKeys.Onboarding.Common.close.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Stats Section
    private var headerStatsSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Date and Duration
            VStack(spacing: theme.spacing.s) {
                Text(formatWorkoutDate(session.completedAt ?? session.startDate))
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text(formatDuration(TimeInterval(session.totalDuration)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            // Primary Metrics Grid
            HStack(spacing: theme.spacing.m) {
                if session.totalDistance > 0 {
                    QuickStatCard(
                        icon: "ruler",
                        title: TrainingKeys.Cardio.distance.localized,
                        value: UnitsFormatter.formatDistance(meters: session.totalDistance, system: unitSettings.unitSystem),
                        subtitle: "",
                        color: theme.colors.accent
                    )
                }
                
                if let pace = session.formattedAveragePace {
                    QuickStatCard(
                        icon: "timer",
                        title: TrainingKeys.Cardio.pace.localized,
                        value: pace,
                        subtitle: "",
                        color: theme.colors.success
                    )
                }
                
                if let calories = session.totalCaloriesBurned, calories > 0 {
                    QuickStatCard(
                        icon: "flame.fill",
                        title: TrainingKeys.Cardio.calories.localized,
                        value: "\(calories)",
                        subtitle: "kcal",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    
    // MARK: - Detailed Metrics Section
    private var detailedMetricsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Detailed Stats")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.s) {
                if let avgSpeed = session.averageSpeed, avgSpeed > 0 {
                    DetailStatRow(
                        label: TrainingKeys.Cardio.avgSpeed.localized,
                        value: UnitsFormatter.formatSpeed(kmh: avgSpeed, system: unitSettings.unitSystem)
                    )
                    Divider()
                }
                
                
                if let elevation = session.elevationGain, elevation > 0 {
                    DetailStatRow(
                        label: "Elevation Gain",
                        value: UnitsFormatter.formatDistance(meters: elevation, system: unitSettings.unitSystem)
                    )
                    Divider()
                }
                
                if let avgHR = session.averageHeartRate, avgHR > 0 {
                    DetailStatRow(
                        label: "Avg Heart Rate",
                        value: "\(Int(avgHR)) bpm"
                    )
                    Divider()
                }
                
                if let maxHR = session.maxHeartRate, maxHR > 0 {
                    DetailStatRow(
                        label: "Max Heart Rate",
                        value: "\(Int(maxHR)) bpm"
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Performance")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.s) {
                // Personal Records
                if !session.personalRecordsHit.isEmpty {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text(TrainingKeys.Cardio.personalRecord.localized)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, theme.spacing.s)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(theme.radius.s)
                }
                
                // Effort Rating
                if let feeling = session.feeling {
                    HStack {
                        Text(session.feelingEmoji)
                            .font(.title2)
                        Text(feeling.capitalized)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, theme.spacing.s)
                    .background(theme.colors.cardBackground)
                    .cornerRadius(theme.radius.s)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Notes")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            Text(session.sessionNotes ?? "")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal)
                .padding(.vertical, theme.spacing.m)
                .background(theme.colors.cardBackground)
                .cornerRadius(theme.radius.m)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



#Preview {
    let session = CardioSession()
    
    CardioSessionDetailView(session: session)
        .environment(UnitSettings.shared)
}