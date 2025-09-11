import SwiftUI
import SwiftData


struct WorkoutHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \LiftSession.startDate, order: .reverse) private var liftSessions: [LiftSession]
    @Query(sort: \CardioSession.startDate, order: .reverse) private var cardioSessions: [CardioSession]
    @Query(sort: \WODResult.completedAt, order: .reverse) private var wodResults: [WODResult]
    
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
        .background(theme.colors.surfaceElevated)
        .cornerRadius(theme.radius.s)
        .padding(.horizontal)
        .padding(.bottom, theme.spacing.s)
    }
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(filteredSessions, id: \.id) { session in
                    WorkoutHistoryRow(
                        session: session,
                        onEdit: {
                            // Session editing functionality placeholder
                            print("Edit session: \(session.workoutName)")
                        },
                        onDelete: {
                            deleteSession(session)
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, theme.spacing.s)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: TrainingKeys.EmptyStatesNew.noWorkoutHistory.localized,
            message: TrainingKeys.EmptyStatesNew.noWorkoutHistoryMessage.localized,
            primaryTitle: "Start Training",
            primaryAction: { dismiss() }
        )
        .padding(.top, theme.spacing.xxl)
    }
    
    // MARK: - Actions
    private func deleteSession(_ session: any WorkoutSession) {
        do {
            // Delete based on session type
            if let liftSession = session as? LiftSession {
                modelContext.delete(liftSession)
            } else if let cardioSession = session as? CardioSession {
                modelContext.delete(cardioSession)
            } else {
                // Handle other session types if needed
                Logger.warning("Unknown session type for deletion")
            }
            
            try modelContext.save()
            Logger.success("Workout session deleted successfully")
            
        } catch {
            Logger.error("Failed to delete workout session: \(error)")
        }
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


struct WorkoutHistoryRow: View {
    @Environment(\.theme) private var theme
    let session: any WorkoutSession
    let onEdit: (() -> Void)?
    let onDelete: () -> Void
    
    init(session: any WorkoutSession, onEdit: (() -> Void)? = nil, onDelete: @escaping () -> Void) {
        self.session = session
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        EditableRow(
            content: {
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
            },
            onRemove: onDelete,
            onEdit: onEdit,
            deleteTitle: "Delete Workout",
            deleteMessage: "Are you sure you want to delete this workout session? This action cannot be undone."
        )
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