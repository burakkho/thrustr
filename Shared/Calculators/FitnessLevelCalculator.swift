import Foundation

/// Calculates FFMI, Body Fat categories and an overall fitness level score
struct FitnessLevelCalculator {
    // MARK: - Public API

    /// Normalized FFMI using lean body mass; returns nil if bodyFatPercent is nil
    static func calculateNormalizedFFMI(weightKg: Double, heightCm: Double, bodyFatPercent: Double?) -> Double? {
        guard let bodyFatPercent = bodyFatPercent else { return nil }
        let leanMass = weightKg * (1.0 - bodyFatPercent / 100.0)
        let heightMeters = heightCm / 100.0
        let ffmi = leanMass / (heightMeters * heightMeters)
        // Normalization for height (1.8m reference)
        let normalized = ffmi + 6.1 * (1.8 - heightMeters)
        return normalized
    }

    /// Maps FFMI to points 0...4
    static func ffmiPoints(for ffmi: Double) -> Int {
        switch ffmi {
        case ..<16: return 0 // below average
        case 16..<18: return 1 // average
        case 18..<21: return 2 // above average
        case 21..<24: return 3 // excellent
        case 24...25: return 4 // superior
        default: return 4 // >25 suspicious but treat as 4 for score
        }
    }

    /// Human readable FFMI category
    static func ffmiCategory(for ffmi: Double) -> String {
        switch ffmi {
        case ..<16: return ProfileKeys.FFMICalculator.belowAverage.localized
        case 16..<18: return ProfileKeys.FFMICalculator.average.localized
        case 18..<21: return ProfileKeys.FFMICalculator.aboveAverage.localized
        case 21..<24: return ProfileKeys.FFMICalculator.excellent.localized
        case 24...25: return ProfileKeys.FFMICalculator.superior.localized
        default: return ProfileKeys.FFMICalculator.suspicious.localized
        }
    }

    /// Body fat category mapped to points 0...4 (depends on gender)
    static func bodyFatPoints(for bodyFat: Double, gender: Gender) -> Int {
        switch gender {
        case .male:
            switch bodyFat {
            case 0..<6: return 4 // essential
            case 6..<14: return 3 // athlete
            case 14..<18: return 2 // fitness
            case 18..<25: return 1 // average
            default: return 0 // obese
            }
        case .female:
            switch bodyFat {
            case 0..<14: return 4 // essential
            case 14..<21: return 3 // athlete
            case 21..<25: return 2 // fitness
            case 25..<32: return 1 // average
            default: return 0 // obese
            }
        }
    }

    /// Human readable body fat category
    static func bodyFatCategory(for bodyFat: Double, gender: Gender) -> String {
        switch gender {
        case .male:
            switch bodyFat {
            case 0..<6: return ProfileKeys.BodyFatCategories.essential.localized
            case 6..<14: return ProfileKeys.BodyFatCategories.athlete.localized
            case 14..<18: return ProfileKeys.BodyFatCategories.fitness.localized
            case 18..<25: return ProfileKeys.BodyFatCategories.average.localized
            default: return ProfileKeys.BodyFatCategories.obese.localized
            }
        case .female:
            switch bodyFat {
            case 0..<14: return ProfileKeys.BodyFatCategories.essential.localized
            case 14..<21: return ProfileKeys.BodyFatCategories.athlete.localized
            case 21..<25: return ProfileKeys.BodyFatCategories.fitness.localized
            case 25..<32: return ProfileKeys.BodyFatCategories.average.localized
            default: return ProfileKeys.BodyFatCategories.obese.localized
            }
        }
    }

    enum FitnessStage: String {
        case beginner
        case intermediate
        case good
        case advanced
        case elite
        
        var localizedString: String {
            switch self {
            case .beginner: return ProfileKeys.FitnessLevels.beginner.localized
            case .intermediate: return ProfileKeys.FitnessLevels.intermediate.localized
            case .good: return ProfileKeys.FitnessLevels.good.localized
            case .advanced: return ProfileKeys.FitnessLevels.advanced.localized
            case .elite: return ProfileKeys.FitnessLevels.elite.localized
            }
        }
    }

    /// Combines FFMI and body fat into a 0-100 score and stage label
    /// - Weights: FFMI 60%, Body Fat 40%. If one is missing, remaining metric is scaled to 100%.
    static func fitnessScore(ffmi: Double?, bodyFat: Double?, gender: Gender) -> (score: Int, stage: FitnessStage)? {
        if ffmi == nil && bodyFat == nil { return nil }
        var totalWeight: Double = 0
        var weightedScore: Double = 0

        if let ffmi = ffmi {
            let ffmiPoints = Double(ffmiPoints(for: ffmi)) // 0...4
            weightedScore += (ffmiPoints / 4.0) * 60.0
            totalWeight += 60.0
        }

        if let bodyFat = bodyFat {
            let bfPoints = Double(bodyFatPoints(for: bodyFat, gender: gender))
            weightedScore += (bfPoints / 4.0) * 40.0
            totalWeight += 40.0
        }

        // Scale if one metric is missing
        let score = totalWeight > 0 ? Int(round(weightedScore * 100.0 / totalWeight) / 1) : 0
        let stage = stageForScore(score)
        return (score, stage)
    }

    static func stageForScore(_ score: Int) -> FitnessStage {
        switch score {
        case ..<20: return .beginner
        case 20..<40: return .intermediate
        case 40..<60: return .good
        case 60..<80: return .advanced
        default: return .elite
        }
    }
}





