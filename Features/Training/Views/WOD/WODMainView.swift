import SwiftUI
import SwiftData

struct WODMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Query private var user: [User]
    
    @Query(
        filter: #Predicate<WOD> { $0.isCustom == true },
        sort: [SortDescriptor<WOD>(\.updatedAt, order: .reverse)]
    ) private var customWODs: [WOD]
    
    @Query(sort: [SortDescriptor<WODResult>(\.completedAt, order: .reverse)])
    private var wodResults: [WODResult]
    
    @Query(
        filter: #Predicate<WOD> { $0.isCustom == false },
        sort: [SortDescriptor<WOD>(\.name)]
    ) private var benchmarkWODs: [WOD]
    
    @State private var selectedCategory: WODCategory = .custom
    @State private var searchText = ""
    @State private var selectedWOD: WOD?
    @State private var showingNewWOD = false
    @State private var showingQRScanner = false
    
    private var currentUser: User? {
        user.first
    }
    
    private var filteredWODs: [WOD] {
        // History is handled separately - return empty for WOD list
        guard selectedCategory != .history else { return [] }
        
        let categoryWODs: [WOD]
        
        switch selectedCategory {
        case .custom:
            categoryWODs = customWODs
        case .girls, .heroes, .opens:
            categoryWODs = benchmarkWODs.filter { wod in
                wod.category == selectedCategory.rawValue
            }
        case .history:
            categoryWODs = []
        }
        
        guard !searchText.isEmpty else {
            return Array(categoryWODs.prefix(20))
        }
        
        let searchResults = categoryWODs.filter { wod in
            wod.name.localizedCaseInsensitiveContains(searchText) ||
            (wod.movements?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false)
        }
        
        return Array(searchResults.prefix(15))
    }
    
    // MARK: - UI Components
    
    // Header removed - no duplicate buttons needed
    
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.s) {
                ForEach(WODCategory.allCases, id: \.self) { category in
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(theme.typography.body)
                                .fontWeight(selectedCategory == category ? .semibold : .regular)
                        }
                        .foregroundColor(selectedCategory == category ? theme.colors.accent : theme.colors.textSecondary)
                        .padding(.horizontal, theme.spacing.m)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.m)
                                .fill(selectedCategory == category ? theme.colors.accent.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.m)
                                .stroke(selectedCategory == category ? theme.colors.accent : Color.clear, lineWidth: 1)
                        )
                    }
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
            TextField("wod.search_placeholder".localized, text: $searchText)
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
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: theme.spacing.m) {
            QuickActionButton(
                title: "wod.create_new_metcon".localized,
                icon: "plus.circle.fill",
                subtitle: "wod.build_custom_workout".localized,
                style: .primary,
                size: .fullWidth,
                action: { showingNewWOD = true }
            )
            
            QuickActionButton(
                title: "wod.scan_qr".localized,
                icon: "qrcode.viewfinder",
                subtitle: "wod.import_shared_workouts".localized,
                style: .secondary,
                size: .fullWidth,
                action: { showingQRScanner = true }
            )
        }
        .padding(.horizontal)
    }
    
    private var wodsList: some View {
        ForEach(filteredWODs) { wod in
            UnifiedWorkoutCard(
                title: wod.name,
                subtitle: formatWODType(wod),
                description: formatMovements(wod),
                primaryStats: buildWODStats(for: wod),
                secondaryInfo: buildSecondaryInfo(for: wod),
                isFavorite: wod.isFavorite,
                cardStyle: .detailed,
                primaryAction: { selectedWOD = wod },
                secondaryAction: { startWOD(wod) }
            )
            .padding(.horizontal)
        }
    }
    
    private var emptyState: some View {
        EmptyStateCard(
            icon: "dumbbell",
            title: selectedCategory == .custom ? "wod.no_custom_metcon".localized : "wod.no_metcon_found".localized,
            message: selectedCategory == .custom ? 
                "wod.create_first_metcon".localized : 
                "wod.try_different_search".localized,
            primaryAction: .init(
                title: selectedCategory == .custom ? "wod.create_metcon".localized : "common.clear_search".localized,
                icon: selectedCategory == .custom ? "plus.circle.fill" : nil,
                action: {
                    if selectedCategory == .custom {
                        showingNewWOD = true
                    } else {
                        searchText = ""
                    }
                }
            )
        )
        .padding(.top, 50)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Selector
            categorySelector
            
            // Search Bar
            searchBar
            
            // Content
            if selectedCategory == .history {
                WODHistoryView()
            } else {
                ScrollView {
                    LazyVStack(spacing: theme.spacing.m) {
                        // WOD Cards
                        if !filteredWODs.isEmpty {
                            wodsList
                        } else if selectedCategory == .custom {
                            // Show quick actions only in empty state for custom
                            quickActionsSection
                        } else {
                            emptyState
                        }
                    }
                    .padding(.vertical, theme.spacing.m)
                }
            }
        }
        .sheet(isPresented: $showingNewWOD) {
            WODBuilderView()
        }
        .sheet(item: $selectedWOD) { wod in
            WODDetailView(wod: wod)
        }
        .fullScreenCover(isPresented: $showingQRScanner) {
            WODQRScannerView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatWODType(_ wod: WOD) -> String {
        switch wod.wodType {
        case .forTime:
            if let timeCap = wod.timeCap {
                return String(format: TrainingKeys.WorkoutTypes.forTimeWithCap.localized, "\(timeCap)")
            }
            return TrainingKeys.WorkoutTypes.forTime.localized
        case .amrap:
            return String(format: TrainingKeys.WorkoutTypes.amrapMinutes.localized, "\(wod.timeCap ?? 20)")
        case .emom:
            return String(format: TrainingKeys.WorkoutTypes.emomMinutes.localized, "\(wod.timeCap ?? 10)")
        case .custom:
            return TrainingKeys.WorkoutTypes.customFormat.localized
        }
    }
    
    private func formatMovements(_ wod: WOD) -> String {
        guard let movements = wod.movements, !movements.isEmpty else {
            return "No movements"
        }
        
        let limitedMovements = Array(movements.prefix(3))
        let movementNames = limitedMovements.map { $0.name }.joined(separator: ", ")
        
        if movements.count > 3 {
            return "\(movementNames) +\(movements.count - 3) more"
        }
        
        return movementNames
    }
    
    private func buildWODStats(for wod: WOD) -> [WorkoutStat] {
        var stats: [WorkoutStat] = []
        
        // Movement count
        stats.append(WorkoutStat(
            label: TrainingKeys.WOD.movements.localized,
            value: "\(wod.movements?.count ?? 0)",
            icon: "figure.strengthtraining.traditional"
        ))
        
        // Time/Rounds
        if let timeCap = wod.timeCap {
            stats.append(WorkoutStat(
                label: wod.wodType == .amrap ? TrainingKeys.Cardio.duration.localized : TrainingKeys.WOD.forTime.localized,
                value: "\(timeCap) \(TrainingKeys.Units.minutes.localized)",
                icon: "clock"
            ))
        } else if let rounds = wod.rounds {
            stats.append(WorkoutStat(
                label: TrainingKeys.WOD.rounds.localized,
                value: "\(rounds)",
                icon: "repeat"
            ))
        }
        
        // Personal Record
        if let bestResult = wodResults.filter({ $0.wodId == wod.id }).sorted(by: { $0.score > $1.score }).first {
            stats.append(WorkoutStat(
                label: TrainingKeys.TestResults.personalRecord.localized,
                value: formatScore(bestResult.score, type: wod.wodType),
                icon: "trophy.fill"
            ))
        }
        
        return stats
    }
    
    private func buildSecondaryInfo(for wod: WOD) -> [String] {
        var info: [String] = []
        
        // Difficulty
        if let difficulty = wod.difficulty {
            info.append(difficulty.capitalized)
        }
        
        // Last performed
        if let lastResult = wodResults.filter({ $0.wodId == wod.id }).sorted(by: { $0.completedAt > $1.completedAt }).first {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            info.append("\(TrainingKeys.Cardio.lastSession.localized): \(formatter.localizedString(for: lastResult.completedAt, relativeTo: Date()))")
        }
        
        // Category
        if !wod.isCustom {
            info.append(wod.category.capitalized)
        }
        
        return info
    }
    
    private func formatScore(_ score: Double, type: WODType) -> String {
        switch type {
        case .forTime:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .amrap:
            return "\(Int(score)) \(TrainingKeys.WOD.rounds.localized)"
        default:
            return "\(Int(score))"
        }
    }
    
    private func startWOD(_ wod: WOD) {
        // Set default weights based on user gender
        if let movements = wod.movements {
            for movement in movements {
                if let rxWeight = movement.rxWeight(for: currentUser?.gender) {
                    // Parse weight value from string (e.g., "43kg" -> 43)
                    let numbers = rxWeight.filter { "0123456789.".contains($0) }
                    if let weight = Double(numbers) {
                        movement.userWeight = weight
                        movement.isRX = true
                    }
                }
            }
        }
        
        // Haptic feedback for user interaction
        HapticManager.shared.impact(.light)
        
        // Trigger detail view which has "Start WOD" button
        selectedWOD = wod
    }
}

#Preview {
    WODMainView()
        .environment(TrainingCoordinator())
        .modelContainer(for: [
            WOD.self,
            WODResult.self,
            User.self
        ], inMemory: true)
}
