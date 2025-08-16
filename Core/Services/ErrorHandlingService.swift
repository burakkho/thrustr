//
//  ErrorHandlingService.swift
//  SporHocam
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
            return "Veritabanı hatası: \(error.localizedDescription)"
        case .networkError(let error):
            return "Bağlantı hatası: \(error.localizedDescription)"
        case .healthKitError(let error):
            return "HealthKit hatası: \(error.localizedDescription)"
        case .dataCorruption(let description):
            return "Veri bozulması: \(description)"
        case .unknownError(let error):
            return "Bilinmeyen hata: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .databaseError:
            return "Uygulamayı yeniden başlatmayı deneyin. Sorun devam ederse, uygulamayı yeniden yükleyin."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
        case .healthKitError:
            return "HealthKit izinlerini kontrol edin ve tekrar deneyin."
        case .dataCorruption:
            return "Veri yeniden yüklenecek. Bu işlem birkaç dakika sürebilir."
        case .unknownError:
            return "Lütfen tekrar deneyin. Sorun devam ederse destek ile iletişime geçin."
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
struct ErrorContext {
    let error: AppError
    let severity: ErrorSeverity
    let source: String
    let timestamp: Date
    let userAction: String?
    let additionalInfo: [String: Any]?
    
    init(
        error: AppError,
        severity: ErrorSeverity,
        source: String,
        userAction: String? = nil,
        additionalInfo: [String: Any]? = nil
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
@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: ErrorContext?
    @Published var showErrorAlert = false
    @Published var errorHistory: [ErrorContext] = []
    
    private let maxHistorySize = 50
    
    private init() {}
    
    // MARK: - Error Reporting
    func handle(_ error: Error, 
               severity: ErrorSeverity = .medium,
               source: String,
               userAction: String? = nil,
               additionalInfo: [String: Any]? = nil) {
        
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
            // Just log, don't show UI
            break
        case .medium:
            showUserError(context)
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
    
    // MARK: - UI Error Display
    private func showUserError(_ context: ErrorContext) {
        currentError = context
        showErrorAlert = true
    }
    
    private func showCriticalError(_ context: ErrorContext) {
        currentError = context
        showErrorAlert = true
        
        // Additional critical error handling
        HapticManager.shared.notification(.error)
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
    @ObservedObject var errorService = ErrorHandlingService.shared
    
    var body: some View {
        EmptyView()
            .alert(
                "Hata",
                isPresented: $errorService.showErrorAlert,
                presenting: errorService.currentError
            ) { context in
                Button("Tamam") {
                    errorService.dismissCurrentError()
                }
                
                if context.severity == .high || context.severity == .critical {
                    Button("Tekrar Dene") {
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