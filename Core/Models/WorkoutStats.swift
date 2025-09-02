import Foundation

struct WorkoutStats {
    let totalWorkouts: Int
    let totalDuration: TimeInterval // in seconds
    let totalCalories: Double // in kilocalories
    let totalDistance: Double // in meters
    let uniqueActivityTypes: Int
    let averageDuration: TimeInterval // in seconds
    let daysTracked: Int
    
    // Computed properties for display
    var totalDurationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
    
    var averageDurationFormatted: String {
        let minutes = Int(averageDuration) / 60
        return "\(minutes)dk"
    }
    
    var totalCaloriesFormatted: String {
        return "\(Int(totalCalories)) kcal"
    }
    
    var totalDistanceFormatted: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        } else {
            return "\(Int(totalDistance)) m"
        }
    }
    
    var workoutsPerWeek: Double {
        let weeks = Double(daysTracked) / 7.0
        return weeks > 0 ? Double(totalWorkouts) / weeks : 0
    }
    
    var workoutsPerWeekFormatted: String {
        return String(format: "%.1f/hafta", workoutsPerWeek)
    }
}

extension WorkoutStats {
    static let empty = WorkoutStats(
        totalWorkouts: 0,
        totalDuration: 0,
        totalCalories: 0,
        totalDistance: 0,
        uniqueActivityTypes: 0,
        averageDuration: 0,
        daysTracked: 30
    )
    
    static let mock = WorkoutStats(
        totalWorkouts: 24,
        totalDuration: 43200, // 12 hours
        totalCalories: 8500,
        totalDistance: 95000, // 95km
        uniqueActivityTypes: 5,
        averageDuration: 1800, // 30 minutes
        daysTracked: 30
    )
}