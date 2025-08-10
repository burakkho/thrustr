import SwiftUI
import SwiftData

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var gramsConsumed: Double = 100
    @State private var selectedMealType = "breakfast"
    
    private let mealTypes = [
        ("breakfast", "Kahvaltı"),
        ("lunch", "Öğle"),
        ("dinner", "Akşam"),
        ("snack", "Atıştırmalık")
    ]
    
    var body: some View {
        NavigationView {
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
                    
                    Text("100g başına: \(Int(food.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Porsiyon girişi
                VStack(alignment: .leading, spacing: 8) {
                    Text("Porsiyon (gram)")
                        .font(.headline)
                    
                    TextField("Gram", value: $gramsConsumed, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                // Öğün seçimi
                VStack(alignment: .leading, spacing: 8) {
                    Text("Öğün")
                        .font(.headline)
                    
                    Picker("Öğün", selection: $selectedMealType) {
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
                        Text("Toplam: \(Int(nutrition.calories)) kcal")
                            .font(.headline)
                        Text("Protein: \(Int(nutrition.protein))g • Carbs: \(Int(nutrition.carbs))g • Fat: \(Int(nutrition.fat))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Ekle butonu
                Button("Öğüne Ekle") {
                    addMealEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(gramsConsumed <= 0)
            }
            .padding()
            .navigationTitle("Öğün Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
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
