import Foundation
import HealthKit

/**
 * HealthKit service specialized for Nutrition feature requirements.
 *
 * Manages nutrition-related HealthKit operations including dietary data
 * recording, macro nutrient tracking, and nutrition goal monitoring.
 * Supports comprehensive nutrition logging integration with HealthKit.
 *
 * Features:
 * - Dietary data writing (calories, macros)
 * - Nutrition tracking integration
 * - Meal logging support
 * - Macro nutrient analysis
 * - Nutrition goal tracking
 * - Daily nutrition summaries
 */
final class HealthKitNutritionService {
    static let shared = HealthKitNutritionService()

    // MARK: - Dependencies
    private let core = HealthKitCore.shared

    // MARK: - Nutrition State
    var isLoading = false
    var error: Error?
    var lastNutritionSync: Date = Date.distantPast

    // MARK: - Daily Nutrition Tracking
    var todayCalories: Double = 0
    var todayProtein: Double = 0
    var todayCarbs: Double = 0
    var todayFat: Double = 0

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /**
     * Save nutrition data to HealthKit.
     *
     * Records comprehensive nutrition information including calories and
     * macronutrients with proper metadata for meal tracking integration.
     */
    func saveNutritionData(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date(),
        mealType: MealType? = nil
    ) async -> Bool {
        guard core.isAuthorized else {
            Logger.warning("HealthKit not authorized for nutrition saving")
            return false
        }

        var metadata: [String: Any] = [HKMetadataKeyWasUserEntered: true]

        // Add meal type to metadata if provided
        if let mealType = mealType {
            metadata[HKMetadataKeyFoodType] = mealType.healthKitValue
        }

        let calorieSample = HKQuantitySample(
            type: core.dietaryEnergyType,
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            start: date,
            end: date,
            metadata: metadata
        )

        let proteinSample = HKQuantitySample(
            type: core.dietaryProteinType,
            quantity: HKQuantity(unit: .gram(), doubleValue: protein),
            start: date,
            end: date,
            metadata: metadata
        )

        let carbsSample = HKQuantitySample(
            type: core.dietaryCarbohydratesType,
            quantity: HKQuantity(unit: .gram(), doubleValue: carbs),
            start: date,
            end: date,
            metadata: metadata
        )

        let fatSample = HKQuantitySample(
            type: core.dietaryFatTotalType,
            quantity: HKQuantity(unit: .gram(), doubleValue: fat),
            start: date,
            end: date,
            metadata: metadata
        )

        let samples = [calorieSample, proteinSample, carbsSample, fatSample]

        do {
            try await core.healthStore.save(samples)
            Logger.success("Nutrition data saved to HealthKit: \(calories) kcal, P:\(protein)g, C:\(carbs)g, F:\(fat)g")

            // Update today's totals if saving for today
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                await updateTodaysNutrition()
            }

            lastNutritionSync = Date()
            return true
        } catch {
            Logger.error("Failed to save nutrition data to HealthKit: \(error)")
            self.error = error
            return false
        }
    }

    /**
     * Save individual food item to HealthKit.
     *
     * Records nutrition data for a specific food item with portion information.
     */
    func saveFoodItem(
        food: Food,
        portionSize: Double,
        mealType: MealType,
        date: Date = Date()
    ) async -> Bool {
        // Calculate nutrition values based on portion size
        let calories = food.calories * portionSize / 100.0
        let protein = food.protein * portionSize / 100.0
        let carbs = food.carbs * portionSize / 100.0
        let fat = food.fat * portionSize / 100.0

        return await saveNutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: date,
            mealType: mealType
        )
    }

    /**
     * Save meal to HealthKit.
     *
     * Records all food items in a meal as individual HealthKit entries
     * with proper meal type categorization.
     */
    func saveMeal(
        foods: [(Food, Double)], // Food and portion size pairs
        mealType: MealType,
        date: Date = Date()
    ) async -> Bool {
        var allSaved = true

        for (food, portionSize) in foods {
            let saved = await saveFoodItem(
                food: food,
                portionSize: portionSize,
                mealType: mealType,
                date: date
            )
            if !saved {
                allSaved = false
            }
        }

        if allSaved {
            Logger.success("Meal saved to HealthKit: \(mealType.displayName), \(foods.count) items")
        } else {
            Logger.warning("Some items in meal failed to save to HealthKit")
        }

        return allSaved
    }

    // MARK: - Nutrition Data Reading

    /**
     * Load today's nutrition data from HealthKit.
     *
     * Retrieves and sums all nutrition entries for the current day
     * to provide daily nutrition totals.
     */
    func loadTodaysNutrition() async {
        isLoading = true
        defer { isLoading = false }

        await updateTodaysNutrition()
    }

    private func updateTodaysNutrition() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        // Read all nutrition data for today concurrently
        async let calories = readTodaysNutrientData(type: core.dietaryEnergyType, unit: .kilocalorie(), startOfDay: startOfDay, endOfDay: now)
        async let protein = readTodaysNutrientData(type: core.dietaryProteinType, unit: .gram(), startOfDay: startOfDay, endOfDay: now)
        async let carbs = readTodaysNutrientData(type: core.dietaryCarbohydratesType, unit: .gram(), startOfDay: startOfDay, endOfDay: now)
        async let fat = readTodaysNutrientData(type: core.dietaryFatTotalType, unit: .gram(), startOfDay: startOfDay, endOfDay: now)

        let results = await (calories, protein, carbs, fat)

        todayCalories = results.0
        todayProtein = results.1
        todayCarbs = results.2
        todayFat = results.3

        Logger.success("Today's nutrition loaded: \(todayCalories) kcal, P:\(todayProtein)g, C:\(todayCarbs)g, F:\(todayFat)g")
    }

    private func readTodaysNutrientData(
        type: HKQuantityType,
        unit: HKUnit,
        startOfDay: Date,
        endOfDay: Date
    ) async -> Double {
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading nutrition data for \(type.identifier): \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            core.healthStore.execute(query)
        }
    }

    /**
     * Get nutrition history for analytics.
     *
     * Retrieves historical nutrition data for trend analysis and progress tracking.
     */
    func getNutritionHistory(daysBack: Int = 30) async -> [NutritionHistoryPoint] {
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
                quantityType: core.dietaryEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    Logger.error("Error reading nutrition history: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                var historyPoints: [NutritionHistoryPoint] = []

                collection?.enumerateStatistics(from: startDate, to: endDate) { statistic, _ in
                    if let sum = statistic.sumQuantity() {
                        let calories = sum.doubleValue(for: .kilocalorie())
                        let point = NutritionHistoryPoint(
                            date: statistic.startDate,
                            calories: calories,
                            protein: 0, // Would need separate queries for each macro
                            carbs: 0,
                            fat: 0
                        )
                        historyPoints.append(point)
                    }
                }

                Logger.success("Retrieved \(historyPoints.count) days of nutrition history")
                continuation.resume(returning: historyPoints)
            }

            core.healthStore.execute(query)
        }
    }

    /**
     * Get nutrition data by meal type.
     *
     * Retrieves nutrition breakdown by meal type (breakfast, lunch, dinner, snacks)
     * for detailed meal analysis.
     */
    func getNutritionByMealType(date: Date = Date()) async -> [MealType: NutritionSummary] {
        var mealNutrition: [MealType: NutritionSummary] = [:]

        for mealType in MealType.allCases {
            let nutrition = await getNutritionForMeal(mealType: mealType, date: date)
            mealNutrition[mealType] = nutrition
        }

        return mealNutrition
    }

    private func getNutritionForMeal(mealType: MealType, date: Date) async -> NutritionSummary {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

            let datePredicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let mealPredicate = HKQuery.predicateForObjects(
                withMetadataKey: HKMetadataKeyFoodType,
                operatorType: .equalTo,
                value: mealType.healthKitValue
            )

            let compoundPredicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: [datePredicate, mealPredicate]
            )

            let query = HKStatisticsQuery(
                quantityType: core.dietaryEnergyType,
                quantitySamplePredicate: compoundPredicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    Logger.error("Error reading nutrition for meal \(mealType.rawValue): \(error)")
                    continuation.resume(returning: NutritionSummary.empty)
                    return
                }

                let calories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                // Note: Would need separate queries for protein, carbs, fat
                let summary = NutritionSummary(
                    calories: calories,
                    protein: 0,
                    carbs: 0,
                    fat: 0
                )

                continuation.resume(returning: summary)
            }

            core.healthStore.execute(query)
        }
    }

    // MARK: - Nutrition Analytics

    /**
     * Calculate nutrition goal progress.
     *
     * Compares today's nutrition intake against user's daily goals.
     */
    func calculateNutritionProgress(user: User) -> NutritionProgress {
        let caloriesProgress = user.dailyCalorieGoal > 0 ? todayCalories / user.dailyCalorieGoal : 0
        let proteinProgress = user.dailyProteinGoal > 0 ? todayProtein / user.dailyProteinGoal : 0
        let carbsProgress = user.dailyCarbGoal > 0 ? todayCarbs / user.dailyCarbGoal : 0
        let fatProgress = user.dailyFatGoal > 0 ? todayFat / user.dailyFatGoal : 0

        return NutritionProgress(
            caloriesProgress: min(1.0, caloriesProgress),
            proteinProgress: min(1.0, proteinProgress),
            carbsProgress: min(1.0, carbsProgress),
            fatProgress: min(1.0, fatProgress)
        )
    }

    /**
     * Get nutrition summary for display.
     */
    func getNutritionSummary() -> NutritionDisplaySummary {
        return NutritionDisplaySummary(
            todayCalories: Int(todayCalories),
            todayProtein: todayProtein,
            todayCarbs: todayCarbs,
            todayFat: todayFat,
            lastSynced: lastNutritionSync
        )
    }

    // MARK: - Cleanup
    deinit {
        Logger.info("HealthKitNutritionService deinitialized")
    }
}

// MARK: - Supporting Types

struct NutritionSummary {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    static let empty = NutritionSummary(calories: 0, protein: 0, carbs: 0, fat: 0)
}


struct NutritionHistoryPoint {
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct NutritionDisplaySummary {
    let todayCalories: Int
    let todayProtein: Double
    let todayCarbs: Double
    let todayFat: Double
    let lastSynced: Date
}

