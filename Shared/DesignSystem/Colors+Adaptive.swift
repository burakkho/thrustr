import SwiftUI

// MARK: - Adaptive Colors for Dark Mode Support
// Moved from ThemeManager.swift to maintain separation of concerns

extension Color {

    // MARK: - Adaptive Background Colors

    /// Ana arkaplan rengi (adaptive)
    static let adaptiveBackground = Color(.systemBackground)

    /// İkincil arkaplan rengi (adaptive)
    static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)

    /// Üçüncül arkaplan rengi (adaptive)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)

    /// Gruplu arkaplan rengi (adaptive)
    static let adaptiveGroupedBackground = Color(.systemGroupedBackground)

    /// İkincil gruplu arkaplan (adaptive)
    static let adaptiveSecondaryGroupedBackground = Color(.secondarySystemGroupedBackground)

    // MARK: - Adaptive Text Colors

    /// Ana yazı rengi (adaptive)
    static let adaptiveText = Color(.label)

    /// İkincil yazı rengi (adaptive)
    static let adaptiveSecondaryText = Color(.secondaryLabel)

    /// Üçüncül yazı rengi (adaptive)
    static let adaptiveTertiaryText = Color(.tertiaryLabel)

    /// Dördüncül yazı rengi (adaptive)
    static let adaptiveQuaternaryText = Color(.quaternaryLabel)

    /// Placeholder yazı rengi (adaptive)
    static let adaptivePlaceholder = Color(.placeholderText)

    // MARK: - Adaptive Border Colors

    /// Ana çerçeve rengi (adaptive)
    static let adaptiveBorder = Color(.separator)

    /// Opak çerçeve rengi (adaptive)
    static let adaptiveOpaqueBorder = Color(.opaqueSeparator)

    // MARK: - Card & Surface Colors

    /// Elevated surface (adaptive)
    static let elevatedSurface = Color(.secondarySystemBackground)

    // MARK: - Feature-Specific Adaptive Colors

    /// Training modülü adaptive renkleri
    static var adaptiveTrainingPrimary: Color {
        Color(.systemBlue)
    }

    static var adaptiveTrainingSecondary: Color {
        Color(.systemBlue).opacity(0.7)
    }

    /// Nutrition modülü adaptive renkleri
    static var adaptiveNutritionPrimary: Color {
        Color(.systemOrange)
    }

    static var adaptiveNutritionSecondary: Color {
        Color(.systemOrange).opacity(0.7)
    }

    /// Dashboard modülü adaptive renkleri
    static var adaptiveDashboardPrimary: Color {
        Color(.systemGreen)
    }

    static var adaptiveDashboardSecondary: Color {
        Color(.systemGreen).opacity(0.7)
    }

    /// Profile modülü adaptive renkleri
    static var adaptiveProfilePrimary: Color {
        Color(.systemPurple)
    }

    static var adaptiveProfileSecondary: Color {
        Color(.systemPurple).opacity(0.7)
    }

    // MARK: - Status Colors (Adaptive)

    /// Başarı rengi (adaptive)
    static let adaptiveSuccess = Color(.systemGreen)

    /// Uyarı rengi (adaptive)
    static let adaptiveWarning = Color(.systemOrange)

    /// Hata rengi (adaptive)
    static let adaptiveError = Color(.systemRed)

    /// Bilgi rengi (adaptive)
    static let adaptiveInfo = Color(.systemBlue)

    // MARK: - Macro Colors (Adaptive)

    /// Protein rengi (adaptive)
    static let adaptiveProtein = Color(.systemRed)

    /// Karbonhidrat rengi (adaptive)
    static let adaptiveCarbs = Color(.systemBlue)

    /// Yağ rengi (adaptive)
    static let adaptiveFat = Color(.systemYellow)

    /// Kalori rengi (adaptive)
    static let adaptiveCalorie = Color(.systemOrange)

    // MARK: - Theme-Aware Shadows

    /// Hafif gölge (theme-aware)
    static var adaptiveShadowLight: Color {
        Color(.label).opacity(0.05)
    }

    /// Orta gölge (theme-aware)
    static var adaptiveShadowMedium: Color {
        Color(.label).opacity(0.1)
    }

    /// Ağır gölge (theme-aware)
    static var adaptiveShadowHeavy: Color {
        Color(.label).opacity(0.2)
    }

    // MARK: - Interactive Colors

    /// Button primary (adaptive)
    static let adaptiveButtonPrimary = Color(.systemBlue)

    /// Button secondary (adaptive)
    static let adaptiveButtonSecondary = Color(.secondarySystemFill)

    /// Button destructive (adaptive)
    static let adaptiveButtonDestructive = Color(.systemRed)

    /// Link rengi (adaptive)
    static let adaptiveLink = Color(.link)
}