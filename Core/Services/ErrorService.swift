import Foundation

// MARK: - Pure Error Service (Business Logic Only)
// Handles error categorization, logging, and history management
// No UI dependencies - can be used across platforms

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

// MARK: - Pure Error Service
class ErrorService {
    static let shared = ErrorService()

    private var errorHistory: [ErrorContext] = []
    private let maxHistorySize = 50
    private let queue = DispatchQueue(label: "errorService.queue", qos: .utility)

    private init() {}

    // MARK: - Error Processing
    func processError(
        _ error: Error,
        severity: ErrorSeverity = .medium,
        source: String,
        userAction: String? = nil,
        additionalInfo: [String: String]? = nil
    ) -> ErrorContext {

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

        return context
    }

    // MARK: - Error Categorization
    func categorizeError(_ error: Error) -> AppError {
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

    // MARK: - Error Logging
    private func logError(_ context: ErrorContext) {
        queue.async {
            let logLevel = self.logLevelForSeverity(context.severity)
            print("\(logLevel) [\(context.source)] \(context.error.localizedDescription)")

            if let userAction = context.userAction {
                print("👤 User Action: \(userAction)")
            }

            if let info = context.additionalInfo {
                print("ℹ️ Additional Info: \(info)")
            }
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
        queue.async {
            self.errorHistory.insert(context, at: 0)

            if self.errorHistory.count > self.maxHistorySize {
                self.errorHistory.removeLast()
            }
        }
    }

    func getErrorHistory() -> [ErrorContext] {
        return queue.sync {
            return Array(errorHistory)
        }
    }

    func getRecentErrors(limit: Int = 10) -> [ErrorContext] {
        return queue.sync {
            return Array(errorHistory.prefix(limit))
        }
    }

    func clearHistory() {
        queue.async {
            self.errorHistory.removeAll()
        }
    }
}