import SwiftUI

struct CalorieBarChart: View {
    let weeklyData: [DayData]
    @Environment(\.theme) private var theme
    
    private var maxCalories: Double {
        weeklyData.map { $0.calories }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(NutritionKeys.Analytics.dailyCalories.localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: theme.spacing.s) {
                ForEach(weeklyData, id: \.date) { day in
                    VStack(spacing: 4) {
                        // Bar
                        Rectangle()
                            .fill(day.calories > 0 ? theme.colors.warning : theme.colors.backgroundSecondary)
                            .frame(width: 32, height: max(4, (day.calories / maxCalories) * 100))
                            .cornerRadius(theme.radius.xs)
                        
                        // Kalori değeri
                        Text("\(Int(day.calories))")
                            .font(.caption2)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        // Gün adı
                        Text(String(day.dayName.prefix(3)))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let sampleData = [
        DayData(date: Date(), dayName: "Mon", calories: 2100, protein: 120, carbs: 250, fat: 70),
        DayData(date: Date(), dayName: "Tue", calories: 1950, protein: 110, carbs: 220, fat: 65),
        DayData(date: Date(), dayName: "Wed", calories: 2250, protein: 130, carbs: 270, fat: 75)
    ]
    
    CalorieBarChart(weeklyData: sampleData)
        .environment(ThemeManager())
}