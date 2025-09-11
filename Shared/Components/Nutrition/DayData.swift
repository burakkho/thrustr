import Foundation

struct DayData {
    let date: Date
    let dayName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

// MARK: - Helper Extensions
extension DayData {
    var totalMacroCalories: Double {
        return (protein * 4) + (carbs * 4) + (fat * 9)
    }
    
    var proteinPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (protein * 4) / totalMacroCalories
    }
    
    var carbsPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (carbs * 4) / totalMacroCalories
    }
    
    var fatPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (fat * 9) / totalMacroCalories
    }
}