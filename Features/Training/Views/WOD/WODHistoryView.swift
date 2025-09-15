import SwiftUI
import SwiftData

/**
 * WODHistoryView - Dedicated WOD history and statistics view
 * 
 * Displays comprehensive WOD completion history with stats, grouping,
 * and personal record tracking. Provides navigation to WOD details.
 */
struct WODHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Query private var user: [User]
    
    @Query(sort: [SortDescriptor(\WODResult.completedAt, order: .reverse)])
    private var wodResults: [WODResult]
    
    @State private var selectedWOD: WOD?
    @State private var searchText = ""
    
    private var currentUser: User? {
        user.first
    }
    
    private var filteredResults: [WODResult] {
        guard !searchText.isEmpty else { return wodResults }
        
        return wodResults.filter { result in
            result.wod?.name.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if filteredResults.isEmpty && searchText.isEmpty {
                historyEmptyState
            } else {
                VStack(spacing: 0) {
                    // Search Bar
                    if !wodResults.isEmpty {
                        searchBar
                    }
                    
                    // Stats Section
                    if !filteredResults.isEmpty {
                        historyStats
                    }
                    
                    // Results List
                    historyList
                }
            }
        }
        .sheet(item: $selectedWOD) { wod in
            WODDetailView(wod: wod)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)
            TextField("WOD ara...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.s)
    }
    
    // MARK: - Empty State
    
    private var historyEmptyState: some View {
        VStack(spacing: theme.spacing.l) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(theme.colors.textSecondary)
            
            Text(TrainingKeys.WOD.noHistoryTitle.localized)
                .font(.title3.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
            
            Text(TrainingKeys.WOD.noHistoryDesc.localized)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Stats Section
    
    private var historyStats: some View {
        HStack(spacing: theme.spacing.l) {
            WODStatCard(
                icon: "flame.fill",
                title: TrainingKeys.WOD.totalCompleted.localized,
                value: "\(filteredResults.count)",
                color: .orange
            )
            
            WODStatCard(
                icon: "trophy.fill", 
                title: TrainingKeys.WOD.personalRecords.localized,
                value: "\(personalRecordsCount)",
                color: .yellow
            )
            
            WODStatCard(
                icon: "calendar.badge.checkmark",
                title: TrainingKeys.WOD.thisMonth.localized,
                value: "\(thisMonthCount)",
                color: .green
            )
        }
        .padding(theme.spacing.m)
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                if filteredResults.isEmpty && !searchText.isEmpty {
                    // No search results
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(TrainingKeys.Search.noResults.localized)
                            .font(.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(TrainingKeys.Search.tryDifferentTerm.localized)
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(theme.spacing.xl)
                } else {
                    ForEach(groupedHistoryResults, id: \.0) { dateTitle, results in
                        // Date header
                        HStack {
                            Text(dateTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, theme.spacing.m)
                        .padding(.top, theme.spacing.m)
                        
                        // Results for this date
                        ForEach(results, id: \.id) { result in
                            WODHistoryRow(result: result)
                                .onTapGesture {
                                    if let wod = result.wod {
                                        selectedWOD = wod
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.bottom, theme.spacing.xl)
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupedHistoryResults: [(String, [WODResult])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let grouped = Dictionary(grouping: filteredResults) { result in
            Calendar.current.startOfDay(for: result.completedAt)
        }
        
        return grouped.map { date, results in
            let title: String
            if Calendar.current.isDateInToday(date) {
                title = "training.common.today".localized
            } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                title = formatter.string(from: date)
            } else {
                title = formatter.string(from: date)
            }
            return (title, results.sorted { $0.completedAt > $1.completedAt })
        }.sorted { $0.1.first?.completedAt ?? Date.distantPast > $1.1.first?.completedAt ?? Date.distantPast }
    }
    
    private var personalRecordsCount: Int {
        filteredResults.filter { result in
            if let wod = result.wod {
                return result == wod.personalRecord
            }
            return false
        }.count
    }
    
    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return filteredResults.filter { result in
            calendar.isDate(result.completedAt, equalTo: now, toGranularity: .month)
        }.count
    }
}

// MARK: - WOD Stat Card

struct WODStatCard: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(theme.spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - WOD History Row

struct WODHistoryRow: View {
    @Environment(\.theme) private var theme
    
    let result: WODResult
    
    private var isPR: Bool {
        if let wod = result.wod {
            return result == wod.personalRecord
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // WOD Icon
            Image(systemName: isPR ? "trophy.fill" : "flame.fill")
                .font(.title3)
                .foregroundColor(isPR ? .yellow : .orange)
                .frame(width: 32)
            
            // WOD Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.wod?.name ?? "Unknown WOD")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack {
                    if let totalTime = result.totalTime {
                        Text(formatTime(totalTime))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.colors.accent)
                    }
                    
                    if let rounds = result.rounds {
                        Text("\(rounds) rounds")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if isPR {
                        Text("PR")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.yellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Date
            Text(formatDate(result.completedAt))
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal, theme.spacing.m)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    WODHistoryView()
        .environment(TrainingCoordinator())
        .modelContainer(for: [
            WOD.self,
            WODResult.self,
            User.self
        ], inMemory: true)
}