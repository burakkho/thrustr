import Foundation
import SwiftUI

// MARK: - Health Data Point for Trends
struct HealthDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
    let unit: String
    
    init(date: Date, value: Double, unit: String = "") {
        self.date = date
        self.value = value
        self.unit = unit
    }
}

// MARK: - Workout Trends Analysis
struct WorkoutTrends {
    let totalWorkouts: Int
    let weeklyWorkouts: [WeeklyWorkoutData]
    let monthlyCalories: [MonthlyData]
    let activityTypeBreakdown: [ActivityTypeData]
    let averageDuration: TimeInterval
    let totalDuration: TimeInterval
    let longestWorkout: TimeInterval
    let totalCalories: Double
    let averageCaloriesPerWorkout: Double
    
    // Computed properties
    var trendsDirection: TrendDirection {
        guard weeklyWorkouts.count >= 2 else { return .stable }
        let recent = weeklyWorkouts.suffix(4).map { $0.workoutCount }
        let previous = weeklyWorkouts.prefix(weeklyWorkouts.count - 4).map { $0.workoutCount }
        
        let recentAvg = recent.isEmpty ? 0 : Double(recent.reduce(0, +)) / Double(recent.count)
        let previousAvg = previous.isEmpty ? 0 : Double(previous.reduce(0, +)) / Double(previous.count)
        
        let percentChange = previousAvg > 0 ? ((recentAvg - previousAvg) / previousAvg) * 100 : 0
        
        if percentChange > 10 { return .increasing }
        else if percentChange < -10 { return .decreasing }
        else { return .stable }
    }
    
    var workoutsPerWeek: Double {
        let weeks = Double(weeklyWorkouts.count)
        return weeks > 0 ? Double(totalWorkouts) / weeks : 0
    }
    
    var mostPopularActivity: String {
        activityTypeBreakdown.max(by: { $0.count < $1.count })?.activityType ?? "Bilinmiyor"
    }
}

// TrendDirection is now defined in Core/Models/TrendDirection.swift

struct WeeklyWorkoutData: Identifiable, Hashable {
    let id = UUID()
    let weekStartDate: Date
    let workoutCount: Int
    let totalDuration: TimeInterval
    let totalCalories: Double
    
    var weekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: weekStartDate)
    }
}

struct MonthlyData: Identifiable, Hashable {
    let id = UUID()
    let month: Date
    let value: Double
    
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }
}

struct ActivityTypeData: Identifiable, Hashable {
    let id = UUID()
    let activityType: String
    let count: Int
    let totalDuration: TimeInterval
    let percentage: Double
}

// MARK: - Extensions and Static Data
extension WorkoutTrends {
    static let empty = WorkoutTrends(
        totalWorkouts: 0,
        weeklyWorkouts: [],
        monthlyCalories: [],
        activityTypeBreakdown: [],
        averageDuration: 0,
        totalDuration: 0,
        longestWorkout: 0,
        totalCalories: 0,
        averageCaloriesPerWorkout: 0
    )
    
    static let mock = WorkoutTrends(
        totalWorkouts: 48,
        weeklyWorkouts: [
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-6*7*24*3600), workoutCount: 3, totalDuration: 5400, totalCalories: 1200),
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-5*7*24*3600), workoutCount: 4, totalDuration: 7200, totalCalories: 1600),
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-4*7*24*3600), workoutCount: 4, totalDuration: 7800, totalCalories: 1750),
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-3*7*24*3600), workoutCount: 5, totalDuration: 9000, totalCalories: 2000),
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-2*7*24*3600), workoutCount: 4, totalDuration: 7200, totalCalories: 1650),
            WeeklyWorkoutData(weekStartDate: Date().addingTimeInterval(-1*7*24*3600), workoutCount: 6, totalDuration: 10800, totalCalories: 2400),
            WeeklyWorkoutData(weekStartDate: Date(), workoutCount: 5, totalDuration: 9600, totalCalories: 2100)
        ],
        monthlyCalories: [
            MonthlyData(month: Date().addingTimeInterval(-3*30*24*3600), value: 12500),
            MonthlyData(month: Date().addingTimeInterval(-2*30*24*3600), value: 14200),
            MonthlyData(month: Date().addingTimeInterval(-1*30*24*3600), value: 15800),
            MonthlyData(month: Date(), value: 13900)
        ],
        activityTypeBreakdown: [
            ActivityTypeData(activityType: "Koşu", count: 18, totalDuration: 32400, percentage: 37.5),
            ActivityTypeData(activityType: "Güç Antrenmanı", count: 16, totalDuration: 28800, percentage: 33.3),
            ActivityTypeData(activityType: "Bisiklet", count: 8, totalDuration: 14400, percentage: 16.7),
            ActivityTypeData(activityType: "Yüzme", count: 6, totalDuration: 10800, percentage: 12.5)
        ],
        averageDuration: 1800,
        totalDuration: 86400,
        longestWorkout: 3600,
        totalCalories: 24000,
        averageCaloriesPerWorkout: 500
    )
}

// MARK: - Health Data Trends Helper with Statistical Analysis
struct HealthDataTrend {
    let dataPoints: [HealthDataPoint]
    let average: Double
    let median: Double
    let standardDeviation: Double
    let trend: TrendDirection
    let percentChange: Double
    let trendStrength: Double // R-squared value (0-1)
    let predictedNextValue: Double?
    let volatility: Double // Coefficient of variation
    
    init(dataPoints: [HealthDataPoint]) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        
        let values = dataPoints.map { $0.value }
        
        // Basic statistics
        let calculatedAverage = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        self.average = calculatedAverage
        
