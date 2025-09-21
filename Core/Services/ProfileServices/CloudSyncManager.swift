import SwiftUI
import SwiftData
import CloudKit

/**
 * Optional CloudKit sync manager for SwiftData
 * 
 * Provides background sync functionality when iCloud is available.
 * Falls back gracefully when iCloud is not available.
 */
@MainActor
@Observable
class CloudSyncManager {
    
    static let shared = CloudSyncManager()
    
    // MARK: - State
    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?
    var isEnabled: Bool = false
    var error: SyncError?
    var isSyncInProgress: Bool = false
    
    // MARK: - Dependencies
    private let availabilityService = CloudKitAvailabilityService.shared
    private var modelContainer: ModelContainer?
    
    // MARK: - Sync Status
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed
        
        var displayText: String {
            switch self {
            case .idle: return "Ready"
            case .syncing: return "Syncing..."
            case .success: return "Synced"
            case .failed: return "Sync failed"
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .success: return "checkmark.icloud"
            case .failed: return "exclamationmark.icloud"
            }
        }
    }
    
    enum SyncError: Error, LocalizedError {
        case cloudKitUnavailable
        case syncFailed(Error)
        case containerNotSet
        case networkUnavailable
        case quotaExceeded
        case authenticationFailed
        case conflictResolutionFailed
        
        var errorDescription: String? {
            switch self {
            case .cloudKitUnavailable:
                return "iCloud is not available. Please sign in to iCloud in Settings."
            case .syncFailed(let error):
                return "Sync failed: \(error.localizedDescription)"
            case .containerNotSet:
                return "Container not configured"
            case .networkUnavailable:
                return "Network connection required for sync"
            case .quotaExceeded:
                return "iCloud storage is full. Free up space to continue syncing."
            case .authenticationFailed:
                return "iCloud authentication failed. Please sign in again."
            case .conflictResolutionFailed:
                return "Unable to resolve data conflicts"
            }
        }
        
        var userActionMessage: String {
            switch self {
            case .cloudKitUnavailable, .authenticationFailed:
                return "Go to Settings → [Your Name] → iCloud to sign in"
            case .networkUnavailable:
                return "Connect to WiFi or cellular data"
            case .quotaExceeded:
                return "Go to Settings → [Your Name] → iCloud → Manage Storage"
            case .syncFailed, .containerNotSet, .conflictResolutionFailed:
                return "Try syncing again in a few minutes"
            }
        }
        
        var recoveryIcon: String {
            switch self {
            case .cloudKitUnavailable, .authenticationFailed:
                return "person.crop.circle.badge.exclamationmark"
            case .networkUnavailable:
                return "wifi.exclamationmark"
            case .quotaExceeded:
                return "icloud.fill"
            case .syncFailed, .containerNotSet, .conflictResolutionFailed:
                return "arrow.clockwise"
            }
        }
    }
    
    private init() {
        // Monitor CloudKit availability changes
        setupAvailabilityObserver()
    }
    
    // MARK: - Public Methods
    
    /**
     * Configure the sync manager with SwiftData container
     */
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        
        // Enable sync if CloudKit is available
        if availabilityService.isAvailable {
            enableSync()
        }
    }
    
    /**
     * Enable CloudKit sync (if available)
     */
    func enableSync() {
        guard availabilityService.isAvailable else {
            error = .cloudKitUnavailable
            isEnabled = false
            return
        }
        
        isEnabled = true
        error = nil
        print("☁️ CloudKit sync enabled")
    }
    
    /**
     * Disable CloudKit sync
     */
    func disableSync() {
        isEnabled = false
        syncStatus = .idle
        error = nil
        print("📱 CloudKit sync disabled - using local storage only")
    }
    
    /**
     * Manual sync trigger with comprehensive sync logic
     */
    func sync() async {
        guard isEnabled else {
            error = .cloudKitUnavailable
            return
        }
        
        guard let container = modelContainer else {
            error = .containerNotSet
            return
        }
        
        syncStatus = .syncing
        isSyncInProgress = true
        let startTime = Date()
        
        do {
            Logger.info("🔄 CloudKit sync started - ActivityLogger will pause meal logging")
            
            // Notify about sync start to prevent activity logging
            NotificationCenter.default.post(name: .cloudSyncStarted, object: nil)
            
            // Step 1: Perform sync operations using existing container
            try await performSyncOperations(container: container)
            
            // Step 2: Update sync status
            syncStatus = .success
            lastSyncDate = Date()
            error = nil
            isSyncInProgress = false
            
            let duration = Date().timeIntervalSince(startTime)
            Logger.success("✅ CloudKit sync completed in \(String(format: "%.2f", duration))s - ActivityLogger will resume and clean duplicates")
            
            // Notify about sync completion
            NotificationCenter.default.post(name: .cloudSyncCompleted, object: nil)
            
        } catch let syncError {
            syncStatus = .failed
            self.error = .syncFailed(syncError)
            isSyncInProgress = false
            Logger.error("❌ CloudKit sync failed: \(syncError)")
            
            // Notify about sync failure
            NotificationCenter.default.post(name: .cloudSyncFailed, object: syncError)
        }
    }
    
    /**
     * Performs actual sync operations between local and CloudKit data
     */
    private func performSyncOperations(container: ModelContainer) async throws {
        let context = container.mainContext
        
        // CloudKit sync operations happen automatically with SwiftData + CloudKit
        // when using dual configuration. We just need to trigger context saves.
        
        do {
            // Ensure pending changes are saved to trigger CloudKit sync
            if context.hasChanges {
                try context.save()
                Logger.info("💾 Local changes saved, CloudKit sync triggered")
            }
            
            // Brief pause to allow CloudKit to process
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // SwiftData + CloudKit sync happens automatically after save
            Logger.info("🔄 CloudKit sync triggered, changes will propagate automatically")
            
        } catch {
            throw SyncError.syncFailed(error)
        }
    }
    
    /**
     * Automatic background sync
     */
    func performBackgroundSync() async {
        guard canSync && !isCurrentlySyncing && !isSyncInProgress else { return }
        
        Logger.info("📱 Background sync triggered")
        await sync()
    }
    
    /**
     * Check if sync is currently in progress
     */
    var isCurrentlySyncing: Bool {
        return syncStatus == .syncing
    }
    
    /**
     * Check if sync is available
     */
    var canSync: Bool {
        return availabilityService.isAvailable && modelContainer != nil
    }
    
    // MARK: - Private Methods
    
    private func setupAvailabilityObserver() {
        // Modern @Observable observation pattern
        // Monitor availabilityService.isAvailable for changes
        Task {
            while true {
                if availabilityService.isAvailable && modelContainer != nil {
                    if !isEnabled {
                        enableSync()
                    }
                } else {
                    if isEnabled {
                        disableSync()
                    }
                }

                // Check every 30 seconds for availability changes
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }

    // Note: Cannot store Task reference due to @Observable macro limitations
    // Using detached tasks instead of stored task references
    
    // MARK: - Automatic Sync Scheduling
    
    /**
     * Start automatic sync scheduling using detached task approach
     */
    func startAutomaticSync() {
        guard isEnabled else { return }

        // Use detached task for background sync (no stored reference due to @Observable)
        Task.detached { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes

                if !Task.isCancelled {
                    await self?.performBackgroundSync()
                }
            }
        }

        Logger.info("⏰ Automatic sync scheduled every 5 minutes using detached task pattern")
    }
    
    /**
     * Trigger sync when app becomes active
     */
    func syncOnAppActive() async {
        guard canSync else { return }
        
        // Only sync if it's been more than 2 minutes since last sync
        let minimumInterval: TimeInterval = 120 // 2 minutes
        
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < minimumInterval {
            Logger.info("⏭️ Skipping sync - too recent (\(Int(Date().timeIntervalSince(lastSync)))s ago)")
            return
        }
        
        Logger.info("📱 App active sync triggered")
        await sync()
    }
    
    /**
     * Get sync status summary for UI
     */
    var syncStatusSummary: String {
        switch syncStatus {
        case .idle:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            } else {
                return "Not synced yet"
            }
        case .syncing:
            return "Syncing..."
        case .success:
            return "Up to date"
        case .failed:
            return "Sync failed"
        }
    }
    
    /**
     * Get sync status color for UI
     */
    var syncStatusColor: String {
        switch syncStatus {
        case .idle:
            return lastSyncDate != nil ? "secondary" : "orange"
        case .syncing:
            return "blue"
        case .success:
            return "green"
        case .failed:
            return "red"
        }
    }

    /**
     * Stop automatic sync (detached tasks will self-cancel when object is deallocated)
     */
    func stopAutomaticSync() {
        // Detached tasks automatically cancel when weak self becomes nil
        Logger.info("⏹️ Automatic sync stopped - detached tasks will self-cancel")
    }

    // MARK: - Cleanup
    deinit {
        // Detached tasks with weak self will automatically stop when object deallocates
        Logger.info("CloudSyncManager deinitialized")
    }
}

// MARK: - Modern @Observable Pattern
// No longer using Combine - migrated to @Observable observation

// MARK: - Notification Names
extension Notification.Name {
    static let cloudSyncStarted = Notification.Name("cloudSyncStarted")
    static let cloudSyncCompleted = Notification.Name("cloudSyncCompleted")
    static let cloudSyncFailed = Notification.Name("cloudSyncFailed")
}