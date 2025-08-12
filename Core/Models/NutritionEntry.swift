import SwiftData
import Foundation

@Model
final class NutritionEntry {
    var id: UUID
    var date: Date
    var mealType: String           // "breakfast", "lunch" etc.
    var consumedAt: Date
    
    // Food bilgisi
    var food: Food?
    var foodName: String          // Food silinirse diye yedek
    
    // Porsiyon bilgisi
    var gramsConsumed: Double     // Tüketilen gram
    
    // Hesaplanmış besin değerleri (performans için)
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(food: Food, gramsConsumed: Double, mealType: String, date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType
        self.consumedAt = Date()
        
        self.food = food
        self.foodName = food.displayName
        self.gramsConsumed = gramsConsumed
        
        // Besin değerlerini hesapla
        let nutrition = food.calculateNutrition(for: gramsConsumed)
        self.calories = nutrition.calories
        self.protein = nutrition.protein
        self.carbs = nutrition.carbs
        self.fat = nutrition.fat
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Computed Properties
extension NutritionEntry {
    var displayMealType: String {
        switch mealType {
        case "breakfast": return LocalizationKeys.Nutrition.MealEntry.MealTypes.breakfast.localized
        case "lunch": return LocalizationKeys.Nutrition.MealEntry.MealTypes.lunch.localized
        case "dinner": return LocalizationKeys.Nutrition.MealEntry.MealTypes.dinner.localized
        case "snack": return LocalizationKeys.Nutrition.MealEntry.MealTypes.snack.localized
        default: return mealType.capitalized
        }
    }
}
