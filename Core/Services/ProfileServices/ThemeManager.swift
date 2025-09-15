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



