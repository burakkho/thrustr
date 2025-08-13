import Foundation
import SwiftUI

// MARK: - Unit System
enum UnitSystem: String, Codable, CaseIterable, Equatable {
    case metric
    case imperial
}

// MARK: - Global Unit Settings
final class UnitSettings: ObservableObject {
    @Published var unitSystem: UnitSystem {
        didSet { Self.persist(unitSystem) }
    }
    
    static let userDefaultsKey = "preferredUnitSystem"
    
    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let parsed = UnitSystem(rawValue: raw) {
            self.unitSystem = parsed
        } else {
            self.unitSystem = .metric
        }
    }
    
    private static func persist(_ system: UnitSystem) {
        UserDefaults.standard.set(system.rawValue, forKey: userDefaultsKey)
    }
}

// MARK: - Conversions
enum UnitsConverter {
    static func kgToLbs(_ kg: Double) -> Double { kg * 2.20462262 }
    static func lbsToKg(_ lbs: Double) -> Double { lbs * 0.45359237 }
    
    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12.0)
        let inches = Int((totalInches - Double(feet) * 12.0).rounded())
        return (feet: feet, inches: min(max(inches, 0), 11))
    }
    
    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet) * 12.0 + Double(inches)
        return totalInches * 2.54
    }
}

// MARK: - Formatting Helpers
enum UnitsFormatter {
    static func formatWeight(kg: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.1f kg", kg)
        case .imperial:
            let lbs = UnitsConverter.kgToLbs(kg)
            return String(format: "%.0f lb", lbs)
        }
    }
    
    static func formatVolume(kg: Double, system: UnitSystem) -> String {
        // Training volume (sum of weights). Follow same units as weight
        switch system {
        case .metric:
            return String(format: "%.0f kg", kg)
        case .imperial:
            let lbs = UnitsConverter.kgToLbs(kg)
            return String(format: "%.0f lb", lbs)
        }
    }

    static func formatHeight(cm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let (f, i) = UnitsConverter.cmToFeetInches(cm)
            return "\(f)' \(i)\""
        }
    }

    static func formatLength(cm: Double, system: UnitSystem) -> String {
        // For circumferences and generic lengths (neck, waist, hips)
        switch system {
        case .metric:
            return String(format: "%.1f cm", cm)
        case .imperial:
            let inches = cm / 2.54
            return String(format: "%.1f in", inches)
        }
    }
}


