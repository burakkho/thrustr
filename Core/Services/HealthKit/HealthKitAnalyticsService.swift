import Foundation
import HealthKit
import SwiftUI

/**
 * HealthKit service specialized for Analytics feature requirements.
 *
 * Manages historical health data analysis, trends calculation, health intelligence,
 * and comprehensive analytics for the Analytics feature. Provides data-driven
 * insights based on long-term health and fitness patterns.
 *
 * Features:
 * - Historical data trends and analysis
 * - Health intelligence calculations
 * - Recovery score and fitness assessment
 * - Long-term health insights
 * - Comprehensive health reports
 * - Sleep and recovery analytics
 */
final class HealthKitAnalyticsService {
    static let shared = HealthKitAnalyticsService()

    // MARK: - Dependencies
    private let core = HealthKitCore.shared

    // MARK: - Analytics Health Data
    var lastNightSleep: Double = 0 // hours
    var sleepEfficiency: Double = 0 // percentage

    // MARK: - Historical Data
    var stepsHistory: [HealthDataPoint] = []
    var weightHistory: [HealthDataPoint] = []
    var heartRateHistory: [HealthDataPoint] = []
    var workoutTrends: WorkoutTrends = WorkoutTrends.empty

    // MARK: - Health Intelligence
    var currentRecoveryScore: RecoveryScore?
    var healthInsights: [HealthInsight] = []
    var fitnessAssessment: FitnessLevelAssessment?

    // MARK: - State Management
    var isLoading = false
    var error: Error?
    var lastAnalyticsUpdate: Date = Date.distantPast

    // MARK: - Performance Metrics
    private var queryPerformanceMetrics: [String: TimeInterval] = [:]

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /**
     * Loads all historical data for analytics.
     *
     * Comprehensive data loading for analytics dashboard including steps,
     * weight, heart rate trends, workout patterns, and sleep data.
     */
    func loadAllAnalyticsData() async {
        isLoading = true
        defer { isLoading = false }

        let startTime = Date()

        // Load all analytics data concurrently
        async let stepsData = readHistoricalStepsData(daysBack: 30)
        async let weightData = readHistoricalWeightData(daysBack: 90)
        async let heartRateData = readHistoricalHeartRateData(daysBack: 30)
        async let sleepData = readSleepData()
        async let trends = calculateWorkoutTrends(daysBack: 90)

        let (steps, weight, heartRate, sleep, workoutTrends) = await (stepsData, weightData, heartRateData, sleepData, trends)

        await updateAnalyticsData(
            steps: steps,
            weight: weight,
            heartRate: heartRate,
            sleep: sleep,
            workoutTrends: workoutTrends,
            startTime: startTime
        )
    }

    /**
     * Generate comprehensive health report.
     *
     * Creates a detailed health report combining all available health data
     * for comprehensive health and fitness analysis.
     */
    func generateComprehensiveHealthReport() async -> HealthReport {
        // Ensure all data is loaded
        await loadAllAnalyticsData()
        await calculateCurrentRecoveryScore()
        await generateHealthInsights()
        await assessFitnessLevel()

        return await HealthIntelligence.generateComprehensiveHealthReport(
            healthKitService: HealthKitService.shared,
            workoutTrends: workoutTrends
        )
    }

    // MARK: - Historical Data Reading

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
                quantityType: core.stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    Logger.error("Error reading historical steps for analytics: \(error)")
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

