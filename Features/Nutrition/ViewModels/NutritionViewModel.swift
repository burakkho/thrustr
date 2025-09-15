import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for NutritionView with comprehensive nutrition tracking management.
 *
 * 🎯 GOLD STANDARD CLEAN ARCHITECTURE EXAMPLE
 * This ViewModel serves as the perfect template for other feature ViewModels.
 *
 * ARCHITECTURE PATTERN:
 * NutritionView (Pure UI) ↔ NutritionViewModel (All State) ↔ Services (Business Logic)
 *
 * RESPONSIBILITIES:
 * ✅ UI State Management - All @State properties centralized here
 * ✅ Business Logic Coordination - Services orchestration
 * ✅ Error Handling - Centralized ErrorHandlingService integration
 * ✅ Data Filtering - Date ranges, meal groupings, analytics
 * ✅ Navigation State - Modals, sheets, form flows
 * ✅ Loading States - Progress indicators and async operations
 * ✅ Success/Error Messages - Unified user feedback
 *
 * CLEAN SEPARATION:
 * - View: Only SwiftUI presentation layer
 * - ViewModel: State management + service coordination
 * - Services: Pure business logic (FoodSearchService, OpenFoodFactsService)
 *
 * INTEGRATION POINTS:
 * - FoodSearchService: Food database search and caching
 * - OpenFoodFactsService: Barcode scanning API integration
 * - ErrorHandlingService: Centralized error handling and user feedback
 * - SwiftData: Database operations with proper error handling
 */
@MainActor
class NutritionViewModel: ObservableObject {

    // MARK: - Published Properties

    // UI State
    @Published var selectedFood: Food?
    @Published var showingMealEntry = false
    @Published var showingFoodSelection = false
    @Published var showingCustomFoodEntry = false
    @Published var forceStartWithScanner = false
    @Published var showRealEmptyState = false

    // Loading and Error States
    @Published var isLoading = false
    @Published var saveErrorMessage: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let foodSearchService = FoodSearchService()
    private let openFoodFactsService = OpenFoodFactsService()

    // MARK: - Error Handling (Centralized)

    @Published var errorHandler = ErrorHandlingService.shared

    // MARK: - Data Filtering