        // Calculate median
        let calculatedMedian: Double = {
            guard !values.isEmpty else { return 0 }
            let sorted = values.sorted()
            let count = sorted.count
            if count % 2 == 0 {
                return (sorted[count/2 - 1] + sorted[count/2]) / 2
            } else {
                return sorted[count/2]
            }
        }()
        self.median = calculatedMedian
        
        // Calculate standard deviation
        let calculatedStandardDeviation: Double = {
            guard values.count > 1, calculatedAverage > 0 else { return 0 }
            let variance = values.map { pow($0 - calculatedAverage, 2) }.reduce(0, +) / Double(values.count - 1)
            return sqrt(variance)
        }()
        self.standardDeviation = calculatedStandardDeviation
        
        // Calculate volatility
        self.volatility = calculatedAverage > 0 ? (calculatedStandardDeviation / calculatedAverage) * 100 : 0
        
        // Advanced trend analysis using linear regression
        if dataPoints.count >= 3 {
            let regression = HealthDataTrend.calculateLinearRegression(dataPoints: self.dataPoints)
            self.trendStrength = regression.rSquared
            self.predictedNextValue = regression.predictNext
            
            // Determine trend direction based on slope and significance
            let slope = regression.slope
            let isSignificant = regression.rSquared > 0.3 // R² > 0.3 indicates some trend
            
            let calculatedTrend: TrendDirection
            if isSignificant {
                if slope > 0.01 * calculatedAverage { // Slope > 1% of average value
                    calculatedTrend = .increasing
                } else if slope < -0.01 * calculatedAverage { // Slope < -1% of average value
                    calculatedTrend = .decreasing
                } else {
                    calculatedTrend = .stable
                }
            } else {
                calculatedTrend = .stable
            }
            self.trend = calculatedTrend
            
            // Calculate percent change using regression endpoints
            let firstPredicted = regression.intercept + regression.slope * 0
            let lastPredicted = regression.intercept + regression.slope * Double(dataPoints.count - 1)
            
            self.percentChange = firstPredicted > 0 ? ((lastPredicted - firstPredicted) / firstPredicted) * 100 : 0
            
        } else {
            // Fallback to simple analysis for insufficient data
            self.trendStrength = 0
            self.predictedNextValue = nil
            
            if dataPoints.count >= 2 {
                let firstValue = dataPoints.first?.value ?? 0
                let lastValue = dataPoints.last?.value ?? 0
                
                let calculatedPercentChange = firstValue > 0 ? ((lastValue - firstValue) / firstValue) * 100 : 0
                self.percentChange = calculatedPercentChange
                
                let calculatedTrend: TrendDirection
                if calculatedPercentChange > 5 {
                    calculatedTrend = .increasing
                } else if calculatedPercentChange < -5 {
                    calculatedTrend = .decreasing
                } else {
                    calculatedTrend = .stable
                }
                self.trend = calculatedTrend
            } else {
                self.trend = .stable
                self.percentChange = 0
            }
        }
    }
    
    // Linear regression calculation
    private static func calculateLinearRegression(dataPoints: [HealthDataPoint]) -> (slope: Double, intercept: Double, rSquared: Double, predictNext: Double?) {
        guard dataPoints.count >= 2 else {
            return (slope: 0, intercept: 0, rSquared: 0, predictNext: nil)
        }
        
        let n = Double(dataPoints.count)
        
        // Use index as x-value for time series analysis
        let xValues = Array(0..<dataPoints.count).map { Double($0) }
        let yValues = dataPoints.map { $0.value }
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        let _ = yValues.map { $0 * $0 }.reduce(0, +)
        
        // Calculate slope and intercept
        let denominator = n * sumX2 - sumX * sumX
        
        guard denominator != 0 else {
            return (slope: 0, intercept: sumY / n, rSquared: 0, predictNext: nil)
        }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        // Calculate R-squared
        let yMean = sumY / n
        let totalSumSquares = yValues.map { pow($0 - yMean, 2) }.reduce(0, +)
        
        if totalSumSquares == 0 {
            let rSquared: Double = slope == 0 ? 1.0 : 0.0
            return (slope: slope, intercept: intercept, rSquared: rSquared, predictNext: nil)
        }
        
        let predictedYValues = xValues.map { intercept + slope * $0 }
        let residualSumSquares = zip(yValues, predictedYValues).map { pow($0 - $1, 2) }.reduce(0, +)
        let rSquared = max(0, 1 - (residualSumSquares / totalSumSquares))
        
        // Predict next value
        let nextX = Double(dataPoints.count)
        let predictNext = intercept + slope * nextX
        
        return (slope: slope, intercept: intercept, rSquared: rSquared, predictNext: predictNext)
    }
    
    // MARK: - Trend Quality Assessment
    
    var trendQuality: TrendQuality {
        switch trendStrength {
        case 0.8...1.0: return .strong
        case 0.5..<0.8: return .moderate
        case 0.3..<0.5: return .weak
        default: return .none
        }
    }
    
    var isVolatile: Bool {
        return volatility > 20 // CV > 20% considered volatile
    }
    
    var confidenceLevel: Double {
        // Confidence based on data points and R-squared
        let dataConfidence = min(1.0, Double(dataPoints.count) / 30.0) // Max confidence with 30+ data points
        let trendConfidence = trendStrength
        return (dataConfidence + trendConfidence) / 2.0
    }
}

enum TrendQuality {
    case strong, moderate, weak, none
    
    var description: String {
        switch self {
        case .strong: return "Güçlü trend"
        case .moderate: return "Orta trend"
        case .weak: return "Zayıf trend"
        case .none: return "Trend yok"
        }
    }
    
    var color: String {
        switch self {
        case .strong: return "green"
        case .moderate: return "blue"
        case .weak: return "orange"
        case .none: return "gray"
        }
    }
}