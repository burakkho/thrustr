import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for ProfileView with clean service coordination and UI state management.
 *
 * Manages UI state for the main profile screen while coordinating between multiple
 * services for achievements, strength analysis, and health data. Follows clean
 * architecture principles with clear separation of concerns.
 *
 * Responsibilities:
 * - UI state management for profile display
 * - Service coordination for data fetching
 * - Loading state management
 * - Error handling and user feedback
 */
@MainActor
@Observable
class ProfileViewModel {

    // MARK: - Observable Properties

    var achievements: [Achievement] = []
    var strengthLevel: StrengthLevel?
    var strengthLevelString: String = "--"
    var strengthLevelColor: Color = .gray
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let achievementService = AchievementService.self
    private let profileAnalyticsService = ProfileAnalyticsService.self
    private var modelContext: ModelContext?

    // MARK: - Configuration

    /**
     * Configures the ViewModel with required dependencies.
     *
     * - Parameter modelContext: SwiftData model context for database queries
     */
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /**
     * Loads all profile data from SwiftData and services.
     *
     * Fetches data from SwiftData database, coordinates with HealthKit service,
     * and updates all UI state. Handles loading states and error conditions.
     *
     * - Parameter user: Current user profile
     */
    func loadProfileData(user: User?) {
        guard let user = user, let modelContext = modelContext else {
            clearData()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch SwiftData entities for achievements calculation
            let liftSessions = try fetchRecentLiftSessions(modelContext: modelContext)
            let nutritionEntries = try fetchRecentNutritionEntries(modelContext: modelContext)
            let weightEntries = try fetchRecentWeightEntries(modelContext: modelContext)

            // Get HealthKit service instance
            let healthKitService = HealthKitService.shared

            // Load achievements using fetched data
            loadAchievements(
                user: user,
                healthKitService: healthKitService,
                liftSessions: liftSessions,
                nutritionEntries: nutritionEntries,
                weightEntries: weightEntries
            )

            // Load strength level analysis
            loadStrengthLevel(user: user)

            isLoading = false
        } catch {
            showError("Failed to load profile data: \(error.localizedDescription)")
        }
    }

    /**
     * Loads all profile data including achievements and strength analysis.
     *
     * Coordinates multiple services to fetch user achievements, calculate strength
     * level, and update UI state. Handles loading states and error conditions.
     *
     * - Parameters:
     *   - user: Current user profile
     *   - healthKitService: HealthKit integration service
     *   - liftSessions: Recent strength training sessions
     *   - nutritionEntries: Recent nutrition tracking entries
     *   - weightEntries: Recent weight tracking entries
     */
    private func loadAchievements(
        user: User,
        healthKitService: HealthKitService,
        liftSessions: [LiftSession],
        nutritionEntries: [NutritionEntry],
        weightEntries: [WeightEntry]
    ) {
        // Load achievements using service
        achievements = achievementService.computeRecentAchievements(
            user: user,
            todaySteps: healthKitService.todaySteps,
            todayActiveCalories: healthKitService.todayActiveCalories,
            liftSessions: liftSessions,
            nutritionEntries: nutritionEntries,
            weightEntries: weightEntries
        )
    }

    /**
     * Loads user's strength level analysis and display properties.
     *
     * - Parameter user: User profile with strength data
     */
    func loadStrengthLevel(user: User) {
        let (levelString, strengthLevelEnum) = profileAnalyticsService.getOverallStrengthLevel(user: user)

        strengthLevelString = levelString
        strengthLevel = strengthLevelEnum
        strengthLevelColor = profileAnalyticsService.getStrengthLevelColor(user: user)
    }

