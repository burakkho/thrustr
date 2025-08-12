import SwiftUI
import SwiftData

struct DailyNutritionSummary: View {
    let nutritionEntries: [NutritionEntry]
    @State private var editingEntry: NutritionEntry?
    @State private var showingEditSheet: Bool = false
    @State private var saveErrorMessage: String? = nil
    
    // İstenen sıralama: Kahvaltı → Öğle → Akşam → Ara Öğün
    private let mealOrderKeys: [String] = ["breakfast", "lunch", "dinner", "snack"]
    private let horizontalPadding: CGFloat = 16
    
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
        mainContent
            .sheet(isPresented: $showingEditSheet) {
                if let entry = editingEntry {
                    NutritionEntryEditSheet(entry: entry)
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
    
    @ViewBuilder
    private var mainContent: some View {
        if !todaysEntries.isEmpty {
            summaryContainer
        }
    }
    
    private var summaryContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryHeader
            mealSections
            totalSummarySection
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 8)
    }
    
    private var summaryHeader: some View {
        Text(LocalizationKeys.Nutrition.DailySummary.title.localized)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.horizontal, horizontalPadding)
    }
    
    private var mealSections: some View {
        ForEach(mealOrderKeys, id: \.self) { mealKey in
            MealSectionView(
                mealKey: mealKey,
                entries: todaysEntries.filter { $0.mealType == mealKey },
                onEdit: { entry in
                    editingEntry = entry
                    showingEditSheet = true
                },
                onError: { error in
                    saveErrorMessage = error
                }
            )
        }
    }
    
    private var totalSummarySection: some View {
        TotalSummaryView(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat
        )
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }
}

// MARK: - Meal Section View
struct MealSectionView: View {
    let mealKey: String
    let entries: [NutritionEntry]
    let onEdit: (NutritionEntry) -> Void
    let onError: (String) -> Void
    
    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                mealHeader
                entryList
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }
    
    private var mealHeader: some View {
        Text(mealHeaderTitle(for: mealKey))
            .font(.headline)
            .underline()
            .padding(.top, 4)
    }
    
    private var entryList: some View {
        ForEach(entries, id: \.id) { entry in
            EntryRowView(
                entry: entry,
                onEdit: { onEdit(entry) },
                onError: onError
            )
        }
    }
    
    private func mealHeaderTitle(for mealKey: String) -> String {
        switch mealKey {
        case "breakfast":
            return LocalizationKeys.Nutrition.MealEntry.MealTypes.breakfast.localized
        case "lunch":
            return LocalizationKeys.Nutrition.MealEntry.MealTypes.lunch.localized
        case "dinner":
            return LocalizationKeys.Nutrition.MealEntry.MealTypes.dinner.localized
        case "snack":
            return LocalizationKeys.Nutrition.MealEntry.MealTypes.snack.localized
        default:
            return mealKey.capitalized
        }
    }
}

// MARK: - Entry Row View
struct EntryRowView: View {
    let entry: NutritionEntry
    let onEdit: () -> Void
    let onError: (String) -> Void
    
    var body: some View {
        HStack {
            entryInfo
            Spacer()
            calorieInfo
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            deleteButton
            editButton
        }
        .swipeActions(edge: .leading) {
            duplicateButton
        }
        .contextMenu {
            contextMenuButtons
        }
    }
    
    private var entryInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.foodName)
                .font(.headline)
            Text("\(Int(entry.gramsConsumed))\(LocalizationKeys.Nutrition.Units.g.localized)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var calorieInfo: some View {
        Text("\(Int(entry.calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized)")
            .font(.subheadline)
            .fontWeight(.medium)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteEntry()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var editButton: some View {
        Button {
            onEdit()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.orange)
    }
    
    private var duplicateButton: some View {
        Button {
            duplicateEntry()
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        .tint(.green)
    }
    
    @ViewBuilder
    private var contextMenuButtons: some View {
        Button {
            onEdit()
        } label: {
            Label(LocalizationKeys.Common.edit.localized, systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteEntry()
        } label: {
            Label(LocalizationKeys.Common.delete.localized, systemImage: "trash")
        }
    }
    
    private func deleteEntry() {
        withAnimation {
            if let context = entry.modelContext {
                context.delete(entry)
                do {
                    try context.save()
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
    }
    
    private func duplicateEntry() {
        if let context = entry.modelContext {
            let food = entry.food ?? Food(
                nameEN: entry.foodName,
                nameTR: entry.foodName,
                calories: entry.calories / (entry.gramsConsumed / 100.0),
                protein: entry.protein / (entry.gramsConsumed / 100.0),
                carbs: entry.carbs / (entry.gramsConsumed / 100.0),
                fat: entry.fat / (entry.gramsConsumed / 100.0),
                category: .other
            )
            
            let cloned = NutritionEntry(
                food: food,
                gramsConsumed: entry.gramsConsumed,
                mealType: entry.mealType,
                date: Date()
            )
            
            context.insert(cloned)
            
            do {
                try context.save()
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Total Summary View
struct TotalSummaryView: View {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            totalHeader
            macroSummary
        }
    }
    
    private var totalHeader: some View {
        HStack {
            Text(LocalizationKeys.Nutrition.DailySummary.total.localized)
                .font(.headline)
            
            Spacer()
            
            Text("\(Int(totalCalories)) \(LocalizationKeys.Nutrition.Units.kcal.localized)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
    }
    
    private var macroSummary: some View {
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
}

// MARK: - Macro View
struct MacroView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            valueText
            labelText
        }
    }
    
    private var valueText: some View {
        Text("\(value)\(LocalizationKeys.Nutrition.Units.g.localized)")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
    
    private var labelText: some View {
        Text(label)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// MARK: - Edit Sheet
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
    DailyNutritionSummary(nutritionEntries: [])
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
