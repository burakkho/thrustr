import SwiftUI

// MARK: - Theme Components
// Colors, Spacing, Radius, Shadows yapıları Tokens.swift'ten geliyor

// MARK: - Theme Protocol

protocol Theme {
    var colors: Colors { get }
    var spacing: Spacing { get }
    var radius: Radius { get }
    var shadows: Shadows { get }
    var typography: Typography { get }
}

// MARK: - Typography
// Typography yapısı Tokens.swift'ten geliyor

// MARK: - Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = DefaultLightTheme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme Implementations

struct DefaultLightTheme: Theme {
    let colors = Colors(
        accent: .appPrimary,
        backgroundPrimary: .backgroundPrimary,
        backgroundSecondary: .backgroundSecondary,
        cardBackground: .cardBackground,
        textPrimary: .textPrimary,
        textSecondary: .textSecondary,
        success: .appSuccess,
        warning: .appWarning,
        error: .appError
    )
    let spacing = Spacing()
    let radius = Radius()
    let shadows = Shadows()
    let typography = Typography()
}

struct DefaultDarkTheme: Theme {
    let colors = Colors(
        accent: .appPrimary,
        backgroundPrimary: .backgroundPrimary,
        backgroundSecondary: .backgroundSecondary,
        cardBackground: .cardBackground,
        textPrimary: .textPrimary,
        textSecondary: .textSecondary,
        success: .appSuccess,
        warning: .appWarning,
        error: .appError
    )
    let spacing = Spacing()
    let radius = Radius()
    let shadows = Shadows()
    let typography = Typography()
}

// MARK: - Common Modifiers

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


