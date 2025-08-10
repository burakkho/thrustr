import SwiftUI
import SwiftData

struct DailyNutritionSummary: View {
    let nutritionEntries: [NutritionEntry]
    
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
