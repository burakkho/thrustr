import Foundation
import SwiftUI
import Combine

// MARK: - Unit System
enum UnitSystem: String, Codable, CaseIterable, Equatable {
    case metric
    case imperial
}

// MARK: - Global Unit Settings
final class UnitSettings: ObservableObject {
    static let shared = UnitSettings()
    
    @Published var unitSystem: UnitSystem
    
    static let userDefaultsKey = "preferredUnitSystem"
    
    private init() {
        // Load from UserDefaults or use locale default
        if let raw = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let parsed = UnitSystem(rawValue: raw) {
            unitSystem = parsed
        } else {
            unitSystem = Self.defaultUnitSystemForLocale()
        }
        
        // Set up persistence after initialization
        setupPersistence()
    }
    
    private func setupPersistence() {
        // Listen to unitSystem changes and persist them
        $unitSystem
            .dropFirst() // Skip initial value
            .sink { newValue in
                Self.persist(newValue)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Updates the unit system and persists the change
    func updateUnitSystem(_ newSystem: UnitSystem) {
        unitSystem = newSystem
    }
    
    private static func defaultUnitSystemForLocale() -> UnitSystem {
        let region = Locale.current.region?.identifier ?? ""
        let imperialCountries = ["US", "LR", "MM"] // USA, Liberia, Myanmar
        return imperialCountries.contains(region) ? .imperial : .metric
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
    
    static func metersToMiles(_ meters: Double) -> Double { meters * 0.000621371 }
    static func milesToMeters(_ miles: Double) -> Double { miles * 1609.34 }
    
    static func kmhToMph(_ kmh: Double) -> Double { kmh * 0.621371 }
    static func mphToKmh(_ mph: Double) -> Double { mph * 1.60934 }
    
    static func minPerKmToMinPerMile(_ minPerKm: Double) -> Double { minPerKm * 1.60934 }
    static func minPerMileToMinPerKm(_ minPerMile: Double) -> Double { minPerMile * 0.621371 }
    
    static func gramToOz(_ grams: Double) -> Double { grams * 0.035274 }
    static func ozToGram(_ oz: Double) -> Double { oz * 28.3495 }
    
    // MARK: - Cardio-Specific Conversions
    
    static func getSplitDistance(system: UnitSystem) -> Double {
        switch system {
        case .metric:
            return 1000.0 // 1 km in meters
        case .imperial:
            return 1609.34 // 1 mile in meters
        }
    }
    
    static func calculateSplitNumber(totalMeters: Double, system: UnitSystem) -> Int {
        let splitDistance = getSplitDistance(system: system)
        return Int(totalMeters / splitDistance)
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
    
    static func formatDistance(meters: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            if meters < 1000 {
                return String(format: "%.0f m", meters)
            } else {
                return String(format: "%.2f km", meters / 1000)
            }
        case .imperial:
            let miles = UnitsConverter.metersToMiles(meters)
            if miles < 0.1 {
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                return String(format: "%.2f mi", miles)
            }
        }
    }
    
    static func formatSpeed(kmh: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.1f km/h", kmh)
        case .imperial:
            let mph = UnitsConverter.kmhToMph(kmh)
            return String(format: "%.1f mph", mph)
        }
    }
    
    static func formatPace(minPerKm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            let minutes = Int(minPerKm)
            let seconds = Int((minPerKm - Double(minutes)) * 60)
            return String(format: "%d:%02d min/km", minutes, seconds)
        case .imperial:
            let minPerMile = UnitsConverter.minPerKmToMinPerMile(minPerKm)
            let minutes = Int(minPerMile)
            let seconds = Int((minPerMile - Double(minutes)) * 60)
            return String(format: "%d:%02d min/mi", minutes, seconds)
        }
    }
    
    static func formatFoodWeight(grams: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.0f g", grams)
        case .imperial:
            let oz = UnitsConverter.gramToOz(grams)
            if oz >= 1.0 {
                return String(format: "%.1f oz", oz)
            } else {
                return String(format: "%.2f oz", oz)
            }
        }
    }
    
    // MARK: - Cardio-Specific Formatters
    
    static func formatShortDistance(meters: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            if meters < 100 {
                return String(format: "%.0f m", meters)
            } else if meters < 1000 {
                return String(format: "%.0f m", meters)
            } else {
                return String(format: "%.1f km", meters / 1000)
            }
        case .imperial:
            let miles = UnitsConverter.metersToMiles(meters)
            if miles < 0.01 {
                let yards = meters * 1.09361
                return String(format: "%.0f yd", yards)
            } else if miles < 0.1 {
                return String(format: "%.2f mi", miles)
            } else {
                return String(format: "%.1f mi", miles)
            }
        }
    }
    
    static func formatSplitDistance(splitNumber: Int, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "Km \(splitNumber)"
        case .imperial:
            return "Mile \(splitNumber)"
        }
    }
    
    static func formatDetailedPace(minPerKm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            let minutes = Int(minPerKm)
            let seconds = Int((minPerKm - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        case .imperial:
            let minPerMile = UnitsConverter.minPerKmToMinPerMile(minPerKm)
            let minutes = Int(minPerMile)
            let seconds = Int((minPerMile - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    static func formatPaceUnit(system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "min/km"
        case .imperial:
            return "min/mi"
        }
    }
    
    static func formatSpeedUnit(system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "km/h"
        case .imperial:
            return "mph"
        }
    }
}


