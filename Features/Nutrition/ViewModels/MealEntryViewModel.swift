import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for MealEntryView with clean separation of concerns.
 *
 * Manages meal entry state, nutrition calculations, and coordinates with multiple services.
 * Handles complex business logic including duplicate detection and HealthKit integration.
 */
@MainActor
@Observable
class MealEntryViewModel {

    // MARK: - State
    var gramsConsumed: Double = 100
    var servingCount: Double = 1
    var inputMode: PortionInputMode = .grams
    var selectedMealTypes: Set<String> = ["breakfast"]
    var saveErrorMessage: String?
    var isLoading = false
    
    // MARK: - Dependencies
    private let unitSettings: UnitSettings
    private let healthKitService: HealthKitService
    private let activityLoggerService: ActivityLoggerService
    
    // MARK: - Computed Properties
    
    /**
     * Effective grams based on current input mode.
     */
    var effectiveGrams: Double {
        switch inputMode {
        case .grams:
            return gramsConsumed
        case .serving:
            return max(servingCount, 0) * (currentFood?.servingSizeGramsOrDefault ?? 100)
        }
    }
    
    /**
     * Whether the entry is valid for saving.
     */
    var isValidEntry: Bool {
        return effectiveGrams > 0 && !selectedMealTypes.isEmpty
    }
    
