import SwiftUI

// MARK: - Card Style ViewModifier

struct ThrustrCardStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    let tokens: CardTokens
    let shadowColor: Color
    
    init(tokens: CardTokens = .default, shadowColor: Color = .clear) {
        self.tokens = tokens
        self.shadowColor = shadowColor
    }
    
    func body(content: Content) -> some View {
        content
            .padding(tokens.padding)
            .background(
                RoundedRectangle(cornerRadius: tokens.cornerRadius)
                    .fill(theme.colors.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: tokens.cornerRadius))
            .shadow(
                color: shadowColor == .clear ? theme.colors.shadow : shadowColor,
                radius: tokens.shadowRadius,
                x: tokens.shadowOffset.width,
                y: tokens.shadowOffset.height
            )
    }
}

// MARK: - View Extension

extension View {
    func cardStyle(
        _ tokens: CardTokens = .default, 
        shadowColor: Color = .clear
    ) -> some View {
        modifier(ThrustrCardStyle(tokens: tokens, shadowColor: shadowColor))
    }
}