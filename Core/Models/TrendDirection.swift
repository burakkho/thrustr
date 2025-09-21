import Foundation
import SwiftUI

// MARK: - Trend Direction Enum
/// Represents the direction of a trend (increasing, decreasing, or stable)
/// Used across analytics, health intelligence, and dashboard components
enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    // MARK: - UI Properties
    
    /// SF Symbol icon name for the trend
    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "minus"
        }
    }
    
    /// SwiftUI Color for the trend
    var swiftUIColor: Color {
        switch self {
        case .increasing:
            return .green
        case .decreasing:
            return .red
        case .stable:
            return .gray
        }
    }
    
    /// Color name string for non-SwiftUI contexts
    var colorName: String {
        switch self {
        case .increasing:
            return "green"
        case .decreasing:
            return "red"
        case .stable:
            return "gray"
        }
    }
    
    /// Localized display text for the trend
    var displayText: String {
        switch self {
        case .increasing:
            return "trends.increasing".localized
        case .decreasing:
            return "trends.decreasing".localized
        case .stable:
            return "trends.stable".localized
        }
    }
    
    /// Alternative display text (Turkish fallback)
    var displayTextTurkish: String {
        switch self {
        case .increasing:
            return "Artış"
        case .decreasing:
            return "Azalış"
        case .stable:
            return "Sabit"
        }
    }
    
    // MARK: - Utility Methods
    
    /// Returns true if the trend represents a positive change
    var isPositive: Bool {
        switch self {
        case .increasing:
            return true
        case .decreasing, .stable:
            return false
        }
    }
    
    /// Returns true if the trend represents a negative change
    var isNegative: Bool {
        switch self {
        case .decreasing:
            return true
        case .increasing, .stable:
            return false
        }
    }
    
    /// Returns true if there's no significant change
    var isNeutral: Bool {
        switch self {
        case .stable:
            return true
        case .increasing, .decreasing:
            return false
        }
    }
}

// MARK: - Trend Calculation Helpers
extension TrendDirection {
    
    /// Calculate trend from percentage change
    /// - Parameter percentChange: The percentage change value
    /// - Parameter threshold: The minimum threshold to consider a significant change (default: 5%)
    /// - Returns: TrendDirection based on the change
    static func from(percentChange: Double, threshold: Double = 5.0) -> TrendDirection {
        if percentChange > threshold {
            return .increasing
        } else if percentChange < -threshold {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    /// Calculate trend from two values
    /// - Parameters:
    ///   - oldValue: The previous value
    ///   - newValue: The current value
    ///   - threshold: The minimum percentage threshold (default: 5%)
    /// - Returns: TrendDirection based on the change
    static func from(oldValue: Double, newValue: Double, threshold: Double = 5.0) -> TrendDirection {
        guard oldValue > 0 else { return .stable }
        
        let percentChange = ((newValue - oldValue) / oldValue) * 100
        return from(percentChange: percentChange, threshold: threshold)
    }
    
    /// Calculate trend from an array of values using linear regression
    /// - Parameter values: Array of values to analyze
    /// - Returns: TrendDirection based on the overall trend
    static func from(values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        
        let n = Double(values.count)
        let xValues = Array(0..<values.count).map { Double($0) }
        
        let sumX = xValues.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xValues, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return .stable }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let average = sumY / n
        
        // Determine trend based on slope significance
        let slopeThreshold = average * 0.01 // 1% of average value
        
        if slope > slopeThreshold {
            return .increasing
        } else if slope < -slopeThreshold {
            return .decreasing
        } else {
            return .stable
        }
    }
}

// MARK: - Codable Support
extension TrendDirection: Codable, CaseIterable, Equatable, Hashable {
    // Automatic Codable synthesis
}

// MARK: - String Conversion
extension TrendDirection: CustomStringConvertible {
    var description: String {
        return displayText
    }
}