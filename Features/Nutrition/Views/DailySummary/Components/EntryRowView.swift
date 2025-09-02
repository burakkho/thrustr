import SwiftUI

struct EntryRowView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
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
        .onLongPressGesture {
            onEdit()
        }
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
            Text(portionSubtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var calorieInfo: some View {
        Text("\(Int(entry.calories)) \(NutritionKeys.Units.kcal.localized)")
            .font(.subheadline)
            .fontWeight(.medium)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteEntry()
        } label: {
            Label("common.delete".localized, systemImage: "trash")
        }
    }
    
    private var editButton: some View {
        Button {
            onEdit()
        } label: {
            Label("common.edit".localized, systemImage: "pencil")
        }
        .tint(.orange)
    }
    
    private var duplicateButton: some View {
        Button {
            duplicateEntry()
        } label: {
            Label("common.duplicate".localized, systemImage: "doc.on.doc")
        }
        .tint(.green)
    }
    
    @ViewBuilder
    private var contextMenuButtons: some View {
        Button {
            onEdit()
        } label: {
            Label(CommonKeys.Onboarding.Common.edit.localized, systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteEntry()
        } label: {
            Label(CommonKeys.Onboarding.Common.delete.localized, systemImage: "trash")
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
    
    // MARK: - Computed Properties
    private var portionSubtitle: String {
        let grams = entry.gramsConsumed
        guard let food = entry.food else {
            return UnitsFormatter.formatFoodWeight(grams: grams, system: unitSettings.unitSystem)
        }
        let per = food.servingSizeGramsOrDefault
        let servings = per > 0 ? grams / per : 0
        if servings > 0 {
            let servingsText: String
            if abs(servings.rounded() - servings) < 0.001 {
                servingsText = String(format: "%.0f", servings)
            } else {
                servingsText = String(format: "%.2f", servings)
            }
            if let name = food.servingName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "\(servingsText) \(name) • \(UnitsFormatter.formatFoodWeight(grams: grams, system: unitSettings.unitSystem))"
            }
            return "\(servingsText) \(NutritionKeys.Labels.serving.localized) • \(UnitsFormatter.formatFoodWeight(grams: grams, system: unitSettings.unitSystem))"
        }
        return UnitsFormatter.formatFoodWeight(grams: grams, system: unitSettings.unitSystem)
    }
}

#Preview {
    let food = Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat)
    let entry = NutritionEntry(food: food, gramsConsumed: 150, mealType: "lunch", date: Date())
    
    EntryRowView(
        entry: entry,
        onEdit: {},
        onError: { _ in }
    )
    .padding()
}
