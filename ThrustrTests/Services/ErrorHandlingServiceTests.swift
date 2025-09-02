import XCTest
import SwiftUI
@testable import Thrustr

/**
 * Comprehensive tests for ErrorHandlingService
 * Tests error handling, categorization, logging, user feedback, and recovery actions
 */
@MainActor
final class ErrorHandlingServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    private var errorService: ErrorHandlingService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        errorService = ErrorHandlingService.shared
        errorService.clearHistory() // Clean slate for each test
        errorService.dismissCurrentError() // Clear any existing error
    }
    
    override func tearDown() async throws {
        errorService.clearHistory()
        errorService.dismissCurrentError()
        try await super.tearDown()
    }
    
    // MARK: - AppError Tests
    
    func testAppErrorDescriptions() {
        // Given - Different app errors
        let testError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let errors: [AppError] = [
            .databaseError(underlying: testError),
            .networkError(underlying: testError),
            .healthKitError(underlying: testError),
            .dataCorruption(description: "Test corruption"),
            .unknownError(underlying: testError)
        ]
        
        // When & Then
        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error \(error) should have description")
            
            switch error {
            case .databaseError:
                XCTAssertTrue(description.contains("Veritabanı hatası"))
            case .networkError:
                XCTAssertTrue(description.contains("Bağlantı hatası"))
            case .healthKitError:
                XCTAssertTrue(description.contains("HealthKit hatası"))
            case .dataCorruption:
                XCTAssertTrue(description.contains("Veri bozulması"))
            case .unknownError:
                XCTAssertTrue(description.contains("Bilinmeyen hata"))
            }
        }
    }
    
    func testAppErrorRecoverySuggestions() {
        // Given - Different app errors
        let testError = NSError(domain: "TestDomain", code: 1001)
        
        let errors: [AppError] = [
            .databaseError(underlying: testError),
            .networkError(underlying: testError),
            .healthKitError(underlying: testError),
            .dataCorruption(description: "Test corruption"),
            .unknownError(underlying: testError)
        ]
        
        // When & Then
        for error in errors {
            let suggestion = error.recoverySuggestion
            XCTAssertNotNil(suggestion, "Error \(error) should have recovery suggestion")
            XCTAssertFalse(suggestion!.isEmpty, "Recovery suggestion should not be empty")
        }
    }
    
    // MARK: - ErrorSeverity Tests
    
    func testErrorSeverityLevels() {
        // Test all severity levels exist
        let severities: [ErrorSeverity] = [.low, .medium, .high, .critical]
        
        for severity in severities {
            // Each severity should be accessible
            switch severity {
            case .low:
                print("Low severity error")
            case .medium:
                print("Medium severity error")
            case .high:
                print("High severity error")
            case .critical:
                print("Critical severity error")
            }
        }
        
        XCTAssertEqual(severities.count, 4)
    }
    
    // MARK: - ErrorContext Tests
    
    func testErrorContextInitialization() {
        // Given
        let testError = AppError.networkError(underlying: NSError(domain: "Test", code: 1))
        let source = "TestClass.testMethod"
        let userAction = "User tapped refresh button"
        let additionalInfo: [String: Any] = ["userId": 123, "timestamp": Date()]
        
        // When
        let context = ErrorContext(
            error: testError,
            severity: .medium,
            source: source,
            userAction: userAction,
            additionalInfo: additionalInfo
        )
        
        // Then
        XCTAssertEqual(context.source, source)
        XCTAssertEqual(context.severity, .medium)
        XCTAssertEqual(context.userAction, userAction)
        XCTAssertNotNil(context.timestamp)
        XCTAssertNotNil(context.additionalInfo)
        
        // Check additional info
        let userId = context.additionalInfo?["userId"] as? Int
        XCTAssertEqual(userId, 123)
    }
    
    func testErrorContextMinimalInitialization() {
        // Given
        let testError = AppError.unknownError(underlying: NSError(domain: "Test", code: 1))
        
        // When
        let context = ErrorContext(
            error: testError,
            severity: .low,
            source: "TestSource"
        )
        
        // Then
        XCTAssertNil(context.userAction)
        XCTAssertNil(context.additionalInfo)
        XCTAssertNotNil(context.timestamp)
    }
    
    // MARK: - ErrorHandlingService Initial State Tests
    
    func testInitialState() {
        // Then
        XCTAssertNil(errorService.currentError)
        XCTAssertFalse(errorService.showErrorAlert)
        XCTAssertTrue(errorService.errorHistory.isEmpty)
    }
    
    func testSingletonPattern() {
        // Given
        let service1 = ErrorHandlingService.shared
        let service2 = ErrorHandlingService.shared
        
        // Then
        XCTAssertIdentical(service1, service2)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleLowSeverityError() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When
        errorService.handle(
            testError,
            severity: .low,
            source: "TestSource",
            userAction: "Test action"
        )
        
        // Then - Should log but not show UI
        XCTAssertNil(errorService.currentError)
        XCTAssertFalse(errorService.showErrorAlert)
        XCTAssertEqual(errorService.errorHistory.count, 1)
        
        let historyError = errorService.errorHistory.first!
        XCTAssertEqual(historyError.severity, .low)
        XCTAssertEqual(historyError.source, "TestSource")
        XCTAssertEqual(historyError.userAction, "Test action")
    }
    
    func testHandleMediumSeverityError() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 1001)
        
        // When
        errorService.handle(
            testError,
            severity: .medium,
            source: "TestSource"
        )
        
        // Then - Should show user error
        XCTAssertNotNil(errorService.currentError)
        XCTAssertTrue(errorService.showErrorAlert)
        XCTAssertEqual(errorService.currentError?.severity, .medium)
        XCTAssertEqual(errorService.errorHistory.count, 1)
    }
    
    func testHandleHighSeverityError() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 1001)
        
        // When
        errorService.handle(
            testError,
            severity: .high,
            source: "CriticalComponent"
        )
        
        // Then - Should show critical error
        XCTAssertNotNil(errorService.currentError)
        XCTAssertTrue(errorService.showErrorAlert)
        XCTAssertEqual(errorService.currentError?.severity, .high)
    }
    
    func testHandleCriticalSeverityError() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 1001)
        
        // When
        errorService.handle(
            testError,
            severity: .critical,
            source: "DatabaseCore"
        )
        
        // Then - Should handle as critical
        XCTAssertNotNil(errorService.currentError)
        XCTAssertTrue(errorService.showErrorAlert)
        XCTAssertEqual(errorService.currentError?.severity, .critical)
        XCTAssertEqual(errorService.errorHistory.count, 1)
    }
    
    // MARK: - Error Categorization Tests
    
    func testDatabaseErrorCategorization() {
        // Given - Errors that should be categorized as database errors
        let sqliteError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "SQLite error occurred"])
        let swiftDataError = NSError(domain: "TestDomain", code: 1002, userInfo: [NSLocalizedDescriptionKey: "SwiftData failed"])
        
        // When
        errorService.handle(sqliteError, severity: .medium, source: "TestSource")
        errorService.handle(swiftDataError, severity: .medium, source: "TestSource")
        
        // Then
        XCTAssertEqual(errorService.errorHistory.count, 2)
        
        for errorContext in errorService.errorHistory {
            if case .databaseError = errorContext.error {
                // Expected behavior
            } else {
                XCTFail("Should categorize as database error")
            }
        }
    }
    
    func testNetworkErrorCategorization() {
        // Given
        let networkError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "network timeout"])
        let urlSessionError = NSError(domain: "TestDomain", code: 1002, userInfo: [NSLocalizedDescriptionKey: "URLSession failed"])
        
        // When
        errorService.handle(networkError, severity: .medium, source: "TestSource")
        errorService.handle(urlSessionError, severity: .medium, source: "TestSource")
        
        // Then
        for errorContext in errorService.errorHistory {
            if case .networkError = errorContext.error {
                // Expected behavior
            } else {
                XCTFail("Should categorize as network error")
            }
        }
    }
    
    func testHealthKitErrorCategorization() {
        // Given
        let healthKitError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "HealthKit authorization failed"])
        
        // When
        errorService.handle(healthKitError, severity: .medium, source: "TestSource")
        
        // Then
        let errorContext = errorService.errorHistory.first!
        if case .healthKitError = errorContext.error {
            // Expected behavior
        } else {
            XCTFail("Should categorize as HealthKit error")
        }
    }
    
    func testUnknownErrorCategorization() {
        // Given
        let genericError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Some generic error"])
        
        // When
        errorService.handle(genericError, severity: .medium, source: "TestSource")
        
        // Then
        let errorContext = errorService.errorHistory.first!
        if case .unknownError = errorContext.error {
            // Expected behavior
        } else {
            XCTFail("Should categorize as unknown error")
        }
    }
    
    // MARK: - Error History Tests
    
    func testErrorHistoryManagement() {
        // Given - Multiple errors
        let errors = (1...5).map { i in
            NSError(domain: "TestDomain", code: i, userInfo: [NSLocalizedDescriptionKey: "Error \(i)"])
        }
        
        // When - Handle multiple errors
        for error in errors {
            errorService.handle(error, severity: .low, source: "TestSource")
        }
        
        // Then - Should store in history
        XCTAssertEqual(errorService.errorHistory.count, 5)
        
        // Should be in reverse chronological order (newest first)
        let firstError = errorService.errorHistory.first!
        let lastError = errorService.errorHistory.last!
        XCTAssertGreaterThan(firstError.timestamp, lastError.timestamp)
    }
    
    func testErrorHistoryLimit() {
        // Given - More errors than history limit
        let errorCount = 55 // More than maxHistorySize (50)
        
        // When - Handle many errors
        for i in 1...errorCount {
            let error = NSError(domain: "TestDomain", code: i)
            errorService.handle(error, severity: .low, source: "TestSource")
        }
        
        // Then - Should limit history size
        XCTAssertEqual(errorService.errorHistory.count, 50) // maxHistorySize
    }
    
    func testClearHistory() {
        // Given - Some errors in history
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .low, source: "TestSource")
        XCTAssertFalse(errorService.errorHistory.isEmpty)
        
        // When
        errorService.clearHistory()
        
        // Then
        XCTAssertTrue(errorService.errorHistory.isEmpty)
    }
    
    func testGetRecentErrors() {
        // Given - Multiple errors
        for i in 1...15 {
            let error = NSError(domain: "TestDomain", code: i)
            errorService.handle(error, severity: .low, source: "TestSource")
        }
        
        // When
        let recentErrors = errorService.getRecentErrors(limit: 5)
        
        // Then
        XCTAssertEqual(recentErrors.count, 5)
        XCTAssertEqual(errorService.errorHistory.count, 15) // Original history unchanged
        
        // Default limit test
        let defaultRecentErrors = errorService.getRecentErrors()
        XCTAssertEqual(defaultRecentErrors.count, 10)
    }
    
    // MARK: - Recovery Actions Tests
    
    func testDismissCurrentError() {
        // Given - Current error set
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .medium, source: "TestSource")
        XCTAssertNotNil(errorService.currentError)
        XCTAssertTrue(errorService.showErrorAlert)
        
        // When
        errorService.dismissCurrentError()
        
        // Then
        XCTAssertNil(errorService.currentError)
        XCTAssertFalse(errorService.showErrorAlert)
    }
    
    func testRetryLastAction() {
        // Given - Current error
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .medium, source: "TestSource")
        XCTAssertNotNil(errorService.currentError)
        
        // When
        errorService.retryLastAction()
        
        // Then - Should dismiss current error
        XCTAssertNil(errorService.currentError)
        XCTAssertFalse(errorService.showErrorAlert)
    }
    
    // MARK: - UI State Tests
    
    func testErrorAlertState() {
        // Given - No current error
        XCTAssertFalse(errorService.showErrorAlert)
        
        // When - Handle medium severity error
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .medium, source: "TestSource")
        
        // Then
        XCTAssertTrue(errorService.showErrorAlert)
        XCTAssertNotNil(errorService.currentError)
    }
    
    func testMultipleErrorsOverwrite() {
        // Given - First error
        let error1 = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "First error"])
        errorService.handle(error1, severity: .medium, source: "Source1")
        
        let firstCurrentError = errorService.currentError
        
        // When - Second error
        let error2 = NSError(domain: "TestDomain", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Second error"])
        errorService.handle(error2, severity: .medium, source: "Source2")
        
        // Then - Should overwrite current error
        XCTAssertNotEqual(errorService.currentError?.source, firstCurrentError?.source)
        XCTAssertEqual(errorService.currentError?.source, "Source2")
        XCTAssertEqual(errorService.errorHistory.count, 2) // But both should be in history
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedPropertiesUpdates() {
        // Test that @Published properties trigger updates
        var currentErrorUpdated = false
        var showErrorAlertUpdated = false
        var errorHistoryUpdated = false
        
        let currentErrorCancellable = errorService.$currentError.sink { _ in
            currentErrorUpdated = true
        }
        
        let showErrorCancellable = errorService.$showErrorAlert.sink { _ in
            showErrorAlertUpdated = true
        }
        
        let historyUpdateCancellable = errorService.$errorHistory.sink { _ in
            errorHistoryUpdated = true
        }
        
        // When
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .medium, source: "TestSource")
        
        // Then
        XCTAssertTrue(currentErrorUpdated)
        XCTAssertTrue(showErrorAlertUpdated)
        XCTAssertTrue(errorHistoryUpdated)
        
        // Cleanup
        currentErrorCancellable.cancel()
        showErrorCancellable.cancel()
        historyUpdateCancellable.cancel()
    }
    
    // MARK: - Error With Additional Info Tests
    
    func testErrorWithAdditionalInfo() {
        // Given
        let error = NSError(domain: "TestDomain", code: 1001)
        let additionalInfo: [String: Any] = [
            "userId": 123,
            "deviceModel": "iPhone14,1",
            "appVersion": "1.0.0",
            "timestamp": Date()
        ]
        
        // When
        errorService.handle(
            error,
            severity: .medium,
            source: "UserProfile",
            userAction: "Updating profile",
            additionalInfo: additionalInfo
        )
        
        // Then
        let errorContext = errorService.errorHistory.first!
        XCTAssertNotNil(errorContext.additionalInfo)
        XCTAssertEqual(errorContext.additionalInfo?["userId"] as? Int, 123)
        XCTAssertEqual(errorContext.additionalInfo?["deviceModel"] as? String, "iPhone14,1")
        XCTAssertEqual(errorContext.additionalInfo?["appVersion"] as? String, "1.0.0")
        XCTAssertEqual(errorContext.userAction, "Updating profile")
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        // Measure performance of error handling
        measure {
            for i in 1...100 {
                let error = NSError(domain: "TestDomain", code: i)
                errorService.handle(error, severity: .low, source: "PerformanceTest")
            }
        }
    }
    
    func testLargeErrorHistoryPerformance() {
        // Test performance with large error history
        
        // Given - Fill up to history limit
        for i in 1...50 {
            let error = NSError(domain: "TestDomain", code: i)
            errorService.handle(error, severity: .low, source: "HistoryTest")
        }
        
        // When - Measure adding more errors (should trigger cleanup)
        measure {
            for i in 51...60 {
                let error = NSError(domain: "TestDomain", code: i)
                errorService.handle(error, severity: .low, source: "HistoryTest")
            }
        }
        
        // Then - History should still be at limit
        XCTAssertEqual(errorService.errorHistory.count, 50)
    }
    
    // MARK: - Edge Cases Tests
    
    func testHandleNilUserAction() {
        // Given
        let error = NSError(domain: "TestDomain", code: 1001)
        
        // When
        errorService.handle(error, severity: .medium, source: "TestSource", userAction: nil)
        
        // Then
        let errorContext = errorService.errorHistory.first!
        XCTAssertNil(errorContext.userAction)
    }
    
    func testHandleEmptySource() {
        // Given
        let error = NSError(domain: "TestDomain", code: 1001)
        
        // When
        errorService.handle(error, severity: .medium, source: "")
        
        // Then
        let errorContext = errorService.errorHistory.first!
        XCTAssertEqual(errorContext.source, "")
    }
    
    func testConsecutiveDismissals() {
        // Given - Current error
        let error = NSError(domain: "TestDomain", code: 1001)
        errorService.handle(error, severity: .medium, source: "TestSource")
        
        // When - Multiple dismissals
        errorService.dismissCurrentError()
        errorService.dismissCurrentError() // Should not crash
        
        // Then
        XCTAssertNil(errorService.currentError)
        XCTAssertFalse(errorService.showErrorAlert)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteErrorWorkflow() {
        // Test a complete error handling workflow
        
        // Step 1: Handle different severity errors
        let lowError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Low priority error"])
        errorService.handle(lowError, severity: .low, source: "Component1")
        XCTAssertNil(errorService.currentError) // Low severity doesn't show UI
        
        // Step 2: Handle medium severity error
        let mediumError = NSError(domain: "TestDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Medium priority error"])
        errorService.handle(mediumError, severity: .medium, source: "Component2", userAction: "User clicked button")
        XCTAssertNotNil(errorService.currentError)
        XCTAssertTrue(errorService.showErrorAlert)
        
        // Step 3: Dismiss error
        errorService.dismissCurrentError()
        XCTAssertNil(errorService.currentError)
        
        // Step 4: Handle critical error
        let criticalError = NSError(domain: "TestDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Critical error"])
        errorService.handle(criticalError, severity: .critical, source: "CoreSystem")
        XCTAssertNotNil(errorService.currentError)
        XCTAssertEqual(errorService.currentError?.severity, .critical)
        
        // Step 5: Retry action
        errorService.retryLastAction()
        XCTAssertNil(errorService.currentError)
        
        // Step 6: Check history
        XCTAssertEqual(errorService.errorHistory.count, 3)
        let recentErrors = errorService.getRecentErrors(limit: 2)
        XCTAssertEqual(recentErrors.count, 2)
        
        // Step 7: Clear history
        errorService.clearHistory()
        XCTAssertTrue(errorService.errorHistory.isEmpty)
        
        print("Complete error handling workflow test passed")
    }
}

// MARK: - ErrorAlertView Tests

extension ErrorHandlingServiceTests {
    
    func testErrorAlertView() {
        // Test that ErrorAlertView can be created
        let alertView = ErrorAlertView()
        XCTAssertNotNil(alertView)
        
        // The actual alert presentation would require UI testing
        // This basic test ensures the view initializes correctly
    }
}