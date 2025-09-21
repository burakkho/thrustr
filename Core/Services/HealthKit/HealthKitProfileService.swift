import Foundation
import HealthKit
import SwiftUI

/**
 * HealthKit service specialized for Profile feature requirements.
 *
 * Manages body measurements, health profile data, and user-specific health
 * metrics for the Profile feature. Handles reading and writing of body
 * composition data, weight tracking, and profile health integration.
 *
 * Features:
 * - Body measurements (weight, height, BMI, body fat)
 * - Weight tracking and history
 * - Body composition analysis
 * - Profile health data synchronization
 * - Health profile integration with User model
 */
final class HealthKitProfileService {
    static let shared = HealthKitProfileService()

    // MARK: - Dependencies
    private let core = HealthKitCore.shared

    // MARK: - Profile Health Data
    var currentWeight: Double? = nil
    var currentHeight: Double? = nil
    var bodyMassIndex: Double? = nil
    var bodyFatPercentage: Double? = nil
    var leanBodyMass: Double? = nil

    // MARK: - State Management
    var isLoading = false
    var error: Error?
    var lastSyncTime: Date = Date.distantPast

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /**
     * Loads all profile health data from HealthKit.
     *
     * Fetches comprehensive body measurement data including weight, height,
     * BMI, body fat percentage, and lean body mass for profile display.
     */
    func loadProfileHealthData() async {
        isLoading = true
        defer { isLoading = false }

        let startTime = Date()

        do {
            // Fetch all profile metrics concurrently
            let results = try await AsyncTimeout.execute(timeout: AsyncTimeout.Duration.medium) {
                async let weight = self.readWeightData()
                async let height = self.readHeightData()
                async let bmi = self.readBMIData()
                async let bodyFat = self.readBodyFatData()
                async let leanMass = self.readLeanBodyMassData()

                return await (weight, height, bmi, bodyFat, leanMass)
            }

            await updateProfileData(with: results, startTime: startTime)

        } catch {
            self.error = error
            let context = ErrorService.shared.processError(
                error,
                severity: .medium,
                source: "HealthKitProfileService.loadProfileHealthData",
                userAction: "Loading profile health data"
            )
            await ErrorUIService.shared.handleUIDisplay(for: context)
        }
    }

    /**
     * Syncs profile data with User model.
     *
     * Updates the User model with latest HealthKit data for profile display
     * and ensures consistency between HealthKit and app data.
     */
    func syncWithUserProfile(user: User) async {
        await loadProfileHealthData()

        // Update user with HealthKit data if available
        if let weight = currentWeight {
            user.currentWeight = weight
        }

        if let height = currentHeight {
            user.height = height * 100 // Convert from meters to cm
        }

        user.lastActiveDate = Date()
        lastSyncTime = Date()

        Logger.info("Profile data synced with User model")
    }

    // MARK: - Weight Management

