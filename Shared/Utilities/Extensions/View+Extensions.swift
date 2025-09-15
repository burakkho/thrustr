import SwiftUI

// MARK: - Theme-Related View Extensions
// Moved from ThemeManager.swift to maintain separation of concerns

extension View {
    /// Adaptive card style uygula
    func adaptiveCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: Color(.label).opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
    }

    /// Theme-aware shadow uygula
    func adaptiveShadow(radius: CGFloat = 4, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(color: Color(.label).opacity(0.05), radius: radius, x: x, y: y)
    }
}