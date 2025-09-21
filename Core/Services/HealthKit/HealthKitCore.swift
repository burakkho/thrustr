import Foundation
import HealthKit
import UserNotifications

/**
 * Core HealthKit infrastructure providing shared functionality for all HealthKit services.
 *
 * This service manages the fundamental HealthKit operations including authorization,
 * permissions, shared health data types, and common utilities. All specialized
 * HealthKit services depend on this core infrastructure.
 *
 * Features:
 * - Centralized authorization management
 * - Shared HKHealthStore instance
 * - Common health data type definitions
 * - Permission status tracking
 * - Notification integration
 * - Error handling utilities
 */
final class HealthKitCore {
    static let shared = HealthKitCore()

    // MARK: - Core HealthKit Infrastructure
    let healthStore = HKHealthStore()
    private let queryManager = HealthQueryManager()

    // MARK: - Authorization State
    var isAuthorized = false
    var authorizationStatuses: [String: HKAuthorizationStatus] = [:]

    // MARK: - Health Data Types

    // MARK: Activity & Fitness Types
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
    let distanceWalkingRunningType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    let distanceCyclingType = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
    let flightsClimbedType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
    let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    let standTimeType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!

    // MARK: Heart & Cardiovascular Types
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!

    // MARK: Body Measurements Types
    let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
    let bodyFatPercentageType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
    let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
    let heightType = HKQuantityType.quantityType(forIdentifier: .height)!

    // MARK: Sleep & Recovery Types
    let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

    // MARK: Workouts & Training Types
    let workoutType = HKWorkoutType.workoutType()

    // MARK: Nutrition Types
    let dietaryEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
    let dietaryProteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
    let dietaryCarbohydratesType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
    let dietaryFatTotalType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!

    // MARK: - Initialization
    private init() {}

    // MARK: - Authorization & Permissions

