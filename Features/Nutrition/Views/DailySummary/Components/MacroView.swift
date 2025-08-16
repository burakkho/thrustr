import SwiftUI

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

#Preview {
    HStack(spacing: 20) {
        MacroView(
            value: 25,
            label: LocalizationKeys.Nutrition.DailySummary.protein.localized,
            color: .red
        )
        MacroView(
            value: 45,
            label: LocalizationKeys.Nutrition.DailySummary.carbs.localized,
            color: .blue
        )
        MacroView(
            value: 15,
            label: LocalizationKeys.Nutrition.DailySummary.fat.localized,
            color: .yellow
        )
    }
    .padding()
}
