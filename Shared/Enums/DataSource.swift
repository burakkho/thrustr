import Foundation

/**
 * Enum for tracking the source of user data entries.
 * 
 * This enum helps maintain data provenance and enables intelligent conflict resolution
 * between different data sources, particularly for HealthKit integration scenarios.
 * 
 * Usage:
 * - manual: User manually entered the data
 * - healthKit: Data synchronized from Apple HealthKit
 * - imported: Data imported from external sources or migration
 */
enum DataSource: String, CaseIterable, Codable, Sendable {
    case manual = "manual"
    case healthKit = "healthkit"
    case imported = "imported"
    
    /// Display name for UI presentation
    var displayName: String {
        switch self {
        case .manual:
            return "Manual Entry"
        case .healthKit:
            return "HealthKit"
        case .imported:
            return "Imported"
        }
    }
    
    /// Localized display name
    var localizedDisplayName: String {
        switch self {
        case .manual:
            return "data_source.manual".localized
        case .healthKit:
            return "data_source.healthkit".localized
        case .imported:
            return "data_source.imported".localized
        }
    }
    
    /// Priority for conflict resolution (higher = more trusted)
    var priority: Int {
        switch self {
        case .manual:
            return 2  // User intent is high priority
        case .healthKit:
            return 3  // HealthKit is most reliable when available
        case .imported:
            return 1  // Imported data has lower trust
        }
    }
    
    /// Icon for UI representation
    var icon: String {
        switch self {
        case .manual:
            return "pencil"
        case .healthKit:
            return "heart.fill"
        case .imported:
            return "square.and.arrow.down"
        }
    }
    
    /// Color for UI representation
    var color: String {
        switch self {
        case .manual:
            return "blue"
        case .healthKit:
            return "red"
        case .imported:
            return "orange"
        }
    }
}

// MARK: - Conflict Resolution Helpers

extension DataSource {
    /**
     * Determines if this data source should override another based on timestamp and priority.
     * 
     * - Parameters:
     *   - other: The competing data source
     *   - thisTimestamp: Timestamp of this data source's data
     *   - otherTimestamp: Timestamp of the other data source's data
     *   - significantTimeDifference: Minimum time difference to consider (default: 1 hour)
     * 
     * - Returns: True if this data source should win the conflict
     */
    func shouldOverride(
        _ other: DataSource, 
        thisTimestamp: Date, 
        otherTimestamp: Date, 
        significantTimeDifference: TimeInterval = 3600
    ) -> Bool {
        let timeDifference = thisTimestamp.timeIntervalSince(otherTimestamp)
        
        // Latest timestamp wins if significant time difference
        if abs(timeDifference) > significantTimeDifference {
            return timeDifference > 0
        }
        
        // If timestamps are close, use priority
        return self.priority > other.priority
    }
}