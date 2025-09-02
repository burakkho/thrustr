import SwiftUI

// MARK: - Design Tokens

struct Colors {
    // MARK: - Brand Colors
    let accent: Color
    let accentSecondary: Color
    let accentTertiary: Color
    
    // MARK: - Background Colors
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color
    let cardBackground: Color
    let cardBackgroundSecondary: Color
    let surfaceElevated: Color
    
    // MARK: - Text Colors
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textInverse: Color
    let textOnAccent: Color
    
    // MARK: - Status Colors
    let success: Color
    let successLight: Color
    let warning: Color
    let warningLight: Color
    let error: Color
    let errorLight: Color
    let info: Color
    let infoLight: Color
    
    // MARK: - Semantic Colors
    let border: Color
    let borderLight: Color
    let shadow: Color
    let overlay: Color
    let disabled: Color
    
    // MARK: - Training Specific Colors
    let strength: Color
    let strengthLight: Color
    let cardio: Color
    let cardioLight: Color
    let flexibility: Color
    let flexibilityLight: Color
    
    init(
        accent: Color,
        accentSecondary: Color,
        accentTertiary: Color,
        backgroundPrimary: Color,
        backgroundSecondary: Color,
        backgroundTertiary: Color,
        cardBackground: Color,
        cardBackgroundSecondary: Color,
        surfaceElevated: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        textInverse: Color,
        textOnAccent: Color,
        success: Color,
        successLight: Color,
        warning: Color,
        warningLight: Color,
        error: Color,
        errorLight: Color,
        info: Color,
        infoLight: Color,
        border: Color,
        borderLight: Color,
        shadow: Color,
        overlay: Color,
        disabled: Color,
        strength: Color,
        strengthLight: Color,
        cardio: Color,
        cardioLight: Color,
        flexibility: Color,
        flexibilityLight: Color
    ) {
        self.accent = accent
        self.accentSecondary = accentSecondary
        self.accentTertiary = accentTertiary
        self.backgroundPrimary = backgroundPrimary
        self.backgroundSecondary = backgroundSecondary
        self.backgroundTertiary = backgroundTertiary
        self.cardBackground = cardBackground
        self.cardBackgroundSecondary = cardBackgroundSecondary
        self.surfaceElevated = surfaceElevated
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.textInverse = textInverse
        self.textOnAccent = textOnAccent
        self.success = success
        self.successLight = successLight
        self.warning = warning
        self.warningLight = warningLight
        self.error = error
        self.errorLight = errorLight
        self.info = info
        self.infoLight = infoLight
        self.border = border
        self.borderLight = borderLight
        self.shadow = shadow
        self.overlay = overlay
        self.disabled = disabled
        self.strength = strength
        self.strengthLight = strengthLight
        self.cardio = cardio
        self.cardioLight = cardioLight
        self.flexibility = flexibility
        self.flexibilityLight = flexibilityLight
    }
}

struct Spacing {
    // MARK: - Base Spacing Scale (4pt grid)
    let xxs: CGFloat = 2
    let xs: CGFloat = 4
    let s: CGFloat = 8
    let m: CGFloat = 12
    let l: CGFloat = 16
    let xl: CGFloat = 24
    let xxl: CGFloat = 32
    let xxxl: CGFloat = 48
    
    // MARK: - Layout Spacing
    let containerPadding: CGFloat = 16
    let sectionSpacing: CGFloat = 32
    let cardPadding: CGFloat = 16
    let buttonPadding: CGFloat = 12
    
    // MARK: - Component Spacing
    let iconTextSpacing: CGFloat = 8
    let labelValueSpacing: CGFloat = 4
    let formFieldSpacing: CGFloat = 16
    let listItemSpacing: CGFloat = 12
}

struct Radius {
    // MARK: - Base Radius Scale
    let xs: CGFloat = 4
    let s: CGFloat = 8
    let m: CGFloat = 12
    let l: CGFloat = 16
    let xl: CGFloat = 20
    let xxl: CGFloat = 28
    let round: CGFloat = 9999 // Fully rounded
    
    // MARK: - Component Radius
    let button: CGFloat = 12
    let card: CGFloat = 16
    let input: CGFloat = 10
    let sheet: CGFloat = 20
    let tag: CGFloat = 8
}

struct Shadows {
    // MARK: - Shadow Colors
    let card: Color
    let elevated: Color
    let overlay: Color
    
    // MARK: - Shadow Styles
    struct CardShadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }
    
    let small: CardShadow
    let medium: CardShadow
    let large: CardShadow
    
    init(
        card: Color,
        elevated: Color,
        overlay: Color
    ) {
        self.card = card
        self.elevated = elevated
        self.overlay = overlay
        
        // Define shadow styles
        self.small = CardShadow(
            color: card,
            radius: 2,
            x: 0,
            y: 1,
            opacity: 0.05
        )
        
        self.medium = CardShadow(
            color: card,
            radius: 8,
            x: 0,
            y: 4,
            opacity: 0.1
        )
        
        self.large = CardShadow(
            color: card,
            radius: 16,
            x: 0,
            y: 8,
            opacity: 0.15
        )
    }
}

// MARK: - Typography
struct Typography {
    // MARK: - Display Fonts (Heroes, large titles)
    let display1: Font = .system(.largeTitle, design: .rounded, weight: .black)
    let display2: Font = .system(.title, design: .rounded, weight: .heavy)
    let display3: Font = .system(.title2, design: .rounded, weight: .bold)
    
    // MARK: - Heading Fonts (Section titles, cards)
    let heading1: Font = .system(.title3, design: .rounded, weight: .bold)
    let heading2: Font = .system(.headline, design: .rounded, weight: .semibold)
    let heading3: Font = .system(.subheadline, design: .rounded, weight: .semibold)
    
    // MARK: - Body Fonts (Content text)
    let bodyLarge: Font = .system(.body, design: .rounded, weight: .medium)
    let body: Font = .system(.body, design: .rounded, weight: .regular)
    let bodySmall: Font = .system(.callout, design: .rounded, weight: .regular)
    
    // MARK: - Label Fonts (Form labels, metadata)
    let labelLarge: Font = .system(.subheadline, design: .rounded, weight: .medium)
    let label: Font = .system(.footnote, design: .rounded, weight: .medium)
    let labelSmall: Font = .system(.caption, design: .rounded, weight: .medium)
    
    // MARK: - Caption Fonts (Supporting text)
    let caption: Font = .system(.caption, design: .rounded, weight: .regular)
    let captionSmall: Font = .system(.caption2, design: .rounded, weight: .regular)
    
    // MARK: - Interactive Fonts (Buttons, links)
    let buttonLarge: Font = .system(.headline, design: .rounded, weight: .semibold)
    let button: Font = .system(.subheadline, design: .rounded, weight: .semibold)
    let buttonSmall: Font = .system(.footnote, design: .rounded, weight: .semibold)
    
    // MARK: - Numeric Fonts (Scores, metrics)
    let numericLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    let numeric: Font = .system(.title2, design: .rounded, weight: .bold)
    let numericSmall: Font = .system(.headline, design: .rounded, weight: .semibold)
    
    // MARK: - Legacy Support (for existing code)
    let title1: Font = .largeTitle
    let title2: Font = .title
    let title3: Font = .title2
    let headline: Font = .headline
    let callout: Font = .callout
    let subheadline: Font = .subheadline
    let footnote: Font = .footnote
    let caption2: Font = .caption2
}


