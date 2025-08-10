import SwiftUI

struct CardStyle: ViewModifier {
    @Environment(\.theme) private var theme
    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .cornerRadius(14)
            .shadow(color: Color.shadowLight, radius: 3, y: 1)
    }

    @Environment(\.colorScheme) private var colorScheme
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.18) : Color.borderPrimary }
    private var strokeWidth: CGFloat { colorScheme == .dark ? 2.0 : 1.0 }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}


