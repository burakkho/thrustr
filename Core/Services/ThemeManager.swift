import SwiftUI
import UIKit

/**
 * Centralized theme management service for app-wide appearance control.
 * 
 * This service manages theme switching between light, dark, and system themes with
 * real-time UI updates. Integrates with the design system protocol for consistent
 * theming across all components and stores user preferences persistently.
 * 
 * Features:
 * - System, light, and dark theme support
 * - Real-time theme switching without app restart  
 * - UIWindow-level theme override for immediate effect
 * - UserDefaults persistence for theme preferences
 * - Published properties for SwiftUI reactive updates
 * 
 * Usage:
 * - Access via @EnvironmentObject in views
 * - Theme protocol available via @Environment(\.theme)
 * - Automatic system theme change detection
 */

// MARK: - Theme Types
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "settings.system_theme".localized
        case .light:
            return "settings.light_mode".localized
        case .dark:
            return "settings.dark_mode".localized
        }
    }
    
    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
}

// MARK: - UserDefaults Extension (EKSİK OLAN KISIM)
extension UserDefaults {
    var selectedTheme: String {
        get {
            return string(forKey: "app_theme") ?? AppTheme.dark.rawValue
        }
        set {
            set(newValue, forKey: "app_theme")
        }
    }
}

// MARK: - Theme Manager
@MainActor
@Observable
class ThemeManager {
    
    // MARK: - Properties
    var currentTheme: AppTheme = .dark
    var isDarkMode: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        loadThemePreference()
        updateCurrentTheme()
        observeSystemThemeChanges()
    }
    
    // MARK: - Public Methods
    
    /// Theme değiştir
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        userDefaults.selectedTheme = theme.rawValue
        updateCurrentTheme()
        applyTheme()
    }
    
    /// Mevcut theme'i yeniden uygula
    func refreshTheme() {
        updateCurrentTheme()
        applyTheme()
    }
    
    /// Dark mode durumunu kontrol et
    func checkDarkMode() -> Bool {
        switch currentTheme {
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    // MARK: - Private Methods
    
    /// Kullanıcı tercihini yükle
    private func loadThemePreference() {
        let themeString = userDefaults.selectedTheme
        currentTheme = AppTheme(rawValue: themeString) ?? .system
    }
    
    /// Mevcut theme'i güncelle
    private func updateCurrentTheme() {
        isDarkMode = checkDarkMode()
    }

    // MARK: - Design Theme Accessor
    /// Design system teması (Environment'e enjekte edilecek)
    var designTheme: Theme {
        isDarkMode ? DefaultDarkTheme() : DefaultLightTheme()
    }
    
    /// Theme'i sisteme uygula
    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch currentTheme {
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
        
        // Smooth animation
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.layoutIfNeeded()
        }
    }
    
    /// Sistem theme değişikliklerini dinle
    private func observeSystemThemeChanges() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentTheme()
            }
        }
    }
}

// MARK: - Theme Helper Extension
extension View {
    /// Theme manager'ı environment'a ekle
    func withThemeManager(_ themeManager: ThemeManager) -> some View {
        self.environment(themeManager)
    }
}

// MARK: - Tab Router for TabView coordination
@Observable
final class TabRouter {
    var selected: Int = 0
}

// MARK: - Color Extensions for Dark Mode
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

// MARK: - View Extensions
extension View {
    /// Adaptive card style uygula
    func adaptiveCardStyle() -> some View {
        self
            .background(Color.adaptiveBackground)
            .cornerRadius(12)
            .shadow(
                color: Color.adaptiveShadowLight,
                radius: 8,
                x: 0,
                y: 2
            )
    }
    
    /// Theme-aware shadow uygula
    func adaptiveShadow(radius: CGFloat = 4, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(color: Color.adaptiveShadowLight, radius: radius, x: x, y: y)
    }
}
