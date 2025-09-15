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

    // MARK: - Data Loading

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
    func loadProfileData(
        user: User?,
        healthKitService: HealthKitService,
        liftSessions: [LiftSession],
        nutritionEntries: [NutritionEntry],
        weightEntries: [WeightEntry]
    ) {
        guard let user = user else {
            clearData()
            return
        }

        isLoading = true
        errorMessage = nil

        // Load achievements using service
        achievements = achievementService.computeRecentAchievements(
            user: user,
            todaySteps: healthKitService.todaySteps,
            todayActiveCalories: healthKitService.todayActiveCalories,
            liftSessions: liftSessions,
            nutritionEntries: nutritionEntries,
            weightEntries: weightEntries
        )

        // Load strength level analysis
        loadStrengthLevel(user: user)

        isLoading = false
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
}