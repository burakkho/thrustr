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
        accentSecondary: .appPrimary.opacity(0.8),
        accentTertiary: .appPrimary.opacity(0.6),
        backgroundPrimary: .backgroundPrimary,
        backgroundSecondary: .backgroundSecondary,
        backgroundTertiary: Color(.systemGroupedBackground),
        cardBackground: .cardBackground,
        cardBackgroundSecondary: Color(.secondarySystemGroupedBackground),
        surfaceElevated: .white,
        textPrimary: .textPrimary,
        textSecondary: .textSecondary,
        textTertiary: Color(.tertiaryLabel),
        textInverse: .white,
        textOnAccent: .white,
        success: .appSuccess,
        successLight: .appSuccess.opacity(0.1),
        warning: .appWarning,
        warningLight: .appWarning.opacity(0.1),
        error: .appError,
        errorLight: .appError.opacity(0.1),
        info: .blue,
        infoLight: .blue.opacity(0.1),
        border: Color(.separator),
        borderLight: Color(.separator).opacity(0.5),
        shadow: .black.opacity(0.1),
        overlay: .black.opacity(0.3),
        disabled: Color(.systemGray4),
        strength: .red,
        strengthLight: .red.opacity(0.1),
        cardio: .blue,
        cardioLight: .blue.opacity(0.1),
        flexibility: .green,
        flexibilityLight: .green.opacity(0.1)
    )
    let spacing = Spacing()
    let radius = Radius()
    let shadows = Shadows(
        card: .black.opacity(0.05),
        elevated: .black.opacity(0.1),
        overlay: .black.opacity(0.15)
    )
    let typography = Typography()
}

struct DefaultDarkTheme: Theme {
    let colors = Colors(
        accent: .appPrimary,
        accentSecondary: .appPrimary.opacity(0.8),
        accentTertiary: .appPrimary.opacity(0.6),
        backgroundPrimary: .backgroundPrimary,
        backgroundSecondary: .backgroundSecondary,
        backgroundTertiary: Color(.systemGroupedBackground),
        cardBackground: .cardBackground,
        cardBackgroundSecondary: Color(.secondarySystemGroupedBackground),
        surfaceElevated: Color(.secondarySystemBackground),
        textPrimary: .textPrimary,
        textSecondary: .textSecondary,
        textTertiary: Color(.tertiaryLabel),
        textInverse: .black,
        textOnAccent: .white,
        success: .appSuccess,
        successLight: .appSuccess.opacity(0.1),
        warning: .appWarning,
        warningLight: .appWarning.opacity(0.1),
        error: .appError,
        errorLight: .appError.opacity(0.1),
        info: .blue,
        infoLight: .blue.opacity(0.1),
        border: Color(.separator),
        borderLight: Color(.separator).opacity(0.5),
        shadow: .black.opacity(0.3),
        overlay: .black.opacity(0.5),
        disabled: Color(.systemGray4),
        strength: .red,
        strengthLight: .red.opacity(0.1),
        cardio: .blue,
        cardioLight: .blue.opacity(0.1),
        flexibility: .green,
        flexibilityLight: .green.opacity(0.1)
    )
    let spacing = Spacing()
    let radius = Radius()
    let shadows = Shadows(
        card: .black.opacity(0.2),
        elevated: .black.opacity(0.3),
        overlay: .black.opacity(0.4)
    )
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


