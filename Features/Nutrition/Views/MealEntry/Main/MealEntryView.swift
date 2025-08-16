import SwiftUI
import SwiftData

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var gramsConsumed: Double = 100
    @State private var servingCount: Double = 1
    @State private var inputMode: PortionInputMode = .grams
    // Çoklu öğün seçimi desteği
    @State private var selectedMealTypes: Set<String> = ["breakfast"]
    @State private var saveErrorMessage: String? = nil
    
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
                foodInfoSection
                
                // Porsiyon girişi (gram veya porsiyon)
                portionInputSection
                
                // Öğün seçimi (çoklu seçim)
                mealSelectionSection
                
                // Hesaplanan değerler
                nutritionCalculationSection
                
                Spacer()
                
                // Ekle butonu
                addButton
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
        .alert(isPresented: errorAlertBinding) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveErrorMessage ?? ""),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
        }
    }
    
    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Favori butonu
                Button {
                    food.toggleFavorite()
                    do { try food.modelContext?.save() } catch { saveErrorMessage = error.localizedDescription }
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
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
    }
    
    private var mealSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationKeys.Nutrition.MealEntry.meal.localized)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(mealTypes, id: \.0) { type, name in
                    let isOn = selectedMealTypes.contains(type)
                    Button {
                        if isOn {
                            selectedMealTypes.remove(type)
                        } else {
                            selectedMealTypes.insert(type)
                        }
                    } label: {
                        Text(name)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isOn ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12))
                            .foregroundColor(isOn ? .accentColor : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var nutritionCalculationSection: some View {
        Group {
            if effectiveGrams > 0 {
                let nutrition = food.calculateNutrition(for: effectiveGrams)
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
        }
    }
    
    private var addButton: some View {
        Button(LocalizationKeys.Nutrition.MealEntry.addToMeal.localized) { addMealEntry() }
            .buttonStyle(.borderedProminent)
            .disabled(effectiveGrams <= 0 || selectedMealTypes.isEmpty)
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }
    
    private func addMealEntry() {
        // Seçilen her öğün için ayrı giriş oluştur
        for meal in selectedMealTypes {
            let entry = NutritionEntry(
                food: food,
                gramsConsumed: effectiveGrams,
                mealType: meal
            )
            modelContext.insert(entry)
        }
        
        // Usage tracking
        food.recordUsage()
        do {
            try modelContext.save()
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            onDismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func suggestedQuickAmounts() -> [Int] {
        // Basit heuristik: bazı yaygın ürünler için pratik gram önerileri
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
}

// MARK: - Portion Input Helpers
extension MealEntryView {
    enum PortionInputMode: String, CaseIterable { case grams, serving }
    
    private var effectiveGrams: Double {
        switch inputMode {
        case .grams:
            return gramsConsumed
        case .serving:
            return max(servingCount, 0) * food.servingSizeGramsOrDefault
        }
    }
    
    @ViewBuilder
    private var portionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode toggle
            Picker("", selection: $inputMode) {
                Text("Gram").tag(PortionInputMode.grams)
                Text("Porsiyon").tag(PortionInputMode.serving)
            }
            .pickerStyle(.segmented)
            
            if inputMode == .grams {
                PortionQuickSelect(quantity: $gramsConsumed, suggested: suggestedQuickAmounts())
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Nutrition.MealEntry.portion.localized)
                        .font(.headline)
                    TextField(LocalizationKeys.Nutrition.MealEntry.portionGrams.localized, value: $gramsConsumed, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.servingDisplayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Text("Adet")
                        TextField("1", value: $servingCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
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
