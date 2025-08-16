import SwiftUI
import SwiftData

struct WODMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var customWODs: [WOD]
    @Query private var wodResults: [WODResult]
    
    @State private var showingNewWOD = false
    @State private var selectedCategory: WODCategory = .custom
    @State private var searchText = ""
    @State private var showingQRScanner = false
    
    private var filteredWODs: [WOD] {
        let categoryWODs: [WOD]
        
        switch selectedCategory {
        case .custom:
            categoryWODs = customWODs.filter { $0.isCustom }
        case .girls, .heroes:
            // Get benchmark WODs for this category
            let benchmarks = BenchmarkWODDatabase.all.filter { $0.category == selectedCategory }
            // Check if they exist in the database, if not show them as available to add
            categoryWODs = benchmarks.compactMap { benchmark in
                customWODs.first { $0.name == benchmark.name && !$0.isCustom }
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
    
    private var benchmarkWODs: [BenchmarkWOD] {
        BenchmarkWODDatabase.all.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with QR Scanner
            HStack {
                Text("WODs")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button(action: { showingQRScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, theme.spacing.s)
            
            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    ForEach(WODCategory.allCases, id: \.self) { category in
                        WODCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, theme.spacing.s)
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                TextField("Search WODs...", text: $searchText)
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
            .padding(.bottom, theme.spacing.s)
            
            // Content
            ScrollView {
                LazyVStack(spacing: theme.spacing.m) {
                    // New WOD Button (only for custom category)
                    if selectedCategory == .custom {
                        Button(action: { showingNewWOD = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create New WOD")
                                    .font(theme.typography.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(theme.colors.accent)
                            .padding()
                            .background(theme.colors.accent.opacity(0.1))
                            .cornerRadius(theme.radius.m)
                        }
                    }
                    
                    // WOD List
                    if selectedCategory == .custom {
                        // Show custom WODs
                        ForEach(filteredWODs) { wod in
                            WODCard(wod: wod)
                        }
                    } else {
                        // Show benchmark WODs
                        ForEach(benchmarkWODs, id: \.name) { benchmark in
                            BenchmarkWODCard(benchmark: benchmark)
                        }
                    }
                    
                    if filteredWODs.isEmpty && benchmarkWODs.isEmpty {
                        EmptyStateView(
                            systemImage: "dumbbell",
                            title: selectedCategory == .custom ? "No Custom WODs" : "No WODs Found",
                            message: selectedCategory == .custom ? "Create your first WOD to get started" : "Try a different search or category",
                            primaryTitle: selectedCategory == .custom ? "Create WOD" : "Clear Search",
                            primaryAction: {
                                if selectedCategory == .custom {
                                    showingNewWOD = true
                                } else {
                                    searchText = ""
                                }
                            }
                        )
                        .padding(.top, 50)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNewWOD) {
            WODBuilderView()
        }
        .fullScreenCover(isPresented: $showingQRScanner) {
            WODQRScannerView()
        }
    }
}

// MARK: - WOD Category Chip
private struct WODCategoryChip: View {
    let category: WODCategory
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: category.icon)
                Text(category.rawValue)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
            .cornerRadius(theme.radius.l)
        }
    }
}

// MARK: - WOD Card
private struct WODCard: View {
    let wod: WOD
    @Environment(\.theme) private var theme
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wod.name)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        Text(wod.wodType.displayName)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if wod.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(theme.colors.warning)
                    }
                    
                    if let pr = wod.personalRecord {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("PR")
                                .font(theme.typography.caption2)
                                .foregroundColor(theme.colors.success)
                            Text(pr.displayScore)
                                .font(theme.typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.success)
                        }
                    }
                }
                
                // Movements
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(wod.movements.prefix(3).enumerated()), id: \.offset) { index, movement in
                        Text("• \(movement.displayText)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                    if wod.movements.count > 3 {
                        Text("... and \(wod.movements.count - 3) more")
                            .font(theme.typography.caption2)
                            .foregroundColor(theme.colors.textSecondary)
                            .italic()
                    }
                }
                
                // Rep Scheme or Time Cap
                if !wod.repScheme.isEmpty {
                    Text(wod.formattedRepScheme)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(theme.colors.accent.opacity(0.1))
                        .foregroundColor(theme.colors.accent)
                        .cornerRadius(theme.radius.s)
                } else if let timeCap = wod.formattedTimeCap {
                    Text(timeCap)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(theme.colors.warning.opacity(0.1))
                        .foregroundColor(theme.colors.warning)
                        .cornerRadius(theme.radius.s)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WODDetailView(wod: wod)
        }
    }
}

// MARK: - Benchmark WOD Card
private struct BenchmarkWODCard: View {
    let benchmark: BenchmarkWOD
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showingDetail = false
    @State private var isAdded = false
    
    var body: some View {
        Button(action: addToMyWODs) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(benchmark.name)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        Text(benchmark.description)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(isAdded ? theme.colors.success : theme.colors.accent)
                }
                
                // Movements
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(benchmark.movements.prefix(3).enumerated()), id: \.offset) { index, movement in
                        HStack(spacing: 4) {
                            Text("•")
                            Text(movement.name)
                            if let rxMale = movement.rxMale {
                                Text("(\(rxMale))")
                                    .foregroundColor(theme.colors.accent)
                            }
                        }
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                    }
                    if benchmark.movements.count > 3 {
                        Text("... and \(benchmark.movements.count - 3) more")
                            .font(theme.typography.caption2)
                            .foregroundColor(theme.colors.textSecondary)
                            .italic()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func addToMyWODs() {
        guard !isAdded else { return }
        
        let wod = BenchmarkWODDatabase.createWOD(from: benchmark)
        modelContext.insert(wod)
        
        withAnimation {
            isAdded = true
        }
        
        HapticManager.shared.notification(.success)
    }
}