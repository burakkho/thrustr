import Foundation

/**
 * Pull-up exercise type for strength testing.
 * 
 * Distinguishes between bodyweight and weighted pull-ups
 * for accurate strength assessment.
 */
public enum PullUpType: String, CaseIterable, Sendable {
    case bodyweight = "bodyweight"
    case weighted = "weighted"
    
    var displayName: String {
        switch self {
        case .bodyweight:
            return "Bodyweight"
        case .weighted:
            return "Weighted"
        }
    }
}