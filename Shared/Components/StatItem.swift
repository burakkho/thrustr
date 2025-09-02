import SwiftUI

// MARK: - Stat Item Component
struct StatItem: View {
    @Environment(\.theme) private var theme
    
    let title: String
    let value: String
    let color: Color?
    
    init(title: String, value: String, color: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(color ?? theme.colors.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatItem(title: "Pace", value: "5:30 min/km")
        StatItem(title: "Speed", value: "10.8 km/h", color: .blue)
        StatItem(title: "Calories", value: "245 kcal", color: .orange)
    }
    .padding()
}