    /**
     * Refreshes achievements data when user activity changes.
     *
     * Lightweight refresh for when new activities are logged that might
     * affect achievement progress without requiring full profile reload.
     *
     * - Parameters:
     *   - user: Current user profile
     *   - healthKitService: HealthKit integration service
     *   - liftSessions: Updated strength training sessions
     *   - nutritionEntries: Updated nutrition tracking entries
     *   - weightEntries: Updated weight tracking entries
     */
    func refreshAchievements(
        user: User?,
        healthKitService: HealthKitService,
        liftSessions: [LiftSession],
        nutritionEntries: [NutritionEntry],
        weightEntries: [WeightEntry]
    ) {
        guard let user = user else { return }

        achievements = achievementService.computeRecentAchievements(
            user: user,
            todaySteps: healthKitService.todaySteps,
            todayActiveCalories: healthKitService.todayActiveCalories,
            liftSessions: liftSessions,
            nutritionEntries: nutritionEntries,
            weightEntries: weightEntries
        )
    }

    /**
     * Refreshes health data and triggers HealthKit data fetch if authorized.
     *
     * - Parameter healthKitService: HealthKit service for data fetching
     */
    func refreshHealthData(healthKitService: HealthKitService) {
        if healthKitService.isAuthorized {
            Task {
                await healthKitService.readTodaysData()
            }
        }
    }

    // MARK: - Computed Properties

    /**
     * Determines if user can calculate strength level based on available data.
     */
    var canCalculateStrengthLevel: Bool {
        return strengthLevel != nil
    }

    /**
     * Determines if there are achievements to display.
     */
    var hasAchievements: Bool {
        return !achievements.isEmpty
    }

    /**
     * Gets the top 3 achievements for showcase display.
     */
    var showcaseAchievements: [Achievement] {
        return Array(achievements.prefix(3))
    }

    /**
     * Gets remaining achievement count for "view more" display.
     */
    var additionalAchievementsCount: Int {
        return max(0, achievements.count - 3)
    }

    // MARK: - State Management

    /**
     * Clears all data and resets to initial state.
     */
    func clearData() {
        achievements = []
        strengthLevel = nil
        strengthLevelString = "--"
        strengthLevelColor = .gray
        errorMessage = nil
        isLoading = false
    }

    /**
     * Shows error message to user.
     *
     * - Parameter message: Error message to display
     */
    func showError(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    /**
     * Clears current error state.
     */
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Analytics Support

    /**
     * Gets strength level progress for progress indicators.
     *
     * - Parameter user: User profile for progress calculation
     * - Returns: Progress percentage toward next strength level
     */
    func getStrengthLevelProgress(user: User?) -> Double {
        guard let user = user else { return 0.0 }
        return profileAnalyticsService.getStrengthLevelProgress(user: user)
    }

    /**
     * Determines if user has sufficient data for detailed analytics.
     *
     * - Parameter user: User profile to evaluate
     * - Returns: Boolean indicating if analytics can be calculated
     */
    func canShowAnalytics(user: User?) -> Bool {
        guard let user = user else { return false }
        return profileAnalyticsService.canCalculateStrengthLevel(user: user)
    }

    // MARK: - SwiftData Queries

    /**
     * Fetches recent lift sessions for achievements calculation.
     *
     * - Parameter modelContext: SwiftData model context
     * - Returns: Array of recent lift sessions
     * - Throws: SwiftData query errors
     */
    private func fetchRecentLiftSessions(modelContext: ModelContext) throws -> [LiftSession] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate { session in
                session.startDate >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /**
     * Fetches recent nutrition entries for achievements calculation.
     *
     * - Parameter modelContext: SwiftData model context
     * - Returns: Array of recent nutrition entries
     * - Throws: SwiftData query errors
     */
    private func fetchRecentNutritionEntries(modelContext: ModelContext) throws -> [NutritionEntry] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { entry in
                entry.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /**
     * Fetches recent weight entries for achievements calculation.
     *
     * - Parameter modelContext: SwiftData model context
     * - Returns: Array of recent weight entries
     * - Throws: SwiftData query errors
     */
    private func fetchRecentWeightEntries(modelContext: ModelContext) throws -> [WeightEntry] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }
}