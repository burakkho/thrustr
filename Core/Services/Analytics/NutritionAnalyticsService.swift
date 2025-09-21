import Foundation
import SwiftData

struct NutritionAnalyticsService {

    // MARK: - Average Calculations

    static func calculateAverageProtein(from entries: [NutritionEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let totalProtein = entries.reduce(0) { $0 + $1.protein }
        return totalProtein / Double(entries.count)
    }

    static func calculateAverageCalories(from entries: [NutritionEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        return totalCalories / Double(entries.count)
    }

    static func calculateAverageCarbs(from entries: [NutritionEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let totalCarbs = entries.reduce(0) { $0 + $1.carbs }
        return totalCarbs / Double(entries.count)
    }

    static func calculateAverageFat(from entries: [NutritionEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }
        let totalFat = entries.reduce(0) { $0 + $1.fat }
        return totalFat / Double(entries.count)
    }

    // MARK: - Story Message Generation

    static func generateNutritionStoryMessage(from entries: [NutritionEntry]) -> String {
        guard !entries.isEmpty else {
            return "Start logging your meals to see personalized nutrition insights and track your progress toward your health goals."
        }

        let totalEntries = entries.count
        let avgCalories = calculateAverageCalories(from: entries)
        let avgProtein = calculateAverageProtein(from: entries)

        // Get recent entries (last 7 days)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.consumedAt >= weekAgo }

        if recentEntries.count >= 10 {
            return "Excellent tracking! You've logged \(totalEntries) meals with an average of \(Int(avgCalories)) calories and \(Int(avgProtein))g protein. Keep up the consistent nutrition monitoring."
        } else if recentEntries.count >= 5 {
            return "Good progress! You've logged \(totalEntries) meals recently. Your average intake is \(Int(avgCalories)) calories with \(Int(avgProtein))g protein daily."
        } else {
            return "You've started tracking with \(totalEntries) meals logged. Try to log more consistently to get better insights into your nutrition patterns."
        }
    }

    // MARK: - Insight Generation (using [DayData])

    static func generateEatingPatternInsight(from weeklyData: [DayData]) -> String {
        guard !weeklyData.isEmpty else {
            return "No data available for eating pattern analysis."
        }

        let daysWithMeals = weeklyData.filter { $0.calories > 0 }.count
        let totalDays = weeklyData.count

        if daysWithMeals >= Int(Double(totalDays) * 0.8) {
            return "Consistent daily tracking detected. You're maintaining regular meal logging habits."
        } else if daysWithMeals >= Int(Double(totalDays) * 0.5) {
            return "Moderate tracking pattern. Try to log meals more consistently for better insights."
        } else {
            return "Irregular tracking detected. Daily meal logging will provide more accurate nutrition insights."
        }
    }

    static func generateMacroBalanceInsight(from weeklyData: [DayData]) -> String {
        // Simplified macro balance analysis
        let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / Double(max(weeklyData.count, 1))

        if avgCalories > 2500 {
            return "High calorie intake detected. Consider balancing with more vegetables and lean proteins."
        } else if avgCalories > 1800 {
            return "Balanced calorie intake. Focus on maintaining good protein and fiber ratios."
        } else if avgCalories > 1200 {
            return "Moderate calorie intake. Ensure you're getting adequate nutrition for your activity level."
        } else {
            return "Low calorie intake detected. Consider consulting a nutritionist to ensure adequate nutrition."
        }
    }

    static func generateGoalProgressInsight(from weeklyData: [DayData]) -> String {
        let totalDays = weeklyData.count
        let activeDays = weeklyData.filter { $0.calories > 0 }.count
        let progressPercentage = totalDays > 0 ? (Double(activeDays) / Double(totalDays)) * 100 : 0

        if progressPercentage >= 80 {
            return "Excellent! You're \(Int(progressPercentage))% on track with your nutrition goals this week."
        } else if progressPercentage >= 60 {
            return "Good progress at \(Int(progressPercentage))%. A few more consistent days will improve your results."
        } else if progressPercentage >= 40 {
            return "You're \(Int(progressPercentage))% toward your goal. Try to increase daily tracking consistency."
        } else {
            return "Focus on daily meal logging to reach your nutrition goals. Current progress: \(Int(progressPercentage))%."
        }
    }

    static func generateNutritionRecommendation(from weeklyData: [DayData]) -> String {
        let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / Double(max(weeklyData.count, 1))
        let daysWithData = weeklyData.filter { $0.calories > 0 }.count

        if daysWithData < 3 {
            return "Log meals for at least 3-4 days to receive personalized nutrition recommendations."
        }

        if avgCalories < 1500 {
            return "Consider adding healthy snacks like nuts, fruits, or protein shakes to meet your energy needs."
        } else if avgCalories > 2800 {
            return "Focus on portion control and choose nutrient-dense, lower-calorie foods like vegetables and lean proteins."
        } else {
            return "Your calorie intake looks balanced. Focus on getting adequate protein (0.8-1g per kg body weight) and stay hydrated."
        }
    }
}