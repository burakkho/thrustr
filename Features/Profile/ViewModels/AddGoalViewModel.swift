import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class AddGoalViewModel {

    // MARK: - Form State
    var title = ""
    var description = ""
    var targetValue = ""
    var selectedGoalType: GoalType = .weight
    var hasDeadline = false
    var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now

    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var showingSuccessMessage = false

    // MARK: - Computed Properties
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !targetValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(targetValue) != nil &&
        Double(targetValue)! > 0
    }

    var targetValueDouble: Double {
        Double(targetValue) ?? 0
    }

    var formattedTargetValue: String {
        switch selectedGoalType {
        case .weight:
            return "\(targetValue) kg"
        case .bodyFat:
            return "\(targetValue)%"
        case .muscle:
            return "\(targetValue) kg"
        case .strength:
            return "\(targetValue) kg"
        case .endurance:
            return "\(targetValue) min"
        case .flexibility:
            return "\(targetValue) cm"
        }
    }

    // MARK: - Dependencies
    private let goalService: GoalServiceProtocol

    // MARK: - Initialization
    init(goalType: GoalType = .weight,
         modelContext: ModelContext) {
        self.selectedGoalType = goalType
        self.goalService = GoalService(modelContext: modelContext)
    }

    // MARK: - Public Methods
    func saveGoal() async -> Bool {
        guard isFormValid else { return false }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            _ = try await goalService.createGoal(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                targetValue: targetValueDouble,
                type: selectedGoalType,
                deadline: hasDeadline ? deadline : nil
            )

            showingSuccessMessage = true

            // Reset form after successful save
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.resetForm()
            }

            return true

        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: .medium,
                source: "AddGoalViewModel.saveGoal"
            )
            errorMessage = context.error.errorDescription
            return false
        }
    }

    func resetForm() {
        title = ""
        description = ""
        targetValue = ""
        hasDeadline = false
        deadline = Date().addingTimeInterval(30 * 24 * 60 * 60)
        errorMessage = nil
        showingSuccessMessage = false
    }

    func clearError() {
        errorMessage = nil
    }

    func updateGoalType(_ newType: GoalType) {
        selectedGoalType = newType
        // Clear target value when switching types to avoid confusion
        targetValue = ""
    }

    // MARK: - Validation Helpers
    func validateTargetValue() -> String? {
        guard !targetValue.isEmpty else { return nil }

        guard let value = Double(targetValue), value > 0 else {
            return "Please enter a valid positive number"
        }

        // Type-specific validation
        switch selectedGoalType {
        case .bodyFat:
            if value > 50 {
                return "Body fat percentage should be realistic (0-50%)"
            }
        case .weight:
            if value < 30 || value > 300 {
                return "Weight should be between 30-300 kg"
            }
        case .strength:
            if value > 500 {
                return "Strength goal should be realistic (0-500 kg)"
            }
        case .endurance:
            if value > 240 {
                return "Endurance duration should be realistic (0-240 minutes)"
            }
        case .flexibility:
            if value > 100 {
                return "Flexibility goal should be realistic (0-100 cm)"
            }
        case .muscle:
            if value > 50 {
                return "Muscle gain goal should be realistic (0-50 kg)"
            }
        }

        return nil
    }

    func getPlaceholderText() -> String {
        switch selectedGoalType {
        case .weight:
            return "e.g., 75"
        case .bodyFat:
            return "e.g., 15"
        case .muscle:
            return "e.g., 2"
        case .strength:
            return "e.g., 100"
        case .endurance:
            return "e.g., 30"
        case .flexibility:
            return "e.g., 15"
        }
    }

    func getUnitText() -> String {
        switch selectedGoalType {
        case .weight, .muscle, .strength:
            return "kg"
        case .bodyFat:
            return "%"
        case .endurance:
            return "minutes"
        case .flexibility:
            return "cm"
        }
    }
}