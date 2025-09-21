import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for MeasurementsStepView with clean separation of concerns.
 *
 * Manages body measurements, Navy Method calculations, and validation.
 * Coordinates with NavyMethodCalculatorService for business logic.
 */
@MainActor
@Observable
class MeasurementsStepViewModel {

    // MARK: - State
    var neckCircumference: Double?
    var waistCircumference: Double?
    var hipCircumference: Double?
    var validationMessage: String?
    var calculatedBodyFat: Double?
    
    // MARK: - Dependencies
    private let unitSettings: UnitSettings
    
    // MARK: - Computed Properties
    
    /**
     * Whether Navy Method can be calculated with current inputs.
     */
    var canCalculateNavyMethod: Bool {
        guard let data = onboardingData else { return false }
        
        if data.gender == "male" {
            return neckCircumference != nil && waistCircumference != nil
        } else {
            return neckCircumference != nil && waistCircumference != nil && hipCircumference != nil
        }
    }
    
    /**
     * Navy Method body fat percentage if calculable.
     */
    var navyMethodBodyFat: Double? {
        guard canCalculateNavyMethod,
              let data = onboardingData,
              let neck = neckCircumference,
              let waist = waistCircumference else { return nil }

        let gender: NavyGender = data.gender == "male" ? .male : .female

        let result = NavyMethodCalculatorService.calculateBodyFat(
            gender: gender,
            age: data.age,
            height: data.height,
            heightFeet: nil as Int?,
            heightInches: nil as Int?,
            waist: waist,
            neck: neck,
            hips: hipCircumference,
            unitSystem: unitSettings.unitSystem
        )

        switch result {
        case .success(let bodyFat):
            return bodyFat
        case .failure:
            return nil
        }
    }
    
    // MARK: - Private Properties
    private var onboardingData: OnboardingData?
    
    // MARK: - Initialization
    
    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }
    
    // MARK: - Public Methods
    
    /**
     * Sets the onboarding data context.
     */
    func setOnboardingData(_ data: OnboardingData) {
        self.onboardingData = data
        
        // Pre-populate existing measurements
        neckCircumference = data.neckCircumference
        waistCircumference = data.waistCircumference
        hipCircumference = data.hipCircumference
        
        updateCalculations()
    }
    
    /**
     * Updates neck circumference with validation.
     */
    func updateNeckCircumference(_ value: Double?) {
        neckCircumference = value
        updateCalculations()
        _ = validateInputs()
    }

    /**
     * Updates waist circumference with validation.
     */
    func updateWaistCircumference(_ value: Double?) {
        waistCircumference = value
        updateCalculations()
        _ = validateInputs()
    }

    /**
     * Updates hip circumference with validation.
     */
    func updateHipCircumference(_ value: Double?) {
        hipCircumference = value
        updateCalculations()
        _ = validateInputs()
    }
    
    /**
     * Validates all inputs and returns error message if any.
     */
    func validateInputs() -> String? {
        // All measurements are optional, so no validation needed
        validationMessage = nil
        return nil
    }
    
    /**
     * Applies measurements to onboarding data.
     */
    func applyToOnboardingData(_ data: inout OnboardingData) {
        data.neckCircumference = neckCircumference
        data.waistCircumference = waistCircumference
        data.hipCircumference = hipCircumference
    }
    
    /**
     * Clears all measurements.
     */
    func clearMeasurements() {
        neckCircumference = nil
        waistCircumference = nil
        hipCircumference = nil
        calculatedBodyFat = nil
        validationMessage = nil
    }
    
    // MARK: - Helper Methods
    
    /**
     * Gets measurement range for specific measurement type.
     */
    func measurementRange(for measurementType: NavyMeasurementType) -> ClosedRange<Double> {
        let isImperial = unitSettings.unitSystem == .imperial

        switch measurementType {
        case .neck:
            return isImperial ? 10...20 : 25...50
        case .waist:
            return isImperial ? 20...60 : 50...150
        case .hip:
            return isImperial ? 25...60 : 70...150
        }
    }
    
    /**
     * Gets unit label for current unit system.
     */
    var unitLabel: String {
        return unitSettings.unitSystem == .metric ? "cm" : "in"
    }
    
    // MARK: - Private Methods
    
    private func updateCalculations() {
        calculatedBodyFat = navyMethodBodyFat
    }
}

// MARK: - Supporting Types

/**
 * Measurement type enumeration.
 */
enum NavyMeasurementType {
    case neck, waist, hip
}

/**
 * Input validation state for measurements.
 */
struct MeasurementValidation {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = MeasurementValidation(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> MeasurementValidation {
        return MeasurementValidation(isValid: false, errorMessage: message)
    }
}