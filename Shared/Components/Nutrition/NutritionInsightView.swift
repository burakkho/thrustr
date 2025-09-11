import SwiftUI

struct NutritionInsightView: View {
    let icon: String
    let insight: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(insight)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    NutritionInsightView(
        icon: "flame.fill",
        insight: "Highest calorie day: Monday (2,150 cal)",
        color: .orange
    )
    .environment(ThemeManager())
}