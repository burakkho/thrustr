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
    let title1: Font = .largeTitle
    let title2: Font = .title
    let title3: Font = .title2
    let headline: Font = .headline
    let body: Font = .body
    let callout: Font = .callout
    let subheadline: Font = .subheadline
    let footnote: Font = .footnote
    let caption: Font = .caption
    let caption2: Font = .caption2
}


