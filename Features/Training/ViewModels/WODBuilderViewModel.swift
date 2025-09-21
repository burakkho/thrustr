import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for WODBuilderView with clean separation of concerns.
 *
 * Manages WOD creation, movement management, validation logic,
 * and coordinates with database operations for workout building.
 */
@MainActor
@Observable
class WODBuilderViewModel {

    // MARK: - State
    var wodName = ""
    var wodType: WODType = .forTime
    var repScheme = ""
    var timeCap = ""
    var movements: [WODMovementData] = []
    var showingMovementPicker = false
    var editingMovement: WODMovementData?
    var errorMessage: String?
    var successMessage: String?
    var showingCancelAlert = false

    // MARK: - Dependencies
    private var modelContext: ModelContext?

    // MARK: - Supporting Types

    /**
     * Temporary data structure for building WOD movements.
     */
    struct WODMovementData: Identifiable {
        let id = UUID()
        var name: String
        var reps: String = ""
        var rxWeightMale: String = ""
        var rxWeightFemale: String = ""
        var scaledWeightMale: String = ""
        var scaledWeightFemale: String = ""
        var notes: String = ""
    }

    // MARK: - Computed Properties

    /**
     * Overall validation state for the WOD.
     */
    var isValid: Bool {
        isNameValid && hasMovements && isTimeCapValid && isRepSchemeValid
    }

    /**
     * Validates WOD name requirements.
     */
    var isNameValid: Bool {
        let trimmed = wodName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 2
    }

    /**
     * Validates that at least one movement is added.
     */
    var hasMovements: Bool {
        !movements.isEmpty
    }

    /**
     * Validates time cap for time-based WODs.
     */
    var isTimeCapValid: Bool {
        guard (wodType == .amrap || wodType == .emom) && !timeCap.isEmpty else { return true }
        guard let minutes = Int(timeCap), minutes > 0, minutes <= 60 else { return false }
        return true
    }

    /**
     * Validates rep scheme format for For Time WODs.
     */
    var isRepSchemeValid: Bool {
        guard wodType == .forTime && !repScheme.isEmpty else { return true }
        let components = repScheme.split(separator: "-")
        return components.allSatisfy { Int($0.trimmingCharacters(in: .whitespaces)) != nil }
    }

    /**
     * Detects if user has made any changes that would be lost.
     */
    var hasUnsavedChanges: Bool {
        !wodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !movements.isEmpty ||
        !repScheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !timeCap.isEmpty
    }

