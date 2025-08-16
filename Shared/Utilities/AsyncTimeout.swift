//
//  AsyncTimeout.swift
//  SporHocam
//
//  Created by Assistant on Error Analysis
//

import Foundation

// MARK: - Timeout Error
enum TimeoutError: LocalizedError, Sendable {
    case operationTimedOut(timeInterval: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .operationTimedOut(let timeInterval):
            return "İşlem \(String(format: "%.1f", timeInterval)) saniye içinde tamamlanamadı"
        }
    }
}

// MARK: - Timeout Utility Functions
enum AsyncTimeout {
    /// Standard timeout durations
    enum Duration {
        static let short: TimeInterval = 5.0      // 5 seconds - for quick operations
        static let medium: TimeInterval = 15.0    // 15 seconds - for API calls
        static let long: TimeInterval = 30.0      // 30 seconds - for complex operations
        static let extended: TimeInterval = 60.0  // 1 minute - for heavy operations like data seeding
    }
    
    /// Execute an async operation with timeout
    static func execute<T: Sendable>(
        timeout: TimeInterval = Duration.medium,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task<Never, Never>.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError.operationTimedOut(timeInterval: timeout)
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Execute an async void operation with timeout
    static func execute(
        timeout: TimeInterval = Duration.medium,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task<Never, Never>.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError.operationTimedOut(timeInterval: timeout)
            }
            
            try await group.next()
            group.cancelAll()
        }
    }
}

// MARK: - Timeout with Retry
extension AsyncTimeout {
    /// Execute operation with timeout and retry on failure
    static func executeWithRetry<T: Sendable>(
        maxRetries: Int = 3,
        timeout: TimeInterval = Duration.medium,
        retryDelay: TimeInterval = 1.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await execute(timeout: timeout, operation: operation)
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    print("⚠️ Operation failed (attempt \(attempt)/\(maxRetries)): \(error)")
                    print("🔄 Retrying in \(retryDelay) seconds...")
                    try await Task<Never, Never>.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TimeoutError.operationTimedOut(timeInterval: timeout)
    }
}

// MARK: - Example Usage Documentation
/*
 
 // Basic timeout usage:
 try await AsyncTimeout.execute(timeout: 10.0) {
     await someAsyncOperation()
 }
 
 // With retry:
 let result = try await AsyncTimeout.executeWithRetry(
     maxRetries: 3,
     timeout: 5.0,
     retryDelay: 2.0
 ) {
     try await riskyNetworkCall()
 }
 
 */