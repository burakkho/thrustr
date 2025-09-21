import SwiftUI
import SwiftData

/**
 * RecentActivitySection - Main activity feed container
 * 
 * Displays recent user activities grouped by date with loading states,
 * empty states, and navigation to full activity history.
 */
struct RecentActivitySection: View {
    @Environment(\.theme) private var theme
    @Environment(TabRouter.self) var tabRouter

    var viewModel: DashboardViewModel
    @State private var showingAllActivities = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section Header
            sectionHeader
            
            // Content (data from ViewModel)
            if viewModel.isActivitiesLoading {
                loadingView
            } else if viewModel.groupedActivities.isEmpty {
                EmptyActivityView(user: viewModel.currentUser)
            } else {
                activityList
            }
        }
        .sheet(isPresented: $showingAllActivities) {
            AllActivitiesView(user: viewModel.currentUser)
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(DashboardKeys.Activities.title.localized)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                if !viewModel.groupedActivities.isEmpty {
                    Text("\(totalActivityCount) \(DashboardKeys.Activities.activity.localized)")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            if !viewModel.groupedActivities.isEmpty {
                Button(DashboardKeys.Activities.seeAll.localized) {
                    showingAllActivities = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.horizontal, theme.spacing.m)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: theme.spacing.m) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonActivityRow()
            }
        }
        .padding(.horizontal, theme.spacing.m)
    }
    
    // MARK: - Activity List
    
    private var activityList: some View {
        LazyVStack(alignment: .leading, spacing: theme.spacing.s) {
            ForEach(Array(viewModel.groupedActivities.enumerated()), id: \.offset) { index, group in
                let (dateTitle, activities) = group
                
                // Date header
                ActivityGroupHeader(title: dateTitle)
                
                // Activities for this date
                ForEach(Array(activities.prefix(maxActivitiesPerGroup(index)).enumerated()), id: \.offset) { _, activity in
                    ActivityRow(activity: activity)
                }
                
                // Show more indicator if there are more activities
                if activities.count > maxActivitiesPerGroup(index) {
                    moreActivitiesIndicator(
                        additionalCount: activities.count - maxActivitiesPerGroup(index)
                    )
                }
            }
        }
    }
    
    // MARK: - More Activities Indicator
    
    private func moreActivitiesIndicator(additionalCount: Int) -> some View {
        Button {
            showingAllActivities = true
        } label: {
            HStack {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text("+\(additionalCount) \(DashboardKeys.Activities.moreActivities.localized)")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var totalActivityCount: Int {
        viewModel.groupedActivities.reduce(0) { $0 + $1.1.count }
    }
    
    private func maxActivitiesPerGroup(_ groupIndex: Int) -> Int {
        // Show more activities for "Today" group, fewer for others
        switch groupIndex {
        case 0: return 5  // Today - show up to 5
        case 1: return 3  // Yesterday - show up to 3
        default: return 2 // Other groups - show up to 2
        }
    }
    
}

// MARK: - Enhanced Skeleton Loading View

private struct SkeletonActivityRow: View {
    @Environment(\.theme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Icon skeleton with shimmer
            Circle()
                .fill(shimmerGradient)
                .frame(width: 32, height: 32)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack {
                    // Title skeleton - varied widths for realism
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: CGFloat.random(in: 100...150), height: 16)
                    
                    Spacer()
                    
                    // Time skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: CGFloat.random(in: 50...80), height: 12)
                }
                
                // Subtitle skeleton - only show sometimes for variety
                if Bool.random() {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: CGFloat.random(in: 140...200), height: 12)
                }
            }
        }
        .padding(.vertical, theme.spacing.s)
        .padding(.horizontal, theme.spacing.m)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                theme.colors.backgroundSecondary.opacity(0.6),
                theme.colors.backgroundSecondary.opacity(0.9),
                theme.colors.backgroundSecondary.opacity(0.6)
            ],
            startPoint: isAnimating ? .trailing : .leading,
            endPoint: isAnimating ? UnitPoint(x: 2, y: 0) : .trailing
        )
    }
}

// MARK: - All Activities View

private struct AllActivitiesView: View {
    let user: User?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    @State private var activityLogger = ActivityLoggerService.shared
    @State private var activities: [ActivityEntry] = []
    @State private var filteredActivities: [ActivityEntry] = []
    @State private var selectedFilter: ActivityFilter = .all
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var groupedActivities: [(String, [ActivityEntry])] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterSection
                
