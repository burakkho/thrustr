import SwiftUI
import SwiftData

struct DailyNutritionSummary: View {
    let nutritionEntries: [NutritionEntry]
    @State private var editingEntry: NutritionEntry?
    @State private var showingEditSheet: Bool = false
    
    private var todaysEntries: [NutritionEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return nutritionEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
    
    private var totalCalories: Double {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        todaysEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        todaysEntries.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFat: Double {
        todaysEntries.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        if !todaysEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizationKeys.Nutrition.DailySummary.title.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // Öğün listesi
                ForEach(todaysEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.foodName)
                                .font(.headline)
                            Text("\(entry.displayMealType) • \(Int(entry.gramsConsumed))\(LocalizationKeys.Nutrition.Units.g.localized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(entry.calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                if let context = entry.modelContext {
                                    context.delete(entry)
                                    try? context.save()
                                    HapticManager.shared.notification(.success)
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                    Button {
                            editingEntry = entry
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            if let context = entry.modelContext {
                                let cloned = NutritionEntry(
                                    food: entry.food ?? Food(nameEN: entry.foodName, nameTR: entry.foodName, calories: entry.calories / (entry.gramsConsumed / 100.0), protein: entry.protein / (entry.gramsConsumed / 100.0), carbs: entry.carbs / (entry.gramsConsumed / 100.0), fat: entry.fat / (entry.gramsConsumed / 100.0), category: .other),
                                    gramsConsumed: entry.gramsConsumed,
                                    mealType: entry.mealType,
                                    date: Date()
                                )
                                context.insert(cloned)
                                try? context.save()
                                HapticManager.shared.notification(.success)
                            }
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.green)
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    if let entry = editingEntry {
                        NutritionEntryEditSheet(entry: entry)
                    }
                }
                
                // Toplam özet
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizationKeys.Nutrition.DailySummary.total.localized)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(totalCalories)) \(LocalizationKeys.Nutrition.Units.kcal.localized)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack(spacing: 20) {
                        MacroView(
                            value: Int(totalProtein),
                            label: LocalizationKeys.Nutrition.DailySummary.protein.localized,
                            color: .red
                        )
                        MacroView(
                            value: Int(totalCarbs),
                            label: LocalizationKeys.Nutrition.DailySummary.carbs.localized,
                            color: .blue
                        )
                        MacroView(
                            value: Int(totalFat),
                            label: LocalizationKeys.Nutrition.DailySummary.fat.localized,
                            color: .yellow
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Edit Sheet
struct NutritionEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var grams: Double
    @State private var meal: String
    let entry: NutritionEntry
    
    init(entry: NutritionEntry) {
        self.entry = entry
        _grams = State(initialValue: entry.gramsConsumed)
        _meal = State(initialValue: entry.mealType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizationKeys.Nutrition.MealEntry.portion.localized)) {
                    TextField(LocalizationKeys.Nutrition.MealEntry.portionGrams.localized, value: $grams, format: .number)
                        .keyboardType(.decimalPad)
                }
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
            .navigationTitle(LocalizationKeys.Common.edit.localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKeys.Common.cancel.localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKeys.Common.save.localized) {
                        applyChanges()
                    }
                    .disabled(grams <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func applyChanges() {
        guard grams > 0 else { return }
        entry.gramsConsumed = grams
        entry.mealType = meal
        // Recalculate cached nutrition
        if let food = entry.food {
            let n = food.calculateNutrition(for: grams)
            entry.calories = n.calories
            entry.protein = n.protein
            entry.carbs = n.carbs
            entry.fat = n.fat
        }
        entry.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.notification(.success)
        dismiss()
    }
}

struct MacroView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(LocalizationKeys.Nutrition.Units.g.localized)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DailyNutritionSummary(nutritionEntries: [])
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
