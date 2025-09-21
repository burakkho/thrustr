import SwiftUI

// MARK: - Celebration Type Model
/// Defines different types of celebration states for achievements and progress tracking
enum CelebrationType: String, CaseIterable {
    case none
    case progress
    case celebration
    case fire

    /// Icon associated with the celebration type
    var icon: String {
        switch self {
        case .none: return ""
        case .progress: return "arrow.up.circle.fill"
        case .celebration: return "party.popper.fill"
        case .fire: return "flame.fill"
        }
    }

    /// Color associated with the celebration type
    var color: Color {
        switch self {
        case .none: return .clear
        case .progress: return .green
        case .celebration: return .yellow
        case .fire: return .red
        }
    }

    /// Whether the celebration should animate
    var shouldAnimate: Bool {
        return self != .none
    }

    /// Scale effect for animations
    var scaleEffect: Double {
        switch self {
        case .none: return 1.0
        case .progress: return 1.1
        case .celebration: return 1.2
        case .fire: return 1.3
        }
    }

    /// Animation duration in seconds
    var animationDuration: Double {
        switch self {
        case .none: return 0
        case .progress: return 0.5
        case .celebration: return 1.0
        case .fire: return 1.5
        }
    }

    /// Emoji associated with the celebration type
    var emoji: String {
        switch self {
        case .none: return ""
        case .progress: return "📈"
        case .celebration: return "🎉"
        case .fire: return "🔥"
        }
    }
}