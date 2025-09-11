import SwiftUI
import SwiftData

struct NutritionAnalyticsView: View {
    let nutritionEntries: [NutritionEntry]
    @Environment(\.theme) private var theme
    
    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        var dailyTotals: [Date: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [:]
        
        // Son 7 günü hesapla
        for entry in nutritionEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            if dayStart >= calendar.startOfDay(for: weekAgo) && dayStart <= calendar.startOfDay(for: today) {
                if let existing = dailyTotals[dayStart] {
                    dailyTotals[dayStart] = (
                        calories: existing.calories + entry.calories,
                        protein: existing.protein + entry.protein,
                        carbs: existing.carbs + entry.carbs,
                        fat: existing.fat + entry.fat
                    )
                } else {
                    dailyTotals[dayStart] = (
                        calories: entry.calories,
                        protein: entry.protein,
                        carbs: entry.carbs,
                        fat: entry.fat
                    )
                }
            }
        }
        
        // 7 günlük veri oluştur
        var weekData: [DayData] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayName = calendar.component(.weekday, from: date)
            
            // Localized day names
            let dayNames = ["",
                            NutritionKeys.Days.sunday.localized,
                            NutritionKeys.Days.monday.localized,
                            NutritionKeys.Days.tuesday.localized,
                            NutritionKeys.Days.wednesday.localized,
                            NutritionKeys.Days.thursday.localized,
                            NutritionKeys.Days.friday.localized,
                            NutritionKeys.Days.saturday.localized]
            
            if let data = dailyTotals[dayStart] {
                weekData.append(DayData(
                    date: date,
                    dayName: dayNames[dayName],
                    calories: data.calories,
                    protein: data.protein,
                    carbs: data.carbs,
                    fat: data.fat
                ))
            } else {
                weekData.append(DayData(
                    date: date,
                    dayName: dayNames[dayName],
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0
                ))
            }
        }
        
        return weekData
    }
    
    private var maxCalories: Double {
        weeklyData.map { $0.calories }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.l) {
            Text(NutritionKeys.Analytics.title.localized)
                .font(theme.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            // Use shared calorie bar chart
            CalorieBarChart(weeklyData: weeklyData)
            
            // Compact macro summary
            compactMacroSummary
            
            // Quick insights
            quickInsightsSection
        }
        .padding(.vertical, theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Compact Macro Summary
    private var compactMacroSummary: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(NutritionKeys.Analytics.weeklyAverage.localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / 7
            let avgProtein = weeklyData.map { $0.protein }.reduce(0, +) / 7
            let avgCarbs = weeklyData.map { $0.carbs }.reduce(0, +) / 7
            let avgFat = weeklyData.map { $0.fat }.reduce(0, +) / 7
            
            HStack(spacing: theme.spacing.m) {
                MacroSummaryView(
                    value: Int(avgCalories),
                    label: NutritionKeys.calories.localized,
                    color: theme.colors.warning,
                    unit: NutritionKeys.Units.kcal.localized
                )
                MacroSummaryView(
                    value: Int(avgProtein),
                    label: NutritionKeys.DailySummary.protein.localized,
                    color: theme.colors.error,
                    unit: NutritionKeys.Units.g.localized
                )
                MacroSummaryView(
                    value: Int(avgCarbs),
                    label: NutritionKeys.DailySummary.carbs.localized,
                    color: theme.colors.info,
                    unit: NutritionKeys.Units.g.localized
                )
                MacroSummaryView(
                    value: Int(avgFat),
                    label: NutritionKeys.DailySummary.fat.localized,
                    color: theme.colors.accent,
                    unit: NutritionKeys.Units.g.localized
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Quick Insights (Compact)
    private var quickInsightsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Insights")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Show only top 2 insights for compact view
                if let highestCalorieDay = weeklyData.max(by: { $0.calories < $1.calories }), highestCalorieDay.calories > 0 {
                    NutritionInsightView(
                        icon: "flame.fill",
                        insight: "Highest: \(highestCalorieDay.dayName) (\(Int(highestCalorieDay.calories)) cal)",
                        color: theme.colors.warning
                    )
                }
                
                let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / 7
                if avgCalories > 0 {
                    let activeDays = weeklyData.filter { $0.calories > 0 }.count
                    NutritionInsightView(
                        icon: "chart.bar.fill",
                        insight: "Logged \(activeDays)/7 days this week",
                        color: activeDays > 5 ? theme.colors.success : theme.colors.warning
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
}

#Preview {
    // Create sample food for preview
    let sampleFood = Food(
        nameEN: "Sample Food",
        nameTR: "Örnek Yemek", 
        calories: 150,
        protein: 20,
        carbs: 5,
        fat: 8
    )
    
    let sampleEntries = [
        NutritionEntry(food: sampleFood, gramsConsumed: 200, mealType: "breakfast", date: Date()),
        NutritionEntry(food: sampleFood, gramsConsumed: 150, mealType: "lunch", date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    ]
    
    NutritionAnalyticsView(nutritionEntries: sampleEntries)
        .environment(ThemeManager())
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}

