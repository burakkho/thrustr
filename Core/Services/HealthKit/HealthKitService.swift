import Foundation
import HealthKit
import SwiftUI

/**
 * Facade HealthKit service providing backward compatibility and unified access.
 *
 * This service acts as a facade over the specialized HealthKit services,
 * maintaining backward compatibility while providing a unified interface
 * for accessing all HealthKit functionality across the app.
 *
 * Architecture:
 * - Delegates operations to specialized services
 * - Maintains existing API for backward compatibility
 * - Provides migration path for gradual adoption
 * - Coordinates between multiple HealthKit services
 */
@MainActor
@Observable
final class HealthKitService: Sendable {
    static let shared = HealthKitService()

    // MARK: - Specialized Services
    private let core = HealthKitCore.shared
    private let dashboard = HealthKitDashboardService.shared
    private let profile = HealthKitProfileService.shared
    private let training = HealthKitTrainingService.shared
    private let analytics = HealthKitAnalyticsService.shared
    private let nutrition = HealthKitNutritionService.shared

    // MARK: - Facade Properties (Delegated)

    // Core authorization
    var isAuthorized: Bool { core.isAuthorized }
    var authorizationStatuses: [String: HKAuthorizationStatus] { core.authorizationStatuses }

    // Dashboard data
    var todaySteps: Double { dashboard.todaySteps }
    var todayActiveCalories: Double { dashboard.todayActiveCalories }
    var todayBasalCalories: Double { dashboard.todayBasalCalories }
    var todayDistance: Double { dashboard.todayDistance }
    var todayCalories: Double { dashboard.todayTotalCalories }
    var todayFlightsClimbed: Double { dashboard.todayFlightsClimbed }
    var todayExerciseMinutes: Double { dashboard.todayExerciseMinutes }
    var todayStandHours: Double { dashboard.todayStandHours }

    // Profile data
    var currentWeight: Double? { profile.currentWeight }
    var currentHeight: Double? { profile.currentHeight }
    var bodyMassIndex: Double? { profile.bodyMassIndex }
    var bodyFatPercentage: Double? { profile.bodyFatPercentage }
    var leanBodyMass: Double? { profile.leanBodyMass }

    // Training data
    var currentHeartRate: Double? { training.currentHeartRate }
    var restingHeartRate: Double? { training.restingHeartRate }
    var heartRateVariability: Double? { training.heartRateVariability }
    var vo2Max: Double? { training.vo2Max }
    var recentWorkouts: [HKWorkout] { training.recentWorkouts }
    var workoutHistory: [WorkoutHistoryItem] { training.workoutHistory }

    // Analytics data
    var lastNightSleep: Double { analytics.lastNightSleep }
    var sleepEfficiency: Double { analytics.sleepEfficiency }
    var stepsHistory: [HealthDataPoint] { analytics.stepsHistory }
    var weightHistory: [HealthDataPoint] { analytics.weightHistory }
    var heartRateHistory: [HealthDataPoint] { analytics.heartRateHistory }
    var workoutTrends: WorkoutTrends { analytics.workoutTrends }
    var currentRecoveryScore: RecoveryScore? { analytics.currentRecoveryScore }
    var healthInsights: [HealthInsight] { analytics.healthInsights }
    var fitnessAssessment: FitnessLevelAssessment? { analytics.fitnessAssessment }

    // State management
    var isLoading: Bool {
        dashboard.isLoading || profile.isLoading || training.isLoading || analytics.isLoading || nutrition.isLoading
    }

    var error: Error? {
        dashboard.error ?? profile.error ?? training.error ?? analytics.error ?? nutrition.error
    }

    // MARK: - Initialization
    init() {}

    // MARK: - Core Operations (Delegated)

    /**
     * Request comprehensive HealthKit permissions.
     */
    func requestPermissions() async -> Bool {
        return await core.requestPermissions()
    }

    /**
     * Read today's comprehensive health data.
     *
     * Loads data across all specialized services for complete health picture.
     */
    func readTodaysData() async {
        // Load data from all relevant services
        await dashboard.loadTodaysDashboardData()
        await profile.loadProfileHealthData()
        await training.loadTrainingHealthData()
        await nutrition.loadTodaysNutrition()
    }

    /**
     * Enable background delivery for HealthKit data.
     */
    func enableBackgroundDelivery() {
        core.enableBackgroundDelivery()
    }

    /**
     * Start observer queries for real-time data updates.
     */
    func startObserverQueries() {
        core.startObserverQueries()
    }

    /**
     * Stop observer queries.
     */
    func stopObserverQueries() async {
        await core.stopObserverQueries()
    }

    // MARK: - Dashboard Operations (Delegated)

    func quickRefresh() async {
        await dashboard.quickRefresh()
    }

    func getActivityRingsProgress() -> (move: Double, exercise: Double, stand: Double) {
        return dashboard.getActivityRingsProgress()
    }

