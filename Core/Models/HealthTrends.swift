import Foundation

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

enum TrendDirection {
    case increasing, decreasing, stable
    
    var displayText: String {
        switch self {
        case .increasing: return "Artış"
        case .decreasing: return "Azalış"
        case .stable: return "Sabit"
        }
    }
    
    var color: String {
        switch self {
        case .increasing: return "green"
        case .decreasing: return "red"
        case .stable: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

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

// MARK: - Health Data Trends Helper
struct HealthDataTrend {
    let dataPoints: [HealthDataPoint]
    let average: Double
    let trend: TrendDirection
    let percentChange: Double
    
    init(dataPoints: [HealthDataPoint]) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        
        let values = dataPoints.map { $0.value }
        self.average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        
        if dataPoints.count >= 2 {
            let halfIndex = dataPoints.count / 2
            let firstHalf = Array(dataPoints.prefix(halfIndex))
            let secondHalf = Array(dataPoints.suffix(dataPoints.count - halfIndex))
            
            let firstAvg = firstHalf.isEmpty ? 0 : firstHalf.map { $0.value }.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.isEmpty ? 0 : secondHalf.map { $0.value }.reduce(0, +) / Double(secondHalf.count)
            
            self.percentChange = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0
            
            if percentChange > 5 {
                self.trend = .increasing
            } else if percentChange < -5 {
                self.trend = .decreasing
            } else {
                self.trend = .stable
            }
        } else {
            self.trend = .stable
            self.percentChange = 0
        }
    }
}