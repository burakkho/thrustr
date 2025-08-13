import Foundation
import HealthKit

@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    
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
    
    // MARK: - Permission Requests
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return false
        }
        
        let readTypes: Set<HKObjectType> = [
            stepCountType,
            activeEnergyType,
            bodyMassType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            
            let stepStatus = healthStore.authorizationStatus(for: stepCountType)
            let calorieStatus = healthStore.authorizationStatus(for: activeEnergyType)
            let weightStatus = healthStore.authorizationStatus(for: bodyMassType)
            
            // Consider authorized if ANY relevant type is permitted
            // Dashboard uses steps and active energy; weight is optional
            isAuthorized = (stepStatus == .sharingAuthorized) ||
                           (calorieStatus == .sharingAuthorized) ||
                           (weightStatus == .sharingAuthorized)
            
            if isAuthorized {
                await readTodaysData()
                // Start background delivery and observers once authorized
                enableBackgroundDelivery()
                startObserverQueries()
            }
            
            return isAuthorized
        } catch {
            print("HealthKit authorization error: \(error)")
            self.error = error
            return false
        }
    }
    
    // MARK: - Data Reading
    func readTodaysData() async {
        isLoading = true
        defer { isLoading = false }
        
        async let steps = readStepsData()
        async let calories = readCaloriesData()
        async let weight = readWeightData()
        
        let results = await (steps, calories, weight)
        
        todaySteps = results.0 ?? 0
        todayCalories = results.1 ?? 0
        currentWeight = results.2
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
    
    // MARK: - Helper Methods
    func getAuthorizationStatus() -> (steps: HKAuthorizationStatus, calories: HKAuthorizationStatus, weight: HKAuthorizationStatus) {
        return (
            steps: healthStore.authorizationStatus(for: stepCountType),
            calories: healthStore.authorizationStatus(for: activeEnergyType),
            weight: healthStore.authorizationStatus(for: bodyMassType)
        )
    }
}
