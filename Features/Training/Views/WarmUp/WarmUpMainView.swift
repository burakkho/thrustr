import SwiftUI
import SwiftData

struct WarmUpMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    
    @Query(filter: #Predicate<WarmUpTemplate> { _ in true })
    private var allTemplates: [WarmUpTemplate]
    
    @State private var showingSessionView = false
    @State private var selectedTemplate: WarmUpTemplate?
    @State private var searchText = ""
    @State private var selectedCategory: WarmUpCategory = .general
    
    private var filteredTemplates: [WarmUpTemplate] {
        var templates = allTemplates
        
        // Filter by category
        if selectedCategory != .general {
            templates = templates.filter { $0.categoryEnum == selectedCategory }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.localizedName.localizedCaseInsensitiveContains(searchText) ||
                template.templateDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return templates.sorted { $0.localizedName < $1.localizedName }
    }
    
    private var favoriteTemplates: [WarmUpTemplate] {
        allTemplates.filter { $0.isFavorite }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Header Section
                headerSection
                
                // Search and Filter
                searchAndFilterSection
                
                // Quick Actions
                quickActionsSection
                
                // Favorite Templates
                if !favoriteTemplates.isEmpty && selectedCategory == .general {
                    favoritesSection
                }
                
                // Templates Grid
                if !filteredTemplates.isEmpty {
                    templatesSection
                } else {
                    emptyStateSection
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(isPresented: $showingSessionView) {
            if let template = selectedTemplate {
                WarmUpSessionView(template: template)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warm-Up")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Prepare your body for optimal performance")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(allTemplates.count)")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                    Text("Templates")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                TextField("Search warm-up routines...", text: $searchText)
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
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(WarmUpCategory.allCases, id: \.self) { category in
                        categoryChip(category)
                    }
                }
                .padding(.horizontal, theme.spacing.xs)
            }
        }
        .padding(.horizontal)
    }
    
    private func categoryChip(_ category: WarmUpCategory) -> some View {
        Button(action: { selectedCategory = category }) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(theme.typography.caption)
            }
            .foregroundColor(selectedCategory == category ? .white : theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.xs)
            .background(selectedCategory == category ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.radius.m)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Quick Start")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    QuickActionButton(
                        title: "5-Min Quick",
                        icon: "bolt.fill",
                        subtitle: "Fast & effective",
                        style: .primary,
                        size: .medium
                    ) {
                        startQuickWarmUp(duration: 300)
                    }
                    
                    QuickActionButton(
                        title: "Upper Body",
                        icon: "figure.arms.open",
                        subtitle: "Before lifting",
                        style: .secondary,
                        size: .medium
                    ) {
                        startCategoryWarmUp(.upper)
                    }
                    
                    QuickActionButton(
                        title: "Lower Body", 
                        icon: "figure.walk",
                        subtitle: "Leg day prep",
                        style: .secondary,
                        size: .medium
                    ) {
                        startCategoryWarmUp(.lower)
                    }
                    
                    QuickActionButton(
                        title: "Dynamic",
                        icon: "flame.fill",
                        subtitle: "High intensity",
                        style: .outlined,
                        size: .medium
                    ) {
                        startCategoryWarmUp(.dynamic)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Favorites Section
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
                    ForEach(favoriteTemplates) { template in
                        templateCompactCard(template)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("All Templates")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: theme.spacing.m),
                    GridItem(.flexible(), spacing: theme.spacing.m)
                ],
                spacing: theme.spacing.m
            ) {
                ForEach(filteredTemplates) { template in
                    templateGridCard(template)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        EmptyStateCard(
            icon: "thermometer.sun",
            title: "No Warm-Up Templates",
            message: searchText.isEmpty ? "Create your first warm-up routine" : "Try adjusting your search or filters",
            primaryAction: searchText.isEmpty ? .init(
                title: "Create Template",
                icon: "plus.circle.fill",
                action: { /* TODO: Create custom template */ }
            ) : .init(
                title: "Clear Search",
                action: { searchText = "" }
            )
        )
        .padding(.top, 50)
    }
    
    // MARK: - Template Cards
    private func templateCompactCard(_ template: WarmUpTemplate) -> some View {
        UnifiedWorkoutCard(
            title: template.localizedName,
            subtitle: template.templateDescription,
            primaryStats: [
                WorkoutStat(
                    label: "Duration",
                    value: template.formattedDuration,
                    icon: "clock"
                ),
                WorkoutStat(
                    label: "Exercises",
                    value: "\(template.totalExercises)",
                    icon: "list.bullet"
                )
            ],
            isFavorite: template.isFavorite,
            cardStyle: .compact,
            primaryAction: { startTemplate(template) },
            secondaryAction: { toggleFavorite(template) }
        )
        .frame(width: 200)
    }
    
    private func templateGridCard(_ template: WarmUpTemplate) -> some View {
        UnifiedWorkoutCard(
            title: template.localizedName,
            subtitle: template.templateDescription,
            primaryStats: [
                WorkoutStat(
                    label: "Duration",
                    value: template.formattedDuration,
                    icon: "clock"
                ),
                WorkoutStat(
                    label: "Exercises",
                    value: "\(template.totalExercises)",
                    icon: "list.bullet"
                )
            ],
            secondaryInfo: template.lastPerformed != nil ? [
                "Last used: \(formatLastPerformed(template.lastPerformed!))",
                template.difficultyEnum.displayName
            ] : [template.difficultyEnum.displayName],
            isFavorite: template.isFavorite,
            cardStyle: .detailed,
            primaryAction: { startTemplate(template) },
            secondaryAction: { toggleFavorite(template) }
        )
    }
    
    // MARK: - Actions
    private func startTemplate(_ template: WarmUpTemplate) {
        selectedTemplate = template
        showingSessionView = true
    }
    
    private func toggleFavorite(_ template: WarmUpTemplate) {
        template.toggleFavorite()
        try? modelContext.save()
    }
    
    private func startQuickWarmUp(duration: Int) {
        // Find a template with matching duration or create quick session
        let quickTemplate = allTemplates.first { $0.estimatedDuration <= duration + 60 }
        if let template = quickTemplate {
            startTemplate(template)
        }
    }
    
    private func startCategoryWarmUp(_ category: WarmUpCategory) {
        let categoryTemplate = allTemplates.first { $0.categoryEnum == category }
        if let template = categoryTemplate {
            startTemplate(template)
        }
    }
    
    // MARK: - Helper Methods
    private func formatLastPerformed(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    WarmUpMainView()
}