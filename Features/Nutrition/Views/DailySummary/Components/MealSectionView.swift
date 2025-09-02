import SwiftUI

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
            return NutritionKeys.MealEntry.MealTypes.breakfast.localized
        case "lunch":
            return NutritionKeys.MealEntry.MealTypes.lunch.localized
        case "dinner":
            return NutritionKeys.MealEntry.MealTypes.dinner.localized
        case "snack":
            return NutritionKeys.MealEntry.MealTypes.snack.localized
        default:
            return mealKey.capitalized
        }
    }
}

#Preview {
    let food1 = Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat)
    let food2 = Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    
    let entry1 = NutritionEntry(food: food1, gramsConsumed: 150, mealType: "lunch", date: Date())
    let entry2 = NutritionEntry(food: food2, gramsConsumed: 100, mealType: "lunch", date: Date())
    
    MealSectionView(
        mealKey: "lunch",
        entries: [entry1, entry2],
        onEdit: { _ in },
        onError: { _ in }
    )
    .padding()
}
