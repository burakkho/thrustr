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
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    
    // OPTIMIZED: Add comprehensive caching for better performance
    private var cachedHealthData: [String: Any] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 900 // 15 minutes - performance optimization
    
    // Legacy cache properties for backward compatibility
    private var cachedSteps: Double = 0
    private var cachedCalories: Double = 0
    private var cachedWeight: Double? = nil
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: Activity & Fitness Data
    @Published var todaySteps: Double = 0
    @Published var todayActiveCalories: Double = 0
    @Published var todayBasalCalories: Double = 0
    @Published var todayDistance: Double = 0
    
    var todayCalories: Double {
        return todayActiveCalories + todayBasalCalories
    }
    @Published var todayFlightsClimbed: Double = 0
    @Published var todayExerciseMinutes: Double = 0
    @Published var todayStandHours: Double = 0
    
    // MARK: Heart & Cardiovascular Data
    @Published var currentHeartRate: Double? = nil
    @Published var restingHeartRate: Double? = nil
    @Published var heartRateVariability: Double? = nil
    @Published var vo2Max: Double? = nil
    
    // MARK: Body Measurements Data
    @Published var currentWeight: Double? = nil
    @Published var bodyMassIndex: Double? = nil
    @Published var bodyFatPercentage: Double? = nil
    @Published var leanBodyMass: Double? = nil
    @Published var currentHeight: Double? = nil
    
    // MARK: Sleep & Recovery Data
    @Published var lastNightSleep: Double = 0 // hours
    @Published var sleepEfficiency: Double = 0 // percentage
    
    // MARK: Workout Data
    @Published var recentWorkouts: [HKWorkout] = []
    @Published var workoutHistory: [WorkoutHistoryItem] = []
    
    // MARK: Historical Trends Data
    @Published var stepsHistory: [HealthDataPoint] = []
    @Published var weightHistory: [HealthDataPoint] = []
    @Published var heartRateHistory: [HealthDataPoint] = []
    @Published var workoutTrends: WorkoutTrends = WorkoutTrends.empty
    
    // MARK: Health Intelligence Data
    @Published var currentRecoveryScore: RecoveryScore?
    @Published var healthInsights: [HealthInsight] = []
    @Published var fitnessAssessment: FitnessLevelAssessment?
    
    // MARK: Authorization Status Tracking
    @Published var authorizationStatuses: [String: HKAuthorizationStatus] = [:]
    
    // MARK: - Health Data Types
    
    // MARK: Activity & Fitness
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
    private let distanceWalkingRunningType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private let distanceCyclingType = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
    private let flightsClimbedType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
    private let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    private let standTimeType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
    
    // MARK: Heart & Cardiovascular
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    private let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
    
    // MARK: Body Measurements
    private let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    private let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
    private let bodyFatPercentageType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
    private let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
    private let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
    
    // MARK: Sleep & Recovery
    private let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    
    // MARK: Workouts & Training
    private let workoutType = HKWorkoutType.workoutType()
    
    // MARK: Nutrition (already declared but grouping for clarity)
    private let dietaryEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
    private let dietaryProteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
    private let dietaryCarbohydratesType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
    private let dietaryFatTotalType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
    
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
            
            // MARK: Comprehensive Authorization Status Tracking
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
            self.error = error
            return false
        }
    }
    
    // MARK: - Authorization Status Management
    @MainActor
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
    
    func getAuthorizationStatusSummary() -> (authorized: Int, denied: Int, notDetermined: Int) {
        let authorized = authorizationStatuses.values.filter { $0 == .sharingAuthorized }.count
        let denied = authorizationStatuses.values.filter { $0 == .sharingDenied }.count
        let notDetermined = authorizationStatuses.values.filter { $0 == .notDetermined }.count
        
        return (authorized, denied, notDetermined)
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
    
    // OPTIMIZED: Comprehensive health data reading with caching
    func readTodaysData() async {
        // Check if cache is still valid
        if Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration {
            await loadFromCache()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let startTime = Date()
        
        do {
            // Use timeout for concurrent HealthKit operations - ALL health metrics
            let results = try await AsyncTimeout.execute(timeout: AsyncTimeout.Duration.medium) {
                async let steps = self.readStepsData()
                async let activeCalories = self.readActiveCaloriesData()
                async let basalCalories = self.readBasalCaloriesData()
                async let distance = self.readDistanceData()
                async let flightsClimbed = self.readFlightsClimbedData()
                async let exerciseMinutes = self.readExerciseTimeData()
                async let standHours = self.readStandTimeData()
                
                async let weight = self.readWeightData()
                async let height = self.readHeightData()
                async let bmi = self.readBMIData()
                async let bodyFat = self.readBodyFatData()
                
                async let heartRate = self.readCurrentHeartRateData()
                async let restingHR = self.readRestingHeartRateData()
                async let hrv = self.readHRVData()
                async let vo2Max = self.readVO2MaxData()
                
                async let sleepHours = self.readSleepData()
                
                return await (
                    // Activity
                    steps, activeCalories, basalCalories, distance, flightsClimbed, exerciseMinutes, standHours,
                    // Body
                    weight, height, bmi, bodyFat,
                    // Heart
                    heartRate, restingHR, hrv, vo2Max,
                    // Sleep
                    sleepHours
                )
            }
            
            await updateComprehensiveHealthCache(with: results, startTime: startTime)
            
        } catch let caughtError {
            Task { @MainActor in
                ErrorHandlingService.shared.handle(
                    caughtError,
                    severity: .medium,
                    source: "HealthKitService.readTodaysData",
                    userAction: "Reading comprehensive health data"
                )
            }
        }
    }
    
    // MARK: - Cache Management
    @MainActor
    private func loadFromCache() async {
        // Activity Data
        todaySteps = cachedHealthData["steps"] as? Double ?? cachedSteps
        todayActiveCalories = cachedHealthData["activeCalories"] as? Double ?? cachedCalories
        todayBasalCalories = cachedHealthData["basalCalories"] as? Double ?? 0
        todayDistance = cachedHealthData["distance"] as? Double ?? 0
        todayFlightsClimbed = cachedHealthData["flightsClimbed"] as? Double ?? 0
        todayExerciseMinutes = cachedHealthData["exerciseMinutes"] as? Double ?? 0
        todayStandHours = cachedHealthData["standHours"] as? Double ?? 0
        
        // Body Data
        currentWeight = cachedHealthData["weight"] as? Double ?? cachedWeight
        currentHeight = cachedHealthData["height"] as? Double
        bodyMassIndex = cachedHealthData["bmi"] as? Double
        bodyFatPercentage = cachedHealthData["bodyFat"] as? Double
        
        // Heart Data
        currentHeartRate = cachedHealthData["heartRate"] as? Double
        restingHeartRate = cachedHealthData["restingHR"] as? Double
        heartRateVariability = cachedHealthData["hrv"] as? Double
        vo2Max = cachedHealthData["vo2Max"] as? Double
        
        // Sleep Data
        lastNightSleep = cachedHealthData["sleepHours"] as? Double ?? 0
        
        Logger.info("Loaded comprehensive health data from cache")
    }
    
    private func updateComprehensiveHealthCache(with results: (Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?, Double?), startTime: Date) async {
        
        // Update comprehensive cache
        cachedHealthData = [
            "steps": results.0 ?? 0,
            "activeCalories": results.1 ?? 0,
            "basalCalories": results.2 ?? 0,
            "distance": results.3 ?? 0,
            "flightsClimbed": results.4 ?? 0,
            "exerciseMinutes": results.5 ?? 0,
            "standHours": results.6 ?? 0,
            "weight": results.7 as Any,
            "height": results.8 as Any,
            "bmi": results.9 as Any,
            "bodyFat": results.10 as Any,
            "heartRate": results.11 as Any,
            "restingHR": results.12 as Any,
            "hrv": results.13 as Any,
            "vo2Max": results.14 as Any,
            "sleepHours": results.15 ?? 0
        ]
        
        // Update legacy cache for backward compatibility
        cachedSteps = results.0 ?? 0
        cachedCalories = results.1 ?? 0
        cachedWeight = results.7
        lastCacheUpdate = Date()
        
        // Update published properties
        await MainActor.run {
            // Activity Data
            todaySteps = results.0 ?? 0
            todayActiveCalories = results.1 ?? 0
            todayBasalCalories = results.2 ?? 0
            todayDistance = results.3 ?? 0
            todayFlightsClimbed = results.4 ?? 0
            todayExerciseMinutes = results.5 ?? 0
            todayStandHours = results.6 ?? 0
            
            // Body Data
            currentWeight = results.7
            currentHeight = results.8
            bodyMassIndex = results.9
            bodyFatPercentage = results.10
            
            // Heart Data
            currentHeartRate = results.11
            restingHeartRate = results.12
            heartRateVariability = results.13
            vo2Max = results.14
            
            // Sleep Data
            lastNightSleep = results.15 ?? 0
        }
        
        // Record performance metrics
        let duration = Date().timeIntervalSince(startTime)
        queryPerformanceMetrics["readComprehensiveHealthData"] = duration
        Logger.success("Comprehensive HealthKit data fetch completed in \(String(format: "%.2f", duration))s")
        
        // Log sync summary
        let syncedMetrics = [
            results.0 != nil ? "Steps" : nil,
            results.1 != nil ? "Active Calories" : nil,
            results.2 != nil ? "Basal Calories" : nil,
            results.3 != nil ? "Distance" : nil,
            results.7 != nil ? "Weight" : nil,
            results.11 != nil ? "Heart Rate" : nil,
            results.15 != nil ? "Sleep" : nil
        ].compactMap { $0 }
        
        if !syncedMetrics.isEmpty {
            Logger.success("HealthKit synced: \(syncedMetrics.joined(separator: ", "))")
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
        todayActiveCalories = cachedCalories
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
    
    func readActiveCaloriesData() async -> Double? {
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
    
    // MARK: - New Comprehensive Health Data Readers
    
    func readBasalCaloriesData() async -> Double? {
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
                quantityType: basalEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    Logger.error("Error reading basal calories: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readDistanceData() async -> Double? {
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
                quantityType: distanceWalkingRunningType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    Logger.error("Error reading distance: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readFlightsClimbedData() async -> Double? {
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
                quantityType: flightsClimbedType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    Logger.error("Error reading flights climbed: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let flights = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: flights)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readExerciseTimeData() async -> Double? {
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
                quantityType: exerciseTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    Logger.error("Error reading exercise time: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readStandTimeData() async -> Double? {
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
                quantityType: standTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    Logger.error("Error reading stand time: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let hours = result?.sumQuantity()?.doubleValue(for: HKUnit.hour()) ?? 0
                continuation.resume(returning: hours)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readHeightData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading height: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readBMIData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: bodyMassIndexType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading BMI: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readBodyFatData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: bodyFatPercentageType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading body fat: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readCurrentHeartRateData() async -> Double? {
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
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading current heart rate: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readRestingHeartRateData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: restingHeartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading resting heart rate: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let rhrsample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let restingHR = rhrsample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: restingHR)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readHRVData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: heartRateVariabilityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading HRV: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readVO2MaxData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: vo2MaxType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading VO2 Max: \(error)")
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
            
            healthStore.execute(query)
        }
    }
    
    func readSleepData() async -> Double? {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            
            let predicate = HKQuery.predicateForSamples(
                withStart: yesterday,
                end: now,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading sleep data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var totalSleepHours: Double = 0
                
                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        let sleepDuration = sample.endDate.timeIntervalSince(sample.startDate)
                        totalSleepHours += sleepDuration / 3600 // Convert to hours
                    }
                }
                
                continuation.resume(returning: totalSleepHours)
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
    
    // MARK: - Workout History Reading
    
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
                sampleType: workoutType,
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
            
            healthStore.execute(query)
        }
    }
    
    func readRecentWorkouts(limit: Int = 10) async {
        let workouts = await readWorkoutHistory(limit: limit, daysBack: 7)
        
        await MainActor.run {
            self.recentWorkouts = workouts.compactMap { item in
                // Convert WorkoutHistoryItem back to HKWorkout if needed
                // For now, we'll store the workout history items
                return nil // We'll need to create HKWorkout objects or change the data structure
            }
            self.workoutHistory = workouts
        }
    }
    
    func getWorkoutsByType(activityType: HKWorkoutActivityType, daysBack: Int = 30) async -> [WorkoutHistoryItem] {
        let allWorkouts = await readWorkoutHistory(limit: 100, daysBack: daysBack)
        return allWorkouts.filter { $0.activityType == activityType }
    }
    
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
    
    // MARK: - Historical Data & Trends
    
    func readHistoricalStepsData(daysBack: Int = 30) async -> [HealthDataPoint] {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    Logger.error("Error reading historical steps: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                var dataPoints: [HealthDataPoint] = []
                
                collection?.enumerateStatistics(from: startDate, to: endDate) { statistic, _ in
                    if let sum = statistic.sumQuantity() {
                        let steps = sum.doubleValue(for: HKUnit.count())
                        let dataPoint = HealthDataPoint(date: statistic.startDate, value: steps, unit: CommonKeys.Units.steps.localized)
                        dataPoints.append(dataPoint)
                    }
                }
                
                continuation.resume(returning: dataPoints)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readHistoricalWeightData(daysBack: Int = 90) async -> [HealthDataPoint] {
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
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    Logger.error("Error reading historical weight: \(error)")
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
                
                continuation.resume(returning: dataPoints)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readHistoricalHeartRateData(daysBack: Int = 30) async -> [HealthDataPoint] {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            
            let query = HKStatisticsCollectionQuery(
                quantityType: restingHeartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    Logger.error("Error reading historical heart rate: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                var dataPoints: [HealthDataPoint] = []
                
                collection?.enumerateStatistics(from: startDate, to: endDate) { statistic, _ in
                    if let average = statistic.averageQuantity() {
                        let heartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        let dataPoint = HealthDataPoint(date: statistic.startDate, value: heartRate, unit: "bpm")
                        dataPoints.append(dataPoint)
                    }
                }
                
                continuation.resume(returning: dataPoints)
            }
            
            healthStore.execute(query)
        }
    }
    
    func calculateWorkoutTrends(daysBack: Int = 90) async -> WorkoutTrends {
        let workouts = await readWorkoutHistory(limit: 1000, daysBack: daysBack)
        
        // Group workouts by week
        let calendar = Calendar.current
        var weeklyData: [Date: WeeklyWorkoutData] = [:]
        
        for workout in workouts {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: workout.startDate)?.start ?? workout.startDate
            
            if let existing = weeklyData[weekStart] {
                weeklyData[weekStart] = WeeklyWorkoutData(
                    weekStartDate: weekStart,
                    workoutCount: existing.workoutCount + 1,
                    totalDuration: existing.totalDuration + workout.duration,
                    totalCalories: existing.totalCalories + (workout.totalEnergyBurned ?? 0)
                )
            } else {
                weeklyData[weekStart] = WeeklyWorkoutData(
                    weekStartDate: weekStart,
                    workoutCount: 1,
                    totalDuration: workout.duration,
                    totalCalories: workout.totalEnergyBurned ?? 0
                )
            }
        }
        
        let weeklyWorkouts = weeklyData.values.sorted { $0.weekStartDate < $1.weekStartDate }
        
        // Calculate activity type breakdown
        var activityCounts: [String: Int] = [:]
        var activityDurations: [String: TimeInterval] = [:]
        
        for workout in workouts {
            let activityName = workout.activityDisplayName
            activityCounts[activityName, default: 0] += 1
            activityDurations[activityName, default: 0] += workout.duration
        }
        
        let totalWorkouts = workouts.count
        let activityBreakdown = activityCounts.map { name, count in
            ActivityTypeData(
                activityType: name,
                count: count,
                totalDuration: activityDurations[name] ?? 0,
                percentage: totalWorkouts > 0 ? (Double(count) / Double(totalWorkouts)) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
        
        // Calculate totals and averages
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let totalCalories = workouts.compactMap { $0.totalEnergyBurned }.reduce(0, +)
        let averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0
        let averageCaloriesPerWorkout = totalWorkouts > 0 ? totalCalories / Double(totalWorkouts) : 0
        let longestWorkout = workouts.map { $0.duration }.max() ?? 0
        
        // Generate monthly calories (simplified for now)
        let monthlyCalories = generateMonthlyCalories(from: workouts)
        
        return WorkoutTrends(
            totalWorkouts: totalWorkouts,
            weeklyWorkouts: Array(weeklyWorkouts),
            monthlyCalories: monthlyCalories,
            activityTypeBreakdown: activityBreakdown,
            averageDuration: averageDuration,
            totalDuration: totalDuration,
            longestWorkout: longestWorkout,
            totalCalories: totalCalories,
            averageCaloriesPerWorkout: averageCaloriesPerWorkout
        )
    }
    
    private func generateMonthlyCalories(from workouts: [WorkoutHistoryItem]) -> [MonthlyData] {
        let calendar = Calendar.current
        var monthlyData: [Date: Double] = [:]
        
        for workout in workouts {
            let monthStart = calendar.dateInterval(of: .month, for: workout.startDate)?.start ?? workout.startDate
            monthlyData[monthStart, default: 0] += workout.totalEnergyBurned ?? 0
        }
        
        return monthlyData.map { month, calories in
            MonthlyData(month: month, value: calories)
        }.sorted { $0.month < $1.month }
    }
    
    func loadAllHistoricalData() async {
        async let stepsData = readHistoricalStepsData(daysBack: 30)
        async let weightData = readHistoricalWeightData(daysBack: 90) 
        async let heartRateData = readHistoricalHeartRateData(daysBack: 30)
        async let trends = calculateWorkoutTrends(daysBack: 90)
        
        let (steps, weight, heartRate, workoutTrends) = await (stepsData, weightData, heartRateData, trends)
        
        await MainActor.run {
            self.stepsHistory = steps
            self.weightHistory = weight
            self.heartRateHistory = heartRate
            self.workoutTrends = workoutTrends
        }
        
        Logger.success("Historical health data loaded - Steps: \(steps.count), Weight: \(weight.count), HR: \(heartRate.count)")
    }
    
    // MARK: - Health Intelligence & Recovery
    
    func calculateCurrentRecoveryScore() async {
        // Calculate workout intensity for last 7 days
        let recentWorkouts = await readWorkoutHistory(limit: 20, daysBack: 7)
        let workoutIntensity = calculateWorkoutIntensity(from: recentWorkouts)
        
        let recoveryScore = HealthIntelligence.calculateRecoveryScore(
            hrv: heartRateVariability,
            sleepHours: lastNightSleep,
            workoutIntensityLast7Days: workoutIntensity,
            restingHeartRate: restingHeartRate
        )
        
        await MainActor.run {
            currentRecoveryScore = recoveryScore
        }
        
        Logger.info("Recovery score calculated: \(String(format: "%.1f", recoveryScore.overallScore))")
    }
    
    func generateHealthInsights() async {
        guard workoutTrends.totalWorkouts > 0 else {
            Logger.warning("Cannot generate health insights without workout trends")
            return
        }
        
        let insights = HealthIntelligence.generateHealthInsights(
            recoveryScore: currentRecoveryScore ?? RecoveryScore(
                overallScore: 50, hrvScore: 50, sleepScore: 50,
                workoutLoadScore: 50, restingHeartRateScore: 50, date: Date()
            ),
            workoutTrends: self.workoutTrends,
            stepsHistory: stepsHistory,
            weightHistory: weightHistory
        )
        
        await MainActor.run {
            healthInsights = insights
        }
        
        Logger.success("Generated \(insights.count) health insights")
    }
    
    func assessFitnessLevel() async {
        let consistencyScore = calculateConsistencyScore()
        
        let assessment = HealthIntelligence.assessFitnessLevel(
            workoutTrends: workoutTrends,
            vo2Max: vo2Max,
            consistencyScore: consistencyScore
        )
        
        await MainActor.run {
            fitnessAssessment = assessment
        }
        
        Logger.info("Fitness level assessed: \(assessment.overallLevel.rawValue)")
    }
    
    func generateComprehensiveHealthReport() async -> HealthReport {
        // Ensure all data is loaded
        await loadAllHistoricalData()
        await calculateCurrentRecoveryScore()
        await generateHealthInsights()
        await assessFitnessLevel()
        
        return HealthIntelligence.generateComprehensiveHealthReport(
            healthKitService: self,
            workoutTrends: workoutTrends
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateWorkoutIntensity(from workouts: [WorkoutHistoryItem]) -> Double {
        guard !workouts.isEmpty else { return 0 }
        
        let totalCalories = workouts.compactMap { $0.totalEnergyBurned }.reduce(0, +)
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        
        // Intensity based on calories per minute
        let avgIntensity = totalDuration > 0 ? totalCalories / (totalDuration / 60) : 0
        
        // Normalize to 0-10 scale (assuming max 15 cal/min for high intensity)
        return min(10, avgIntensity / 15 * 10)
    }
    
    private func calculateConsistencyScore() -> Double {
        guard !workoutTrends.weeklyWorkouts.isEmpty else { return 0 }
        
        let weeks = workoutTrends.weeklyWorkouts.count
        let workoutWeeks = workoutTrends.weeklyWorkouts.filter { $0.workoutCount > 0 }.count
        
        return weeks > 0 ? (Double(workoutWeeks) / Double(weeks)) * 100 : 0
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
                        let calories = Int(self.todayActiveCalories)
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
