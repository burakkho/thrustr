import SwiftUI

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
            Text(NutritionKeys.DailySummary.total.localized)
                .font(.headline)
            
            Spacer()
            
            Text("\(Int(totalCalories)) \(NutritionKeys.Units.kcal.localized)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
    }
    
    private var macroSummary: some View {
        HStack(spacing: 20) {
            MacroView(
                value: Int(totalProtein),
                label: NutritionKeys.DailySummary.protein.localized,
                color: .red
            )
            MacroView(
                value: Int(totalCarbs),
                label: NutritionKeys.DailySummary.carbs.localized,
                color: .blue
            )
            MacroView(
                value: Int(totalFat),
                label: NutritionKeys.DailySummary.fat.localized,
                color: .yellow
            )
        }
    }
}

#Preview {
    TotalSummaryView(
        totalCalories: 1850,
        totalProtein: 120,
        totalCarbs: 180,
        totalFat: 65
    )
    .padding()
}