    func getDashboardSummary() -> DashboardHealthSummary {
        return dashboard.getDashboardSummary()
    }

    // MARK: - Profile Operations (Delegated)

    func syncWithUserProfile(user: User) async {
        await profile.syncWithUserProfile(user: user)
    }

    func saveWeight(_ weight: Double, date: Date = Date()) async -> Bool {
        return await profile.saveWeight(weight, date: date)
    }

    func saveBodyFat(_ bodyFat: Double, date: Date = Date()) async -> Bool {
        return await profile.saveBodyFat(bodyFat, date: date)
    }

    func saveHeight(_ height: Double, date: Date = Date()) async -> Bool {
        return await profile.saveHeight(height, date: date)
    }

    func getWeightHistory(daysBack: Int = 90) async -> [HealthDataPoint] {
        return await profile.getWeightHistory(daysBack: daysBack)
    }

    func getProfileHealthSummary() -> ProfileHealthSummary {
        return profile.getProfileHealthSummary()
    }

    func hasCompleteProfileData() -> Bool {
        return profile.hasCompleteProfileData()
    }

    // MARK: - Training Operations (Delegated)

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
        return await training.saveCardioWorkout(
            activityType: activityType,
            duration: duration,
            distance: distance,
            caloriesBurned: caloriesBurned,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            startDate: startDate,
            endDate: endDate
        )
    }

    func saveLiftWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        totalVolume: Double? = nil
    ) async -> Bool {
        return await training.saveLiftWorkout(
            duration: duration,
            caloriesBurned: caloriesBurned,
            startDate: startDate,
            endDate: endDate,
            totalVolume: totalVolume
        )
    }

    func saveWODWorkout(
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        startDate: Date,
        endDate: Date,
        wodType: String? = nil
    ) async -> Bool {
        return await training.saveWODWorkout(
            duration: duration,
            caloriesBurned: caloriesBurned,
            startDate: startDate,
            endDate: endDate,
            wodType: wodType
        )
    }

    func readWorkoutHistory(limit: Int = 50, daysBack: Int = 30) async -> [WorkoutHistoryItem] {
        return await training.readWorkoutHistory(limit: limit, daysBack: daysBack)
    }

    func getWorkoutsByType(activityType: HKWorkoutActivityType, daysBack: Int = 30) async -> [WorkoutHistoryItem] {
        return await training.getWorkoutsByType(activityType: activityType, daysBack: daysBack)
    }

    func getTotalWorkoutStats(daysBack: Int = 30) async -> WorkoutStats {
        return await training.getTotalWorkoutStats(daysBack: daysBack)
    }

    func loadRecentWorkouts(limit: Int = 10) async {
        await training.loadRecentWorkouts(limit: limit)
    }

    func getTrainingHealthSummary() -> TrainingHealthSummary {
        return training.getTrainingHealthSummary()
    }

    func calculateHeartRateZones(age: Int) -> HeartRateZones? {
        return training.calculateHeartRateZones(age: age)
    }

    // MARK: - Analytics Operations (Delegated)

    func loadAllHistoricalData() async {
        await analytics.loadAllAnalyticsData()
    }

    func readHistoricalStepsData(daysBack: Int = 30) async -> [HealthDataPoint] {
        return await analytics.readHistoricalStepsData(daysBack: daysBack)
    }

    func readHistoricalWeightData(daysBack: Int = 90) async -> [HealthDataPoint] {
        return await analytics.readHistoricalWeightData(daysBack: daysBack)
    }

    func readHistoricalHeartRateData(daysBack: Int = 30) async -> [HealthDataPoint] {
        return await analytics.readHistoricalHeartRateData(daysBack: daysBack)
    }

    func calculateWorkoutTrends(daysBack: Int = 90) async -> WorkoutTrends {
        return await analytics.calculateWorkoutTrends(daysBack: daysBack)
    }

    func calculateCurrentRecoveryScore() async {
        await analytics.calculateCurrentRecoveryScore()
    }

    func generateHealthInsights() async {
        await analytics.generateHealthInsights()
    }

    func assessFitnessLevel() async {
        await analytics.assessFitnessLevel()
    }

    func generateComprehensiveHealthReport() async -> HealthReport {
        return await analytics.generateComprehensiveHealthReport()
    }

    func getAnalyticsSummary() -> AnalyticsHealthSummary {
        return analytics.getAnalyticsSummary()
    }

    // MARK: - Nutrition Operations (Delegated)

    func saveNutritionData(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date()
    ) async -> Bool {
        return await nutrition.saveNutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: date
        )
    }

    func saveFoodItem(
        food: Food,
        portionSize: Double,
        mealType: MealType,
        date: Date = Date()
    ) async -> Bool {
        return await nutrition.saveFoodItem(
            food: food,
            portionSize: portionSize,
            mealType: mealType,
            date: date
        )
    }

    func saveMeal(
        foods: [(Food, Double)],
        mealType: MealType,
        date: Date = Date()
    ) async -> Bool {
        return await nutrition.saveMeal(
            foods: foods,
            mealType: mealType,
            date: date
        )
    }

    func loadTodaysNutrition() async {
        await nutrition.loadTodaysNutrition()
    }

    func getNutritionHistory(daysBack: Int = 30) async -> [NutritionHistoryPoint] {
        return await nutrition.getNutritionHistory(daysBack: daysBack)
    }

    func getNutritionByMealType(date: Date = Date()) async -> [MealType: NutritionSummary] {
        return await nutrition.getNutritionByMealType(date: date)
    }

    func calculateNutritionProgress(user: User) -> NutritionProgress {
        return nutrition.calculateNutritionProgress(user: user)
    }

    func getNutritionSummary() -> NutritionDisplaySummary {
        return nutrition.getNutritionSummary()
    }

    // MARK: - Utility Methods (Delegated)

    func getAuthorizationStatus() -> (steps: HKAuthorizationStatus, calories: HKAuthorizationStatus, weight: HKAuthorizationStatus) {
        return core.getAuthorizationStatus()
    }

    func getAuthorizationStatusSummary() -> (authorized: Int, denied: Int, notDetermined: Int) {
        return core.getAuthorizationStatusSummary()
    }

    func disableBackgroundDelivery() {
        core.disableBackgroundDelivery()
    }

    // MARK: - Comprehensive Operations

    /**
     * Load all HealthKit data across all services.
     *
     * Comprehensive data loading for complete app initialization.
     */
    func loadAllHealthData() async {
        Logger.info("Loading comprehensive HealthKit data across all services...")

        // Load data from all services concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.dashboard.loadTodaysDashboardData() }
            group.addTask { await self.profile.loadProfileHealthData() }
            group.addTask { await self.training.loadTrainingHealthData() }
            group.addTask { await self.analytics.loadAllAnalyticsData() }
            group.addTask { await self.nutrition.loadTodaysNutrition() }
        }

        Logger.success("All HealthKit data loaded successfully")
    }

    /**
     * Get unified health summary across all services.
     */
    func getUnifiedHealthSummary() -> UnifiedHealthSummary {
        return UnifiedHealthSummary(
            dashboard: dashboard.getDashboardSummary(),
            profile: profile.getProfileHealthSummary(),
            training: training.getTrainingHealthSummary(),
            analytics: analytics.getAnalyticsSummary(),
            nutrition: nutrition.getNutritionSummary()
        )
    }

    /**
     * Update User model with latest HealthKit data.
     */
    func updateUserWithHealthKitData(user: User) async {
        // Sync profile data
        await profile.syncWithUserProfile(user: user)

        // Update user with latest HealthKit data if available
        if dashboard.todaySteps > 0 {
            // HealthKit steps available - could update user activity metrics
        }

        if training.currentHeartRate != nil {
            // Could update user's current health status based on heart rate data
        }

        user.lastActiveDate = Date()
        Logger.info("User model updated with latest HealthKit data")
    }

    // MARK: - Migration Helpers

    /**
     * Check if all specialized services are functioning correctly.
     */
    func validateServiceHealth() -> ServiceHealthStatus {
        return ServiceHealthStatus(
            coreHealthy: core.isAuthorized,
            dashboardHealthy: !dashboard.isLoading && dashboard.error == nil,
            profileHealthy: !profile.isLoading && profile.error == nil,
            trainingHealthy: !training.isLoading && training.error == nil,
            analyticsHealthy: !analytics.isLoading && analytics.error == nil,
            nutritionHealthy: !nutrition.isLoading && nutrition.error == nil
        )
    }

    // MARK: - Cleanup
    deinit {
        Logger.info("HealthKitService facade deinitialized")
    }
}

// MARK: - Supporting Types

struct UnifiedHealthSummary {
    let dashboard: DashboardHealthSummary
    let profile: ProfileHealthSummary
    let training: TrainingHealthSummary
    let analytics: AnalyticsHealthSummary
    let nutrition: NutritionDisplaySummary
}

struct ServiceHealthStatus {
    let coreHealthy: Bool
    let dashboardHealthy: Bool
    let profileHealthy: Bool
    let trainingHealthy: Bool
    let analyticsHealthy: Bool
    let nutritionHealthy: Bool

    var allHealthy: Bool {
        return coreHealthy && dashboardHealthy && profileHealthy &&
               trainingHealthy && analyticsHealthy && nutritionHealthy
    }

    var healthyServicesCount: Int {
        return [coreHealthy, dashboardHealthy, profileHealthy,
                trainingHealthy, analyticsHealthy, nutritionHealthy].filter { $0 }.count
    }
}