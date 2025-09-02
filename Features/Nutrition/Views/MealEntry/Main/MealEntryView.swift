import SwiftUI
import SwiftData

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var gramsConsumed: Double = 100
    @State private var servingCount: Double = 1
    @State private var inputMode: PortionInputMode = .grams
    // Çoklu öğün seçimi desteği
    @State private var selectedMealTypes: Set<String> = ["breakfast"]
    @State private var saveErrorMessage: String? = nil
    
    private var mealTypes: [(String, String)] {
        [
            ("breakfast", NutritionKeys.MealEntry.MealTypes.breakfast.localized),
            ("lunch", NutritionKeys.MealEntry.MealTypes.lunch.localized),
            ("dinner", NutritionKeys.MealEntry.MealTypes.dinner.localized),
            ("snack", NutritionKeys.MealEntry.MealTypes.snack.localized)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Native iOS Sheet Header
            HStack {
                Button(NutritionKeys.MealEntry.cancel.localized) {
                    onDismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text(NutritionKeys.MealEntry.title.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Invisible button for balance
                Text(NutritionKeys.MealEntry.cancel.localized)
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
        }
        .alert(isPresented: errorAlertBinding) {
            Alert(
                title: Text(CommonKeys.Onboarding.Common.error.localized),
                message: Text(saveErrorMessage ?? ""),
                dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
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
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: food.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(food.isFavorite ? .red : .gray)
                        .font(.title3)
                }
            }
            
            Text(NutritionKeys.MealEntry.per100gCalories.localized(with: Int(food.calories)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var mealSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NutritionKeys.MealEntry.meal.localized)
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
                    Text(NutritionKeys.MealEntry.total.localized(with: Int(nutrition.calories)))
                        .font(.headline)
                    Text("\(NutritionKeys.CustomFood.protein.localized): \(Int(nutrition.protein))\(NutritionKeys.Units.g.localized) • \(NutritionKeys.CustomFood.carbs.localized): \(Int(nutrition.carbs))\(NutritionKeys.Units.g.localized) • \(NutritionKeys.CustomFood.fat.localized): \(Int(nutrition.fat))\(NutritionKeys.Units.g.localized)")
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
        Button(NutritionKeys.MealEntry.addToMeal.localized) { addMealEntry() }
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
            
            // Log meal completion activity for dashboard
            let currentUser = fetchCurrentUser()
            ActivityLoggerService.shared.setModelContext(modelContext)
            
            // For each meal type, calculate total nutrition and log meal completion
            for meal in selectedMealTypes {
                let mealDisplayName = mealTypes.first { $0.0 == meal }?.1 ?? meal
                let mealTotals = calculateMealTotals(for: meal, on: Date())
                
                ActivityLoggerService.shared.logMealCompleted(
                    mealType: mealDisplayName,
                    foodCount: mealTotals.foodCount,
                    totalCalories: mealTotals.calories,
                    totalProtein: mealTotals.protein,
                    totalCarbs: mealTotals.carbs,
                    totalFat: mealTotals.fat,
                    user: currentUser
                )
            }
            
            // Save daily nutrition totals to HealthKit
            Task {
                let dailyTotals = calculateDailyTotals(for: Date())
                let success = await healthKitService.saveNutritionData(
                    calories: dailyTotals.calories,
                    protein: dailyTotals.protein,
                    carbs: dailyTotals.carbs,
                    fat: dailyTotals.fat,
                    date: Date()
                )
                
                if success {
                    Logger.info("Daily nutrition data successfully synced to HealthKit")
                }
            }
            
            HapticManager.shared.notification(.success)
            onDismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    // Helper to get current user
    private func fetchCurrentUser() -> User? {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\User.createdAt)])
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            return nil
        }
    }
    
    // Calculate total nutrition for a specific meal type on a given date
    private func calculateMealTotals(for mealType: String, on date: Date) -> (foodCount: Int, calories: Double, protein: Double, carbs: Double, fat: Double) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = #Predicate<NutritionEntry> { entry in
            entry.mealType == mealType &&
            entry.date >= startOfDay &&
            entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<NutritionEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            let totalCalories = entries.reduce(0) { $0 + $1.calories }
            let totalProtein = entries.reduce(0) { $0 + $1.protein }
            let totalCarbs = entries.reduce(0) { $0 + $1.carbs }
            let totalFat = entries.reduce(0) { $0 + $1.fat }
            
            return (
                foodCount: entries.count,
                calories: totalCalories,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat
            )
        } catch {
            print("Error calculating meal totals: \(error)")
            return (foodCount: 0, calories: 0, protein: 0, carbs: 0, fat: 0)
        }
    }
    
    // Calculate total nutrition for all meals on a given date
    private func calculateDailyTotals(for date: Date) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = #Predicate<NutritionEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<NutritionEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            let totalCalories = entries.reduce(0) { $0 + $1.calories }
            let totalProtein = entries.reduce(0) { $0 + $1.protein }
            let totalCarbs = entries.reduce(0) { $0 + $1.carbs }
            let totalFat = entries.reduce(0) { $0 + $1.fat }
            
            return (
                calories: totalCalories,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat
            )
        } catch {
            print("Error calculating daily totals: \(error)")
            return (calories: 0, protein: 0, carbs: 0, fat: 0)
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
    
    // Unit-aware binding for TextField display
    private var displayBinding: Binding<Double> {
        Binding<Double>(
            get: {
                switch unitSettings.unitSystem {
                case .metric:
                    return gramsConsumed
                case .imperial:
                    return UnitsConverter.gramToOz(gramsConsumed)
                }
            },
            set: { newValue in
                switch unitSettings.unitSystem {
                case .metric:
                    gramsConsumed = newValue
                case .imperial:
                    gramsConsumed = UnitsConverter.ozToGram(newValue)
                }
            }
        )
    }
    
    @ViewBuilder
    private var portionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode toggle
            Picker("", selection: $inputMode) {
                Text(NutritionKeys.PortionInput.grams.localized).tag(PortionInputMode.grams)
                Text(NutritionKeys.PortionInput.serving.localized).tag(PortionInputMode.serving)
            }
            .pickerStyle(.segmented)
            
            if inputMode == .grams {
                PortionQuickSelect(quantity: $gramsConsumed, suggested: suggestedQuickAmounts())
                VStack(alignment: .leading, spacing: 8) {
                    Text(NutritionKeys.MealEntry.portion.localized)
                        .font(.headline)
                    TextField(
                        unitSettings.unitSystem == .metric ? 
                        NutritionKeys.MealEntry.portionGrams.localized :
                        NutritionKeys.MealEntry.portionOunces.localized, 
                        value: displayBinding,
                        format: .number
                    )
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.servingDisplayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Text("nutrition.portion_input.count".localized)
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
