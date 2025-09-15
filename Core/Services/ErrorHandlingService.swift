//
//  ErrorHandlingService.swift
//  Thrustr
//
//  Created by Assistant on Error Analysis
//

import Foundation
import SwiftUI

// MARK: - App Error Types
enum AppError: LocalizedError {
    case databaseError(underlying: Error)
    case networkError(underlying: Error)
    case healthKitError(underlying: Error)
    case dataCorruption(description: String)
    case unknownError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .databaseError(let error):
            return "\(CommonKeys.ErrorHandling.databaseError.localized): \(error.localizedDescription)"
        case .networkError(let error):
            return "\(CommonKeys.ErrorHandling.networkError.localized): \(error.localizedDescription)"
        case .healthKitError(let error):
            return "\(CommonKeys.ErrorHandling.healthKitError.localized): \(error.localizedDescription)"
        case .dataCorruption(let description):
            return "\(CommonKeys.ErrorHandling.dataCorruption.localized): \(description)"
        case .unknownError(let error):
            return "\(CommonKeys.ErrorHandling.unknownError.localized): \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .databaseError:
            return CommonKeys.ErrorHandling.databaseRecovery.localized
        case .networkError:
            return CommonKeys.ErrorHandling.networkRecovery.localized
        case .healthKitError:
            return CommonKeys.ErrorHandling.healthKitRecovery.localized
        case .dataCorruption:
            return CommonKeys.ErrorHandling.dataCorruptionRecovery.localized
        case .unknownError:
            return CommonKeys.ErrorHandling.unknownRecovery.localized
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case low      // User can continue, just show a toast
    case medium   // Show alert, but app continues working
    case high     // Critical error, might require restart
    case critical // App state corrupted, emergency measures needed
}

// MARK: - Error Context
struct ErrorContext: Sendable {
    let error: AppError
    let severity: ErrorSeverity
    let source: String
    let timestamp: Date
    let userAction: String?
    let additionalInfo: [String: String]?
    
    init(
        error: AppError,
        severity: ErrorSeverity,
        source: String,
        userAction: String? = nil,
        additionalInfo: [String: String]? = nil
    ) {
        self.error = error
        self.severity = severity
        self.source = source
        self.timestamp = Date()
        self.userAction = userAction
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Error Handling Service
@Observable
class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    var currentError: ErrorContext?
    var showErrorAlert = false
    var errorHistory: [ErrorContext] = []
    var toastMessage: String?
    var toastType: ToastType = .info
    
    private let maxHistorySize = 50
    
    private init() {}
    
    // MARK: - Error Reporting
    func handle(_ error: Error, 
               severity: ErrorSeverity = .medium,
               source: String,
               userAction: String? = nil,
               additionalInfo: [String: String]? = nil) {
        
        let appError = categorizeError(error)
        let context = ErrorContext(
            error: appError,
            severity: severity,
            source: source,
            userAction: userAction,
            additionalInfo: additionalInfo
        )
        
        logError(context)
        addToHistory(context)
        
        switch severity {
        case .low:
            showToast(context.error.errorDescription ?? "Unknown error", type: .info)
        case .medium:
            showToast(context.error.errorDescription ?? "Unknown error", type: .warning)
        case .high:
            showCriticalError(context)
        case .critical:
            handleCriticalError(context)
        }
    }
    
    // MARK: - Error Categorization
    private func categorizeError(_ error: Error) -> AppError {
        if error.localizedDescription.contains("SQLite") || 
           error.localizedDescription.contains("SwiftData") {
            return .databaseError(underlying: error)
        }
        
        if error.localizedDescription.contains("network") ||
           error.localizedDescription.contains("URLSession") {
            return .networkError(underlying: error)
        }
        
        if error.localizedDescription.contains("HealthKit") {
            return .healthKitError(underlying: error)
        }
        
        return .unknownError(underlying: error)
    }
    
    // MARK: - Toast Methods
    func showToast(_ message: String, type: ToastType) {
        toastType = type
        toastMessage = message
        
        // Auto-clear toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.toastMessage = nil
        }
    }
    
    func showSuccessToast(_ message: String) {
        showToast(message, type: .success)
        DispatchQueue.main.async {
            HapticManager.shared.notification(.success)
        }
    }
    
    func showErrorToast(_ message: String) {
        showToast(message, type: .error)
        DispatchQueue.main.async {
            HapticManager.shared.notification(.error)
        }
    }
    
    // MARK: - UI Error Display
    private func showUserError(_ context: ErrorContext) {
        currentError = context
        showErrorAlert = true
    }
    
    private func showCriticalError(_ context: ErrorContext) {
        currentError = context
        showErrorAlert = true
        showErrorToast(context.error.errorDescription ?? "Critical error occurred")
    }
    
    private func handleCriticalError(_ context: ErrorContext) {
        showCriticalError(context)
        
        // Log critical error with more detail
        print("🚨 CRITICAL ERROR: \(context.error.localizedDescription)")
        print("📍 Source: \(context.source)")
        print("⏰ Time: \(context.timestamp)")
        
        // Could trigger emergency data backup, reset user preferences, etc.
    }
    
    // MARK: - Error Logging
    private func logError(_ context: ErrorContext) {
        let logLevel = logLevelForSeverity(context.severity)
        print("\(logLevel) [\(context.source)] \(context.error.localizedDescription)")
        
        if let userAction = context.userAction {
            print("👤 User Action: \(userAction)")
        }
        
        if let info = context.additionalInfo {
            print("ℹ️ Additional Info: \(info)")
        }
    }
    
    private func logLevelForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low: return "💛"
        case .medium: return "🔶"
        case .high: return "🔴"
        case .critical: return "🚨"
        }
    }
    
    // MARK: - Error History
    private func addToHistory(_ context: ErrorContext) {
        errorHistory.insert(context, at: 0)
        
        if errorHistory.count > maxHistorySize {
            errorHistory.removeLast()
        }
    }
    
    // MARK: - Recovery Actions
    func dismissCurrentError() {
        currentError = nil
        showErrorAlert = false
    }
    
    func retryLastAction() {
        // Could implement retry logic based on error context
        dismissCurrentError()
    }
    
    // MARK: - Utility Methods
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    func getRecentErrors(limit: Int = 10) -> [ErrorContext] {
        return Array(errorHistory.prefix(limit))
    }
}

// MARK: - Error Display View
struct ErrorAlertView: View {
    @State var errorService = ErrorHandlingService.shared
    
    var body: some View {
        EmptyView()
            .alert(
                CommonKeys.Onboarding.Common.error.localized,
                isPresented: $errorService.showErrorAlert,
                presenting: errorService.currentError
            ) { context in
                Button(CommonKeys.ErrorHandling.okButton.localized) {
                    errorService.dismissCurrentError()
                }
                
                if context.severity == .high || context.severity == .critical {
                    Button(CommonKeys.ErrorHandling.retryButton.localized) {
                        errorService.retryLastAction()
                    }
                }
            } message: { context in
                VStack(alignment: .leading, spacing: 8) {
                    Text(context.error.localizedDescription)
                    
                    if let suggestion = context.error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}