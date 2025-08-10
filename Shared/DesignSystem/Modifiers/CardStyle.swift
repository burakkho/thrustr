import SwiftUI

struct CardStyle: ViewModifier {
    @Environment(\.theme) private var theme
    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card, radius: 2, y: 1)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}