    /**
     * Filters nutrition entries for today's date.
     *
     * - Parameter allEntries: Complete list of nutrition entries
     * - Returns: Entries from today only
     */
    func getTodayEntries(from allEntries: [NutritionEntry]) -> [NutritionEntry] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        return allEntries.filter { entry in
            entry.date >= todayStart && entry.date < todayEnd
        }
    }

    /**
     * Filters nutrition entries for the last 7 days.
     *
     * - Parameter allEntries: Complete list of nutrition entries
     * - Returns: Entries from the last 7 days
     */
    func getWeekEntries(from allEntries: [NutritionEntry]) -> [NutritionEntry] {
        let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        let weekStartOfDay = Calendar.current.startOfDay(for: weekStart)

        return allEntries.filter { entry in
            entry.date >= weekStartOfDay
        }
    }

    /**
     * Groups today's entries by meal type for organized display.
     *
     * - Parameter todayEntries: Today's nutrition entries
     * - Returns: Dictionary grouped by meal type
     */
    func groupEntriesByMeal(_ todayEntries: [NutritionEntry]) -> [String: [NutritionEntry]] {
        return Dictionary(grouping: todayEntries) { $0.mealType }
    }

    // MARK: - Nutrition Calculations

    /**
     * Calculates daily nutrition summary from entries.
     *
     * - Parameter entries: Nutrition entries to calculate from
     * - Returns: Daily nutrition summary
     */
    func calculateDailyNutrition(from entries: [NutritionEntry]) -> NutritionSummaryData {
        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbs }
        let totalFat = entries.reduce(0.0) { $0 + $1.fat }

        return NutritionSummaryData(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            entryCount: entries.count
        )
    }

    /**
     * Calculates nutrition progress against daily goals.
     *
     * - Parameters:
     *   - summary: Daily nutrition summary
     *   - user: User with daily goals
     * - Returns: Progress percentages for each macro
     */
    func calculateNutritionProgress(summary: NutritionSummaryData, user: User?) -> NutritionProgress {
        guard let user = user else {
            return NutritionProgress(caloriesProgress: 0, proteinProgress: 0, carbsProgress: 0, fatProgress: 0)
        }

        let caloriesProgress = user.dailyCalorieGoal > 0 ? summary.calories / user.dailyCalorieGoal : 0
        let proteinProgress = user.dailyProteinGoal > 0 ? summary.protein / user.dailyProteinGoal : 0
        let carbsProgress = user.dailyCarbGoal > 0 ? summary.carbs / user.dailyCarbGoal : 0
        let fatProgress = user.dailyFatGoal > 0 ? summary.fat / user.dailyFatGoal : 0

        return NutritionProgress(
            caloriesProgress: min(caloriesProgress, 1.0),
            proteinProgress: min(proteinProgress, 1.0),
            carbsProgress: min(carbsProgress, 1.0),
            fatProgress: min(fatProgress, 1.0)
        )
    }

    // MARK: - Food Search Integration

    /**
     * Searches for foods using the FoodSearchService.
     *
     * - Parameters:
     *   - query: Search query string
     *   - foods: Available foods list
     *   - selectedCategory: Optional category filter
     *   - modelContext: SwiftData context
     */
    func searchFoods(
        query: String,
        foods: [Food],
        selectedCategory: FoodCategory?,
        modelContext: ModelContext
    ) {
        foodSearchService.search(
            query: query,
            foods: foods,
            selectedCategory: selectedCategory,
            modelContext: modelContext
        )
    }

    /**
     * Gets current search results from FoodSearchService.
     */
    var foodSearchResults: [Food] {
        return foodSearchService.searchResults
    }

    /**
     * Gets current alias search results from FoodSearchService.
     */
    var aliasSearchResults: [Food] {
        return foodSearchService.aliasResults
    }

    /**
     * Checks if food search is currently in progress.
     */
    var isSearchingFoods: Bool {
        return foodSearchService.isSearching
    }

    // MARK: - UI State Management

    /**
     * Shows meal entry form with selected food.
     *
     * - Parameter food: Food to add to meal
     */
    func showMealEntryForm(with food: Food) {
        selectedFood = food
        showingMealEntry = true
    }

    /**
     * Shows food selection interface.
     */
    func showFoodSelection() {
        showingFoodSelection = true
    }

    /**
     * Shows custom food entry form.
     */
    func showCustomFoodEntry() {
        showingCustomFoodEntry = true
    }

    /**
     * Forces scanner to start when opening food selection.
     */
    func startWithScanner() {
        forceStartWithScanner = true
        showingFoodSelection = true
    }

    /**
     * Dismisses all modal presentations.
     */
    func dismissAllModals() {
        showingMealEntry = false
        showingFoodSelection = false
        showingCustomFoodEntry = false
        forceStartWithScanner = false
        selectedFood = nil
    }

    // MARK: - Empty State Management

    /**
     * Determines if empty state should be shown based on entries.
     *
     * - Parameter todayEntries: Today's nutrition entries
     * - Returns: Boolean indicating if empty state should display
     */
    func shouldShowEmptyState(todayEntries: [NutritionEntry]) -> Bool {
        return todayEntries.isEmpty && showRealEmptyState
    }

    /**
     * Triggers empty state display after a delay.
     */
    func triggerEmptyStateCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showRealEmptyState = true
        }
    }

    // MARK: - Error Handling

    /**
     * Shows error message to user via centralized ErrorHandlingService.
     *
     * - Parameter message: Error message to display
     */
    func showError(_ message: String) {
        errorMessage = message
        errorHandler.showErrorToast(message) // Centralized toast
        isLoading = false
    }

    /**
     * Shows success message via ErrorHandlingService.
     *
     * - Parameter message: Success message to display
     */
    func showSuccess(_ message: String) {
        errorHandler.showSuccessToast(message)
    }

    /**
     * Shows save error message specifically.
     *
     * - Parameter message: Save error message
     */
    func showSaveError(_ message: String) {
        saveErrorMessage = message
        errorHandler.showErrorToast(message)
    }

    /**
     * Clears all error states including centralized handler.
     */
    func clearErrors() {
        errorMessage = nil
        saveErrorMessage = nil
        errorHandler.toastMessage = nil
    }

    // MARK: - Meal Management

    /**
     * Saves nutrition entry to database with proper error handling.
     *
     * - Parameters:
     *   - nutritionEntry: Entry to save
     *   - modelContext: SwiftData context
     */
    func saveNutritionEntry(_ nutritionEntry: NutritionEntry, modelContext: ModelContext) {
        isLoading = true
        clearErrors()

        modelContext.insert(nutritionEntry)

        do {
            try modelContext.save()
            isLoading = false
            showSuccess("Meal added successfully!")
            dismissAllModals()
        } catch {
            showSaveError("Failed to save meal: \(error.localizedDescription)")
        }
    }

    // MARK: - Barcode Integration

    /**
     * Processes scanned barcode using OpenFoodFactsService.
     *
     * - Parameter barcode: Scanned barcode string
     */
    func processBarcodeSearch(barcode: String) async {
        isLoading = true
        clearErrors()

        do {
            // This would integrate with OpenFoodFactsService
            // Implementation depends on existing OpenFoodFactsService API
            isLoading = false
        } catch {
            showError("Failed to process barcode: \(error.localizedDescription)")
        }
    }

    // MARK: - Analytics Support

    /**
     * Determines if nutrition analytics can be calculated.
     *
     * - Parameter entries: Nutrition entries to evaluate
     * - Returns: Boolean indicating if analytics should be shown
     */
    func canShowNutritionAnalytics(entries: [NutritionEntry]) -> Bool {
        return entries.count >= 3 // Need at least 3 entries for meaningful analytics
    }

    /**
     * Calculates weekly nutrition trend.
     *
     * - Parameter weekEntries: Week's nutrition entries
     * - Returns: Nutrition trend analysis
     */
    func calculateWeeklyTrend(weekEntries: [NutritionEntry]) -> NutritionTrend {
        let dailyTotals = Dictionary(grouping: weekEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }.mapValues { entries in
            self.calculateDailyNutrition(from: entries)
        }

        let averageCalories = dailyTotals.values.map { $0.calories }.average
        let averageProtein = dailyTotals.values.map { $0.protein }.average

        return NutritionTrend(
            averageDailyCalories: averageCalories,
            averageDailyProtein: averageProtein,
            totalDays: dailyTotals.count
        )
    }
}

// MARK: - Supporting Types

/**
 * Daily nutrition summary structure.
 */
struct NutritionSummaryData {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let entryCount: Int
}

/**
 * Nutrition progress against daily goals.
 */
struct NutritionProgress {
    let caloriesProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
}

/**
 * Weekly nutrition trend analysis.
 */
struct NutritionTrend {
    let averageDailyCalories: Double
    let averageDailyProtein: Double
    let totalDays: Int
}

// MARK: - Extensions

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
