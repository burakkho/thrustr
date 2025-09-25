import SwiftData
import Foundation

/**
 * Manages activity data operations and persistence.
 *
 * Responsibilities:
 * - Data persistence and retrieval
 * - Cache management
 * - Data cleanup and maintenance
 * - Query optimization
 */
@MainActor
@Observable
class ActivityDataManager {

    // MARK: - Properties

    private var _modelContext: ModelContext?

    var modelContext: ModelContext? {
        return _modelContext
    }
    private let maxRetentionDays = 30

    // Cache properties
    private var cachedActivities: [ActivityEntry] = []
    private var lastCacheTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    // MARK: - Singleton

    static let shared = ActivityDataManager()
    private init() {}

    // MARK: - Configuration

    func setModelContext(_ context: ModelContext) {
        self._modelContext = context
    }

    // MARK: - Data Operations

    /**
     * Saves activity directly to database.
     */
    func saveActivityDirectly(_ activity: ActivityEntry) async {
        guard let modelContext = _modelContext else {
            Logger.error("Model context not set for ActivityDataManager")
            return
        }

        do {
            modelContext.insert(activity)
            try modelContext.save()
            invalidateCache()
            Logger.info("✅ Activity saved: \(activity.title)")
        } catch {
            Logger.error("Failed to save activity: \(error)")
        }
    }

    /**
     * Retrieves recent activities with caching.
     */
    func getRecentActivities(limit: Int = 50) async -> [ActivityEntry] {
        // Check cache first
        if let lastCacheTime = lastCacheTime,
           Date().timeIntervalSince(lastCacheTime) < cacheValidityDuration,
           !cachedActivities.isEmpty {
            return Array(cachedActivities.prefix(limit))
        }

        // Fetch from database
        return await fetchActivitiesFromDatabase(limit: limit)
    }

    /**
     * Gets activities for a specific user.
     */
    func getActivitiesForUser(_ user: User, limit: Int = 50) async -> [ActivityEntry] {
        guard let modelContext = _modelContext else { return [] }

        do {
            // Fetch all activities and filter manually due to SwiftData Predicate limitations
            var descriptor = FetchDescriptor<ActivityEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = limit * 2 // Fetch more to account for filtering

            let allActivities = try modelContext.fetch(descriptor)
            let userActivities = allActivities.filter { activity in
                activity.user?.id == user.id
            }

            return Array(userActivities.prefix(limit))
        } catch {
            Logger.error("Failed to fetch user activities: \(error)")
            return []
        }
    }

    /**
     * Gets activities by type.
     */
    func getActivitiesByType(_ type: ActivityType, limit: Int = 20) async -> [ActivityEntry] {
        guard let modelContext = _modelContext else { return [] }

        do {
            // Use direct string comparison to avoid enum rawValue issues
            let typeString = type.rawValue
            var descriptor = FetchDescriptor<ActivityEntry>(
                predicate: #Predicate<ActivityEntry> { activity in
                    activity.type == typeString
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = limit

            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("Failed to fetch activities by type: \(error)")
            return []
        }
    }

    // MARK: - Data Maintenance

    /**
     * Cleans up old activities beyond retention period.
     */
    func cleanupOldActivities() async {
        guard let modelContext = _modelContext else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxRetentionDays, to: Date()) ?? Date()

        do {
            let descriptor = FetchDescriptor<ActivityEntry>(
                predicate: #Predicate { activity in
                    activity.timestamp < cutoffDate
                }
            )

            let oldActivities = try modelContext.fetch(descriptor)

            for activity in oldActivities {
                modelContext.delete(activity)
            }

            try modelContext.save()
            invalidateCache()

            Logger.info("🧹 Cleaned up \(oldActivities.count) old activities")
        } catch {
            Logger.error("Failed to cleanup old activities: \(error)")
        }
    }

    /**
     * Removes duplicate activities after sync.
     */
    func cleanupDuplicates() async {
        guard let modelContext = _modelContext else { return }

        do {
            let descriptor = FetchDescriptor<ActivityEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )

            let allActivities = try modelContext.fetch(descriptor)
            var seenActivityIds = Set<PersistentIdentifier>()
            var duplicatesToDelete: [ActivityEntry] = []

            for activity in allActivities {
                if seenActivityIds.contains(activity.persistentModelID) {
                    duplicatesToDelete.append(activity)
                } else {
                    seenActivityIds.insert(activity.persistentModelID)
                }
            }

            for duplicate in duplicatesToDelete {
                modelContext.delete(duplicate)
            }

            if !duplicatesToDelete.isEmpty {
                try modelContext.save()
                invalidateCache()
                Logger.info("🧹 Removed \(duplicatesToDelete.count) duplicate activities")
            }

        } catch {
            Logger.error("Failed to cleanup duplicates: \(error)")
        }
    }

    /**
     * Gets total activity count.
     */
    func getTotalActivityCount() async -> Int {
        guard let modelContext = _modelContext else { return 0 }

        do {
            let descriptor = FetchDescriptor<ActivityEntry>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            Logger.error("Failed to get activity count: \(error)")
            return 0
        }
    }

    // MARK: - Cache Management

    /**
     * Invalidates activity cache.
     */
    func invalidateCache() {
        cachedActivities.removeAll()
        lastCacheTime = nil
    }

    /**
     * Fetches activities from database and updates cache.
     */
    private func fetchActivitiesFromDatabase(limit: Int) async -> [ActivityEntry] {
        guard let modelContext = _modelContext else { return [] }

        do {
            var descriptor = FetchDescriptor<ActivityEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = limit

            let activities = try modelContext.fetch(descriptor)

            // Update cache
            cachedActivities = activities
            lastCacheTime = Date()

            return activities
        } catch {
            Logger.error("Failed to fetch activities: \(error)")
            return []
        }
    }

    // MARK: - Statistics

    /**
     * Gets activity statistics for date range.
     */
    func getActivityStats(from startDate: Date, to endDate: Date) async -> ActivityStats {
        guard let modelContext = _modelContext else {
            return ActivityStats(totalActivities: 0, workoutCount: 0, nutritionCount: 0, averagePerDay: 0.0)
        }

        do {
            let descriptor = FetchDescriptor<ActivityEntry>(
                predicate: #Predicate { activity in
                    activity.timestamp >= startDate && activity.timestamp <= endDate
                }
            )

            let activities = try modelContext.fetch(descriptor)
            let workoutCount = activities.filter { $0.typeEnum == .workoutCompleted || $0.typeEnum == .cardioCompleted }.count
            let nutritionCount = activities.filter { $0.typeEnum == .nutritionLogged }.count

            let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            let averagePerDay = Double(activities.count) / Double(max(daysDifference, 1))

            return ActivityStats(
                totalActivities: activities.count,
                workoutCount: workoutCount,
                nutritionCount: nutritionCount,
                averagePerDay: averagePerDay
            )
        } catch {
            Logger.error("Failed to get activity stats: \(error)")
            return ActivityStats(totalActivities: 0, workoutCount: 0, nutritionCount: 0, averagePerDay: 0.0)
        }
    }
}

// MARK: - Supporting Types

struct ActivityStats {
    let totalActivities: Int
    let workoutCount: Int
    let nutritionCount: Int
    let averagePerDay: Double
}