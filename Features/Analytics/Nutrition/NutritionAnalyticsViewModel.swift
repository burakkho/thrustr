import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for NutritionAnalyticsView with clean separation of concerns.
 *
 * Manages nutrition data processing, weekly analytics, and insights generation.
 * Coordinates with NutritionAnalyticsService for business logic.
 */
@MainActor
@Observable
class NutritionAnalyticsViewModel {

    // MARK: - State
    var weeklyData: [DayData] = []
    var maxCalories: Double = 1
    var averageCalories: Double = 0
    var averageProtein: Double = 0
    var averageCarbs: Double = 0
    var averageFat: Double = 0
    var highestCalorieDay: DayData?
    var activeDaysCount: Int = 0
    var isLoading = false
    var errorMessage: String?
    var filteredEntries: [NutritionEntry] = []
    
    // MARK: - Dependencies
    // NutritionAnalyticsService is static, no instance needed
    
    // MARK: - Computed Properties
    
    /**
     * Whether there is sufficient data to show analytics.
     */
    var hasAnalyticsData: Bool {
        return !weeklyData.isEmpty && weeklyData.contains { $0.calories > 0 }
    }
    
    /**
     * Completion percentage for the week (days with logged nutrition).
     */
    var weekCompletionPercentage: Double {
        return Double(activeDaysCount) / 7.0
    }
    
    /**
     * Color for completion indicator based on active days.
     */
    var completionIndicatorColor: Color {
        switch activeDaysCount {
        case 6...7: return .green
        case 4...5: return .orange
        default: return .red
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // No dependencies needed since service is static
    }
    
    // MARK: - Public Methods
    
    /**
     * Updates data with new nutrition entries.
     */
    func updateData(_ nutritionEntries: [NutritionEntry]) {
        // Filter to last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        filteredEntries = nutritionEntries.filter { entry in
            entry.date >= thirtyDaysAgo
        }

        loadAnalytics(from: filteredEntries)
    }

    /**
     * Loads and processes nutrition analytics for given entries.
     */
    func loadAnalytics(from nutritionEntries: [NutritionEntry]) {
        isLoading = true
        errorMessage = nil

        // Process weekly data directly
        weeklyData = calculateWeeklyData(from: nutritionEntries)

        // Calculate aggregated metrics
        calculateAggregatedMetrics()

        // Generate insights
        generateInsights()

        isLoading = false
    }
    
    /**
     * Refreshes analytics data.
     */
    func refreshAnalytics(from nutritionEntries: [NutritionEntry]) {
        loadAnalytics(from: nutritionEntries)
    }
    
    /**
     * Gets formatted average calorie display.
     */
    func formattedAverageCalories() -> String {
        return "\(Int(averageCalories))"
    }
    
    /**
     * Gets formatted average protein display.
     */
    func formattedAverageProtein() -> String {
        return "\(Int(averageProtein))"
    }
    
    /**
     * Gets formatted average carbs display.
     */
    func formattedAverageCarbs() -> String {
        return "\(Int(averageCarbs))"
    }
    
    /**
     * Gets formatted average fat display.
     */
    func formattedAverageFat() -> String {
        return "\(Int(averageFat))"
    }
    
    /**
     * Gets highest calorie day insight text.
     */
    func highestCalorieDayInsight() -> String? {
        guard let day = highestCalorieDay, day.calories > 0 else { return nil }
        return "Highest: \(day.dayName) (\(Int(day.calories)) cal)"
    }
    
    /**
     * Gets active days insight text.
     */
    func activeDaysInsight() -> String {
        return "Logged \(activeDaysCount)/7 days this week"
    }
    
    /**
     * Gets insight color for active days.
     */
    func activeDaysInsightColor() -> Color {
        return activeDaysCount > 5 ? .green : .orange
    }
    
    /**
     * Resets all analytics data.
     */
    func reset() {
        weeklyData.removeAll()
        maxCalories = 1
        averageCalories = 0
        averageProtein = 0
        averageCarbs = 0
        averageFat = 0
        highestCalorieDay = nil
        activeDaysCount = 0
        isLoading = false
        errorMessage = nil
    }
    
    // MARK: - Private Methods

    private func calculateWeeklyData(from nutritionEntries: [NutritionEntry]) -> [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        var dailyTotals: [Date: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [:]

        // Process last 7 days
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

        // Create 7-day data array
        var weekData: [DayData] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayName = calendar.component(.weekday, from: date)

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

    private func calculateAggregatedMetrics() {
        guard !weeklyData.isEmpty else {
            reset()
            return
        }
        
        // Calculate averages
        averageCalories = weeklyData.map { $0.calories }.reduce(0, +) / 7
        averageProtein = weeklyData.map { $0.protein }.reduce(0, +) / 7
        averageCarbs = weeklyData.map { $0.carbs }.reduce(0, +) / 7
        averageFat = weeklyData.map { $0.fat }.reduce(0, +) / 7
        
        // Calculate max calories for chart scaling
        maxCalories = weeklyData.map { $0.calories }.max() ?? 1
        
        // Count active days
        activeDaysCount = weeklyData.filter { $0.calories > 0 }.count
    }
    
    private func generateInsights() {
        // Find highest calorie day
        highestCalorieDay = weeklyData.max(by: { $0.calories < $1.calories })
        
        // Additional insights could be generated here
        // e.g., trends, recommendations, etc.
    }
}

// MARK: - Supporting Types

/**
 * Nutrition analytics calculation errors.
 */
enum NutritionAnalyticsError: LocalizedError {
    case noData
    case invalidDateRange
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No nutrition data available for analysis"
        case .invalidDateRange:
            return "Invalid date range for analytics"
        case .calculationFailed:
            return "Failed to calculate nutrition analytics"
        }
    }
}