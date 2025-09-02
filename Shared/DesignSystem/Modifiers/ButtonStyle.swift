import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    let tokens: ButtonTokens
    
    init(_ tokens: ButtonTokens = .primary) {
        self.tokens = tokens
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(tokens.font)
            .foregroundColor(theme.colors.textOnAccent)
            .frame(minHeight: tokens.height)
            .padding(.horizontal, tokens.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: tokens.cornerRadius)
                    .fill(isEnabled ? theme.colors.accent : theme.colors.disabled)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    let tokens: ButtonTokens
    
    init(_ tokens: ButtonTokens = .secondary) {
        self.tokens = tokens
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(tokens.font)
            .foregroundColor(isEnabled ? theme.colors.accent : theme.colors.disabled)
            .frame(minHeight: tokens.height)
            .padding(.horizontal, tokens.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: tokens.cornerRadius)
                    .fill(theme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: tokens.cornerRadius)
                            .stroke(isEnabled ? theme.colors.accent : theme.colors.disabled, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension Button {
    func primaryButtonStyle(_ tokens: ButtonTokens = .primary) -> some View {
        self.buttonStyle(PrimaryButtonStyle(tokens))
    }
    
    func secondaryButtonStyle(_ tokens: ButtonTokens = .secondary) -> some View {
        self.buttonStyle(SecondaryButtonStyle(tokens))
    }
}