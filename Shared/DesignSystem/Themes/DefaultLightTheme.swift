import SwiftUI

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


