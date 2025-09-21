import SwiftData
import Foundation

/**
 * ActivityLoggerService - Main orchestrator for activity logging
 *
 * Coordinates between micro-services to provide unified activity logging interface.
 * Delegates responsibilities to specialized services for better maintainability.
 */
@MainActor
@Observable
class ActivityLoggerService {

    // MARK: - Dependencies
    private let syncManager = ActivitySyncManager.shared
    private let dataManager = ActivityDataManager.shared

    // MARK: - Published Properties (delegated to micro-services)
    var isSyncInProgress: Bool {
        return syncManager.shouldPauseLogging
    }

    var lastSyncCompletedTime: Date? {
        return syncManager.lastSyncCompletedTime
    }

    var pendingActivityCount: Int {
        return syncManager.pendingActivityCount
    }

    // MARK: - Singleton
    static let shared = ActivityLoggerService()
    private init() {}

    // MARK: - Configuration
    func setModelContext(_ context: ModelContext) {
        dataManager.setModelContext(context)
    }

    // MARK: - Core Logging Methods (delegated to ActivityLoggerCore)

    /**
     * Logs a workout completion activity - delegates to ActivityLoggerCore
     */
    func logWorkoutCompleted(
        workoutType: String,
        duration: TimeInterval,
        volume: Double? = nil,
        user: User? = nil
    ) {
        guard let modelContext = dataManager.modelContext else {
            Logger.error("Model context not set")
            return
        }

        ActivityLoggerCore.logWorkoutCompleted(
            workoutType: workoutType,
            duration: duration,
            volume: volume,
            user: user ?? getCurrentUser(),
            modelContext: modelContext
        )
    }

    /**
     * Logs a cardio session completion - delegates to ActivityLoggerCore
     */
    func logCardioCompleted(
        activityType: String,
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        user: User? = nil
    ) {
        guard let modelContext = dataManager.modelContext else {
            Logger.error("Model context not set")
            return
        }

        ActivityLoggerCore.logCardioCompleted(
            activityType: activityType,
            distance: distance,
            duration: duration,
            calories: calories,
            user: user ?? getCurrentUser(),
            modelContext: modelContext
        )
    }

    /**
     * Logs nutrition entry - delegates to ActivityLoggerCore
     */
    func logNutritionEntry(
        foodName: String,
        calories: Double,
        meal: String,
        user: User? = nil
    ) {
        guard let modelContext = dataManager.modelContext else {
            Logger.error("Model context not set")
            return
        }

        ActivityLoggerCore.logNutritionEntry(
            foodName: foodName,
            calories: calories,
            meal: meal,
            user: user ?? getCurrentUser(),
            modelContext: modelContext
        )
    }

    /**
     * Logs personal record achievement - delegates to ActivityLoggerCore
     */
    func logPersonalRecord(
        exerciseName: String,
        newRecord: Double,
        previousRecord: Double? = nil,
        user: User? = nil
    ) {
        guard let modelContext = dataManager.modelContext else {
            Logger.error("Model context not set")
            return
        }

        ActivityLoggerCore.logNewPR(
            exerciseName: exerciseName,
            newRecord: newRecord,
            previousRecord: previousRecord,
            user: user ?? getCurrentUser(),
            modelContext: modelContext
        )
    }

    /**
     * Logs weight tracking entry - delegates to ActivityLoggerCore
     */
    func logWeightEntry(
        weight: Double,
        user: User? = nil
    ) {
        guard let modelContext = dataManager.modelContext else {
            Logger.error("Model context not set")
            return
        }

        ActivityLoggerCore.logWeightEntry(
            weight: weight,
            user: user ?? getCurrentUser(),
            modelContext: modelContext
        )
    }

    // MARK: - Data Management (delegated to ActivityDataManager)

    /**
     * Fetches recent activities for dashboard - delegates to ActivityDataManager
     */
    func fetchRecentActivities(limit: Int = 10, for user: User? = nil) async -> [ActivityEntry] {
        if let user = user {
            return await dataManager.getActivitiesForUser(user, limit: limit)
        } else {
            return await dataManager.getRecentActivities(limit: limit)
        }
    }

    /**
     * Fetches activities by type - delegates to ActivityDataManager
     */
    func fetchActivitiesByType(_ type: ActivityType, limit: Int = 20) async -> [ActivityEntry] {
        return await dataManager.getActivitiesByType(type, limit: limit)
    }

    /**
     * Gets activity statistics - delegates to ActivityDataManager
     */
    func getActivityStats(from startDate: Date, to endDate: Date) async -> ActivityStats {
        return await dataManager.getActivityStats(from: startDate, to: endDate)
    }

    /**
     * Gets total activity count - delegates to ActivityDataManager
     */
    func getTotalActivityCount() async -> Int {
        return await dataManager.getTotalActivityCount()
    }

    /**
     * Performs cleanup of old activities - delegates to ActivityDataManager
     */
    func performCleanup() async {
        await dataManager.cleanupOldActivities()
        await dataManager.cleanupDuplicates()
    }

    // MARK: - Sync Management (delegated to ActivitySyncManager)

    /**
     * Queues activity during sync - delegates to ActivitySyncManager
     */
    func queueActivity(_ activity: ActivityEntry) {
        syncManager.queueActivity(activity)
    }

    /**
     * Checks if activity was processed during sync - delegates to ActivitySyncManager
     */
    func wasActivityProcessedDuringSync(_ activityId: String) -> Bool {
        return syncManager.wasActivityProcessedDuringSync(activityId)
    }

    /**
     * Marks activity as processed - delegates to ActivitySyncManager
     */
    func markActivityProcessed(_ activityId: String) {
        syncManager.markActivityProcessed(activityId)
    }

    // MARK: - Direct Activity Operations

    /**
     * Saves activity directly - coordinates between sync and data managers
     */
    func saveActivityDirectly(_ activity: ActivityEntry) async {
        if syncManager.shouldPauseLogging {
            syncManager.queueActivity(activity)
        } else {
            await dataManager.saveActivityDirectly(activity)
        }
    }

    // MARK: - Cache Management

    /**
     * Invalidates data cache - delegates to ActivityDataManager
     */
    func invalidateCache() {
        dataManager.invalidateCache()
    }

    // MARK: - Helper Methods

    /**
     * Gets current user - should be implemented based on app's user management
     */
    private func getCurrentUser() -> User {
        // TODO: Implement proper user fetching logic
        return User()
    }
}

// MARK: - Legacy Support

extension ActivityLoggerService {

    /**
     * Legacy meal logging method - kept for backward compatibility
     */
    func logMealCompleted(
        mealType: String,
        foodCount: Int,
        totalCalories: Double,
        totalProtein: Double,
        totalCarbs: Double,
        totalFat: Double,
        user: User? = nil
    ) {
        // For now, just log the main nutrition info
        logNutritionEntry(
            foodName: "\(foodCount) foods",
            calories: totalCalories,
            meal: mealType,
            user: user
        )
    }

    /**
     * Legacy synchronous fetch method - deprecated, use async version
     */
    @available(*, deprecated, message: "Use fetchRecentActivities(limit:for:) async version instead")
    func fetchRecentActivitiesSync(limit: Int = 10, for user: User? = nil) -> [ActivityEntry] {
        // Return empty array for sync version, encourage async usage
        return []
    }
}