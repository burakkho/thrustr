import SwiftUI
import SwiftData

struct CustomFoodEntryView: View {
    let onFoodCreated: (Food) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var foodName = ""
    @State private var brand = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var selectedCategory: FoodCategory = .other
    @State private var portionSize: Double = 100
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isValid: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        calories > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Nutrition.CustomFood.newFood.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Nutrition.CustomFood.subtitle.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Temel bilgiler
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationKeys.Nutrition.CustomFood.basicInfo.localized)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationKeys.Nutrition.CustomFood.foodNameRequired.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(LocalizationKeys.Nutrition.CustomFood.foodNamePlaceholder.localized, text: $foodName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationKeys.Nutrition.CustomFood.brandOptional.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(LocalizationKeys.Nutrition.CustomFood.brandPlaceholder.localized, text: $brand)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationKeys.Nutrition.CustomFood.category.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker(LocalizationKeys.Nutrition.CustomFood.category.localized, selection: $selectedCategory) {
                                ForEach(FoodCategory.allCases, id: \.self) { category in
                                    Label(category.displayName, systemImage: category.icon)
                                        .tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Besin değerleri
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(LocalizationKeys.Nutrition.CustomFood.nutritionValues.localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(LocalizationKeys.Nutrition.CustomFood.per100g.localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NutritionInputField(
                                title: LocalizationKeys.Nutrition.CustomFood.caloriesRequired.localized,
                                value: $calories,
                                unit: LocalizationKeys.Nutrition.Units.kcal.localized,
                                color: .orange
                            )
                            
                            NutritionInputField(
                                title: LocalizationKeys.Nutrition.CustomFood.protein.localized,
                                value: $protein,
                                unit: LocalizationKeys.Nutrition.Units.g.localized,
                                color: .red
                            )
                            
                            NutritionInputField(
                                title: LocalizationKeys.Nutrition.CustomFood.carbs.localized,
                                value: $carbs,
                                unit: LocalizationKeys.Nutrition.Units.g.localized,
                                color: .blue
                            )
                            
                            NutritionInputField(
                                title: LocalizationKeys.Nutrition.CustomFood.fat.localized,
                                value: $fat,
                                unit: LocalizationKeys.Nutrition.Units.g.localized,
                                color: .yellow
                            )
                        }
                    }
                    
                    // Önizleme
                    if isValid {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationKeys.Nutrition.CustomFood.preview.localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(foodName)
                                    .font(.headline)
                                
                                if !brand.isEmpty {
                                    Text(brand)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                
                                Text("\(Int(calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized) • P: \(Int(protein))\(LocalizationKeys.Nutrition.Units.g.localized) • C: \(Int(carbs))\(LocalizationKeys.Nutrition.Units.g.localized) • F: \(Int(fat))\(LocalizationKeys.Nutrition.Units.g.localized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Ekle butonu
                    Button(LocalizationKeys.Nutrition.CustomFood.addFood.localized) {
                        createCustomFood()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
                     .onTapGesture {
                         if isValid { HapticManager.shared.notification(.success) }
                     }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(LocalizationKeys.Nutrition.CustomFood.title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Nutrition.CustomFood.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
        .alert(LocalizationKeys.Nutrition.CustomFood.error.localized, isPresented: $showingAlert) {
            Button(LocalizationKeys.Nutrition.CustomFood.ok.localized) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func createCustomFood() {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newFood = Food(
            nameEN: trimmedName,
            nameTR: trimmedName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            category: selectedCategory
        )
        
        if !trimmedBrand.isEmpty {
            newFood.brand = trimmedBrand
        }
        
        // Mark as user-created
        newFood.isVerified = false
        
        modelContext.insert(newFood)
        onFoodCreated(newFood)
        dismiss()
    }
}

struct NutritionInputField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            HStack {
                TextField("0", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }
}

#Preview {
    CustomFoodEntryView { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
