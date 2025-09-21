import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for WODDetailView with clean separation of concerns.
 *
 * Manages WOD display data, favorite toggling, weight calculations,
 * and user interactions. Coordinates with database and services.
 */
@MainActor
@Observable
class WODDetailViewModel {

    // MARK: - State
    var isRX = true
    var selectedWeight: Double?
    var selectedWeights: [UUID: Double] = [:]
    var errorMessage: String?
    var successMessage: String?
    var isLoading = false

    // User data
    var currentUser: User?

    // MARK: - Dependencies
    private var modelContext: ModelContext?
    private let unitSettings = UnitSettings.shared

    // MARK: - Initialization
    init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    // MARK: - Data Loading

    /**
     * Load current user from database
     */
    private func loadCurrentUser() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            currentUser = users.first
        } catch {
            Logger.error("Failed to load current user: \(error)")
            errorMessage = "Failed to load user profile"
        }
    }

    /**
     * Get sorted WOD results for display
     */
    func getSortedResults(for wod: WOD) -> [WODResult] {
        return (wod.results ?? []).sorted { $0.completedAt > $1.completedAt }
    }

    /**
     * Prepare movements with selected weights for timer
     */
    func prepareMovementsForTimer(from wod: WOD) -> [WODMovement] {
        return (wod.movements ?? []).map { movement in
            let updatedMovement = movement
            updatedMovement.userWeight = selectedWeights[movement.id]
            updatedMovement.isRX = isRX
            return updatedMovement
        }
    }

    // MARK: - Favorite Management

    /**
     * Toggles favorite status for a WOD with proper database handling
     */
    func toggleFavorite(for wod: WOD) {
        guard let modelContext = modelContext else {
            errorMessage = "Database context not available"
            return
        }

        wod.isFavorite.toggle()

        do {
            try modelContext.save()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            successMessage = wod.isFavorite ? "Added to favorites" : "Removed from favorites"
        } catch {
            // Revert the toggle if save fails
            wod.isFavorite.toggle()
            errorMessage = "Failed to update favorite status"
            Logger.error("Failed to save favorite status: \(error)")
        }
    }

    // MARK: - Weight Calculations

    /**
     * Calculates and formats RX weight for display
     */
    func displayRxWeight(for movement: WODMovement, userGender: String?) -> String? {
        guard let rxWeight = movement.rxWeight(for: userGender) else { return nil }
        return formatWeightForDisplay(rxWeight)
    }

    /**
     * Calculates and formats Scaled weight for display
     */
    func displayScaledWeight(for movement: WODMovement, userGender: String?) -> String? {
        guard let scaledWeight = movement.scaledWeight(for: userGender) else { return nil }
        return formatWeightForDisplay(scaledWeight)
    }

    /**
     * Handles weight input changes with proper unit conversion
     */
    func handleWeightInput(_ inputText: String) -> Double? {
        guard let inputWeight = Double(inputText) else { return nil }

        // Always store in kg internally
        let weightInKg = unitSettings.unitSystem == .metric ?
            inputWeight :
            UnitsConverter.lbsToKg(inputWeight)

        selectedWeight = weightInKg
        return weightInKg
    }

    /**
     * Gets formatted weight text for input field
     */
    func getWeightInputText(for weight: Double?) -> String {
        guard let weight = weight else { return "" }

        let displayWeight = unitSettings.unitSystem == .metric ?
            weight :
            UnitsConverter.kgToLbs(weight)

        return String(format: "%.1f", displayWeight)
    }

    // MARK: - Private Helper Methods

    private func formatWeightForDisplay(_ weightString: String) -> String {
        // Parse weight value and convert to user's preferred units
        let numbers = weightString.filter { "0123456789.".contains($0) }

        if let weight = Double(numbers) {
            return UnitsFormatter.formatWeight(kg: weight, system: unitSettings.unitSystem)
        }

        return weightString // Fallback to original string
    }
}

// MARK: - Supporting Types

/**
 * Represents weight options for a movement
 */
struct MovementWeightData {
    let rxWeight: String?
    let scaledWeight: String?
    let displayRxWeight: String?
    let displayScaledWeight: String?
}