    /**
     * Request comprehensive HealthKit permissions for all app features.
     *
     * Requests authorization for both reading and writing health data across
     * all features including activity, body measurements, heart data, sleep,
     * workouts, and nutrition. Also requests notification permissions.
     *
     * - Returns: Boolean indicating if authorization was granted for core metrics
     */
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device")
            return false
        }

        // Request both HealthKit and Notification permissions together
        async let healthKitResult = requestHealthKitPermissions()
        async let notificationResult = requestNotificationPermissions()

        let (healthAuthorized, notificationRequested) = await (healthKitResult, notificationResult)

        if healthAuthorized {
            enableBackgroundDelivery()
            startObserverQueries()
        }

        Logger.success("Permissions requested - HealthKit: \(healthAuthorized), Notifications: \(notificationRequested)")
        return healthAuthorized
    }

    private func requestHealthKitPermissions() async -> Bool {
        // MARK: Comprehensive Read Types - 20+ health metrics
        let readTypes: Set<HKObjectType> = [
            // Activity & Fitness
            stepCountType,
            activeEnergyType,
            basalEnergyType,
            distanceWalkingRunningType,
            distanceCyclingType,
            flightsClimbedType,
            exerciseTimeType,
            standTimeType,

            // Heart & Cardiovascular
            heartRateType,
            restingHeartRateType,
            heartRateVariabilityType,
            vo2MaxType,

            // Body Measurements
            bodyMassType,
            bodyMassIndexType,
            bodyFatPercentageType,
            leanBodyMassType,
            heightType,

            // Sleep & Recovery
            sleepAnalysisType,

            // Workouts
            workoutType
        ]

        // MARK: Write/Share Types
        let shareTypes: Set<HKSampleType> = [
            // Body Measurements
            bodyMassType,
            bodyMassIndexType,
            bodyFatPercentageType,
            leanBodyMassType,
            heightType,

            // Workouts & Activity
            workoutType,
            heartRateType,

            // Nutrition
            dietaryEnergyType,
            dietaryProteinType,
            dietaryCarbohydratesType,
            dietaryFatTotalType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)

            // Update authorization statuses
            await updateAuthorizationStatuses(for: readTypes)

            // Check if we have at least basic authorization for core metrics
            let stepStatus = healthStore.authorizationStatus(for: stepCountType)
            let calorieStatus = healthStore.authorizationStatus(for: activeEnergyType)
            let weightStatus = healthStore.authorizationStatus(for: bodyMassType)
            let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)

            isAuthorized = (stepStatus == .sharingAuthorized) ||
                           (calorieStatus == .sharingAuthorized) ||
                           (weightStatus == .sharingAuthorized) ||
                           (heartRateStatus == .sharingAuthorized)

            Logger.info("HealthKit Authorization Summary - Steps: \(stepStatus.rawValue), Calories: \(calorieStatus.rawValue), Weight: \(weightStatus.rawValue), HR: \(heartRateStatus.rawValue)")

            return isAuthorized
        } catch {
            Logger.error("HealthKit authorization error: \(error)")
            return false
        }
    }

    private func updateAuthorizationStatuses(for types: Set<HKObjectType>) async {
        var statuses: [String: HKAuthorizationStatus] = [:]

        for type in types {
            let status = healthStore.authorizationStatus(for: type)
            let identifier = type.identifier
            statuses[identifier] = status
        }

        authorizationStatuses = statuses
        Logger.info("Updated authorization statuses for \(statuses.count) health data types")
    }

    private func requestNotificationPermissions() async -> Bool {
        do {
            try await NotificationManager.shared.requestAuthorization()
            return true
        } catch {
            Logger.error("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Authorization Status Utilities

    func getAuthorizationStatusSummary() -> (authorized: Int, denied: Int, notDetermined: Int) {
        let authorized = authorizationStatuses.values.filter { $0 == .sharingAuthorized }.count
        let denied = authorizationStatuses.values.filter { $0 == .sharingDenied }.count
        let notDetermined = authorizationStatuses.values.filter { $0 == .notDetermined }.count

        return (authorized, denied, notDetermined)
    }

    func getAuthorizationStatus() -> (steps: HKAuthorizationStatus, calories: HKAuthorizationStatus, weight: HKAuthorizationStatus) {
        return (
            steps: healthStore.authorizationStatus(for: stepCountType),
            calories: healthStore.authorizationStatus(for: activeEnergyType),
            weight: healthStore.authorizationStatus(for: bodyMassType)
        )
    }

    // MARK: - Background Updates & Observer Queries

    func enableBackgroundDelivery() {
        let types: [HKQuantityType] = [
            // Core metrics
            stepCountType, activeEnergyType, bodyMassType,
            // Extended metrics
            heartRateType, restingHeartRateType, heartRateVariabilityType,
            distanceWalkingRunningType, flightsClimbedType,
            exerciseTimeType, standTimeType
        ]

        for type in types {
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    Logger.error("Error enabling background delivery for \(type.identifier): \(error)")
                } else if success {
                    Logger.info("Background delivery enabled for \(type.identifier)")
                }
            }
        }
    }

    func startObserverQueries() {
        let types: [HKQuantityType] = [stepCountType, activeEnergyType, bodyMassType]

        // Cancel previously running queries to avoid duplicates
        Task {
            await queryManager.stopAllQueries(healthStore)
        }

        for type in types {
            let observerQuery = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                // Create a nonisolated wrapper for the completion handler
                nonisolated(unsafe) let completion = completionHandler
                if let error = error {
                    Logger.error("HealthKit observer error for \(type.identifier): \(error)")
                    completion()
                    return
                }

                Task { @MainActor [weak self] in
                    guard self != nil else { completion(); return }
                    // Notify interested services about updates
                    NotificationCenter.default.post(name: .healthKitDataUpdated, object: type.identifier)
                    Logger.info("HealthKit update received for \(type.identifier) at \(Date())")
                    completion()
                }
            }
            healthStore.execute(observerQuery)
            Task {
                await queryManager.addQuery(observerQuery)
            }
            Logger.info("Observer query started for: \(type.identifier)")
        }
    }

    func stopObserverQueries() async {
        await queryManager.stopAllQueries(healthStore)
    }

    func disableBackgroundDelivery() {
        let types: [HKQuantityType] = [stepCountType, activeEnergyType, bodyMassType]
        for type in types {
            healthStore.disableBackgroundDelivery(for: type) { success, error in
                if let error = error {
                    Logger.error("Error disabling background delivery for \(type.identifier): \(error)")
                } else {
                    Logger.info("Background delivery disabled for \(type.identifier)")
                }
            }
        }
    }

    // MARK: - Activity Type Mapping Utilities

    func mapCardioActivityToHKType(_ activityType: String) -> HKWorkoutActivityType {
        switch activityType.lowercased() {
        case "running", TrainingKeys.ActivityTypes.running.localized:
            return .running
        case "cycling", TrainingKeys.ActivityTypes.cycling.localized:
            return .cycling
        case "swimming", TrainingKeys.ActivityTypes.swimming.localized:
            return .swimming
        case "walking", TrainingKeys.ActivityTypes.walking.localized:
            return .walking
        case "rowing", TrainingKeys.ActivityTypes.rowing.localized:
            return .rowing
        case "elliptical":
            return .elliptical
        case "stairClimbing":
            return .stairClimbing
        default:
            return .other
        }
    }

    // MARK: - Cleanup
    deinit {
        // Actor-safe cleanup of observer queries
        let queryManager = self.queryManager
        let healthStore = self.healthStore
        Task {
            await queryManager.stopAllQueries(healthStore)
        }
        Logger.info("HealthKitCore deinitialized")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let healthKitDataUpdated = Notification.Name("healthKitDataUpdated")
}

// MARK: - Thread-Safe Query Management Actor
/**
 * Actor responsible for managing HKObserverQuery lifecycle in a thread-safe manner.
 *
 * This actor ensures that HealthKit observer queries are properly managed without
 * concurrency issues, especially during cleanup operations in deinit.
 */
actor HealthQueryManager {
    private var queries: [HKObserverQuery] = []

    /// Add an observer query to be managed
    func addQuery(_ query: HKObserverQuery) {
        queries.append(query)
        Logger.info("Added HealthKit observer query. Total: \(queries.count)")
    }

    /// Stop all managed queries and clear the collection
    func stopAllQueries(_ healthStore: HKHealthStore) {
        guard !queries.isEmpty else {
            Logger.info("No HealthKit observer queries to stop")
            return
        }

        let queryCount = queries.count
        Logger.info("Stopping \(queryCount) HealthKit observer queries...")

        for query in queries {
            healthStore.stop(query)
        }

        queries.removeAll()
        Logger.success("All HealthKit observer queries stopped and cleared")
    }

    /// Get current number of managed queries
    func getQueryCount() -> Int {
        return queries.count
    }
}