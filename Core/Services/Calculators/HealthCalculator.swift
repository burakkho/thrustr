import Foundation

/**
 * Health and fitness calculation utilities with comprehensive input validation.
 * 
 * This utility struct provides scientifically-backed calculations for fitness metrics
 * including BMR, TDEE, body composition, and strength assessments. All calculations
 * include proper input validation and reasonable bounds checking.
 * 
 * Supported calculations:
 * - Basal Metabolic Rate (Mifflin-St Jeor and Katch-McArdle equations)
 * - Total Daily Energy Expenditure with activity level adjustments
 * - Body composition metrics (BMI, body fat percentage)
 * - Fitness level assessments and strength ratings
 */
struct HealthCalculator: Sendable {
    
    /**
     * Calculates Basal Metabolic Rate using scientifically validated equations.
     * 
     * Uses Katch-McArdle equation when body fat percentage is available (more accurate),
     * otherwise falls back to Mifflin-St Jeor equation. Includes comprehensive input
     * validation and reasonable bounds checking.
     * 
     * - Parameters:
     *   - gender: User's biological gender (affects metabolic rate)
     *   - age: Age in years (10-120 valid range)
     *   - heightCm: Height in centimeters (100-250 valid range)  
     *   - weightKg: Weight in kilograms (30-300 valid range)
     *   - bodyFatPercentage: Optional body fat percentage (3-50% valid range)
     * - Returns: BMR in calories per day, clamped to 800-4000 reasonable range
     */
    static func calculateBMR(gender: Gender, age: Int, heightCm: Double, weightKg: Double, bodyFatPercentage: Double?) -> Double {
        // VALIDATION: Reasonable parameter ranges
        guard age >= 10 && age <= 120,           // 10-120 years
              heightCm >= 100 && heightCm <= 250, // 1m - 2.5m
              weightKg >= 30 && weightKg <= 300    // 30-300kg
        else {
            // Return conservative estimate for invalid inputs
            return gender == .male ? 1800 : 1500
        }
        
        // Use Katch-McArdle if body fat percentage is available and reasonable
        if let bf = bodyFatPercentage, bf >= 3 && bf <= 50 {
            let lbm = weightKg * (1 - bf / 100.0)
            let bmr = 370 + 21.6 * lbm
            return max(800, min(4000, bmr))  // Reasonable BMR range
        }
        
        // Use Mifflin-St Jeor equation
        let w = 10 * weightKg
        let h = 6.25 * heightCm  
        let a = 5 * Double(age)
        let bmr = gender == .male ? (w + h - a + 5) : (w + h - a - 161)
        return max(800, min(4000, bmr))  // Clamp to reasonable range
    }

    // FIXED: TDEE calculation with validation
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        // VALIDATION: BMR should be reasonable
        guard bmr >= 800 && bmr <= 4000 else {
            return 2000  // Default reasonable TDEE
        }
        
        let tdee = bmr * activityLevel.multiplier
        return max(1000, min(6000, tdee))  // Reasonable TDEE range
    }

    // FIXED: Daily calories calculation with validation
    static func calculateDailyCalories(tdee: Double, goal: FitnessGoal) -> Double {
        // VALIDATION: TDEE should be reasonable
        guard tdee >= 1000 && tdee <= 6000 else {
            return 2000  // Default reasonable daily calories
        }
        
        let dailyCalories = tdee * goal.calorieAdjustment
        return max(1000, min(5000, dailyCalories))  // Reasonable daily calorie range
    }

    // FIXED: Macros calculation with validation
    static func calculateMacros(weightKg: Double, dailyCalories: Double, goal: FitnessGoal) -> (protein: Double, carbs: Double, fat: Double) {
        // VALIDATION: Reasonable parameter ranges
        guard weightKg >= 30 && weightKg <= 300,           // 30-300kg
              dailyCalories >= 1000 && dailyCalories <= 5000  // 1000-5000 kcal
        else {
            // Return conservative macros for invalid inputs
            return (protein: 100, carbs: 200, fat: 70)  // ~1500 kcal balanced macros
        }
        
        // Calculate protein based on goal (with reasonable limits)
        let protein = max(50, min(300, weightKg * goal.proteinMultiplier))  // 50-300g protein
        
        // Fat: 25% of calories (with reasonable limits)
        let fat = max(30, min(150, (dailyCalories * 0.25) / 9.0))  // 30-150g fat
        
        // Carbs: remainder after protein and fat
        let remainingCalories = dailyCalories - (protein * 4.0) - (fat * 9.0)
        let carbs = max(50, remainingCalories / 4.0)  // Minimum 50g carbs
        
        return (protein: protein, carbs: carbs, fat: fat)
    }

    // FIXED: Navy Method Body Fat with improved validation
    static func calculateBodyFatNavy(gender: Gender, heightCm: Double, neckCm: Double?, waistCm: Double?, hipCm: Double?) -> Double? {
        guard let neck = neckCm, let waist = waistCm else { return nil }
        
        // VALIDATION: Reasonable measurement ranges (in CM)
        guard heightCm > 100 && heightCm < 250,  // 1m - 2.5m
              neck > 20 && neck < 60,             // 20-60cm neck
              waist > 50 && waist < 200           // 50-200cm waist
        else { return nil }
        
        let h = heightCm
        
        if gender == .male {
            // Male Navy Method: waist - neck difference must be positive
            guard waist > neck else { return nil }
            let d = 1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(h)
            guard d > 0 else { return nil }  // Prevent division by zero
            let result = 495 / d - 450
            return max(2.0, min(50.0, result))  // Reasonable body fat range 2-50%
        } else {
            guard let hip = hipCm, hip > 60 && hip < 200 else { return nil }  // 60-200cm hips
            // Female Navy Method: waist + hips - neck must be positive  
            guard (waist + hip) > neck else { return nil }
            let d = 1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(h)
            guard d > 0 else { return nil }  // Prevent division by zero
            let result = 495 / d - 450
            return max(8.0, min(50.0, result))  // Female essential fat starts ~8%
        }
    }
    
    // MARK: - Workout Calorie Estimation
    
    enum WorkoutIntensity: Sendable {
        case low, moderate, high, veryHigh
        
        var metValue: Double {
            switch self {
            case .low: return 3.0
            case .moderate: return 5.0
            case .high: return 8.0
            case .veryHigh: return 12.0
            }
        }
    }
    
    static func estimateStrengthTrainingCalories(duration: TimeInterval, bodyWeight: Double, intensity: WorkoutIntensity) -> Double {
        guard duration > 0 && bodyWeight > 0 else { return 0 }
        
        let hours = duration / 3600.0
        let metValue = intensity.metValue
        let calories = metValue * bodyWeight * hours
        
        return max(0, min(2000, calories)) // Reasonable range 0-2000 kcal
    }
    
    static func estimateMetconCalories(duration: TimeInterval, bodyWeight: Double, intensity: WorkoutIntensity) -> Double {
        guard duration > 0 && bodyWeight > 0 else { return 0 }
        
        let hours = duration / 3600.0
        let metValue = intensity.metValue
        let calories = metValue * bodyWeight * hours
        
        return max(0, min(2000, calories)) // Reasonable range 0-2000 kcal
    }
}


