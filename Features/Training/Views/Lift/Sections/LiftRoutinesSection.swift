import SwiftUI
import SwiftData

struct LiftRoutinesSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LiftWorkout> { $0.isTemplate })
    private var allRoutines: [LiftWorkout]
    @Query private var users: [User]

    @State private var showingCreateMethodSheet = false
    @State private var showingScratchBuilder = false
    @State private var showingTemplateSelection = false
    @State private var selectedRoutine: LiftWorkout?
    @State private var routineToDelete: LiftWorkout?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var selectedFilter: RoutineFilter = .all

    private var currentUser: User? {
        users.first
    }
    
    enum RoutineFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case custom = "My Routines"
        case templates = "Templates"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .favorites: return "star.fill"
            case .custom: return "person.fill"
            case .templates: return "doc.text"
            }
        }
    }
    
    private var filteredRoutines: [LiftWorkout] {
        var routines = allRoutines
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            routines = routines.filter { $0.isFavorite }
        case .custom:
            routines = routines.filter { $0.isCustom }
        case .templates:
            routines = routines.filter { !$0.isCustom }
        }
        
        // Apply search
        if !searchText.isEmpty {
            routines = routines.filter { routine in
                routine.localizedName.localizedCaseInsensitiveContains(searchText) ||
                (routine.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return routines.sorted { $0.name < $1.name }
    }
    
    private var favoriteRoutines: [LiftWorkout] {
        allRoutines.filter { $0.isFavorite }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Favorites Section (if any)
                if !favoriteRoutines.isEmpty && selectedFilter == .all {
                    favoritesSection
                }
                
                // Main Routines Grid
                if !filteredRoutines.isEmpty {
                    routinesGrid
                } else {
                    emptyState
                }
                
                // Create New Routine FAB
                createRoutineFAB
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(isPresented: $showingCreateMethodSheet) {
            CreateRoutineMethodSheet(
                onStartFromScratch: {
                    showingScratchBuilder = true
                },
                onCopyFromTemplate: {
                    showingTemplateSelection = true
                }
            )
        }
        .sheet(isPresented: $showingScratchBuilder) {
            ScratchRoutineBuilderView()
        }
        .sheet(isPresented: $showingTemplateSelection) {
            TemplateSelectionView { template in
                copyAndCustomizeTemplate(template)
            }
        }
        .sheet(item: $selectedRoutine) { routine in
            LiftSessionView(workout: routine, programExecution: nil)
        }
        .alert("Delete Routine", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let routine = routineToDelete {
                    deleteRoutine(routine)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let routine = routineToDelete {
                Text("Are you sure you want to delete \"\(routine.localizedName)\"? This action cannot be undone.")
            }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: theme.spacing.m) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                TextField("Search routines...", text: $searchText)
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
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(RoutineFilter.allCases, id: \.self) { filter in
                        filterChip(filter)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func filterChip(_ filter: RoutineFilter) -> some View {
        Button(action: { selectedFilter = filter }) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(theme.typography.caption)
            }
            .foregroundColor(selectedFilter == filter ? .white : theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.xs)
            .background(selectedFilter == filter ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.radius.m)
        }
    }
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Label("Favorites", systemImage: "star.fill")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    ForEach(favoriteRoutines) { routine in
                        routineCompactCard(routine)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func routineCompactCard(_ routine: LiftWorkout) -> some View {
        UnifiedWorkoutCard(
            title: routine.localizedName,
            subtitle: "\(routine.exercises?.count ?? 0) exercises",
            primaryStats: [
                WorkoutStat(
                    label: "Duration",
                    value: "\(routine.estimatedDuration ?? 45) min",
                    icon: "clock"
                )
            ],
            isFavorite: true,
            cardStyle: .compact,
            primaryAction: { selectedRoutine = routine },
            secondaryAction: { startRoutine(routine) }
        )
        .frame(width: 200)
    }
    
    private var routinesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: theme.spacing.m),
                GridItem(.flexible(), spacing: theme.spacing.m)
            ],
            spacing: theme.spacing.m
        ) {
            ForEach(filteredRoutines) { routine in
                routineGridCard(routine)
            }
        }
        .padding(.horizontal)
    }
    
    private func routineGridCard(_ routine: LiftWorkout) -> some View {
        VStack(spacing: 0) {
            // Card Content
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                HStack {
                    Text(routine.localizedName)
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if routine.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.warning)
                    }
                }
                
                Text("\(routine.exercises?.count ?? 0) exercises")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if let duration = routine.estimatedDuration {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: theme.spacing.s) {
                    Button(action: { startRoutine(routine) }) {
                        Text("Start")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.accent)
                            .cornerRadius(theme.radius.s)
                    }
                    
                    Menu {
                        Button(action: { toggleFavorite(routine) }) {
                            Label(
                                routine.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: routine.isFavorite ? "star.slash" : "star"
                            )
                        }
                        
                        Button(action: { duplicateRoutine(routine) }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        
                        if routine.isCustom {
                            Button(role: .destructive, action: {
                                routineToDelete = routine
                                showingDeleteAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.s)
                    }
                }
            }
            .padding(theme.spacing.m)
        }
        .frame(height: 150)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private var emptyState: some View {
        EmptyStateCard(
            icon: "list.bullet.rectangle",
            title: "No Routines Found",
            message: searchText.isEmpty ? "Create your first routine to get started" : "Try adjusting your search or filters",
            primaryAction: searchText.isEmpty ? .init(
                title: "Create Routine",
                icon: "plus.circle.fill",
                action: { showingCreateMethodSheet = true }
            ) : .init(
                title: "Clear Search",
                action: { searchText = "" }
            )
        )
        .padding(.top, 50)
    }
    
    private var createRoutineFAB: some View {
        HStack {
            Spacer()
            Button(action: { showingCreateMethodSheet = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(theme.colors.accent)
                    .clipShape(Circle())
                    .shadow(color: theme.colors.accent.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, theme.spacing.m)
    }
    
    // MARK: - Actions
    
    private func startRoutine(_ routine: LiftWorkout) {
        guard let user = currentUser else {
            Logger.error("No user found for starting routine")
            return
        }

        // Create a LiftSession for the routine
        let liftSession = LiftSession(
            workout: routine,
            user: user,
            programExecution: nil
        )

        do {
            modelContext.insert(liftSession)
            try modelContext.save()

            // Start the routine session
            selectedRoutine = routine

            Logger.success("Started routine: \(routine.localizedName)")
        } catch {
            Logger.error("Failed to start routine: \(error)")
        }
    }
    
    private func toggleFavorite(_ routine: LiftWorkout) {
        routine.isFavorite.toggle()
        try? modelContext.save()
    }
    
    private func duplicateRoutine(_ routine: LiftWorkout) {
        let copy = LiftWorkout(
            name: "\(routine.name) (Copy)",
            isTemplate: true,
            isCustom: true
        )
        // Copy exercises
        if copy.exercises == nil {
            copy.exercises = []
        }
        for exercise in routine.exercises ?? [] {
            copy.exercises?.append(exercise)
        }
        modelContext.insert(copy)
        try? modelContext.save()
    }
    
    private func deleteRoutine(_ routine: LiftWorkout) {
        modelContext.delete(routine)
        try? modelContext.save()
    }
    
    private func copyAndCustomizeTemplate(_ template: LiftWorkout) {
        // Implementation for customizing template
        Logger.info("Customize template: \(template.localizedName)")
    }
}