import Foundation
import HealthKit

/**
 * HealthKit service specialized for Dashboard feature requirements.
 *
 * Manages daily health metrics displayed on the main dashboard including
 * activity data, quick stats, and real-time health updates. Provides
 * optimized caching and efficient data fetching for dashboard performance.
 *
 * Features:
 * - Today's activity metrics (steps, calories, distance)
 * - Real-time health data updates
 * - Optimized caching for dashboard performance
 * - Quick health summary statistics
 * - Health rings data for activity visualization
 */
final class HealthKitDashboardService {
    static let shared = HealthKitDashboardService()

    // MARK: - Dependencies
    private let core = HealthKitCore.shared

    // MARK: - Dashboard Health Data
    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var todayBasalCalories: Double = 0
    var todayDistance: Double = 0
    var todayFlightsClimbed: Double = 0
    var todayExerciseMinutes: Double = 0
    var todayStandHours: Double = 0

    // MARK: - Computed Properties
    var todayTotalCalories: Double {
        return todayActiveCalories + todayBasalCalories
    }

    // MARK: - State Management
    var isLoading = false
    var error: Error?
    var lastUpdateTime: Date = Date.distantPast

    // MARK: - Cache Management
    private var cachedDashboardData: [String: Any] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes for dashboard

    // MARK: - Initialization
    private init() {
        setupNotificationObservers()
    }

    // MARK: - Public API

