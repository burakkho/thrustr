import SwiftUI
import SwiftData

struct WODMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    
    @Query private var customWODs: [WOD]
    @Query private var wodResults: [WODResult]
    @Query(filter: #Predicate<WOD> { !$0.isCustom }) private var benchmarkWODs: [WOD]
    
    @State private var selectedCategory: WODCategory = .custom
    @State private var searchText = ""
    @State private var selectedWOD: WOD?
    @State private var showingNewWOD = false
    @State private var showingQRScanner = false
    
    private var filteredWODs: [WOD] {
        let categoryWODs: [WOD]
        
        switch selectedCategory {
        case .custom:
            categoryWODs = customWODs.filter { $0.isCustom }
        case .girls, .heroes:
            categoryWODs = benchmarkWODs.filter { wod in
                wod.category == selectedCategory.rawValue
            }
        default:
            categoryWODs = []
        }
        
        if searchText.isEmpty {
            return categoryWODs
        }
        
        return categoryWODs.filter { wod in
            wod.name.localizedCaseInsensitiveContains(searchText) ||
            wod.movements.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
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
            TextField("Search METCON...", text: $searchText)
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
                title: "Create New METCON",
                icon: "plus.circle.fill",
                subtitle: "Build your custom workout",
                style: .primary,
                size: .fullWidth,
                action: { showingNewWOD = true }
            )
            
            HStack(spacing: theme.spacing.m) {
                QuickActionButton(
                    title: "Scan QR",
                    icon: "qrcode.viewfinder",
                    style: .secondary,
                    size: .medium,
                    action: { showingQRScanner = true }
                )
                
                QuickActionButton(
                    title: "METCON Generator",
                    icon: "sparkles",
                    style: .secondary,
                    size: .medium,
                    action: { generateRandomWOD() }
                )
            }
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
            title: selectedCategory == .custom ? "No Custom METCON" : "No METCON Found",
            message: selectedCategory == .custom ? 
                "Create your first METCON to get started" : 
                "Try a different search or category",
            primaryAction: .init(
                title: selectedCategory == .custom ? "Create METCON" : "Clear Search",
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
    
    // MARK: - Helper Methods
    
    private func formatWODType(_ wod: WOD) -> String {
        switch wod.wodType {
        case .forTime:
            if let timeCap = wod.timeCap {
                return "For Time • \(timeCap) min cap"
            }
            return "For Time"
        case .amrap:
            return "AMRAP • \(wod.timeCap ?? 20) minutes"
        case .emom:
            return "EMOM • \(wod.timeCap ?? 10) minutes"
        case .custom:
            return "Custom Format"
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
        selectedWOD = wod
        // Navigate to timer/tracking view
    }
    
    private func generateRandomWOD() {
        // Generate a random WOD based on available movements
        Logger.info("Generate random WOD")
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