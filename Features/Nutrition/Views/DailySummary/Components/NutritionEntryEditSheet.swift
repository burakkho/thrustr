import SwiftUI

struct NutritionEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var grams: Double
    @State private var meal: String
    @State private var saveErrorMessage: String? = nil
    let entry: NutritionEntry
    
    init(entry: NutritionEntry) {
        self.entry = entry
        _grams = State(initialValue: entry.gramsConsumed)
        _meal = State(initialValue: entry.mealType)
    }
    
    var body: some View {
        NavigationStack {
            editForm
                .navigationTitle(LocalizationKeys.Common.edit.localized)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        saveButton
                    }
                }
        }
        .presentationDetents([.medium])
    }
    
    private var editForm: some View {
        Form {
            portionSection
            mealSection
        }
    }
    
    private var portionSection: some View {
        Section(header: Text(LocalizationKeys.Nutrition.MealEntry.portion.localized)) {
            TextField(
                LocalizationKeys.Nutrition.MealEntry.portionGrams.localized,
                value: $grams,
                format: .number
            )
            .keyboardType(.decimalPad)
        }
    }
    
    private var mealSection: some View {
        Section(header: Text(LocalizationKeys.Nutrition.MealEntry.meal.localized)) {
            Picker("", selection: $meal) {
                Text(LocalizationKeys.Nutrition.MealEntry.MealTypes.breakfast.localized).tag("breakfast")
                Text(LocalizationKeys.Nutrition.MealEntry.MealTypes.lunch.localized).tag("lunch")
                Text(LocalizationKeys.Nutrition.MealEntry.MealTypes.dinner.localized).tag("dinner")
                Text(LocalizationKeys.Nutrition.MealEntry.MealTypes.snack.localized).tag("snack")
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var cancelButton: some View {
        Button(LocalizationKeys.Common.cancel.localized) {
            dismiss()
        }
    }
    
    private var saveButton: some View {
        Button(LocalizationKeys.Common.save.localized) {
            applyChanges()
        }
        .disabled(grams <= 0)
    }
    
    private func applyChanges() {
        guard grams > 0 else { return }
        
        let oldGrams = entry.gramsConsumed
        entry.gramsConsumed = grams
        entry.mealType = meal
        
        // Recalculate cached nutrition
        if let food = entry.food {
            let nutrition = food.calculateNutrition(for: grams)
            entry.calories = nutrition.calories
            entry.protein = nutrition.protein
            entry.carbs = nutrition.carbs
            entry.fat = nutrition.fat
        } else if oldGrams > 0 {
            let factor = grams / oldGrams
            entry.calories *= factor
            entry.protein *= factor
            entry.carbs *= factor
            entry.fat *= factor
        }
        
        entry.updatedAt = Date()
        
        do {
            try modelContext.save()
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let food = Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat)
    let entry = NutritionEntry(food: food, gramsConsumed: 150, mealType: "lunch", date: Date())
    
    NutritionEntryEditSheet(entry: entry)
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
