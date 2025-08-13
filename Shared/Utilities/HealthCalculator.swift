import Foundation

// MARK: - HealthCalculator
struct HealthCalculator {
    // BMR: Katch-McArdle (BF% varsa) veya Mifflin-St Jeor (yoksa)
    static func calculateBMR(gender: Gender, age: Int, heightCm: Double, weightKg: Double, bodyFatPercentage: Double?) -> Double {
        if let bf = bodyFatPercentage {
            let lbm = weightKg * (1 - bf / 100.0)
            return 370 + 21.6 * lbm
        }
        let w = 10 * weightKg
        let h = 6.25 * heightCm
        let a = 5 * Double(age)
        return gender == .male ? (w + h - a + 5) : (w + h - a - 161)
    }

    // TDEE: BMR * activity multiplier
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }

    // Daily calories: TDEE * goal adjustment
    static func calculateDailyCalories(tdee: Double, goal: FitnessGoal) -> Double {
        return tdee * goal.calorieAdjustment
    }

    // Macros: protein goal-sensitive, fat 25% cals, carbs remainder
    static func calculateMacros(weightKg: Double, dailyCalories: Double, goal: FitnessGoal) -> (protein: Double, carbs: Double, fat: Double) {
        let protein = weightKg * goal.proteinMultiplier
        let fat = (dailyCalories * 0.25) / 9.0
        let carbs = max(0, (dailyCalories - protein * 4.0 - fat * 9.0) / 4.0)
        return (protein, carbs, fat)
    }

    // Navy Method Body Fat
    static func calculateBodyFatNavy(gender: Gender, heightCm: Double, neckCm: Double?, waistCm: Double?, hipCm: Double?) -> Double? {
        guard let neck = neckCm, let waist = waistCm else { return nil }
        let h = heightCm
        if gender == .male {
            let d = 1.0324 - 0.19077 * log10(max(waist - neck, 0.1)) + 0.15456 * log10(h)
            return max(0, min(50, 495 / d - 450))
        } else {
            guard let hip = hipCm else { return nil }
            let d = 1.29579 - 0.35004 * log10(max(waist + hip - neck, 0.1)) + 0.22100 * log10(h)
            return max(0, min(50, 495 / d - 450))
        }
    }
}


