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

    /// Human readable FFMI category (TR)
    static func ffmiCategory(for ffmi: Double) -> String {
        switch ffmi {
        case ..<16: return "Ortalamanın Altı"
        case 16..<18: return "Ortalama"
        case 18..<21: return "Ortalamanın Üstü"
        case 21..<24: return "Mükemmel"
        case 24...25: return "Üstün"
        default: return "Şüpheli"
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

    /// Human readable body fat category (TR)
    static func bodyFatCategory(for bodyFat: Double, gender: Gender) -> String {
        switch gender {
        case .male:
            switch bodyFat {
            case 0..<6: return "Temel Yağ"
            case 6..<14: return "Atlet"
            case 14..<18: return "Fitness"
            case 18..<25: return "Ortalama"
            default: return "Obez"
            }
        case .female:
            switch bodyFat {
            case 0..<14: return "Temel Yağ"
            case 14..<21: return "Atlet"
            case 21..<25: return "Fitness"
            case 25..<32: return "Ortalama"
            default: return "Obez"
            }
        }
    }

    enum FitnessStage: String {
        case beginner = "Başlangıç"
        case intermediate = "Orta"
        case good = "İyi"
        case advanced = "İleri"
        case elite = "Elit"
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





