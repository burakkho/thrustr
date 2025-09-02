import SwiftUI

struct MacroView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
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
        Text(formatMacroValue(Double(value)))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
    
    private var labelText: some View {
        Text(label)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    // Helper to format macro values based on unit system
    private func formatMacroValue(_ grams: Double) -> String {
        switch unitSettings.unitSystem {
        case .metric:
            return "\(Int(grams))\(NutritionKeys.Units.g.localized)"
        case .imperial:
            let oz = UnitsConverter.gramToOz(grams)
            return String(format: "%.1f oz", oz)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        MacroView(
            value: 25,
            label: NutritionKeys.DailySummary.protein.localized,
            color: .red
        )
        MacroView(
            value: 45,
            label: NutritionKeys.DailySummary.carbs.localized,
            color: .blue
        )
        MacroView(
            value: 15,
            label: NutritionKeys.DailySummary.fat.localized,
            color: .yellow
        )
    }
    .padding()
}
