import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for PRHistoryDetailView with clean separation of concerns.
 *
 * Manages PR history data processing, filtering, and analytics service coordination.
 * Handles all business logic for PR tracking and historical analysis.
 */
@MainActor
@Observable
class PRHistoryDetailViewModel {

    // MARK: - State
    var selectedCategory: AnalyticsService.PRCategory = .strength
    var selectedTimeRange: TimeFilter = .all
    var searchText = ""
    var prRecords: [AnalyticsService.DetailedPRRecord] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies
    private var modelContext: ModelContext?
    private var analyticsService: AnalyticsService?

    // MARK: - Computed Properties

    /**
     * Filtered PR records based on search and filters.
     */
    var filteredPRRecords: [AnalyticsService.DetailedPRRecord] {
        return prRecords.filter { record in
            // Category filter
            let categoryMatches = record.category == selectedCategory

            // Search filter
            let searchMatches = searchText.isEmpty ||
                record.exerciseName.lowercased().contains(searchText.lowercased())

            // Time range filter
            let timeMatches: Bool
            let now = Date()
            switch selectedTimeRange {
            case .week:
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
                timeMatches = record.date >= weekAgo
            case .month:
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
                timeMatches = record.date >= monthAgo
            case .threeMonths:
                let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
                timeMatches = record.date >= threeMonthsAgo
            case .sixMonths:
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
                timeMatches = record.date >= sixMonthsAgo
            case .year:
                let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
                timeMatches = record.date >= yearAgo
            case .all:
                timeMatches = true
            }

            return categoryMatches && searchMatches && timeMatches
        }
    }

    /**
     * Whether there are PR records to display.
     */
    var hasRecords: Bool {
        return !filteredPRRecords.isEmpty
    }

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading Methods

    /**
     * Loads PR history data from SwiftData context.
     */
    func loadPRHistory() {
        guard let context = modelContext,
              let user = getCurrentUser() else { return }

        isLoading = true
        errorMessage = nil

        // Initialize analytics service
        analyticsService = AnalyticsService(modelContext: context)

        Task {
            do {
                let records = try await analyticsService?.getPRHistory(
                    for: user,
                    category: selectedCategory,
                    timeRange: selectedTimeRange
                ) ?? []

                await MainActor.run {
                    self.prRecords = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    /**
     * Sets the ModelContext for SwiftData queries.
     */
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        loadPRHistory()
    }

    // MARK: - Filter Methods

    /**
     * Updates the selected category and refreshes data.
     */
    func updateCategory(_ category: AnalyticsService.PRCategory) {
        selectedCategory = category
        loadPRHistory()
    }

    /**
     * Updates the selected time range and refreshes data.
     */
    func updateTimeRange(_ timeRange: TimeFilter) {
        selectedTimeRange = timeRange
        loadPRHistory()
    }

    /**
     * Updates the search text.
     */
    func updateSearchText(_ text: String) {
        searchText = text
    }

    // MARK: - Helper Methods

    private func getCurrentUser() -> User? {
        guard let context = modelContext else { return nil }

        do {
            let userDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(userDescriptor)
            return users.first
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
            return nil
        }
    }

    /**
     * Gets the display title for current category.
     */
    var categoryTitle: String {
        switch selectedCategory {
        case .strength: return CommonKeys.Analytics.strengthPRs.localized
        case .endurance: return CommonKeys.Analytics.endurancePRs.localized
        case .volume: return CommonKeys.Analytics.volumePRs.localized
        }
    }

    /**
     * Gets the display title for current time range.
     */
    var timeRangeTitle: String {
        switch selectedTimeRange {
        case .week: return CommonKeys.Analytics.lastWeek.localized
        case .month: return CommonKeys.Analytics.lastMonth.localized
        case .threeMonths: return CommonKeys.Analytics.lastThreeMonths.localized
        case .sixMonths: return CommonKeys.Analytics.lastSixMonths.localized
        case .year: return CommonKeys.Analytics.lastYear.localized
        case .all: return CommonKeys.Analytics.allTime.localized
        }
    }

    /**
     * Refreshes all PR data.
     */
    func refreshData() {
        loadPRHistory()
    }
}

// MARK: - Supporting Types

enum TimeFilter: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    case sixMonths = "sixMonths"
    case year = "year"
    case all = "all"

    var displayName: String {
        switch self {
        case .week: return CommonKeys.Analytics.week.localized
        case .month: return CommonKeys.Analytics.month.localized
        case .threeMonths: return CommonKeys.Analytics.threeMonths.localized
        case .sixMonths: return CommonKeys.Analytics.sixMonths.localized
        case .year: return CommonKeys.Analytics.year.localized
        case .all: return CommonKeys.Analytics.allTime.localized
        }
    }
}