    /**
     * Common CrossFit movements for quick selection.
     */
    var suggestedMovements: [String] {
        [
            "Thrusters", "Pull-ups", "Push-ups", "Air Squats",
            "Burpees", "Box Jumps", "Wall Balls", "Kettlebell Swings",
            "Double-unders", "Toes-to-bar", "Clean and Jerk", "Snatches",
            "Deadlifts", "Handstand Push-ups", "Muscle-ups", "Row",
            "Run", "Assault Bike", "Ski Erg"
        ]
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /**
     * Sets the model context for database operations.
     */
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    /**
     * Updates WOD name with validation.
     */
    func updateWODName(_ name: String) {
        wodName = name
    }

    /**
     * Updates WOD type and resets conditional fields.
     */
    func updateWODType(_ type: WODType) {
        wodType = type

        // Reset conditional fields when type changes
        if type != .forTime {
            repScheme = ""
        }
        if type != .amrap && type != .emom {
            timeCap = ""
        }
    }

    /**
     * Updates rep scheme for For Time WODs.
     */
    func updateRepScheme(_ scheme: String) {
        repScheme = scheme
    }

    /**
     * Updates time cap for time-based WODs.
     */
    func updateTimeCap(_ cap: String) {
        timeCap = cap
    }

    /**
     * Adds a quick movement to the workout.
     */
    func addQuickMovement(_ name: String) {
        let movement = WODMovementData(name: name)
        movements.append(movement)
    }

    /**
     * Adds a custom movement to the workout.
     */
    func addMovement(_ movement: WODMovementData) {
        movements.append(movement)
    }

    /**
     * Updates an existing movement.
     */
    func updateMovement(_ updatedMovement: WODMovementData) {
        if let index = movements.firstIndex(where: { $0.id == updatedMovement.id }) {
            movements[index] = updatedMovement
        }
    }

    /**
     * Removes a movement from the workout.
     */
    func removeMovement(withId id: UUID) {
        movements.removeAll { $0.id == id }
    }

    /**
     * Shows movement picker modal.
     */
    func showMovementPicker() {
        showingMovementPicker = true
    }

    /**
     * Hides movement picker modal.
     */
    func hideMovementPicker() {
        showingMovementPicker = false
    }

    /**
     * Shows movement edit modal.
     */
    func editMovement(_ movement: WODMovementData) {
        editingMovement = movement
    }

    /**
     * Hides movement edit modal.
     */
    func hideMovementEdit() {
        editingMovement = nil
    }

    /**
     * Shows cancel confirmation alert.
     */
    func showCancelAlert() {
        showingCancelAlert = true
    }

    /**
     * Hides cancel confirmation alert.
     */
    func hideCancelAlert() {
        showingCancelAlert = false
    }

    /**
     * Validates and saves the WOD to database.
     */
    func saveWOD() async -> Result<Void, WODBuilderError> {
        // Pre-save validation
        guard isValid else {
            HapticManager.shared.notification(.error)
            errorMessage = "wod.fix_validation_errors".localized
            return .failure(.validationFailed)
        }

        guard let modelContext = modelContext else {
            errorMessage = "Database context not available"
            return .failure(.databaseError)
        }

        do {
            // Parse rep scheme
            let reps: [Int] = parseRepScheme()

            // Parse time cap
            let timeCapSeconds: Int? = parseTimeCap()

            // Create WOD
            let wod = WOD(
                name: wodName,
                type: wodType,
                repScheme: reps,
                timeCap: timeCapSeconds,
                isCustom: true
            )

            // Add movements
            for (index, movementData) in movements.enumerated() {
                let movement = WODMovement(
                    name: movementData.name,
                    rxWeightMale: movementData.rxWeightMale.isEmpty ? nil : movementData.rxWeightMale,
                    rxWeightFemale: movementData.rxWeightFemale.isEmpty ? nil : movementData.rxWeightFemale,
                    reps: movementData.reps.isEmpty ? nil : Int(movementData.reps),
                    orderIndex: index,
                    scaledWeightMale: movementData.scaledWeightMale.isEmpty ? nil : movementData.scaledWeightMale,
                    scaledWeightFemale: movementData.scaledWeightFemale.isEmpty ? nil : movementData.scaledWeightFemale,
                    notes: movementData.notes.isEmpty ? nil : movementData.notes
                )
                movement.wod = wod
                if wod.movements == nil { wod.movements = [] }
                wod.movements!.append(movement)
                modelContext.insert(movement)
            }

            modelContext.insert(wod)
            try modelContext.save()

            HapticManager.shared.notification(.success)
            successMessage = "wod.metcon_created_successfully".localized

            return .success(())

        } catch {
            HapticManager.shared.notification(.error)
            errorMessage = "wod.failed_to_save_metcon".localized + ": \(error.localizedDescription)"
            return .failure(.saveFailed(error))
        }
    }

    /**
     * Clears error message.
     */
    func clearError() {
        errorMessage = nil
    }

    /**
     * Clears success message.
     */
    func clearSuccess() {
        successMessage = nil
    }

    /**
     * Resets all form data to initial state.
     */
    func reset() {
        wodName = ""
        wodType = .forTime
        repScheme = ""
        timeCap = ""
        movements = []
        showingMovementPicker = false
        editingMovement = nil
        errorMessage = nil
        successMessage = nil
        showingCancelAlert = false
    }

    // MARK: - Private Methods

    private func parseRepScheme() -> [Int] {
        if wodType == .forTime {
            let components = repScheme.split(separator: "-")
            return components.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        return []
    }

    private func parseTimeCap() -> Int? {
        if let minutes = Int(timeCap) {
            return minutes * 60
        }
        return nil
    }

    /**
     * Gets validation error message for a specific field.
     */
    func getValidationError(for field: ValidationField) -> String? {
        switch field {
        case .name:
            if !wodName.isEmpty && !isNameValid {
                return "Name must be at least 2 characters"
            }
        case .repScheme:
            if !repScheme.isEmpty && !isRepSchemeValid {
                return "Rep scheme must contain valid numbers (e.g., 21-15-9)"
            }
        case .timeCap:
            if !timeCap.isEmpty && !isTimeCapValid {
                return "Time must be between 1-60 minutes"
            }
        case .movements:
            if !hasMovements {
                return "At least one movement is required"
            }
        }
        return nil
    }

    /**
     * Gets helper text for a specific field.
     */
    func getHelperText(for field: ValidationField) -> String? {
        switch field {
        case .repScheme where wodType == .forTime:
            return "wod.rep_scheme_examples".localized
        default:
            return nil
        }
    }
}

// MARK: - Supporting Types

/**
 * WOD builder errors.
 */
enum WODBuilderError: LocalizedError {
    case validationFailed
    case databaseError
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "Validation failed. Please check all fields."
        case .databaseError:
            return "Database error occurred"
        case .saveFailed(let error):
            return "Failed to save WOD: \(error.localizedDescription)"
        }
    }
}

/**
 * Validation fields enumeration.
 */
enum ValidationField {
    case name
    case repScheme
    case timeCap
    case movements
}