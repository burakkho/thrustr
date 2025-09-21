import Foundation
import HealthKit

/**
 * HealthKit service specialized for Training feature requirements.
 *
 * Manages workout-related HealthKit operations including workout recording,
 * heart rate monitoring, training performance metrics, and workout history.
 * Supports all training types: cardio, strength training, and WOD workouts.
 *
 * Features:
 * - Workout recording (cardio, lift, WOD)
 * - Heart rate monitoring during workouts
 * - Training performance metrics
 * - Workout history and trends
 * - Training-specific health data
 */
final class HealthKitTrainingService {
    static let shared = HealthKitTrainingService()

    // MARK: - Dependencies
    private let core = HealthKitCore.shared

    // MARK: - Training Health Data
    var currentHeartRate: Double? = nil
    var restingHeartRate: Double? = nil
    var heartRateVariability: Double? = nil
    var vo2Max: Double? = nil

    // MARK: - Workout Data
    var recentWorkouts: [HKWorkout] = []
    var workoutHistory: [WorkoutHistoryItem] = []

    // MARK: - State Management
    var isLoading = false
    var error: Error?
    var lastTrainingSync: Date = Date.distantPast

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /**
     * Loads training-specific health data.
     *
     * Fetches heart rate data, VO2 max, and other cardiovascular metrics
     * relevant for training performance monitoring.
     */
    func loadTrainingHealthData() async {
        isLoading = true
        defer { isLoading = false }

        let startTime = Date()

        do {
            // Fetch all training metrics concurrently
            let results = try await AsyncTimeout.execute(timeout: AsyncTimeout.Duration.medium) {
                async let heartRate = self.readCurrentHeartRateData()
                async let restingHR = self.readRestingHeartRateData()
                async let hrv = self.readHRVData()
                async let vo2Max = self.readVO2MaxData()

                return await (heartRate, restingHR, hrv, vo2Max)
            }

            await updateTrainingData(with: results, startTime: startTime)

        } catch {
            self.error = error
            let context = ErrorService.shared.processError(
                error,
                severity: .medium,
                source: "HealthKitTrainingService.loadTrainingHealthData",
                userAction: "Loading training health data"
            )
            await ErrorUIService.shared.handleUIDisplay(for: context)
        }
    }

    // MARK: - Workout Recording

    /**
     * Save cardio workout to HealthKit.
     *
     * Records a cardio workout session with comprehensive metrics including
     * duration, distance, calories, and heart rate data.
     */
    func saveCardioWorkout(
        activityType: String,
        duration: TimeInterval,
        distance: Double? = nil,
        caloriesBurned: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        startDate: Date,
        endDate: Date
    ) async -> Bool {
        guard core.isAuthorized else {
            Logger.warning("HealthKit not authorized for workout saving")
            return false
        }

        // Map cardio activity to HKWorkoutActivityType
        let hkActivityType = core.mapCardioActivityToHKType(activityType)

        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkActivityType

        // Create workout builder
        let builder = HKWorkoutBuilder(healthStore: core.healthStore, configuration: configuration, device: .local())

        do {
            // Start workout session
            try await builder.beginCollection(at: startDate)

            // Add energy and distance if available
            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: core.activeEnergyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await addSampleToBuilder(builder, sample: energySample)
            }

            if let dist = distance {
                let distanceSample = HKQuantitySample(
                    type: core.distanceWalkingRunningType,
                    quantity: HKQuantity(unit: .meter(), doubleValue: dist),
                    start: startDate,
                    end: endDate
                )
                try await addSampleToBuilder(builder, sample: distanceSample)
            }

            // Add heart rate if available
            if let avgHR = averageHeartRate, avgHR > 0 {
                let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: avgHR)
                let heartRateSample = HKQuantitySample(
                    type: core.heartRateType,
                    quantity: heartRateQuantity,
                    start: startDate,
                    end: endDate
                )
                try await addSampleToBuilder(builder, sample: heartRateSample)
            }

            // Finish workout
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()

