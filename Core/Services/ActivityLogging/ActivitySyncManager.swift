import Foundation

/**
 * Manages CloudKit sync coordination for activity logging.
 *
 * Responsibilities:
 * - CloudKit sync state monitoring
 * - Pending activity queue management
 * - Sync conflict resolution
 */
@MainActor
@Observable
class ActivitySyncManager {

    // MARK: - Properties

    private(set) var isSyncInProgress = false
    private(set) var lastSyncCompletedTime: Date?
    private var activitiesProcessedDuringSync: Set<String> = []
    private var pendingActivities: [ActivityEntry] = []

    // MARK: - Singleton

    static let shared = ActivitySyncManager()
    private init() {
        setupCloudSyncObservers()
    }

    // MARK: - Public Methods

    /**
     * Checks if activity logging should be paused due to sync.
     */
    var shouldPauseLogging: Bool {
        return isSyncInProgress
    }

    /**
     * Adds activity to pending queue during sync.
     */
    func queueActivity(_ activity: ActivityEntry) {
        pendingActivities.append(activity)
        Logger.info("📋 Queued activity during sync: \(activity.title)")
    }

    /**
     * Gets count of pending activities.
     */
    var pendingActivityCount: Int {
        return pendingActivities.count
    }

    // MARK: - CloudKit Sync Observers

    private func setupCloudSyncObservers() {
        NotificationCenter.default.addObserver(
            forName: .cloudSyncStarted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSyncStarted()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .cloudSyncCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleSyncCompleted()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .cloudSyncFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleSyncFailed()
            }
        }
    }

    // MARK: - Sync Event Handlers

    private func handleSyncStarted() {
        isSyncInProgress = true
        activitiesProcessedDuringSync.removeAll()
        Logger.info("🔄 ActivitySync: Started, pausing activity logging")
    }

    private func handleSyncCompleted() async {
        isSyncInProgress = false
        lastSyncCompletedTime = Date()
        Logger.info("✅ ActivitySync: Completed, resuming activity logging")

        // Process pending activities
        await processPendingActivities()

        // Cleanup duplicates
        await cleanupPostSyncDuplicates()
    }

    private func handleSyncFailed() async {
        isSyncInProgress = false
        Logger.info("❌ ActivitySync: Failed, resuming activity logging")

        // Process pending activities even if sync failed
        await processPendingActivities()
    }

    // MARK: - Pending Activity Processing

    /**
     * Processes all pending activities after sync.
     */
    private func processPendingActivities() async {
        guard !pendingActivities.isEmpty else { return }

        Logger.info("🔄 Processing \(pendingActivities.count) pending activities")

        let activitiesToProcess = pendingActivities
        pendingActivities.removeAll()

        for activity in activitiesToProcess {
            // Process each pending activity
            await ActivityDataManager.shared.saveActivityDirectly(activity)
        }

        Logger.info("✅ Processed all pending activities")
    }

    /**
     * Cleans up duplicate activities after sync.
     */
    private func cleanupPostSyncDuplicates() async {
        // Delegate to data manager for cleanup
        await ActivityDataManager.shared.cleanupDuplicates()
    }

    /**
     * Marks activity as processed during sync.
     */
    func markActivityProcessed(_ activityId: String) {
        activitiesProcessedDuringSync.insert(activityId)
    }

    /**
     * Checks if activity was processed during current sync.
     */
    func wasActivityProcessedDuringSync(_ activityId: String) -> Bool {
        return activitiesProcessedDuringSync.contains(activityId)
    }
}