                Logger.success("Retrieved \(dataPoints.count) days of steps history for analytics")
                continuation.resume(returning: dataPoints)
            }

            core.healthStore.execute(query)
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
                sampleType: core.bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading historical weight for analytics: \(error)")
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

                Logger.success("Retrieved \(dataPoints.count) weight history points for analytics")
                continuation.resume(returning: dataPoints)
            }

            core.healthStore.execute(query)
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
                quantityType: core.restingHeartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    Logger.error("Error reading historical heart rate for analytics: \(error)")
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

                Logger.success("Retrieved \(dataPoints.count) days of heart rate history for analytics")
                continuation.resume(returning: dataPoints)
            }

            core.healthStore.execute(query)
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
                sampleType: core.sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in

                if let error = error {
                    Logger.error("Error reading sleep data for analytics: \(error)")
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

                Logger.success("Retrieved sleep data: \(totalSleepHours) hours")
                continuation.resume(returning: totalSleepHours)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Workout Trends Analysis

    func calculateWorkoutTrends(daysBack: Int = 90) async -> WorkoutTrends {
        // Get workout history from training service
        let workouts = await HealthKitTrainingService.shared.readWorkoutHistory(limit: 1000, daysBack: daysBack)

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

        // Generate monthly calories
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

    // MARK: - Health Intelligence & Recovery

    func calculateCurrentRecoveryScore() async {
        // Get training data from training service
        let trainingService = HealthKitTrainingService.shared
        await trainingService.loadTrainingHealthData()

        // Calculate workout intensity for last 7 days
        let recentWorkouts = await trainingService.readWorkoutHistory(limit: 20, daysBack: 7)
        let workoutIntensity = calculateWorkoutIntensity(from: recentWorkouts)

        let recoveryScore = HealthIntelligence.calculateRecoveryScore(
            hrv: trainingService.heartRateVariability,
            sleepHours: lastNightSleep,
            workoutIntensityLast7Days: workoutIntensity,
            restingHeartRate: trainingService.restingHeartRate
        )

        currentRecoveryScore = recoveryScore
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

        healthInsights = insights
        Logger.success("Generated \(insights.count) health insights")
    }

    func assessFitnessLevel() async {
        let consistencyScore = calculateConsistencyScore()

        // Get VO2 max from training service
        let trainingService = HealthKitTrainingService.shared
        await trainingService.loadTrainingHealthData()

        let assessment = HealthIntelligence.assessFitnessLevel(
            workoutTrends: workoutTrends,
            vo2Max: trainingService.vo2Max,
            consistencyScore: consistencyScore
        )

        fitnessAssessment = assessment
        Logger.info("Fitness level assessed: \(assessment.overallLevel.rawValue)")
    }

    // MARK: - Analytics Utilities

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

    private func updateAnalyticsData(
        steps: [HealthDataPoint],
        weight: [HealthDataPoint],
        heartRate: [HealthDataPoint],
        sleep: Double?,
        workoutTrends: WorkoutTrends,
        startTime: Date
    ) async {
        // Update published properties
        self.stepsHistory = steps
        self.weightHistory = weight
        self.heartRateHistory = heartRate
        self.lastNightSleep = sleep ?? 0
        self.workoutTrends = workoutTrends

        lastAnalyticsUpdate = Date()

        // Performance logging
        let duration = Date().timeIntervalSince(startTime)
        queryPerformanceMetrics["loadAllAnalyticsData"] = duration
        Logger.success("Analytics HealthKit data fetch completed in \(String(format: "%.2f", duration))s")

        // Log sync summary
        Logger.success("Analytics data loaded - Steps: \(steps.count), Weight: \(weight.count), HR: \(heartRate.count), Sleep: \(sleep != nil ? "✓" : "✗")")
    }

    // MARK: - Analytics Summary

    /**
     * Get comprehensive analytics summary.
     */
    func getAnalyticsSummary() -> AnalyticsHealthSummary {
        return AnalyticsHealthSummary(
            stepsHistoryCount: stepsHistory.count,
            weightHistoryCount: weightHistory.count,
            heartRateHistoryCount: heartRateHistory.count,
            totalWorkouts: workoutTrends.totalWorkouts,
            recoveryScore: currentRecoveryScore?.overallScore,
            fitnessLevel: fitnessAssessment?.overallLevel.rawValue,
            healthInsightsCount: healthInsights.count,
            lastUpdated: lastAnalyticsUpdate
        )
    }

    // MARK: - Cleanup
    deinit {
        Logger.info("HealthKitAnalyticsService deinitialized")
    }
}

// MARK: - Supporting Types

struct AnalyticsHealthSummary {
    let stepsHistoryCount: Int
    let weightHistoryCount: Int
    let heartRateHistoryCount: Int
    let totalWorkouts: Int
    let recoveryScore: Double?
    let fitnessLevel: String?
    let healthInsightsCount: Int
    let lastUpdated: Date
}