            Logger.success("Cardio workout saved to HealthKit: \(activityType), duration: \(duration)s")
            return true
        } catch {
            Logger.error("Failed to save cardio workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }

    /**
     * Save strength training workout to HealthKit.
     *
     * Records a strength training session with duration, calories burned,
     * and total volume if available.
     */
    func saveLiftWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        totalVolume: Double? = nil
    ) async -> Bool {
        guard core.isAuthorized else { return false }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: core.healthStore, configuration: configuration, device: .local())

        do {
            try await builder.beginCollection(at: startDate)

            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: core.activeEnergyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await addSampleToBuilder(builder, sample: energySample)
            }

            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()

            Logger.success("Lift workout saved to HealthKit: duration: \(duration)s")
            return true
        } catch {
            Logger.error("Failed to save lift workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }

    /**
     * Save WOD workout to HealthKit.
     *
     * Records a CrossFit-style workout (WOD) with duration, calories,
     * and workout type information.
     */
    func saveWODWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        wodType: String? = nil
    ) async -> Bool {
        guard core.isAuthorized else { return false }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .crossTraining

        let builder = HKWorkoutBuilder(healthStore: core.healthStore, configuration: configuration, device: .local())

        do {
            try await builder.beginCollection(at: startDate)

            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: core.activeEnergyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await addSampleToBuilder(builder, sample: energySample)
            }

            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()

            Logger.success("WOD workout saved to HealthKit: duration: \(duration)s, type: \(wodType ?? "Unknown")")
            return true
        } catch {
            Logger.error("Failed to save WOD workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }

    // MARK: - Workout History

    /**
     * Read workout history from HealthKit.
     *
     * Retrieves recent workout data for training analytics and progress tracking.
     */
    func readWorkoutHistory(limit: Int = 50, daysBack: Int = 30) async -> [WorkoutHistoryItem] {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading workout history: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    Logger.warning("No workout data found")
                    continuation.resume(returning: [])
                    return
                }

                let workoutItems = workouts.map { WorkoutHistoryItem(from: $0) }
                Logger.success("Retrieved \(workoutItems.count) workouts from HealthKit")
                continuation.resume(returning: workoutItems)
            }

            core.healthStore.execute(query)
        }
    }

    /**
     * Get workouts by specific activity type.
     */
    func getWorkoutsByType(activityType: HKWorkoutActivityType, daysBack: Int = 30) async -> [WorkoutHistoryItem] {
        let allWorkouts = await readWorkoutHistory(limit: 100, daysBack: daysBack)
        return allWorkouts.filter { $0.activityType == activityType }
    }

    /**
     * Get total workout statistics.
     */
    func getTotalWorkoutStats(daysBack: Int = 30) async -> WorkoutStats {
        let workouts = await readWorkoutHistory(limit: 1000, daysBack: daysBack)

        let totalWorkouts = workouts.count
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let totalCalories = workouts.compactMap { $0.totalEnergyBurned }.reduce(0, +)
        let totalDistance = workouts.compactMap { $0.totalDistance }.reduce(0, +)

        let uniqueActivityTypes = Set(workouts.map { $0.activityType }).count
        let averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0

        return WorkoutStats(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            totalDistance: totalDistance,
            uniqueActivityTypes: uniqueActivityTypes,
            averageDuration: averageDuration,
            daysTracked: daysBack
        )
    }

    /**
     * Load recent workouts for training dashboard.
     */
    func loadRecentWorkouts(limit: Int = 10) async {
        let workouts = await readWorkoutHistory(limit: limit, daysBack: 7)

        workoutHistory = workouts
        // Note: recentWorkouts would need HKWorkout objects, which requires different handling
        Logger.info("Loaded \(workouts.count) recent workouts")
    }

    // MARK: - Heart Rate Data Reading

    private func readCurrentHeartRateData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now) ?? now

            let predicate = HKQuery.predicateForSamples(
                withStart: oneHourAgo,
                end: now,
                options: .strictEndDate
            )

            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading current heart rate for training: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let hrSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let heartRate = hrSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }

            core.healthStore.execute(query)
        }
    }

    private func readRestingHeartRateData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.restingHeartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading resting heart rate for training: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let rhrSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let restingHR = rhrSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: restingHR)
            }

            core.healthStore.execute(query)
        }
    }

    private func readHRVData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.heartRateVariabilityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading HRV for training: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let hrvSample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrv = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }

            core.healthStore.execute(query)
        }
    }

    private func readVO2MaxData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: core.vo2MaxType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading VO2 Max for training: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let vo2Sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let vo2Max = vo2Sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())))
                continuation.resume(returning: vo2Max)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Helper Methods

    private func addSampleToBuilder(_ builder: HKWorkoutBuilder, sample: HKQuantitySample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.add([sample]) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func updateTrainingData(
        with results: (Double?, Double?, Double?, Double?),
        startTime: Date
    ) async {
        // Update published properties
        currentHeartRate = results.0
        restingHeartRate = results.1
        heartRateVariability = results.2
        vo2Max = results.3

        lastTrainingSync = Date()

        // Performance logging
        let duration = Date().timeIntervalSince(startTime)
        Logger.success("Training HealthKit data fetch completed in \(String(format: "%.2f", duration))s")

        // Log sync summary
        let syncedMetrics = [
            results.0 != nil ? "Heart Rate" : nil,
            results.1 != nil ? "Resting HR" : nil,
            results.2 != nil ? "HRV" : nil,
            results.3 != nil ? "VO2 Max" : nil
        ].compactMap { $0 }

        if !syncedMetrics.isEmpty {
            Logger.success("Training synced: \(syncedMetrics.joined(separator: ", "))")
        }
    }

    // MARK: - Training Specific Utilities

    /**
     * Get training health summary for display.
     */
    func getTrainingHealthSummary() -> TrainingHealthSummary {
        return TrainingHealthSummary(
            currentHeartRate: currentHeartRate,
            restingHeartRate: restingHeartRate,
            heartRateVariability: heartRateVariability,
            vo2Max: vo2Max,
            lastSynced: lastTrainingSync
        )
    }

    /**
     * Calculate heart rate zones based on resting and max heart rate.
     */
    func calculateHeartRateZones(age: Int) -> HeartRateZones? {
        guard let restingHR = restingHeartRate else { return nil }

        let maxHR = Double(220 - age) // Age-predicted max heart rate
        let hrReserve = maxHR - restingHR

        return HeartRateZones(
            zone1: (restingHR + hrReserve * 0.5, restingHR + hrReserve * 0.6), // 50-60%
            zone2: (restingHR + hrReserve * 0.6, restingHR + hrReserve * 0.7), // 60-70%
            zone3: (restingHR + hrReserve * 0.7, restingHR + hrReserve * 0.8), // 70-80%
            zone4: (restingHR + hrReserve * 0.8, restingHR + hrReserve * 0.9), // 80-90%
            zone5: (restingHR + hrReserve * 0.9, maxHR) // 90-100%
        )
    }

    // MARK: - Cleanup
    deinit {
        Logger.info("HealthKitTrainingService deinitialized")
    }
}

// MARK: - Supporting Types

struct TrainingHealthSummary {
    let currentHeartRate: Double?
    let restingHeartRate: Double?
    let heartRateVariability: Double?
    let vo2Max: Double?
    let lastSynced: Date
}

struct HeartRateZones {
    let zone1: (min: Double, max: Double) // Recovery
    let zone2: (min: Double, max: Double) // Aerobic Base
    let zone3: (min: Double, max: Double) // Aerobic
    let zone4: (min: Double, max: Double) // Threshold
    let zone5: (min: Double, max: Double) // Neuromuscular Power
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:
            return TrainingKeys.ActivityTypes.running.localized
        case .cycling:
            return TrainingKeys.ActivityTypes.cycling.localized
        case .swimming:
            return TrainingKeys.ActivityTypes.swimming.localized
        case .walking:
            return TrainingKeys.ActivityTypes.walking.localized
        case .traditionalStrengthTraining:
            return TrainingKeys.ActivityTypes.strengthTraining.localized
        case .crossTraining:
            return TrainingKeys.ActivityTypes.hiit.localized
        case .rowing:
            return TrainingKeys.ActivityTypes.rowing.localized
        default:
            return TrainingKeys.ActivityTypes.other.localized
        }
    }
}

