import SwiftUI
import SwiftData

struct LiftHistorySection: View {
    @Environment(\.theme) private var theme
    @Query(sort: \LiftSession.startDate, order: .reverse) private var sessions: [LiftSession]
    
    private var completedSessions: [LiftSession] {
        sessions.filter { $0.isCompleted }
    }
    
    private var groupedSessions: [(key: String, value: [LiftSession])] {
        let grouped = Dictionary(grouping: completedSessions) { session in
            formatMonthYear(session.startDate)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        ScrollView {
            contentView
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if completedSessions.isEmpty {
            emptyStateView
                .padding(.top, 100)
        } else {
            sessionsList
                .padding(.vertical, theme.spacing.m)
        }
    }
    
    private var sessionsList: some View {
        LazyVStack(spacing: theme.spacing.xl, pinnedViews: .sectionHeaders) {
            ForEach(groupedSessions, id: \.key) { month, sessions in
                sessionSection(month: month, sessions: sessions)
            }
        }
    }
    
    @ViewBuilder
    private func sessionSection(month: String, sessions: [LiftSession]) -> some View {
        Section {
            ForEach(sessions, id: \.id) { session in
                sessionCard(for: session)
                    .padding(.horizontal)
            }
        } header: {
            sectionHeader(month: month, count: sessions.count)
        }
    }
    
    private func sessionCard(for session: LiftSession) -> some View {
        SessionHistoryCard(
            workoutName: session.workout.localizedName,
            date: session.startDate,
            duration: session.duration,
            primaryMetric: SessionMetric(
                label: "training.lift.stats.volume".localized,
                value: formatVolume(session.totalVolume)
            ),
            secondaryMetrics: buildSecondaryMetrics(for: session),
            achievements: buildAchievements(for: session),
            feeling: buildFeeling(for: session),
            onTap: { viewSessionDetail(session) }
        )
    }
    
    private func buildSecondaryMetrics(for session: LiftSession) -> [SessionMetric] {
        [
            SessionMetric(
                label: "training.lift.stats.sets".localized,
                value: "\(session.totalSets)"
            ),
            SessionMetric(
                label: "training.lift.stats.exercises".localized,
                value: "\(session.exercises.count)"
            )
        ]
    }
    
    private func buildFeeling(for session: LiftSession) -> WorkoutFeeling? {
        guard let feeling = session.feeling else { return nil }
        return WorkoutFeeling.from(rating: feeling)
    }
    
    private func sectionHeader(month: String, count: Int) -> some View {
        HStack {
            Text(month)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            Text("\(count) \(count == 1 ? "session" : "sessions")")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.s)
        .background(theme.colors.backgroundPrimary.opacity(0.95))
    }
    
    private var emptyStateView: some View {
        EmptyStateCard(
            icon: "clock.arrow.circlepath",
            title: "training.lift.noHistory".localized,
            message: "training.lift.noHistoryMessage".localized,
            primaryAction: .init(
                title: "training.lift.startWorkout".localized,
                icon: "play.circle.fill",
                action: { /* Start workout */ }
            )
        )
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return "\(formatter.string(from: NSNumber(value: volume)) ?? "0") kg"
    }
    
    private func buildAchievements(for session: LiftSession) -> [String] {
        var achievements: [String] = []
        
        if !session.prsHit.isEmpty {
            achievements.append("PR")
        }
        
        if session.totalVolume > 10000 {
            achievements.append("10K+")
        }
        
        if session.duration > 3600 {
            achievements.append("1h+")
        }
        
        return achievements
    }
    
    private func viewSessionDetail(_ session: LiftSession) {
        // Navigate to session detail view
        Logger.info("View session detail: \(session.id)")
    }
}