import SwiftUI
import SwiftData

struct WODMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Query private var user: [User]
    
    @Query(
        filter: #Predicate<WOD> { $0.isCustom == true },
        sort: [SortDescriptor(\WOD.updatedAt, order: .reverse)]
    ) private var customWODs: [WOD]
    
    @Query(sort: [SortDescriptor(\WODResult.completedAt, order: .reverse)]) 
    private var wodResults: [WODResult]
    
    @Query(
        filter: #Predicate<WOD> { $0.isCustom == false },
        sort: [SortDescriptor(\WOD.name)]
    ) private var benchmarkWODs: [WOD]
    
    @State private var selectedCategory: WODCategory = .custom
    private var selectedTab: WODTab {
        get {
            switch coordinator.wodSelectedTab {
            case "history": return .history
            case "custom": return .custom
            default: return .benchmark
            }
        }
        set {
            coordinator.wodSelectedTab = newValue.rawValue.lowercased()
        }
    }
    
    private enum WODTab: String, CaseIterable {
        case benchmark = "Benchmark"
        case custom = "Custom" 
        case history = "History"
        
        var localizedTitle: String {
            switch self {
            case .benchmark: return TrainingKeys.WOD.benchmark.localized
            case .custom: return TrainingKeys.WOD.custom.localized
            case .history: return TrainingKeys.WOD.history.localized
            }
        }
        
        var icon: String {
            switch self {
            case .benchmark: return "star.circle.fill"
            case .custom: return "plus.circle.fill"
            case .history: return "clock.fill"
            }
        }
    }
    @State private var searchText = ""
    @State private var selectedWOD: WOD?
    @State private var showingNewWOD = false
    @State private var showingQRScanner = false
    
    private var currentUser: User? {
        user.first
    }
    
    private var filteredWODs: [WOD] {
        let categoryWODs: [WOD]
        
        switch selectedCategory {
        case .custom:
            categoryWODs = customWODs // Already filtered by @Query
        case .girls, .heroes:
            categoryWODs = benchmarkWODs.filter { wod in
                wod.category == selectedCategory.rawValue
            }
        default:
            categoryWODs = []
        }
        
        // Early return for empty search
        guard !searchText.isEmpty else {
            return Array(categoryWODs.prefix(20)) // Limit initial results
        }
        
        // Optimized search with prefix limiting
        let searchResults = categoryWODs.filter { wod in
            wod.name.localizedCaseInsensitiveContains(searchText) ||
            wod.movements.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return Array(searchResults.prefix(15)) // Limit search results
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("METCON")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let lastResult = wodResults.sorted(by: { $0.completedAt > $1.completedAt }).first {
                    Text("Last METCON: \(lastResult.completedAt, formatter: RelativeDateTimeFormatter())")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: theme.spacing.m) {
                Button(action: { showingQRScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                        .foregroundColor(theme.colors.accent)
                }
                
                Button(action: { showingNewWOD = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.m)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(WODTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        coordinator.wodSelectedTab = tab.rawValue.lowercased()
                        if tab != .history {
                            selectedCategory = tab == .benchmark ? .girls : .custom
                        }
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.localizedTitle)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? theme.colors.accent : theme.colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(theme.colors.backgroundSecondary)
        .overlay(
            Rectangle()
                .fill(theme.colors.accent)
                .frame(height: 2)
                .offset(x: tabIndicatorOffset, y: 0)
                .animation(.easeInOut(duration: 0.2), value: selectedTab),
            alignment: .bottom
        )
    }
    
    private var tabIndicatorOffset: CGFloat {
        let tabWidth = UIScreen.main.bounds.width / 3
        switch selectedTab {
        case .benchmark: return -tabWidth
        case .custom: return 0
        case .history: return tabWidth
        }
    }
    
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
            // Header
            headerView
            
            // Tab Selector
            tabSelector
            
            // Content based on selected tab
            if selectedTab == .history {
                WODHistoryView()
            } else {
                VStack(spacing: 0) {
                    // Category Selector
                    categorySelector
                    
                    // Search Bar
                    searchBar
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.m) {
                            // Quick Actions for Custom WODs
                            if selectedCategory == .custom {
                                quickActionsSection
                            }
                            
                            // WOD Cards
                            if !filteredWODs.isEmpty {
                                wodsList
                            } else {
                                emptyState
                            }
                        }
                        .padding(.vertical, theme.spacing.m)
                    }
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
        let movements = wod.movements.prefix(3)
        let movementNames = movements.map { $0.name }.joined(separator: ", ")
        
        if wod.movements.count > 3 {
            return "\(movementNames) +\(wod.movements.count - 3) more"
        }
        
        return movementNames
    }
    
    private func buildWODStats(for wod: WOD) -> [WorkoutStat] {
        var stats: [WorkoutStat] = []
        
        // Movement count
        stats.append(WorkoutStat(
            label: "Movements",
            value: "\(wod.movements.count)",
            icon: "figure.strengthtraining.traditional"
        ))
        
        // Time/Rounds
        if let timeCap = wod.timeCap {
            stats.append(WorkoutStat(
                label: wod.wodType == .amrap ? "Duration" : "Time Cap",
                value: "\(timeCap) min",
                icon: "clock"
            ))
        } else if let rounds = wod.rounds {
            stats.append(WorkoutStat(
                label: "Rounds",
                value: "\(rounds)",
                icon: "repeat"
            ))
        }
        
        // Personal Record
        if let bestResult = wodResults.filter({ $0.wodId == wod.id }).sorted(by: { $0.score > $1.score }).first {
            stats.append(WorkoutStat(
                label: "Best",
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
            info.append("Last: \(formatter.localizedString(for: lastResult.completedAt, relativeTo: Date()))")
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
            return "\(Int(score)) rounds"
        default:
            return "\(Int(score))"
        }
    }
    
    private func startWOD(_ wod: WOD) {
        // Set default weights based on user gender
        for movement in wod.movements {
            if let rxWeight = movement.rxWeight(for: currentUser?.gender) {
                // Parse weight value from string (e.g., "43kg" -> 43)
                let numbers = rxWeight.filter { "0123456789.".contains($0) }
                if let weight = Double(numbers) {
                    movement.userWeight = weight
                    movement.isRX = true
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