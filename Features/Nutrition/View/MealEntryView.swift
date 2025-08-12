import SwiftUI
import SwiftData

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var gramsConsumed: Double = 100
    // Çoklu öğün seçimi desteği
    @State private var selectedMealTypes: Set<String> = ["breakfast"]
    
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
                            try? food.modelContext?.save()
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
                
                // Porsiyon girişi
                PortionQuickSelect(quantity: $gramsConsumed)
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Nutrition.MealEntry.portion.localized)
                        .font(.headline)
                    
                    TextField(LocalizationKeys.Nutrition.MealEntry.portionGrams.localized, value: $gramsConsumed, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                // Öğün seçimi (çoklu seçim)
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
                .disabled(gramsConsumed <= 0 || selectedMealTypes.isEmpty)
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
        // Seçilen her öğün için ayrı giriş oluştur
        for meal in selectedMealTypes {
            let entry = NutritionEntry(
                food: food,
                gramsConsumed: gramsConsumed,
                mealType: meal
            )
            modelContext.insert(entry)
        }
        
        // Usage tracking
        food.recordUsage()
        try? modelContext.save()
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
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

// MARK: - Portion Quick Select
struct PortionQuickSelect: View {
    @Binding var quantity: Double
    private let quickAmounts: [Int] = [25, 50, 100, 150, 200, 250]
    @State private var showingCustomInput = false
    @State private var customText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Portions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button {
                            quantity = Double(amount)
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(amount)")
                                    .font(.headline)
                                Text("g")
                                    .font(.caption2)
                            }
                            .foregroundColor(quantity == Double(amount) ? .white : .primary)
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(quantity == Double(amount) ? Color.blue : Color(.systemGray6))
                            )
                        }
                    }
                    
                    Button {
                        showingCustomInput = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.headline)
                            Text("Custom")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showingCustomInput) {
                        NavigationStack {
                            VStack(spacing: 16) {
                                Text("Custom Amount (g)")
                                    .font(.headline)
                                TextField("0", text: $customText)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                Spacer()
                            }
                            .padding()
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Set") {
                                        if let value = Double(customText), value > 0 {
                                            quantity = value
                                            #if canImport(UIKit)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            #endif
                                            showingCustomInput = false
                                        }
                                    }
                                }
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(LocalizationKeys.Common.cancel.localized) {
                                        showingCustomInput = false
                                    }
                                }
                            }
                        }
                        .presentationDetents([.medium])
                    }
                }
                .padding(.horizontal, 2)
            }
            
            HStack {
                Text("\(Int(quantity))g")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 60)
                
                Slider(value: $quantity, in: 1...500, step: 5)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}
