import SwiftUI

struct MacroSummaryView: View {
    let value: Int
    let label: String
    let color: Color
    let unit: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(unit)
                .font(theme.typography.caption2)
                .foregroundColor(color)
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MacroSummaryView(
        value: 150,
        label: "Protein",
        color: .red,
        unit: "g"
    )
    .environment(ThemeManager())
}