    /**
     * Save weight measurement to HealthKit.
     *
     * Records a new weight measurement in HealthKit and updates local cache.
     * Supports both manual entry and automatic sync scenarios.
     */
    func saveWeight(_ weight: Double, date: Date = Date()) async -> Bool {
        guard core.isAuthorized else {
            Logger.warning("HealthKit not authorized for weight saving")
            return false
        }

        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: core.bodyMassType,
            quantity: weightQuantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await core.healthStore.save(weightSample)
            currentWeight = weight
            Logger.success("Weight saved to HealthKit: \(weight) kg")
            return true
        } catch {
            self.error = error
            Logger.error("Error saving weight to HealthKit: \(error)")
            return false
        }
    }

    /**
     * Get weight history for profile trends.
     *
     * Retrieves historical weight data for profile analytics and trends display.
     */
    func getWeightHistory(daysBack: Int = 90) async -> [HealthDataPoint] {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            let query = HKSampleQuery(
                sampleType: core.bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading weight history: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                guard let weightSamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let dataPoints = weightSamples.map { sample in
                    let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                    return HealthDataPoint(date: sample.startDate, value: weight, unit: "kg")
                }

                Logger.success("Retrieved \(dataPoints.count) weight history points")
                continuation.resume(returning: dataPoints)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Body Measurements

    /**
     * Save body fat percentage to HealthKit.
     */
    func saveBodyFat(_ bodyFat: Double, date: Date = Date()) async -> Bool {
        guard core.isAuthorized else { return false }

        let bodyFatQuantity = HKQuantity(unit: HKUnit.percent(), doubleValue: bodyFat)
        let bodyFatSample = HKQuantitySample(
            type: core.bodyFatPercentageType,
            quantity: bodyFatQuantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await core.healthStore.save(bodyFatSample)
            bodyFatPercentage = bodyFat
            Logger.success("Body fat saved to HealthKit: \(bodyFat)%")
            return true
        } catch {
            Logger.error("Error saving body fat to HealthKit: \(error)")
            return false
        }
    }

    /**
     * Save height measurement to HealthKit.
     */
    func saveHeight(_ height: Double, date: Date = Date()) async -> Bool {
        guard core.isAuthorized else { return false }

        // Height should be in meters for HealthKit
        let heightInMeters = height / 100 // Convert cm to meters
        let heightQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: heightInMeters)
        let heightSample = HKQuantitySample(
            type: core.heightType,
            quantity: heightQuantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await core.healthStore.save(heightSample)
            currentHeight = heightInMeters
            Logger.success("Height saved to HealthKit: \(height) cm")
            return true
        } catch {
            Logger.error("Error saving height to HealthKit: \(error)")
            return false
        }
    }

    // MARK: - Data Reading Methods

    private func readWeightData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading weight for profile: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let weightSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weight = weightSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }

            core.healthStore.execute(query)
        }
    }

    private func readHeightData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading height for profile: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let heightSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let height = heightSample.quantity.doubleValue(for: HKUnit.meter())
                continuation.resume(returning: height)
            }

            core.healthStore.execute(query)
        }
    }

    private func readBMIData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.bodyMassIndexType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading BMI for profile: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let bmiSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let bmi = bmiSample.quantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: bmi)
            }

            core.healthStore.execute(query)
        }
    }

    private func readBodyFatData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.bodyFatPercentageType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading body fat for profile: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let bodyFatSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let bodyFat = bodyFatSample.quantity.doubleValue(for: HKUnit.percent())
                continuation.resume(returning: bodyFat)
            }

            core.healthStore.execute(query)
        }
    }

    private func readLeanBodyMassData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.leanBodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading lean body mass for profile: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let leanMassSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let leanMass = leanMassSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: leanMass)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Cache Update

    private func updateProfileData(
        with results: (Double?, Double?, Double?, Double?, Double?),
        startTime: Date
    ) async {
        // Update published properties
        currentWeight = results.0
        currentHeight = results.1
        bodyMassIndex = results.2
        bodyFatPercentage = results.3
        leanBodyMass = results.4

        lastSyncTime = Date()

        // Performance logging
        let duration = Date().timeIntervalSince(startTime)
        Logger.success("Profile HealthKit data fetch completed in \(String(format: "%.2f", duration))s")

        // Log sync summary
        let syncedMetrics = [
            results.0 != nil ? "Weight" : nil,
            results.1 != nil ? "Height" : nil,
            results.2 != nil ? "BMI" : nil,
            results.3 != nil ? "Body Fat" : nil,
            results.4 != nil ? "Lean Mass" : nil
        ].compactMap { $0 }

        if !syncedMetrics.isEmpty {
            Logger.success("Profile synced: \(syncedMetrics.joined(separator: ", "))")
        }
    }

    // MARK: - Profile Specific Utilities

    /**
     * Calculate BMI if weight and height are available.
     */
    func calculateBMI() -> Double? {
        guard let weight = currentWeight,
              let height = currentHeight,
              height > 0 else { return nil }

        return weight / (height * height)
    }

    /**
     * Get profile health summary for display.
     */
    func getProfileHealthSummary() -> ProfileHealthSummary {
        return ProfileHealthSummary(
            weight: currentWeight,
            height: currentHeight,
            bmi: bodyMassIndex ?? calculateBMI(),
            bodyFat: bodyFatPercentage,
            leanMass: leanBodyMass,
            lastSynced: lastSyncTime
        )
    }

    /**
     * Check if profile has sufficient health data.
     */
    func hasCompleteProfileData() -> Bool {
        return currentWeight != nil && currentHeight != nil
    }

    // MARK: - Cleanup
    deinit {
        Logger.info("HealthKitProfileService deinitialized")
    }
}

// MARK: - Supporting Types

struct ProfileHealthSummary {
    let weight: Double? // kg
    let height: Double? // meters
    let bmi: Double?
    let bodyFat: Double? // percentage
    let leanMass: Double? // kg
    let lastSynced: Date
}