    /**
     * Current calculated nutrition based on effective grams.
     */
    var calculatedNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double)? {
        guard let food = currentFood, effectiveGrams > 0 else { return nil }
        return food.calculateNutrition(for: effectiveGrams)
    }
    
    /**
     * Unit-aware display binding for portion input.
     */
    var displayBinding: Binding<Double> {
        Binding<Double>(
            get: {
                switch self.unitSettings.unitSystem {
                case .metric:
                    return self.gramsConsumed
                case .imperial:
                    return UnitsConverter.gramToOz(self.gramsConsumed)
                }
            },
            set: { newValue in
                switch self.unitSettings.unitSystem {
                case .metric:
                    self.gramsConsumed = newValue
                case .imperial:
                    self.gramsConsumed = UnitsConverter.ozToGram(newValue)
                }
            }
        )
    }
    
    // MARK: - Private Properties
    private var currentFood: Food?
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    @MainActor
    init(
        unitSettings: UnitSettings,
        healthKitService: HealthKitService,
        activityLoggerService: ActivityLoggerService
    ) {
        self.unitSettings = unitSettings
        self.healthKitService = healthKitService
        self.activityLoggerService = activityLoggerService
    }
    
    // MARK: - Public Methods
    
    /**
     * Sets the food context for this meal entry.
     */
    func setFood(_ food: Food, modelContext: ModelContext) {
        self.currentFood = food
        self.modelContext = modelContext
    }
    
    /**
     * Updates grams consumed with validation.
     */
    func updateGramsConsumed(_ grams: Double) {
        gramsConsumed = max(0, grams)
    }
    
    /**
     * Updates serving count with validation.
     */
    func updateServingCount(_ count: Double) {
        servingCount = max(0, count)
    }
    
    /**
     * Toggles input mode between grams and servings.
     */
    func setInputMode(_ mode: PortionInputMode) {
        inputMode = mode
    }
    
    /**
     * Updates selected meal types.
     */
    func updateSelectedMealTypes(_ mealTypes: Set<String>) {
        selectedMealTypes = mealTypes
    }
    
    /**
     * Toggles meal type selection.
     */
    func toggleMealType(_ mealType: String) {
        if selectedMealTypes.contains(mealType) {
            selectedMealTypes.remove(mealType)
        } else {
            selectedMealTypes.insert(mealType)
        }
    }
    
    /**
     * Toggles food favorite status.
     */
    func toggleFoodFavorite() {
        guard let food = currentFood else { return }
        
        food.toggleFavorite()
        
        do {
            try modelContext?.save()
            HapticManager.shared.impact(.light)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
    
    /**
     * Saves meal entry with comprehensive business logic.
     */
    func saveMealEntry() async -> Result<Void, MealEntryError> {
        guard let food = currentFood,
              let modelContext = modelContext else {
            return .failure(.invalidContext)
        }
        
        guard isValidEntry else {
            return .failure(.invalidEntry)
        }
        
        isLoading = true
        saveErrorMessage = nil
        
        do {
            // Create entries for each selected meal type
            for mealType in selectedMealTypes {
                let entry = NutritionEntry(
                    food: food,
                    gramsConsumed: effectiveGrams,
                    mealType: mealType
                )
                modelContext.insert(entry)
            }
            
            // Record food usage
            food.recordUsage()
            
            // Save to SwiftData
            try modelContext.save()
            
            // Activity logging is handled by MealEntryView to avoid duplication
            
            // Sync to HealthKit
            let dailyTotals = try await calculateDailyTotals(for: Date())
            let healthKitSuccess = await healthKitService.saveNutritionData(
                calories: dailyTotals.calories,
                protein: dailyTotals.protein,
                carbs: dailyTotals.carbs,
                fat: dailyTotals.fat,
                date: Date()
            )
            
            if healthKitSuccess {
                Logger.info("Daily nutrition data successfully synced to HealthKit")
            }
            
            HapticManager.shared.notification(.success)
            isLoading = false
            
            return .success(())
            
        } catch {
            saveErrorMessage = error.localizedDescription
            isLoading = false
            return .failure(.saveFailed(error))
        }
    }
    
    /**
     * Gets suggested quick portion amounts based on food type.
     */
    func getSuggestedQuickAmounts() -> [Int] {
        guard let food = currentFood else { return [] }
        
        let name = food.displayName.lowercased()
        
        if name.contains("muz") || name.contains("banana") {
            return [80, 100, 120, 150, 200]
        } else if name.contains("yoğurt") || name.contains("yoghurt") || name.contains("yogurt") {
            return [100, 150, 200, 250]
        } else if name.contains("süt") || name.contains("milk") {
            return [200, 250, 300]
        } else if name.contains("pirinç") || name.contains("rice") {
            return [50, 100, 150, 200, 250]
        } else if name.contains("tavuk") || name.contains("chicken") {
            return [100, 120, 150, 180, 200]
        }
        
        return []
    }
    
    /**
     * Gets formatted nutrition display text.
     */
    func getFormattedNutrition() -> String? {
        guard let nutrition = calculatedNutrition else { return nil }
        
        return "\(NutritionKeys.CustomFood.protein.localized): \(Int(nutrition.protein))\(NutritionKeys.Units.g.localized) • \(NutritionKeys.CustomFood.carbs.localized): \(Int(nutrition.carbs))\(NutritionKeys.Units.g.localized) • \(NutritionKeys.CustomFood.fat.localized): \(Int(nutrition.fat))\(NutritionKeys.Units.g.localized)"
    }
    
    /**
     * Resets the view model to initial state.
     */
    func reset() {
        gramsConsumed = 100
        servingCount = 1
        inputMode = .grams
        selectedMealTypes = ["breakfast"]
        saveErrorMessage = nil
        isLoading = false
        currentFood = nil
        modelContext = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchCurrentUser() throws -> User? {
        guard let modelContext = modelContext else { throw MealEntryError.invalidContext }
        
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\User.createdAt)])
        let users = try modelContext.fetch(descriptor)
        return users.first
    }
    
    private func calculateMealTotals(for mealType: String, on date: Date) async throws -> MealTotals {
        guard let modelContext = modelContext else { throw MealEntryError.invalidContext }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = #Predicate<NutritionEntry> { entry in
            entry.mealType == mealType &&
            entry.date >= startOfDay &&
            entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<NutritionEntry>(predicate: predicate)
        let allEntries = try modelContext.fetch(descriptor)
        
        // Remove duplicates
        let uniqueEntries = removeDuplicateEntries(allEntries)
        
        let totalCalories = uniqueEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = uniqueEntries.reduce(0) { $0 + $1.protein }
        let totalCarbs = uniqueEntries.reduce(0) { $0 + $1.carbs }
        let totalFat = uniqueEntries.reduce(0) { $0 + $1.fat }
        
        return MealTotals(
            foodCount: uniqueEntries.count,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
    }
    
    private func calculateDailyTotals(for date: Date) async throws -> DailyTotals {
        guard let modelContext = modelContext else { throw MealEntryError.invalidContext }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = #Predicate<NutritionEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<NutritionEntry>(predicate: predicate)
        let allEntries = try modelContext.fetch(descriptor)
        
        // Remove duplicates
        let uniqueEntries = removeDuplicateEntries(allEntries)
        
        let totalCalories = uniqueEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = uniqueEntries.reduce(0) { $0 + $1.protein }
        let totalCarbs = uniqueEntries.reduce(0) { $0 + $1.carbs }
        let totalFat = uniqueEntries.reduce(0) { $0 + $1.fat }
        
        return DailyTotals(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
    }
    
    private func removeDuplicateEntries(_ entries: [NutritionEntry]) -> [NutritionEntry] {
        var uniqueEntries: [NutritionEntry] = []
        var seenEntries: Set<String> = []
        
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let roughTimestamp = Int(entry.date.timeIntervalSince1970 / 60)
            let uniqueKey = "\(entry.food?.id.uuidString ?? "unknown")_\(entry.gramsConsumed)_\(entry.mealType)_\(roughTimestamp)"
            
            if !seenEntries.contains(uniqueKey) {
                seenEntries.insert(uniqueKey)
                uniqueEntries.append(entry)
            }
        }
        
        return uniqueEntries
    }
    
    private func getMealDisplayName(_ mealType: String) -> String {
        let mealTypes = [
            ("breakfast", NutritionKeys.MealEntry.MealTypes.breakfast.localized),
            ("lunch", NutritionKeys.MealEntry.MealTypes.lunch.localized),
            ("dinner", NutritionKeys.MealEntry.MealTypes.dinner.localized),
            ("snack", NutritionKeys.MealEntry.MealTypes.snack.localized)
        ]
        
        return mealTypes.first { $0.0 == mealType }?.1 ?? mealType
    }
}

// MARK: - Supporting Types

/**
 * Portion input mode enumeration.
 */
enum PortionInputMode: String, CaseIterable {
    case grams, serving
}

/**
 * Meal totals structure.
 */
struct MealTotals {
    let foodCount: Int
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

/**
 * Daily totals structure.
 */
struct DailyTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

/**
 * Meal entry errors.
 */
enum MealEntryError: LocalizedError {
    case invalidContext
    case invalidEntry
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Invalid model context"
        case .invalidEntry:
            return "Invalid meal entry data"
        case .saveFailed(let error):
            return "Failed to save meal entry: \(error.localizedDescription)"
        }
    }
}