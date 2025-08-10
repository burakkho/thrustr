import SwiftUI
import SwiftData

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var gramsConsumed: Double = 100
    @State private var selectedMealType = "breakfast"
    
    private var mealTypes: [(String, String)] {
        [
            ("breakfast", LocalizationKeys.Nutrition.MealEntry.MealTypes.breakfast.localized),
            ("lunch", LocalizationKeys.Nutrition.MealEntry.MealTypes.lunch.localized),
            ("dinner", LocalizationKeys.Nutrition.MealEntry.MealTypes.dinner.localized),
            ("snack", LocalizationKeys.Nutrition.MealEntry.MealTypes.snack.localized)
        ]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Food bilgisi
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(food.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Favori butonu
                        Button {
                            food.toggleFavorite()
                        } label: {
                            Image(systemName: food.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(food.isFavorite ? .red : .gray)
                                .font(.title3)
                        }
                    }
                    
                    Text(LocalizationKeys.Nutrition.MealEntry.per100gCalories.localized(with: Int(food.calories)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Porsiyon girişi
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Nutrition.MealEntry.portion.localized)
                        .font(.headline)
                    
                    TextField(LocalizationKeys.Nutrition.MealEntry.portionGrams.localized, value: $gramsConsumed, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                // Öğün seçimi
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Nutrition.MealEntry.meal.localized)
                        .font(.headline)
                    
                    Picker(LocalizationKeys.Nutrition.MealEntry.meal.localized, selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.0) { type, name in
                            Text(name).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Hesaplanan değerler
                if gramsConsumed > 0 {
                    let nutrition = food.calculateNutrition(for: gramsConsumed)
                    VStack(spacing: 4) {
                        Text(LocalizationKeys.Nutrition.MealEntry.total.localized(with: Int(nutrition.calories)))
                            .font(.headline)
                        Text("Protein: \(Int(nutrition.protein))\(LocalizationKeys.Nutrition.Units.g.localized) • Carbs: \(Int(nutrition.carbs))\(LocalizationKeys.Nutrition.Units.g.localized) • Fat: \(Int(nutrition.fat))\(LocalizationKeys.Nutrition.Units.g.localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Ekle butonu
                Button(LocalizationKeys.Nutrition.MealEntry.addToMeal.localized) {
                    addMealEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(gramsConsumed <= 0)
            }
            .padding()
            .navigationTitle(LocalizationKeys.Nutrition.MealEntry.title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Nutrition.MealEntry.cancel.localized) {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func addMealEntry() {
        let entry = NutritionEntry(
            food: food,
            gramsConsumed: gramsConsumed,
            mealType: selectedMealType
        )
        
        modelContext.insert(entry)
        
        // Usage tracking
        food.recordUsage()
        
        onDismiss()
    }
}

#Preview {
    MealEntryView(
        food: Food(
            nameEN: "Chicken Breast",
            nameTR: "Tavuk Göğsü",
            calories: 165,
            protein: 31,
            carbs: 0,
            fat: 3.6,
            category: .meat
        )
    ) {
        // Preview için boş closure
    }
    .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
