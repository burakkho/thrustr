import Foundation

// MARK: - Session Feelings
enum SessionFeeling: String, CaseIterable {
    case great = "great"
    case good = "good"
    case okay = "okay"
    case tired = "tired"
    case exhausted = "exhausted"

    var displayName: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .tired: return "Tired"
        case .exhausted: return "Exhausted"
        }
    }

    var emoji: String {
        switch self {
        case .great: return "🔥"
        case .good: return "💪"
        case .okay: return "😊"
        case .tired: return "😓"
        case .exhausted: return "😫"
        }
    }

    var color: String {
        switch self {
        case .great: return "green"
        case .good: return "blue"
        case .okay: return "yellow"
        case .tired: return "orange"
        case .exhausted: return "red"
        }
    }

    static func fromString(_ string: String) -> SessionFeeling? {
        return SessionFeeling(rawValue: string.lowercased())
    }
}