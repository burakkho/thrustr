import SwiftUI

// MARK: - Design Tokens

struct Colors {
    let accent: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let success: Color
    let warning: Color
    let error: Color
}

struct Spacing {
    let xs: CGFloat = 4
    let s: CGFloat = 8
    let m: CGFloat = 12
    let l: CGFloat = 16
    let xl: CGFloat = 24
}

struct Radius {
    let s: CGFloat = 8
    let m: CGFloat = 12
    let l: CGFloat = 16
    let xl: CGFloat = 20
}

struct Shadows {
    let card: Color = Color.shadowLight
}

// MARK: - Typography
struct Typography {
    let title: Font = .system(size: 28, weight: .semibold, design: .rounded)
    let subtitle: Font = .system(size: 14, weight: .regular, design: .rounded)
    let value: Font = .system(size: 20, weight: .semibold, design: .rounded)
    let caption: Font = .caption
}


