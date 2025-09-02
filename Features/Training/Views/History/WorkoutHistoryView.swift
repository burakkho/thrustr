import SwiftUI
import SwiftData

// MARK: - WorkoutSession Protocol (shared from TrainingDashboardView)
protocol WorkoutSession {
    var workoutName: String { get }
    var startDate: Date { get }
    var completedAt: Date? { get }
    var sessionDuration: TimeInterval { get }
    var isCompleted: Bool { get }
}

extension LiftSession: WorkoutSession {
    var workoutName: String {
        workout.name
    }
    
    var completedAt: Date? {
        endDate
    }
    
    var sessionDuration: TimeInterval {
        self.duration
    }
}

extension CardioSession: WorkoutSession {
    var sessionDuration: TimeInterval {
        TimeInterval(self.duration)
    }
}

struct WorkoutHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \LiftSession.startDate, order: .reverse) private var liftSessions: [LiftSession]
    @Query(sort: \CardioSession.startDate, order: .reverse) private var cardioSessions: [CardioSession]
    @Query(sort: \WODResult.date, order: .reverse) private var wodResults: [WODResult]
    
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var searchText = ""
    
    private var filteredSessions: [any WorkoutSession] {
        var allSessions: [any WorkoutSession] = []
        
        switch selectedFilter {
        case .all:
            allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })
            allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })
        case .strength:
            allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })
        case .cardio:
            allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })
        case .wod:
            // WODResult doesn't conform to WorkoutSession yet
            break
        }
        
        return allSessions
            .sorted { session1, session2 in
                let date1 = session1.completedAt ?? session1.startDate
                let date2 = session2.completedAt ?? session2.startDate
                return date1 > date2
            }
            .filter { session in
                searchText.isEmpty || session.workoutName.localizedCaseInsensitiveContains(searchText)
            }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                
                // Search Bar
                searchBar
                
                // Content
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle(TrainingKeys.Dashboard.recentActivity.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonKeys.Onboarding.Common.done.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.s) {
                ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, theme.spacing.s)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)
            
            TextField(CommonKeys.Onboarding.Common.search.localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(theme.spacing.s)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.radius.s)
        .padding(.horizontal)
        .padding(.bottom, theme.spacing.s)
    }
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(Array(filteredSessions.enumerated()), id: \.offset) { index, session in
                    WorkoutHistoryRow(session: session)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, theme.spacing.s)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: "No Workout History",
            message: "Complete your first workout to see your training history here.",
            primaryTitle: "Start Training",
            primaryAction: { dismiss() }
        )
        .padding(.top, theme.spacing.xxl)
    }
}

// MARK: - Supporting Types & Views

enum WorkoutFilter: CaseIterable {
    case all, strength, cardio, wod
    
    var title: String {
        switch self {
        case .all: return CommonKeys.Onboarding.Common.all.localized
        case .strength: return TrainingKeys.Lift.title.localized
        case .cardio: return TrainingKeys.Cardio.title.localized
        case .wod: return TrainingKeys.WOD.title.localized
        }
    }
}

struct FilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : theme.colors.textSecondary)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(
                    isSelected ? theme.colors.accent : theme.colors.surfaceSecondary
                )
                .cornerRadius(theme.radius.s)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutHistoryRow: View {
    @Environment(\.theme) private var theme
    let session: any WorkoutSession
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Workout type icon
            Image(systemName: workoutTypeIcon)
                .font(.title3)
                .foregroundColor(workoutTypeColor)
                .frame(width: 32, height: 32)
                .background(workoutTypeColor.opacity(0.1))
                .cornerRadius(theme.radius.s)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(formatDate(session.completedAt ?? session.startDate))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(session.sessionDuration))
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(workoutTypeLabel)
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private var workoutTypeIcon: String {
        if session is LiftSession { return "dumbbell.fill" }
        if session is CardioSession { return "heart.fill" }
        return "flame.fill"
    }
    
    private var workoutTypeColor: Color {
        if session is LiftSession { return .strengthColor }
        if session is CardioSession { return .cardioColor }
        return .wodColor
    }
    
    private var workoutTypeLabel: String {
        if session is LiftSession { return TrainingKeys.Lift.title.localized }
        if session is CardioSession { return TrainingKeys.Cardio.title.localized }
        return TrainingKeys.WOD.title.localized
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [
            LiftSession.self,
            CardioSession.self,
            WODResult.self
        ], inMemory: true)
}