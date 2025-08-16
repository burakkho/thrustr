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

#Preview {
    TotalSummaryView(
        totalCalories: 1850,
        totalProtein: 120,
        totalCarbs: 180,
        totalFat: 65
    )
    .padding()
}