                // Content
                if isLoading {
                    loadingView
                } else if filteredActivities.isEmpty {
                    emptyResultsView
                } else {
                    activitiesListView
                }
            }
            .navigationTitle(DashboardKeys.Activities.allActivitiesTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(DashboardKeys.Activities.close.localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAllActivities()
            }
            .searchable(text: $searchText, prompt: DashboardKeys.Activities.searchPlaceholder.localized)
            .onChange(of: searchText) { _, newValue in
                filterActivities()
            }
            .onChange(of: selectedFilter) { _, _ in
                filterActivities()
            }
        }
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: theme.spacing.s) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            onTap: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.m)
            }
            
            // Stats Summary
            if !activities.isEmpty {
                statsSection
            }
        }
        .padding(.vertical, theme.spacing.s)
        .background(theme.colors.backgroundPrimary)
    }
    
    private var statsSection: some View {
        HStack(spacing: theme.spacing.l) {
            ActivityStatItem(
                icon: "list.bullet",
                value: "\(activities.count)",
                label: String(format: DashboardKeys.Activities.totalActivities.localized, activities.count)
            )
            
            ActivityStatItem(
                icon: "calendar",
                value: "\(thisWeekCount)",
                label: String(format: DashboardKeys.Activities.thisWeekStats.localized, thisWeekCount)
            )
            
            Spacer()
        }
        .padding(.horizontal, theme.spacing.m)
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.m) {
                ForEach(0..<8, id: \.self) { index in
                    SkeletonActivityRow()
                }
            }
            .padding(theme.spacing.m)
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: theme.spacing.l) {
            if searchText.isEmpty && selectedFilter == .all {
                // No activities at all
                EmptyActivityView(user: user)
            } else {
                // No results for current search/filter
                VStack(spacing: theme.spacing.m) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(DashboardKeys.Activities.noResultsTitle.localized)
                        .font(.title3.weight(.medium))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(DashboardKeys.Activities.noResultsDesc.localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(DashboardKeys.Activities.clearFilters.localized) {
                        searchText = ""
                        selectedFilter = .all
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(theme.colors.accent)
                }
                .padding(theme.spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.spacing.s) {
                ForEach(Array(groupedActivities.enumerated()), id: \.offset) { index, group in
                    let (dateTitle, activities) = group
                    
                    // Date header
                    ActivityGroupHeader(title: dateTitle)
                    
                    // Activities for this date
                    ForEach(activities, id: \.id) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return activities.filter { activity in
            calendar.dateInterval(of: .weekOfYear, for: now)?.contains(activity.timestamp) == true
        }.count
    }
    
    // MARK: - Methods
    
    private func loadAllActivities() {
        isLoading = true
        activityLogger.setModelContext(modelContext)
        
        Task { @MainActor in
            // Fetch more activities for the full view
            activities = activityLogger.fetchRecentActivities(limit: 100, for: user)
            filterActivities()
            isLoading = false
        }
    }
    
    private func filterActivities() {
        var filtered = activities
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.title.localizedCaseInsensitiveContains(searchText) ||
                (activity.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .workouts:
            filtered = filtered.filter { activity in
                [.workoutCompleted, .cardioCompleted, .wodCompleted, .personalRecord].contains(activity.typeEnum)
            }
        case .nutrition:
            filtered = filtered.filter { activity in
                [.nutritionLogged, .mealCompleted].contains(activity.typeEnum)
            }
        case .measurements:
            filtered = filtered.filter { activity in
                [.measurementUpdated, .weightUpdated, .bodyFatUpdated].contains(activity.typeEnum)
            }
        }
        
        filteredActivities = filtered
        groupedActivities = ActivityFormatter.groupActivitiesByDate(filteredActivities)
    }
}

// MARK: - Activity Filter Enum

enum ActivityFilter: String, CaseIterable {
    case all = "all"
    case workouts = "workouts"
    case nutrition = "nutrition"
    case measurements = "measurements"
    
    var localizedTitle: String {
        switch self {
        case .all: return DashboardKeys.Activities.filterAll.localized
        case .workouts: return DashboardKeys.Activities.filterWorkouts.localized
        case .nutrition: return DashboardKeys.Activities.filterNutrition.localized
        case .measurements: return DashboardKeys.Activities.filterMeasurements.localized
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .workouts: return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .measurements: return "scalemass"
        }
    }
}

// MARK: - Filter Pill Component

private struct FilterPill: View {
    @Environment(\.theme) private var theme
    
    let filter: ActivityFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: filter.icon)
                    .font(.caption.weight(.medium))
                
                Text(filter.localizedTitle)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.l)
                    .fill(isSelected ? theme.colors.accent : theme.colors.cardBackground)
                    .animation(nil, value: isSelected)
            )
            .foregroundColor(isSelected ? theme.colors.textOnAccent : theme.colors.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil, value: isSelected)
    }
}

// MARK: - Activity Stat Item Component

private struct ActivityStatItem: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let activityLogged = Notification.Name("ActivityLogged")
    static let navigateToWODHistory = Notification.Name("NavigateToWODHistory")
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ActivityEntry.self, configurations: config)
    let context = container.mainContext

    // Create sample activities
    let sampleUser = User()
    let activities = [
        sampleWorkoutActivity(user: sampleUser),
        sampleNutritionActivity(user: sampleUser),
        sampleMeasurementActivity(user: sampleUser)
    ]

    // Insert activities and setup viewModel
    _ = activities.map { context.insert($0) }

    let viewModel = DashboardViewModel(healthKitService: HealthKitService())
    _ = { viewModel.currentUser = sampleUser }()

    return RecentActivitySection(viewModel: viewModel)
        .modelContainer(container)
        .environment(TabRouter())
        .padding()
}

// MARK: - Preview Helpers

private func sampleWorkoutActivity(user: User) -> ActivityEntry {
    return ActivityEntry.workoutCompleted(
        workoutType: "Bench Press",
        duration: 2700, // 45 minutes
        volume: 240,
        sets: 3,
        reps: 24,
        user: user
    )
}

private func sampleNutritionActivity(user: User) -> ActivityEntry {
    return ActivityEntry.nutritionLogged(
        mealType: "Kahvaltı",
        calories: 420,
        protein: 25,
        carbs: 45,
        fat: 18,
        user: user
    )
}

private func sampleMeasurementActivity(user: User) -> ActivityEntry {
    return ActivityEntry.measurementUpdated(
        measurementType: "Kilo",
        value: 75.0,
        previousValue: 75.2,
        unit: "kg",
        user: user
    )
}