    /**
     * Loads today's dashboard health data with caching optimization.
     *
     * Fetches all daily metrics required for dashboard display including
     * steps, calories, distance, and activity rings data. Uses intelligent
     * caching to optimize performance for frequent dashboard updates.
     */
    func loadTodaysDashboardData() async {
        // Check if cache is still valid
        if Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration {
            await loadFromCache()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let startTime = Date()

        do {
            // Fetch all dashboard metrics concurrently
            let results = try await AsyncTimeout.execute(timeout: AsyncTimeout.Duration.medium) {
                async let steps = self.readStepsData()
                async let activeCalories = self.readActiveCaloriesData()
                async let basalCalories = self.readBasalCaloriesData()
                async let distance = self.readDistanceData()
                async let flightsClimbed = self.readFlightsClimbedData()
                async let exerciseMinutes = self.readExerciseTimeData()
                async let standHours = self.readStandTimeData()

                return await (
                    steps, activeCalories, basalCalories, distance,
                    flightsClimbed, exerciseMinutes, standHours
                )
            }

            await updateDashboardCache(with: results, startTime: startTime)

        } catch {
            self.error = error
            let context = ErrorService.shared.processError(
                error,
                severity: .medium,
                source: "HealthKitDashboardService.loadTodaysDashboardData",
                userAction: "Loading dashboard health data"
            )
            await ErrorUIService.shared.handleUIDisplay(for: context)
        }
    }

    /**
     * Quick refresh for real-time dashboard updates.
     *
     * Performs a fast update of key metrics without full cache invalidation.
     * Ideal for background updates and real-time dashboard refreshes.
     */
    func quickRefresh() async {
        // Only refresh if last update was more than 1 minute ago
        guard Date().timeIntervalSince(lastUpdateTime) > 60 else { return }

        async let steps = readStepsData()
        async let activeCalories = readActiveCaloriesData()
        async let distance = readDistanceData()

        let (stepsResult, caloriesResult, distanceResult) = await (steps, activeCalories, distance)

        todaySteps = stepsResult ?? todaySteps
        todayActiveCalories = caloriesResult ?? todayActiveCalories
        todayDistance = distanceResult ?? todayDistance
        lastUpdateTime = Date()

        Logger.info("Dashboard quick refresh completed")
    }

    // MARK: - Cache Management

    private func loadFromCache() async {
        todaySteps = cachedDashboardData["steps"] as? Double ?? 0
        todayActiveCalories = cachedDashboardData["activeCalories"] as? Double ?? 0
        todayBasalCalories = cachedDashboardData["basalCalories"] as? Double ?? 0
        todayDistance = cachedDashboardData["distance"] as? Double ?? 0
        todayFlightsClimbed = cachedDashboardData["flightsClimbed"] as? Double ?? 0
        todayExerciseMinutes = cachedDashboardData["exerciseMinutes"] as? Double ?? 0
        todayStandHours = cachedDashboardData["standHours"] as? Double ?? 0

        Logger.info("Loaded dashboard data from cache")
    }

    private func updateDashboardCache(
        with results: (Double?, Double?, Double?, Double?, Double?, Double?, Double?),
        startTime: Date
    ) async {
        // Update cache
        cachedDashboardData = [
            "steps": results.0 ?? 0,
            "activeCalories": results.1 ?? 0,
            "basalCalories": results.2 ?? 0,
            "distance": results.3 ?? 0,
            "flightsClimbed": results.4 ?? 0,
            "exerciseMinutes": results.5 ?? 0,
            "standHours": results.6 ?? 0
        ]

        lastCacheUpdate = Date()
        lastUpdateTime = Date()

        // Update published properties
        todaySteps = results.0 ?? 0
        todayActiveCalories = results.1 ?? 0
        todayBasalCalories = results.2 ?? 0
        todayDistance = results.3 ?? 0
        todayFlightsClimbed = results.4 ?? 0
        todayExerciseMinutes = results.5 ?? 0
        todayStandHours = results.6 ?? 0

        // Performance logging
        let duration = Date().timeIntervalSince(startTime)
        Logger.success("Dashboard HealthKit data fetch completed in \(String(format: "%.2f", duration))s")

        // Log sync summary
        let syncedMetrics = [
            results.0 != nil ? "Steps" : nil,
            results.1 != nil ? "Active Calories" : nil,
            results.2 != nil ? "Basal Calories" : nil,
            results.3 != nil ? "Distance" : nil,
            results.4 != nil ? "Flights" : nil,
            results.5 != nil ? "Exercise" : nil,
            results.6 != nil ? "Stand" : nil
        ].compactMap { $0 }

        if !syncedMetrics.isEmpty {
            Logger.success("Dashboard synced: \(syncedMetrics.joined(separator: ", "))")
        }
    }

    // MARK: - Data Reading Methods

    private func readStepsData() async -> Double? {
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
                quantityType: core.stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading steps for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }

            core.healthStore.execute(query)
        }
    }

    private func readActiveCaloriesData() async -> Double? {
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
                quantityType: core.activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading active calories for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }

            core.healthStore.execute(query)
        }
    }

    private func readBasalCaloriesData() async -> Double? {
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
                quantityType: core.basalEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading basal calories for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }

            core.healthStore.execute(query)
        }
    }

    private func readDistanceData() async -> Double? {
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
                quantityType: core.distanceWalkingRunningType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading distance for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance)
            }

            core.healthStore.execute(query)
        }
    }

    private func readFlightsClimbedData() async -> Double? {
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
                quantityType: core.flightsClimbedType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading flights climbed for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let flights = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: flights)
            }

            core.healthStore.execute(query)
        }
    }

    private func readExerciseTimeData() async -> Double? {
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
                quantityType: core.exerciseTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading exercise time for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }

            core.healthStore.execute(query)
        }
    }

    private func readStandTimeData() async -> Double? {
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
                quantityType: core.standTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading stand time for dashboard: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let hours = result?.sumQuantity()?.doubleValue(for: HKUnit.hour()) ?? 0
                continuation.resume(returning: hours)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Dashboard Specific Utilities

    /**
     * Get activity ring progress for dashboard display.
     *
     * Returns progress percentages for move, exercise, and stand rings
     * based on user's personal goals and today's achievements.
     */
    func getActivityRingsProgress() -> (move: Double, exercise: Double, stand: Double) {
        // Get user's personal activity goals with smart defaults
        let goals = getUserActivityGoals()
        let moveGoal = goals.move
        let exerciseGoal = goals.exercise
        let standGoal = goals.stand

        let moveProgress = min(1.0, todayActiveCalories / moveGoal)
        let exerciseProgress = min(1.0, todayExerciseMinutes / exerciseGoal)
        let standProgress = min(1.0, todayStandHours / standGoal)

        return (moveProgress, exerciseProgress, standProgress)
    }

    /**
     * Get quick stats summary for dashboard.
     *
     * Returns formatted summary of today's key metrics for dashboard display.
     */
    func getDashboardSummary() -> DashboardHealthSummary {
        return DashboardHealthSummary(
            steps: Int(todaySteps),
            activeCalories: Int(todayActiveCalories),
            totalCalories: Int(todayTotalCalories),
            distance: todayDistance,
            exerciseMinutes: Int(todayExerciseMinutes),
            lastUpdated: lastUpdateTime
        )
    }

    /**
     * Get user's personal activity goals with smart defaults.
     *
     * Retrieves user-specific daily activity goals from UserDefaults with
     * intelligent fallbacks based on user's daily calorie goal and activity level.
     */
    private func getUserActivityGoals() -> (move: Double, exercise: Double, stand: Double) {
        // Try to get stored user goals from UserDefaults
        let moveGoal = UserDefaults.standard.double(forKey: "user_move_goal")
        let exerciseGoal = UserDefaults.standard.double(forKey: "user_exercise_goal")
        let standGoal = UserDefaults.standard.double(forKey: "user_stand_goal")

        // If we have stored goals, use them
        if moveGoal > 0 && exerciseGoal > 0 && standGoal > 0 {
            Logger.info("Using stored user activity goals: Move=\(moveGoal), Exercise=\(exerciseGoal), Stand=\(standGoal)")
            return (moveGoal, exerciseGoal, standGoal)
        }

        // Otherwise, calculate smart defaults based on user profile
        let smartDefaults = calculateSmartActivityDefaults()
        Logger.info("Using calculated smart defaults: Move=\(smartDefaults.move), Exercise=\(smartDefaults.exercise), Stand=\(smartDefaults.stand)")

        return smartDefaults
    }

    /**
     * Calculate smart activity goal defaults based on user profile.
     *
     * Uses user's daily calorie goal, activity level, and fitness goals
     * to provide personalized activity ring targets.
     */
    private func calculateSmartActivityDefaults() -> (move: Double, exercise: Double, stand: Double) {
        // Get user's daily calorie goal from stored data or calculate default
        let dailyCalorieGoal = UserDefaults.standard.double(forKey: "user_daily_calorie_goal")

        // Smart defaults based on fitness guidelines and user characteristics
        let moveGoal: Double
        let exerciseGoal: Double = 30.0 // 30 minutes recommended daily exercise
        let standGoal: Double = 12.0   // 12 hours standing goal (Apple default)

        if dailyCalorieGoal > 0 {
            // Base move goal on percentage of daily calorie target (typically 20-30% for active calories)
            moveGoal = dailyCalorieGoal * 0.25
        } else {
            // Use activity level-based defaults
            let activityLevel = UserDefaults.standard.string(forKey: "user_activity_level") ?? "moderate"
            switch activityLevel {
            case "sedentary":
                moveGoal = 300.0
            case "light":
                moveGoal = 400.0
            case "moderate":
                moveGoal = 500.0
            case "active":
                moveGoal = 600.0
            case "very_active":
                moveGoal = 700.0
            default:
                moveGoal = 500.0 // Default moderate level
            }
        }

        return (moveGoal, exerciseGoal, standGoal)
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .healthKitDataUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            // Check if the update is for dashboard-relevant data
            if let dataType = notification.object as? String,
               [self.core.stepCountType.identifier,
                self.core.activeEnergyType.identifier,
                self.core.distanceWalkingRunningType.identifier].contains(dataType) {

                Task {
                    await self.quickRefresh()
                }
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        Logger.info("HealthKitDashboardService deinitialized")
    }
}

// MARK: - Supporting Types

struct DashboardHealthSummary {
    let steps: Int
    let activeCalories: Int
    let totalCalories: Int
    let distance: Double // meters
    let exerciseMinutes: Int
    let lastUpdated: Date
}