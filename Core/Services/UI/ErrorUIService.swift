import SwiftUI

// MARK: - Error UI Service
// Handles UI state management for error display
// Toast notifications, alert states, and haptic feedback

@MainActor
@Observable
class ErrorUIService {
    static let shared = ErrorUIService()

    // MARK: - UI State Properties
    var currentError: ErrorContext?
    var showErrorAlert = false
    var toastMessage: String? {
        didSet {
            // Auto-clear toast if message is set
            if toastMessage != nil {
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                    if toastMessage == oldValue {
                        toastMessage = nil
                    }
                }
            }
        }
    }
    var toastType: ToastType = .info

    private init() {}

    // MARK: - Toast Methods
    func showToast(_ message: String, type: ToastType) {
        toastType = type
        toastMessage = message
        // Auto-clear handled by didSet
    }

    func showSuccessToast(_ message: String) {
        showToast(message, type: .success)
        HapticManager.shared.notification(.success)
    }

    func showErrorToast(_ message: String) {
        showToast(message, type: .error)
        HapticManager.shared.notification(.error)
    }

    func showWarningToast(_ message: String) {
        showToast(message, type: .warning)
        HapticManager.shared.notification(.warning)
    }

    func showInfoToast(_ message: String) {
        showToast(message, type: .info)
    }

    func clearToast() {
        toastMessage = nil
    }

    // MARK: - Alert Methods
    func showAlert(for context: ErrorContext) {
        currentError = context
        showErrorAlert = true
    }

    func showCriticalAlert(for context: ErrorContext) {
        currentError = context
        showErrorAlert = true
        showErrorToast(context.error.errorDescription ?? "Critical error occurred")
    }

    func dismissAlert() {
        currentError = nil
        showErrorAlert = false
    }

    // MARK: - UI Error Display Based on Severity
    func handleUIDisplay(for context: ErrorContext) {
        switch context.severity {
        case .low:
            showInfoToast(context.error.errorDescription ?? "Unknown error")
        case .medium:
            showWarningToast(context.error.errorDescription ?? "Unknown error")
        case .high:
            showCriticalAlert(for: context)
        case .critical:
            handleCriticalError(for: context)
        }
    }

    private func handleCriticalError(for context: ErrorContext) {
        showCriticalAlert(for: context)

        // Additional critical error handling
        print("🚨 CRITICAL UI ERROR: \(context.error.localizedDescription)")
        print("📍 Source: \(context.source)")
        print("⏰ Time: \(context.timestamp)")
    }

    // MARK: - Recovery Actions
    func retryLastAction() {
        // Could implement retry logic based on error context
        dismissAlert()
    }
}