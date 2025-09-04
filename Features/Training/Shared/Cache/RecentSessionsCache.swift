import Foundation
import SwiftUI

// MARK: - Simple Session Cache (No @Published to avoid SwiftUI conflicts)
class RecentSessionsCache: ObservableObject {
    private var cachedSessions: [any WorkoutSession]?
    private var lastUpdateTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    var isValid: Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheValidityDuration
    }
    
    func getCachedSessions() -> [any WorkoutSession]? {
        return isValid ? cachedSessions : nil
    }
    
    func updateCache(_ sessions: [any WorkoutSession]) {
        cachedSessions = sessions
        lastUpdateTime = Date()
    }
    
    func invalidateCache() {
        cachedSessions = nil
        lastUpdateTime = nil
    }
}