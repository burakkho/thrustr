import Foundation

enum WODType: String, Codable, CaseIterable {
    case forTime = "for_time"
    case amrap = "amrap"
    case emom = "emom"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .forTime:
            return "For Time"
        case .amrap:
            return "AMRAP"
        case .emom:
            return "EMOM"
        case .custom:
            return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .forTime:
            return "Complete the workout as fast as possible"
        case .amrap:
            return "As Many Rounds As Possible in the given time"
        case .emom:
            return "Every Minute On the Minute"
        case .custom:
            return "Custom workout format"
        }
    }
}