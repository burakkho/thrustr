import SwiftUI

// MARK: - Theme Protocol

protocol Theme {
    var colors: Colors { get }
    var spacing: Spacing { get }
    var radius: Radius { get }
    var shadows: Shadows { get }
    var typography: Typography { get }
}

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


