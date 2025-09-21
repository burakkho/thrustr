import SwiftUI
import Foundation

// MARK: - NavyGender Enum

/**
 * Gender enumeration for Navy Method body fat calculations.
 *
 * Provides gender-specific properties and display information for body fat
 * calculation forms and results. Each gender has different calculation formulas
 * and classification ranges.
 */
enum NavyGender: String, CaseIterable, Sendable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male:
            return ProfileKeys.NavyMethodCalculator.male.localized
        case .female:
            return ProfileKeys.NavyMethodCalculator.female.localized
        }
    }

    var icon: String {
        switch self {
        case .male:
            return "person.fill"
        case .female:
            return "person.dress.fill"
        }
    }

    var color: Color {
        switch self {
        case .male:
            return .blue
        case .female:
            return .pink
        }
    }
}

// MARK: - BodyFatCategory Enum

/**
 * Body fat percentage category classification system.
 *
 * Provides standardized body fat categorization based on Navy Method calculations
 * and fitness industry standards. Includes gender-specific ranges and interpretations
 * for proper health assessment.
 *
 * Categories:
 * - Essential: Minimum fat required for basic physiological functions
 * - Athlete: Elite athlete performance level
 * - Fitness: Good fitness level for general population
 * - Average: Acceptable but not optimal level
 * - Obese: Health risk level requiring intervention
 */
enum BodyFatCategory: String, CaseIterable, Sendable {
    case essential = "essential"
    case athlete = "athlete"
    case fitness = "fitness"
    case average = "average"
    case obese = "obese"

    // MARK: - Display Properties

    var description: String {
        switch self {
        case .essential: return CommonKeys.Calculator.bodyFatEssential.localized
        case .athlete: return CommonKeys.Calculator.bodyFatAthlete.localized
        case .fitness: return CommonKeys.Calculator.bodyFatFitness.localized
        case .average: return CommonKeys.Calculator.bodyFatAverage.localized
        case .obese: return CommonKeys.Calculator.bodyFatObese.localized
        }
    }

    var interpretation: String {
        switch self {
        case .essential: return CommonKeys.Calculator.bodyFatEssentialDesc.localized
        case .athlete: return CommonKeys.Calculator.bodyFatAthleteDesc.localized
        case .fitness: return CommonKeys.Calculator.bodyFatFitnessDesc.localized
        case .average: return CommonKeys.Calculator.bodyFatAverageDesc.localized
        case .obese: return CommonKeys.Calculator.bodyFatObeseDesc.localized
        }
    }

    var color: Color {
        switch self {
        case .essential: return .blue
        case .athlete: return .green
        case .fitness: return .yellow
        case .average: return .orange
        case .obese: return .red
        }
    }

    // MARK: - Gender-Specific Ranges

    /**
     * Returns the body fat percentage range for this category based on gender.
     *
     * - Parameter gender: NavyGender (male/female)
     * - Returns: Formatted range string (e.g., "6-13%")
     */
    func range(for gender: NavyGender) -> String {
        switch (self, gender) {
        case (.essential, .male): return "2-5%"
        case (.essential, .female): return "10-13%"
        case (.athlete, .male): return "6-13%"
        case (.athlete, .female): return "14-20%"
        case (.fitness, .male): return "14-17%"
        case (.fitness, .female): return "21-24%"
        case (.average, .male): return "18-24%"
        case (.average, .female): return "25-31%"
        case (.obese, .male): return "25%+"
        case (.obese, .female): return "32%+"
        }
    }

    // MARK: - Classification Logic

    /**
     * Determines the body fat category for a given percentage and gender.
     *
     * Uses scientifically validated ranges for accurate health assessment.
     * Categories are based on fitness industry standards and medical research.
     *
     * - Parameters:
     *   - bodyFat: Body fat percentage (0-100)
     *   - gender: NavyGender for gender-specific classification
     * - Returns: Appropriate BodyFatCategory
     */
    static func category(for bodyFat: Double, gender: NavyGender) -> BodyFatCategory {
        switch gender {
        case .male:
            switch bodyFat {
            case 0..<6: return .essential
            case 6..<14: return .athlete
            case 14..<18: return .fitness
            case 18..<25: return .average
            default: return .obese
            }
        case .female:
            switch bodyFat {
            case 0..<14: return .essential
            case 14..<21: return .athlete
            case 21..<25: return .fitness
            case 25..<32: return .average
            default: return .obese
            }
        }
    }

    // MARK: - Health Assessment

    /**
     * Indicates if this category represents a healthy body fat level.
     */
    var isHealthy: Bool {
        switch self {
        case .essential, .athlete, .fitness, .average:
            return true
        case .obese:
            return false
        }
    }

    /**
     * Indicates if this category requires medical attention or intervention.
     */
    var requiresAttention: Bool {
        switch self {
        case .essential, .obese:
            return true
        case .athlete, .fitness, .average:
            return false
        }
    }
}