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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yeni Yiyecek Ekle")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Evde yaptığınız yemekler veya bulamadığınız yiyecekler için")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Temel bilgiler
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Temel Bilgiler")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Yiyecek Adı *")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("örn: Ev Yapımı Menemen", text: $foodName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Marka (Opsiyonel)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("örn: Ev Yapımı", text: $brand)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Kategori", selection: $selectedCategory) {
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
                            Text("Besin Değerleri")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("100g başına")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NutritionInputField(
                                title: "Kalori *",
                                value: $calories,
                                unit: "kcal",
                                color: .orange
                            )
                            
                            NutritionInputField(
                                title: "Protein",
                                value: $protein,
                                unit: "g",
                                color: .red
                            )
                            
                            NutritionInputField(
                                title: "Karbonhidrat",
                                value: $carbs,
                                unit: "g",
                                color: .blue
                            )
                            
                            NutritionInputField(
                                title: "Yağ",
                                value: $fat,
                                unit: "g",
                                color: .yellow
                            )
                        }
                    }
                    
                    // Önizleme
                    if isValid {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Önizleme")
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
                                
                                Text("\(Int(calories)) kcal • P: \(Int(protein))g • C: \(Int(carbs))g • F: \(Int(fat))g")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Ekle butonu
                    Button("Yiyecek Ekle") {
                        createCustomFood()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Yeni Yiyecek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Hata", isPresented: $showingAlert) {
            Button("Tamam") { }
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
