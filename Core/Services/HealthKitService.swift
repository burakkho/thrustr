import Foundation
import HealthKit
import UserNotifications

/**
 * HealthKit integration service for seamless health data synchronization.
 * 
 * This service manages Apple HealthKit permissions, data fetching, and background sync
 * for health metrics including steps, calories, and weight. Implements caching for
 * performance optimization and observer queries for real-time updates.
 * 
 * Features:
 * - Authorization management for HealthKit permissions
 * - Background delivery and observer queries for real-time sync
 * - Cached data with configurable validity duration (5 minutes)
 * - Automatic data refresh when app becomes active
 * - Thread-safe operations with @MainActor
 * 
 * Supported data types:
 * - Steps (HKQuantityTypeIdentifier.stepCount)
 * - Active Energy Burned (HKQuantityTypeIdentifier.activeEnergyBurned)
 * - Body Weight (HKQuantityTypeIdentifier.bodyMass) - read/write
 */
@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    
    // OPTIMIZED: Add caching for better performance
    private var cachedSteps: Double = 0
    private var cachedCalories: Double = 0
    private var cachedWeight: Double? = nil
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 900 // 15 minutes - performance optimization
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var todaySteps: Double = 0
    @Published var todayCalories: Double = 0
    @Published var currentWeight: Double? = nil
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Health Data Types
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    
    // OPTIMIZED: Add performance monitoring
    private var queryPerformanceMetrics: [String: TimeInterval] = [:]
    
    // MARK: - Permission Requests
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return false
        }
        
        // Request both HealthKit and Notification permissions together
        async let healthKitResult = requestHealthKitPermissions()
        async let notificationResult = requestNotificationPermissions()
        
        let (healthAuthorized, notificationRequested) = await (healthKitResult, notificationResult)
        
        if healthAuthorized {
            await readTodaysData()
            enableBackgroundDelivery()
            startObserverQueries()
        }
        
        print("✅ Permissions requested - HealthKit: \(healthAuthorized), Notifications: \(notificationRequested)")
        return healthAuthorized
    }
    
    private func requestHealthKitPermissions() async -> Bool {
        let readTypes: Set<HKObjectType> = [
            stepCountType,
            activeEnergyType,
            bodyMassType
        ]
        
        let shareTypes: Set<HKSampleType> = [
            bodyMassType,
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            
            let stepStatus = healthStore.authorizationStatus(for: stepCountType)
            let calorieStatus = healthStore.authorizationStatus(for: activeEnergyType)
            let weightStatus = healthStore.authorizationStatus(for: bodyMassType)
            
            isAuthorized = (stepStatus == .sharingAuthorized) ||
                           (calorieStatus == .sharingAuthorized) ||
                           (weightStatus == .sharingAuthorized)
            
            return isAuthorized
        } catch {
            print("HealthKit authorization error: \(error)")
            self.error = error
            return false
        }
    }
    
    private func requestNotificationPermissions() async -> Bool {
        do {
            try await NotificationManager.shared.requestAuthorization()
            return true
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    // OPTIMIZED: Add caching logic with timeout
    func readTodaysData() async {
        // Check if cache is still valid
        if Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration {
            todaySteps = cachedSteps
            todayCalories = cachedCalories
            currentWeight = cachedWeight
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let startTime = Date()
        
        do {
            // Use timeout for concurrent HealthKit operations
            let results = try await AsyncTimeout.execute(timeout: AsyncTimeout.Duration.medium) {
                async let steps = self.readStepsData()
                async let calories = self.readCaloriesData()
                async let weight = self.readWeightData()
                
                return await (steps, calories, weight)
            }
            
            await updateCacheAndUI(with: results, startTime: startTime)
            
            // Log HealthKit sync activity if data was successfully fetched
            if results.0 != nil || results.1 != nil || results.2 != nil {
                let syncedTypes = [
                    results.0 != nil ? "Adımlar" : nil,
                    results.1 != nil ? "Kalori" : nil, 
                    results.2 != nil ? "Kilo" : nil
                ].compactMap { $0 }
                
                if !syncedTypes.isEmpty {
                    // Note: ActivityLoggerService integration would need user and modelContext
                    // For now, just log the sync attempt
                    print("HealthKit synced: \(syncedTypes.joined(separator: ", "))")
                }
            }
        } catch let caughtError {
            Task { @MainActor in
                ErrorHandlingService.shared.handle(
                    caughtError,
                    severity: .medium,
                    source: "HealthKitService.readTodaysData",
                    userAction: "Reading health data"
                )
            }
        }
    }
    
    private func updateCacheAndUI(with results: (Double?, Double?, Double?), startTime: Date) async {
        
        // Update cache
        cachedSteps = results.0 ?? 0
        cachedCalories = results.1 ?? 0
        cachedWeight = results.2
        lastCacheUpdate = Date()
        
        // Update published properties
        todaySteps = cachedSteps
        todayCalories = cachedCalories
        currentWeight = cachedWeight
        
        // Record performance metrics
        let duration = Date().timeIntervalSince(startTime)
        queryPerformanceMetrics["readTodaysData"] = duration
        print("HealthKit data fetch completed in \(String(format: "%.2f", duration))s")
    }
    
    func readStepsData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: now,
                options: .strictStartDate
            )
            
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    print("Error reading steps: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readCaloriesData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: now,
                options: .strictStartDate
            )
            
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    print("Error reading calories: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readWeightData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    print("Error reading weight: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Data Writing
    func saveWeight(_ weight: Double) async -> Bool {
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: bodyMassType,
            quantity: weightQuantity,
            start: Date(),
            end: Date()
        )
        
        do {
            try await healthStore.save(weightSample)
            currentWeight = weight
            return true
        } catch {
            print("Error saving weight: \(error)")
            self.error = error
            return false
        }
    }
    
    // MARK: - Workout Writing
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
        guard isAuthorized else { return false }
        
        // Map cardio activity to HKWorkoutActivityType
        let hkActivityType = mapCardioActivityToHKType(activityType)
        
        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkActivityType
        
        // Create workout builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            // Start workout session
            try await builder.beginCollection(at: startDate)
            
            // Add energy and distance if available
            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.add([energySample]) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            if let dist = distance {
                let distanceSample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                    quantity: HKQuantity(unit: .meter(), doubleValue: dist),
                    start: startDate,
                    end: endDate
                )
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.add([distanceSample]) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            // Add heart rate if available
            if let avgHR = averageHeartRate, avgHR > 0 {
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: avgHR)
                let heartRateSample = HKQuantitySample(
                    type: heartRateType,
                    quantity: heartRateQuantity,
                    start: startDate,
                    end: endDate
                )
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.add([heartRateSample]) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            // Finish workout
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
            
            Logger.info("Cardio workout saved to HealthKit successfully")
            return true
        } catch {
            Logger.error("Failed to save cardio workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }
    
    func saveLiftWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        totalVolume: Double? = nil
    ) async -> Bool {
        guard isAuthorized else { return false }
        
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            try await builder.beginCollection(at: startDate)
            
            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.add([energySample]) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
            
            Logger.info("Lift workout saved to HealthKit successfully")
            return true
        } catch {
            Logger.error("Failed to save lift workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }
    
    func saveWODWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        wodType: String? = nil
    ) async -> Bool {
        guard isAuthorized else { return false }
        
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .crossTraining
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            try await builder.beginCollection(at: startDate)
            
            if let calories = caloriesBurned {
                let energySample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: startDate,
                    end: endDate
                )
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.add([energySample]) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
            
            Logger.info("WOD workout saved to HealthKit successfully")
            return true
        } catch {
            Logger.error("Failed to save WOD workout to HealthKit: \(error)")
            self.error = error
            return false
        }
    }
    
    private func mapCardioActivityToHKType(_ activityType: String) -> HKWorkoutActivityType {
        switch activityType.lowercased() {
        case "running", "koşu":
            return .running
        case "cycling", "bisiklet":
            return .cycling
        case "swimming", "yüzme":
            return .swimming
        case "walking", "yürüyüş":
            return .walking
        case "rowing", "kürek":
            return .rowing
        case "elliptical":
            return .elliptical
        case "stairClimbing":
            return .stairClimbing
        default:
            return .other
        }
    }
    
    // MARK: - Nutrition Writing
    func saveNutritionData(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date()
    ) async -> Bool {
        guard isAuthorized else { return false }
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
        let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
        
        let calorieSample = HKQuantitySample(
            type: calorieType,
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        let proteinSample = HKQuantitySample(
            type: proteinType,
            quantity: HKQuantity(unit: .gram(), doubleValue: protein),
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        let carbsSample = HKQuantitySample(
            type: carbsType,
            quantity: HKQuantity(unit: .gram(), doubleValue: carbs),
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        let fatSample = HKQuantitySample(
            type: fatType,
            quantity: HKQuantity(unit: .gram(), doubleValue: fat),
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        let samples = [calorieSample, proteinSample, carbsSample, fatSample]
        
        do {
            try await healthStore.save(samples)
            Logger.info("Nutrition data saved to HealthKit successfully")
            return true
        } catch {
            Logger.error("Failed to save nutrition data to HealthKit: \(error)")
            self.error = error
            return false
        }
    }
    
    // MARK: - Background Updates
    func enableBackgroundDelivery() {
        let types: [HKQuantityType] = [stepCountType, activeEnergyType, bodyMassType]
        
        for type in types {
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("Error enabling background delivery for \(type): \(error)")
                } else if success {
                    print("Background delivery enabled for \(type)")
                }
            }
        }
    }
    
    /// Start HealthKit observer queries to receive live updates for steps, calories and weight.
    /// When an update is received, we refresh today's data and log for verification.
    func startObserverQueries() {
        let types: [HKQuantityType] = [stepCountType, activeEnergyType, bodyMassType]
        
        // Cancel previously running queries to avoid duplicates
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
        
        for type in types {
            let observerQuery = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                if let error = error {
                    print("❌ HealthKit observer error for \(type.identifier): \(error)")
                    completionHandler()
                    return
                }
                
                Task { [weak self] in
                    guard let self else { completionHandler(); return }
                    await self.readTodaysData()
                    await MainActor.run {
                        let steps = Int(self.todaySteps)
                        let calories = Int(self.todayCalories)
                        let weightString = self.currentWeight.map { String(format: "%.1f", $0) } ?? "-"
                        print("✅ HealthKit update received for \(type.identifier) at \(Date()) | steps=\(steps) kcal=\(calories) weight=\(weightString)")
                    }
                    completionHandler()
                }
            }
            healthStore.execute(observerQuery)
            observerQueries.append(observerQuery)
            print("Observer query started for: \(type.identifier)")
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Stop observer queries synchronously
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
        print("🧹 HealthKitService deinitialized")
    }
    
    @MainActor
    func stopObserverQueries() {
        guard !observerQueries.isEmpty else { 
            print("🔍 No HealthKit observer queries to stop")
            return 
        }
        
        let queryCount = observerQueries.count
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
        print("🛑 Stopped \(queryCount) HealthKit observer queries (\(Date()))")
    }
    
    func disableBackgroundDelivery() {
        let types: [HKQuantityType] = [stepCountType, activeEnergyType, bodyMassType]
        for type in types {
            healthStore.disableBackgroundDelivery(for: type) { success, error in
                if let error = error {
                    print("❌ Error disabling background delivery for \(type.identifier): \(error)")
                } else {
                    print("✅ Background delivery disabled for \(type.identifier)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func getAuthorizationStatus() -> (steps: HKAuthorizationStatus, calories: HKAuthorizationStatus, weight: HKAuthorizationStatus) {
        return (
            steps: healthStore.authorizationStatus(for: stepCountType),
            calories: healthStore.authorizationStatus(for: activeEnergyType),
            weight: healthStore.authorizationStatus(for: bodyMassType)
        )
    }
}
