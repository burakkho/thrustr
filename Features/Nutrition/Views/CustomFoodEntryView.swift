import SwiftUI
import SwiftData

struct CustomFoodEntryView: View {
    let onFoodCreated: (Food) -> Void
    var prefillBarcode: String? = nil
    var prefillName: String? = nil
    var prefillBrand: String? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    
    @State private var foodName = ""
    @State private var brand = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var selectedCategory: FoodCategory = .other
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isValid: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        calories > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Native iOS Sheet Header
            HStack {
                Button(NutritionKeys.CustomFood.cancel.localized) {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text(NutritionKeys.CustomFood.title.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Invisible button for balance
                Text(NutritionKeys.CustomFood.cancel.localized)
                    .font(.body)
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NutritionKeys.CustomFood.newFood.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(NutritionKeys.CustomFood.subtitle.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Temel bilgiler
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NutritionKeys.CustomFood.basicInfo.localized)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NutritionKeys.CustomFood.foodNameRequired.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(NutritionKeys.CustomFood.foodNamePlaceholder.localized, text: $foodName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NutritionKeys.CustomFood.brandOptional.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(NutritionKeys.CustomFood.brandPlaceholder.localized, text: $brand)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NutritionKeys.CustomFood.category.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker(NutritionKeys.CustomFood.category.localized, selection: $selectedCategory) {
                                ForEach(FoodCategory.allCases, id: \.self) { category in
                                    Label(category.displayName, systemImage: category.systemIcon)
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
                            Text(NutritionKeys.CustomFood.nutritionValues.localized)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(unitSettings.unitSystem == .metric ? NutritionKeys.CustomFood.per100g.localized : NutritionKeys.CustomFood.per100gImperial.localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NutritionInputField(
                                title: NutritionKeys.CustomFood.caloriesRequired.localized,
                                value: $calories,
                                unit: NutritionKeys.Units.kcal.localized,
                                color: .orange
                            )
                            
                            NutritionInputField(
                                title: NutritionKeys.CustomFood.protein.localized,
                                value: $protein,
                                unit: NutritionKeys.Units.g.localized,
                                color: .red
                            )
                            
                            NutritionInputField(
                                title: NutritionKeys.CustomFood.carbs.localized,
                                value: $carbs,
                                unit: NutritionKeys.Units.g.localized,
                                color: .blue
                            )
                            
                            NutritionInputField(
                                title: NutritionKeys.CustomFood.fat.localized,
                                value: $fat,
                                unit: NutritionKeys.Units.g.localized,
                                color: .yellow
                            )
                        }
                    }
                    
                    // Önizleme
                    if isValid {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NutritionKeys.CustomFood.preview.localized)
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
                                
                                Text("\(Int(calories)) \(NutritionKeys.Units.kcal.localized) • P: \(Int(protein))\(NutritionKeys.Units.g.localized) • C: \(Int(carbs))\(NutritionKeys.Units.g.localized) • F: \(Int(fat))\(NutritionKeys.Units.g.localized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Ekle butonu
                    Button(NutritionKeys.CustomFood.addFood.localized) {
                        createCustomFood()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
                     .onTapGesture {
                         if isValid {
                             HapticManager.shared.notification(.success)
                         }
                     }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .alert(NutritionKeys.CustomFood.error.localized, isPresented: $showingAlert) {
            Button(NutritionKeys.CustomFood.ok.localized) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let prefillName, foodName.isEmpty { foodName = prefillName }
            if let prefillBrand, brand.isEmpty { brand = prefillBrand }
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
        if let prefillBarcode {
            newFood.barcode = prefillBarcode
        }
        
        modelContext.insert(newFood)
        do {
            try modelContext.save()
            onFoodCreated(newFood)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
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
