import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for BodyMeasurementsView with comprehensive form and data management.
 *
 * Manages UI state for body measurements tracking while coordinating with
 * BodyMeasurementService for data persistence and analytics. Follows modern
 * @Observable pattern for iOS 17+ with automatic UI updates.
 *
 * Responsibilities:
 * - Form state management for adding measurements
 * - Data filtering and organization for display
 * - Progress calculations and statistics
 * - Loading states and error handling
 * - Measurement persistence coordination
 */
@MainActor
@Observable
class BodyMeasurementsViewModel {

    // MARK: - Observable Properties

    // Form state
    var selectedMeasurement: MeasurementType = .chest
    var measurementValue = ""
    var selectedDate = Date()
    var notes = ""
    var showingAddMeasurement = false
    var showingSuccessAlert = false

    // UI state
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let bodyMeasurementService = BodyMeasurementService.self

    // MARK: - Initialization

    init() {
        // Default initializer for @State initialization
        // BodyMeasurementService uses static methods, no injection needed
    }

    // MARK: - Data Processing

    /**
     * Filters recent measurements from all measurements data.
     *
     * - Parameter allMeasurements: Complete list of body measurements
     * - Returns: Filtered measurements from last 6 months
     */
    func filterRecentMeasurements(_ allMeasurements: [BodyMeasurement]) -> [BodyMeasurement] {
        return bodyMeasurementService.filterRecentMeasurements(allMeasurements)
    }

    /**
     * Filters recent weight entries from all weight data.
     *
     * - Parameter allWeightEntries: Complete list of weight entries
     * - Returns: Filtered weight entries from last 6 months
     */
    func filterRecentWeightEntries(_ allWeightEntries: [WeightEntry]) -> [WeightEntry] {
        return bodyMeasurementService.filterRecentMeasurements(allWeightEntries)
    }

    /**
     * Gets the latest measurement for a specific body measurement type.
     *
     * - Parameters:
     *   - type: Measurement type to find
     *   - measurements: List of measurements to search
     * - Returns: Latest measurement of the specified type, if any
     */
    func getLatestMeasurement(for type: MeasurementType, from measurements: [BodyMeasurement]) -> BodyMeasurement? {
        return measurements.first { $0.typeEnum == type }
    }

    // MARK: - Progress Analytics

    /**
     * Calculates latest measurement date for progress display.
     *
     * - Parameter measurements: List of measurements
     * - Returns: Formatted date string of latest measurement
     */
    func getLatestMeasurementDate(from measurements: [BodyMeasurement]) -> String {
        let latest = measurements.max(by: { $0.date < $1.date })
        guard let date = latest?.date else { return "analytics.no_data".localized }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    /**
     * Calculates number of active measurement types being tracked.
     *
     * - Parameter measurements: List of measurements
     * - Returns: Count of unique measurement types
     */
    func getActiveMeasurementTypes(from measurements: [BodyMeasurement]) -> Int {
        let types = Set(measurements.map { $0.type })
        return types.count
    }

    /**
     * Determines if progress data should be shown.
     *
     * - Parameters:
     *   - measurements: Body measurements
     *   - weightEntries: Weight tracking entries
     * - Returns: Boolean indicating if progress section should display
     */
    func shouldShowProgress(measurements: [BodyMeasurement], weightEntries: [WeightEntry]) -> Bool {
        return !measurements.isEmpty || !weightEntries.isEmpty
    }

    // MARK: - Form Management

    /**
     * Validates measurement form data for completeness and correctness.
     */
    var isFormValid: Bool {
        guard !measurementValue.isEmpty else { return false }
        guard Double(measurementValue.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        return true
    }

    /**
     * Saves measurement using service with proper validation and error handling.
     *
     * - Parameters:
     *   - user: Current user profile
     *   - modelContext: SwiftData context for persistence
     */
    func saveMeasurement(user: User?, modelContext: ModelContext) {
        guard let value = Double(measurementValue.replacingOccurrences(of: ",", with: ".")) else {
            showError("Invalid measurement value")
            return
        }

        isLoading = true
        clearError()

        let result = bodyMeasurementService.saveMeasurement(
            type: selectedMeasurement,
            value: value,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            user: user,
            modelContext: modelContext
        )

        switch result {
        case .success:
            isLoading = false
            showingSuccessAlert = true
            resetForm()

        case .failure(let error):
            showError("Error saving measurement: \(error.localizedDescription)")
        }
    }

    /**
     * Resets form to default values after successful save.
     */
    func resetForm() {
        measurementValue = ""
        notes = ""
        selectedDate = Date()
        showingAddMeasurement = false
    }

    /**
     * Clears form completely including selected measurement type.
     */
    func clearForm() {
        selectedMeasurement = .chest
        measurementValue = ""
        notes = ""
        selectedDate = Date()
        clearError()
    }

    /**
     * Validates individual field input as user types.
     *
     * - Parameter value: Current measurement value
     * - Returns: Validation message or nil if valid
     */
    func validateMeasurementValue(_ value: String) -> String? {
        if value.isEmpty {
            return "Measurement value cannot be empty"
        }

        guard let numericValue = Double(value.replacingOccurrences(of: ",", with: ".")) else {
            return "Please enter a valid numeric value"
        }

        if numericValue <= 0 {
            return "Measurement value must be greater than zero"
        }

        if numericValue > 500 { // Reasonable upper limit for body measurements in cm
            return "Measurement value seems unreasonably high"
        }

        return nil
    }

    // MARK: - UI State Management

    /**
     * Shows add measurement form.
     */
    func showAddMeasurementForm() {
        showingAddMeasurement = true
    }

    /**
     * Dismisses add measurement form.
     */
    func dismissAddMeasurementForm() {
        showingAddMeasurement = false
    }

    // MARK: - Error Handling

    /**
     * Shows error message to user.
     *
     * - Parameter message: Error message to display
     */
    private func showError(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    /**
     * Clears current error state.
     */
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Formatting Helpers

    /**
     * Formats date for measurement display.
     *
     * - Parameter date: Date to format
     * - Returns: Short formatted date string
     */
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    /**
     * Determines if empty state should be shown.
     *
     * - Parameters:
     *   - measurements: Body measurements
     *   - weightEntries: Weight entries
     * - Returns: Boolean indicating if empty state should display
     */
    func shouldShowEmptyState(measurements: [BodyMeasurement], weightEntries: [WeightEntry]) -> Bool {
        return measurements.isEmpty && weightEntries.isEmpty
    }

    /**
     * Gets appropriate empty state message based on context.
     *
     * - Returns: Localized empty state message
     */
    func getEmptyStateMessage() -> String {
        return "body_measurements.empty_state_message".localized
    }

    // MARK: - Data Analytics

    /**
     * Calculates progress statistics for display.
     *
     * - Parameters:
     *   - measurements: Body measurements
     *   - weightEntries: Weight entries
     * - Returns: Progress statistics structure
     */
    func calculateProgressStats(measurements: [BodyMeasurement], weightEntries: [WeightEntry]) -> ProgressStats {
        return ProgressStats(
            totalMeasurements: measurements.count,
            totalWeightEntries: weightEntries.count,
            latestMeasurementDate: getLatestMeasurementDate(from: measurements),
            activeMeasurementTypes: getActiveMeasurementTypes(from: measurements)
        )
    }
}

// MARK: - Supporting Types

/**
 * Progress statistics structure for dashboard display.
 */
struct ProgressStats {
    let totalMeasurements: Int
    let totalWeightEntries: Int
    let latestMeasurementDate: String
    let activeMeasurementTypes: Int
}