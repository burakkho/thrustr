import SwiftUI

// MARK: - Component Tokens

struct ButtonTokens {
    let height: CGFloat
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let iconSpacing: CGFloat
    let font: Font
    
    static let primary = ButtonTokens(
        height: 48,
        cornerRadius: 12,
        horizontalPadding: 24,
        iconSpacing: 8,
        font: .system(.headline, design: .rounded, weight: .semibold)
    )
    
    static let secondary = ButtonTokens(
        height: 44,
        cornerRadius: 10,
        horizontalPadding: 20,
        iconSpacing: 6,
        font: .system(.subheadline, design: .rounded, weight: .semibold)
    )
    
    static let compact = ButtonTokens(
        height: 36,
        cornerRadius: 8,
        horizontalPadding: 16,
        iconSpacing: 6,
        font: .system(.footnote, design: .rounded, weight: .semibold)
    )
}

struct CardTokens {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let shadowOpacity: Double
    
    static let `default` = CardTokens(
        cornerRadius: 16,
        padding: 16,
        shadowRadius: 4,
        shadowOffset: CGSize(width: 0, height: 2),
        shadowOpacity: 0.08
    )
    
    static let elevated = CardTokens(
        cornerRadius: 16,
        padding: 20,
        shadowRadius: 8,
        shadowOffset: CGSize(width: 0, height: 4),
        shadowOpacity: 0.12
    )
    
    static let compact = CardTokens(
        cornerRadius: 12,
        padding: 12,
        shadowRadius: 2,
        shadowOffset: CGSize(width: 0, height: 1),
        shadowOpacity: 0.05
    )
}

struct InputTokens {
    let height: CGFloat
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let borderWidth: CGFloat
    let font: Font
    
    static let `default` = InputTokens(
        height: 48,
        cornerRadius: 10,
        horizontalPadding: 16,
        borderWidth: 1.5,
        font: .system(.body, design: .rounded)
    )
    
    static let compact = InputTokens(
        height: 40,
        cornerRadius: 8,
        horizontalPadding: 12,
        borderWidth: 1,
        font: .system(.subheadline, design: .rounded)
    )
}

// MARK: - Animation Tokens

struct AnimationTokens {
    static let quick: Animation = .easeOut(duration: 0.2)
    static let smooth: Animation = .easeInOut(duration: 0.3)
    static let gentle: Animation = .easeInOut(duration: 0.5)
    static let spring: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    static let bouncy: Animation = .spring(response: 0.5, dampingFraction: 0.6)
    
    // Progress animations
    static let progressFill: Animation = .easeInOut(duration: 1.2)
    static let levelUp: Animation = .spring(response: 0.8, dampingFraction: 0.6)
    
    // Interaction animations
    static let buttonPress: Animation = .easeOut(duration: 0.15)
    static let cardHover: Animation = .easeOut(duration: 0.25)
}

// MARK: - Strength Test Specific Tokens

struct StrengthTestTokens {
    // Level colors with modern palette
    static let levelColors: [StrengthLevel: (primary: Color, secondary: Color)] = [
        .beginner: (Color(red: 0.91, green: 0.30, blue: 0.24), Color(red: 0.96, green: 0.45, blue: 0.40)),
        .novice: (Color(red: 0.98, green: 0.55, blue: 0.09), Color(red: 0.99, green: 0.70, blue: 0.30)),
        .intermediate: (Color(red: 0.95, green: 0.77, blue: 0.06), Color(red: 0.97, green: 0.85, blue: 0.25)),
        .advanced: (Color(red: 0.20, green: 0.78, blue: 0.35), Color(red: 0.40, green: 0.85, blue: 0.55)),
        .expert: (Color(red: 0.20, green: 0.60, blue: 0.86), Color(red: 0.40, green: 0.75, blue: 0.92)),
        .elite: (Color(red: 0.69, green: 0.32, blue: 0.87), Color(red: 0.80, green: 0.50, blue: 0.93))
    ]
    
    // Ring animation parameters
    static let ringAnimationDuration: Double = 1.5
    static let ringAnimationDelay: Double = 0.3
    
    // Card animations
    static let cardEntranceAnimation: Animation = .easeOut(duration: 0.4)
    static let cardEntranceDelay: Double = 0.1
    
    // Result summary animations
    static let resultSectionDelay: Double = 0.8
    static let resultItemDelay: Double = 0.1
}