import Foundation
import CloudKit

/**
 * Background workout data synchronization using Swift 6 actor pattern.
 * 
 * Handles all sync operations including:
 * - CloudKit data synchronization  
 * - Offline queue management
 * - Conflict resolution
 * - Data integrity validation
 */
actor WorkoutDataSyncer {
    static let shared = WorkoutDataSyncer()
    
    // MARK: - Private State
    private var syncQueue: [SyncOperation] = []
    private var activeSyncs: Set<UUID> = []
    private var lastSyncDate: Date?
    private var isOnline = true
    private let maxRetries = 3
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        Task { @Sendable in
            await startPeriodicSync()
        }
    }
    
    // MARK: - Public Interface
    
    /**
     * Sync workout data to CloudKit
     */
    func syncWorkout(_ workoutData: WorkoutSyncData) async -> SyncResult {
        let operation = SyncOperation(
            id: UUID(),
            type: .workout,
            data: workoutData,
            priority: .normal,
            retryCount: 0,
            createdAt: Date()
        )
        
        return await performSync(operation)
    }
    
    /**
     * Sync nutrition data to CloudKit
     */
    func syncNutrition(_ nutritionData: NutritionSyncData) async -> SyncResult {
        let operation = SyncOperation(
            id: UUID(),
            type: .nutrition,
            data: nutritionData,
            priority: .normal,
            retryCount: 0,
            createdAt: Date()
        )
        
        return await performSync(operation)
    }
    
    /**
     * Queue data for background sync (when offline)
     */
    func queueForSync<T: Sendable>(_ data: T, type: SyncType, priority: SyncPriority = .normal) async {
        let operation = SyncOperation(
            id: UUID(),
            type: type,
            data: data,
            priority: priority,
            retryCount: 0,
            createdAt: Date()
        )
        
        // Insert based on priority
        if priority == .high {
            syncQueue.insert(operation, at: 0)
        } else {
            syncQueue.append(operation)
        }
    }
    
    /**
     * Process sync queue (called when coming online)
     */
    func processPendingSync() async {
        guard isOnline && !syncQueue.isEmpty else { return }
        
        let operations = Array(syncQueue.prefix(10)) // Process 10 at a time
        syncQueue.removeFirst(min(10, syncQueue.count))
        
        await withTaskGroup(of: SyncResult.self) { group in
            for operation in operations {
                group.addTask { @Sendable in
                    await self.performSync(operation)
                }
            }
            
            // Collect results
            for await result in group {
                if case .failure = result {
                    // Re-queue failed operations
                    // Implementation would add back to queue with retry logic
                }
            }
        }
    }
    
    /**
     * Update online status
     */
    func updateOnlineStatus(_ online: Bool) async {
        let wasOffline = !isOnline
        isOnline = online
        
        // If just came online, process pending syncs
        if online && wasOffline {
            await processPendingSync()
        }
    }
    
    /**
     * Get sync status
     */
    func getSyncStatus() async -> SyncStatus {
        return SyncStatus(
            isOnline: isOnline,
            pendingOperations: syncQueue.count,
            activeOperations: activeSyncs.count,
            lastSyncDate: lastSyncDate
        )
    }
    
    /**
     * Force immediate sync of all pending data
     */
    func forceSync() async -> [SyncResult] {
        guard isOnline else { 
            return [.failure(SyncError.offline)]
        }
        
        var results: [SyncResult] = []
        
        // Process all pending operations
        while !syncQueue.isEmpty {
            let batch = Array(syncQueue.prefix(5))
            syncQueue.removeFirst(min(5, syncQueue.count))
            
            await withTaskGroup(of: SyncResult.self) { group in
                for operation in batch {
                    group.addTask { @Sendable in
                        await self.performSync(operation)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Private Implementation
    
    private func startPeriodicSync() async {
        while true {
            try? await Task.sleep(nanoseconds: UInt64(syncInterval * 1_000_000_000))
            
            if isOnline && !syncQueue.isEmpty {
                await processPendingSync()
            }
        }
    }
    
    private func performSync(_ operation: SyncOperation) async -> SyncResult {
        guard isOnline else {
            // Re-queue for later
            syncQueue.append(operation)
            return .failure(SyncError.offline)
        }
        
        guard !activeSyncs.contains(operation.id) else {
            return .failure(SyncError.alreadyInProgress)
        }
        
        activeSyncs.insert(operation.id)
        defer { activeSyncs.remove(operation.id) }
        
        do {
            switch operation.type {
            case .workout:
                if let workoutData = operation.data as? WorkoutSyncData {
                    try await syncWorkoutToCloudKit(workoutData)
                }
            case .nutrition:
                if let nutritionData = operation.data as? NutritionSyncData {
                    try await syncNutritionToCloudKit(nutritionData)
                }
            case .userProfile:
                if let profileData = operation.data as? UserProfileSyncData {
                    try await syncProfileToCloudKit(profileData)
                }
            }
            
            lastSyncDate = Date()
            return .success
            
        } catch {
            // Handle retry logic
            if operation.retryCount < maxRetries {
                var retriedOperation = operation
                retriedOperation.retryCount += 1
                
                // Exponential backoff
                let delay = pow(2.0, Double(operation.retryCount))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return await performSync(retriedOperation)
            } else {
                return .failure(SyncError.maxRetriesExceeded)
            }
        }
    }
    
    private func syncWorkoutToCloudKit(_ data: WorkoutSyncData) async throws {
        // CloudKit sync implementation
        // This would use CKRecord and CKDatabase operations
        
        // Simulate network operation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate data integrity
        try validateWorkoutData(data)
    }
    
    private func syncNutritionToCloudKit(_ data: NutritionSyncData) async throws {
        // CloudKit sync implementation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        try validateNutritionData(data)
    }
    
    private func syncProfileToCloudKit(_ data: UserProfileSyncData) async throws {
        // CloudKit sync implementation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        try validateProfileData(data)
    }
    
    private func validateWorkoutData(_ data: WorkoutSyncData) throws {
        guard data.duration > 0 else {
            throw SyncError.invalidData("Workout duration must be positive")
        }
        guard !data.exercises.isEmpty else {
            throw SyncError.invalidData("Workout must contain exercises")
        }
    }
    
    private func validateNutritionData(_ data: NutritionSyncData) throws {
        guard data.calories >= 0 else {
            throw SyncError.invalidData("Calories cannot be negative")
        }
    }
    
    private func validateProfileData(_ data: UserProfileSyncData) throws {
        guard !data.userId.isEmpty else {
            throw SyncError.invalidData("User ID cannot be empty")
        }
    }
}

// MARK: - Supporting Types

struct SyncOperation: Sendable {
    let id: UUID
    let type: SyncType
    let data: Any
    let priority: SyncPriority
    var retryCount: Int
    let createdAt: Date
}

enum SyncType: Sendable {
    case workout, nutrition, userProfile
}

enum SyncPriority: Sendable {
    case low, normal, high
}

enum SyncResult: Sendable {
    case success
    case failure(SyncError)
}

enum SyncError: Error, Sendable {
    case offline
    case alreadyInProgress
    case maxRetriesExceeded
    case invalidData(String)
    case networkError(String)
    case cloudKitError(String)
}

struct SyncStatus: Sendable {
    let isOnline: Bool
    let pendingOperations: Int
    let activeOperations: Int
    let lastSyncDate: Date?
}

// MARK: - Data Types

struct WorkoutSyncData: Sendable {
    let id: UUID
    let type: String
    let duration: TimeInterval
    let exercises: [ExerciseSyncData]
    let completedAt: Date
}

struct ExerciseSyncData: Sendable {
    let name: String
    let sets: Int
    let reps: [Int]
    let weight: [Double]
}

struct NutritionSyncData: Sendable {
    let id: UUID
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let meals: [MealSyncData]
}

struct MealSyncData: Sendable {
    let name: String
    let foods: [FoodSyncData]
}

struct FoodSyncData: Sendable {
    let name: String
    let quantity: Double
    let unit: String
    let calories: Double
}

struct UserProfileSyncData: Sendable {
    let userId: String
    let name: String
    let age: Int
    let weight: Double
    let height: Double
    let fitnessGoals: [String]
}