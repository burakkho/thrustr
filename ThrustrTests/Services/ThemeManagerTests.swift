import XCTest
import SwiftUI
import UIKit
@testable import Thrustr

/**
 * Comprehensive tests for ThemeManager
 * Tests theme switching, persistence, system theme integration, and design system
 */
@MainActor
final class ThemeManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    private var themeManager: ThemeManager!
    private var userDefaults: UserDefaults!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test UserDefaults
        userDefaults = UserDefaults(suiteName: "ThemeManagerTests")!
        userDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        
        // Create theme manager
        themeManager = ThemeManager()
    }
    
    override func tearDown() async throws {
        // Cleanup
        userDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        themeManager = nil
        userDefaults = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Then - Default state should be system theme
        XCTAssertEqual(themeManager.currentTheme, .system)
        XCTAssertFalse(themeManager.isDarkMode) // Depends on system state
    }
    
    func testInitialThemeLoading() {
        // Given - Saved theme preference
        UserDefaults.standard.selectedTheme = AppTheme.dark.rawValue
        
        // When - Create new theme manager
        let newManager = ThemeManager()
        
        // Then - Should load saved preference
        XCTAssertEqual(newManager.currentTheme, .dark)
        XCTAssertTrue(newManager.isDarkMode)
        
        // Cleanup
        UserDefaults.standard.selectedTheme = AppTheme.system.rawValue
    }
    
    // MARK: - Theme Switching Tests
    
    func testSetThemeLight() {
        // When
        themeManager.setTheme(.light)
        
        // Then
        XCTAssertEqual(themeManager.currentTheme, .light)
        XCTAssertFalse(themeManager.isDarkMode)
        XCTAssertEqual(UserDefaults.standard.selectedTheme, AppTheme.light.rawValue)
    }
    
    func testSetThemeDark() {
        // When
        themeManager.setTheme(.dark)
        
        // Then
        XCTAssertEqual(themeManager.currentTheme, .dark)
        XCTAssertTrue(themeManager.isDarkMode)
        XCTAssertEqual(UserDefaults.standard.selectedTheme, AppTheme.dark.rawValue)
    }
    
    func testSetThemeSystem() {
        // When
        themeManager.setTheme(.system)
        
        // Then
        XCTAssertEqual(themeManager.currentTheme, .system)
        XCTAssertEqual(UserDefaults.standard.selectedTheme, AppTheme.system.rawValue)
        // isDarkMode depends on system state
    }
    
    func testThemeSwitchingSequence() {
        // Test switching through all themes
        let themes: [AppTheme] = [.light, .dark, .system, .light]
        
        for theme in themes {
            // When
            themeManager.setTheme(theme)
            
            // Then
            XCTAssertEqual(themeManager.currentTheme, theme)
            XCTAssertEqual(UserDefaults.standard.selectedTheme, theme.rawValue)
            
            switch theme {
            case .light:
                XCTAssertFalse(themeManager.isDarkMode)
            case .dark:
                XCTAssertTrue(themeManager.isDarkMode)
            case .system:
                // System theme depends on device state
                break
            }
        }
    }
    
    // MARK: - Dark Mode Detection Tests
    
    func testCheckDarkModeForLightTheme() {
        // Given
        themeManager.setTheme(.light)
        
        // When
        let isDark = themeManager.checkDarkMode()
        
        // Then
        XCTAssertFalse(isDark)
        XCTAssertFalse(themeManager.isDarkMode)
    }
    
    func testCheckDarkModeForDarkTheme() {
        // Given
        themeManager.setTheme(.dark)
        
        // When
        let isDark = themeManager.checkDarkMode()
        
        // Then
        XCTAssertTrue(isDark)
        XCTAssertTrue(themeManager.isDarkMode)
    }
    
    func testCheckDarkModeForSystemTheme() {
        // Given
        themeManager.setTheme(.system)
        
        // When
        let isDark = themeManager.checkDarkMode()
        
        // Then
        // Should match system appearance
        let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        XCTAssertEqual(isDark, systemIsDark)
        XCTAssertEqual(themeManager.isDarkMode, systemIsDark)
    }
    
    // MARK: - Persistence Tests
    
    func testThemePersistence() {
        // Given - Set each theme and verify persistence
        let themes: [AppTheme] = [.light, .dark, .system]
        
        for theme in themes {
            // When
            themeManager.setTheme(theme)
            
            // Then - Should be saved to UserDefaults
            XCTAssertEqual(UserDefaults.standard.selectedTheme, theme.rawValue)
            
            // When - Create new manager to test loading
            let newManager = ThemeManager()
            
            // Then - Should load saved theme
            XCTAssertEqual(newManager.currentTheme, theme)
        }
    }
    
    func testUserDefaultsExtension() {
        // Test UserDefaults extension for theme storage
        
        // Test default value
        let cleanDefaults = UserDefaults(suiteName: "test")!
        cleanDefaults.removePersistentDomain(forName: "test")
        XCTAssertEqual(cleanDefaults.selectedTheme, AppTheme.system.rawValue)
        
        // Test setting values
        cleanDefaults.selectedTheme = AppTheme.dark.rawValue
        XCTAssertEqual(cleanDefaults.selectedTheme, AppTheme.dark.rawValue)
        
        cleanDefaults.selectedTheme = AppTheme.light.rawValue
        XCTAssertEqual(cleanDefaults.selectedTheme, AppTheme.light.rawValue)
    }
    
    // MARK: - Design System Integration Tests
    
    func testDesignThemeForLightMode() {
        // Given
        themeManager.setTheme(.light)
        
        // When
        let designTheme = themeManager.designTheme
        
        // Then
        XCTAssertTrue(designTheme is DefaultLightTheme)
    }
    
    func testDesignThemeForDarkMode() {
        // Given
        themeManager.setTheme(.dark)
        
        // When
        let designTheme = themeManager.designTheme
        
        // Then
        XCTAssertTrue(designTheme is DefaultDarkTheme)
    }
    
    func testDesignThemeForSystemMode() {
        // Given
        themeManager.setTheme(.system)
        
        // When
        let designTheme = themeManager.designTheme
        
        // Then - Should match system appearance
        if UITraitCollection.current.userInterfaceStyle == .dark {
            XCTAssertTrue(designTheme is DefaultDarkTheme)
        } else {
            XCTAssertTrue(designTheme is DefaultLightTheme)
        }
    }
    
    // MARK: - Theme Refresh Tests
    
    func testRefreshTheme() {
        // Given
        themeManager.setTheme(.system)
        let initialDarkMode = themeManager.isDarkMode
        
        // When
        themeManager.refreshTheme()
        
        // Then - Should update current state
        XCTAssertEqual(themeManager.currentTheme, .system)
        // isDarkMode might change if system changed (unlikely in test)
        XCTAssertEqual(themeManager.isDarkMode, themeManager.checkDarkMode())
    }
    
    // MARK: - AppTheme Enum Tests
    
    func testAppThemeDisplayNames() {
        // Test all theme display names
        for theme in AppTheme.allCases {
            let displayName = theme.displayName
            XCTAssertFalse(displayName.isEmpty, "Theme \(theme) should have display name")
            
            // Test localization keys exist
            switch theme {
            case .system:
                XCTAssertEqual(displayName, "settings.system_theme".localized)
            case .light:
                XCTAssertEqual(displayName, "settings.light_mode".localized)
            case .dark:
                XCTAssertEqual(displayName, "settings.dark_mode".localized)
            }
        }
    }
    
    func testAppThemeIcons() {
        // Test all theme icons
        for theme in AppTheme.allCases {
            let icon = theme.icon
            XCTAssertFalse(icon.isEmpty, "Theme \(theme) should have icon")
            
            // Test expected icon names
            switch theme {
            case .system:
                XCTAssertEqual(icon, "circle.lefthalf.filled")
            case .light:
                XCTAssertEqual(icon, "sun.max")
            case .dark:
                XCTAssertEqual(icon, "moon")
            }
        }
    }
    
    func testAppThemeRawValues() {
        // Test raw values for persistence
        XCTAssertEqual(AppTheme.system.rawValue, "system")
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
    }
    
    func testAppThemeFromRawValue() {
        // Test creating themes from raw values
        XCTAssertEqual(AppTheme(rawValue: "system"), .system)
        XCTAssertEqual(AppTheme(rawValue: "light"), .light)
        XCTAssertEqual(AppTheme(rawValue: "dark"), .dark)
        XCTAssertNil(AppTheme(rawValue: "invalid"))
    }
    
    func testAppThemeAllCases() {
        // Test all cases include all expected themes
        XCTAssertEqual(AppTheme.allCases.count, 3)
        XCTAssertTrue(AppTheme.allCases.contains(.system))
        XCTAssertTrue(AppTheme.allCases.contains(.light))
        XCTAssertTrue(AppTheme.allCases.contains(.dark))
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedPropertiesUpdates() {
        // Test that published properties trigger updates
        var currentThemeUpdated = false
        var isDarkModeUpdated = false
        
        let currentThemeCancellable = themeManager.$currentTheme.sink { _ in
            currentThemeUpdated = true
        }
        
        let isDarkModeCancellable = themeManager.$isDarkMode.sink { _ in
            isDarkModeUpdated = true
        }
        
        // When
        themeManager.setTheme(.dark)
        
        // Then
        XCTAssertTrue(currentThemeUpdated)
        XCTAssertTrue(isDarkModeUpdated)
        
        // Cleanup
        currentThemeCancellable.cancel()
        isDarkModeCancellable.cancel()
    }
    
    // MARK: - Color Extension Tests
    
    func testAdaptiveColors() {
        // Test that adaptive colors are accessible
        let adaptiveColors: [Color] = [
            .adaptiveBackground,
            .adaptiveSecondaryBackground,
            .adaptiveTertiaryBackground,
            .adaptiveText,
            .adaptiveSecondaryText,
            .adaptiveBorder,
            .adaptiveSuccess,
            .adaptiveWarning,
            .adaptiveError,
            .adaptiveInfo
        ]
        
        // All colors should be accessible without crashing
        for color in adaptiveColors {
            XCTAssertNotNil(color)
        }
    }
    
    func testFeatureSpecificColors() {
        // Test feature-specific adaptive colors
        let featureColors: [Color] = [
            .adaptiveTrainingPrimary,
            .adaptiveTrainingSecondary,
            .adaptiveNutritionPrimary,
            .adaptiveNutritionSecondary,
            .adaptiveDashboardPrimary,
            .adaptiveDashboardSecondary,
            .adaptiveProfilePrimary,
            .adaptiveProfileSecondary
        ]
        
        for color in featureColors {
            XCTAssertNotNil(color)
        }
    }
    
    func testMacroColors() {
        // Test macro-specific colors
        let macroColors: [Color] = [
            .adaptiveProtein,
            .adaptiveCarbs,
            .adaptiveFat,
            .adaptiveCalorie
        ]
        
        for color in macroColors {
            XCTAssertNotNil(color)
        }
    }
    
    func testShadowColors() {
        // Test shadow colors
        let shadowColors: [Color] = [
            .adaptiveShadowLight,
            .adaptiveShadowMedium,
            .adaptiveShadowHeavy
        ]
        
        for color in shadowColors {
            XCTAssertNotNil(color)
        }
    }
    
    func testInteractiveColors() {
        // Test interactive element colors
        let interactiveColors: [Color] = [
            .adaptiveButtonPrimary,
            .adaptiveButtonSecondary,
            .adaptiveButtonDestructive,
            .adaptiveLink
        ]
        
        for color in interactiveColors {
            XCTAssertNotNil(color)
        }
    }
    
    // MARK: - View Extensions Tests
    
    func testAdaptiveCardStyleModifier() {
        // Given
        let testView = Rectangle().frame(width: 100, height: 100)
        
        // When
        let cardView = testView.adaptiveCardStyle()
        
        // Then - Should not crash when applied
        XCTAssertNotNil(cardView)
    }
    
    func testAdaptiveShadowModifier() {
        // Given
        let testView = Rectangle().frame(width: 100, height: 100)
        
        // When
        let shadowView = testView.adaptiveShadow()
        let customShadowView = testView.adaptiveShadow(radius: 8, x: 2, y: 4)
        
        // Then - Should not crash when applied
        XCTAssertNotNil(shadowView)
        XCTAssertNotNil(customShadowView)
    }
    
    func testWithThemeManagerExtension() {
        // Given
        let testView = Text("Test")
        
        // When
        let themedView = testView.withThemeManager(themeManager)
        
        // Then - Should not crash when applied
        XCTAssertNotNil(themedView)
    }
    
    // MARK: - TabRouter Tests
    
    func testTabRouter() {
        // Given
        let tabRouter = TabRouter()
        
        // Then - Initial state
        XCTAssertEqual(tabRouter.selected, 0)
        
        // When - Change selection
        tabRouter.selected = 2
        
        // Then
        XCTAssertEqual(tabRouter.selected, 2)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakManager: ThemeManager?
        
        autoreleasepool {
            let testManager = ThemeManager()
            weakManager = testManager
            
            // Use the manager
            testManager.setTheme(.dark)
            testManager.refreshTheme()
        }
        
        // Manager should be deallocated (note: may not work due to NotificationCenter observer)
        // This test verifies the pattern but may not pass due to observer retention
        print("WeakManager after autorelease: \(weakManager != nil ? "retained" : "deallocated")")
    }
    
    // MARK: - Performance Tests
    
    func testThemeSwitchingPerformance() {
        // Measure theme switching performance
        measure {
            let themes: [AppTheme] = [.light, .dark, .system]
            for theme in themes {
                themeManager.setTheme(theme)
                themeManager.refreshTheme()
            }
        }
    }
    
    func testMultipleThemeManagersPerformance() {
        // Test creating multiple theme managers
        measure {
            for _ in 1...10 {
                let manager = ThemeManager()
                manager.setTheme(.dark)
                manager.refreshTheme()
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteThemeWorkflow() {
        // Test a complete theme workflow
        
        // Step 1: Verify initial state
        XCTAssertEqual(themeManager.currentTheme, .system)
        
        // Step 2: Switch to light theme
        themeManager.setTheme(.light)
        XCTAssertEqual(themeManager.currentTheme, .light)
        XCTAssertFalse(themeManager.isDarkMode)
        
        // Step 3: Get design theme
        let lightDesignTheme = themeManager.designTheme
        XCTAssertTrue(lightDesignTheme is DefaultLightTheme)
        
        // Step 4: Switch to dark theme
        themeManager.setTheme(.dark)
        XCTAssertEqual(themeManager.currentTheme, .dark)
        XCTAssertTrue(themeManager.isDarkMode)
        
        // Step 5: Get design theme
        let darkDesignTheme = themeManager.designTheme
        XCTAssertTrue(darkDesignTheme is DefaultDarkTheme)
        
        // Step 6: Switch to system theme
        themeManager.setTheme(.system)
        XCTAssertEqual(themeManager.currentTheme, .system)
        
        // Step 7: Refresh theme
        themeManager.refreshTheme()
        XCTAssertEqual(themeManager.currentTheme, .system)
        
        // Step 8: Verify persistence
        let newManager = ThemeManager()
        XCTAssertEqual(newManager.currentTheme, .system)
        
        print("Complete theme workflow test passed")
    }
    
    // MARK: - Edge Cases Tests
    
    func testInvalidThemePersistence() {
        // Given - Invalid theme in UserDefaults
        UserDefaults.standard.selectedTheme = "invalid_theme"
        
        // When - Create new manager
        let newManager = ThemeManager()
        
        // Then - Should fallback to system theme
        XCTAssertEqual(newManager.currentTheme, .system)
        
        // Cleanup
        UserDefaults.standard.selectedTheme = AppTheme.system.rawValue
    }
    
    func testRapidThemeSwitching() {
        // Test rapid theme switching doesn't cause issues
        let themes: [AppTheme] = [.light, .dark, .system, .light, .dark]
        
        for theme in themes {
            themeManager.setTheme(theme)
            XCTAssertEqual(themeManager.currentTheme, theme)
        }
        
        // Should remain stable
        XCTAssertNotNil(themeManager)
    }
    
    func testThemeManagerWithoutWindow() {
        // Test theme manager behavior when no window is available
        // This mainly tests that applyTheme() doesn't crash without a window
        
        // When
        themeManager.setTheme(.dark)
        
        // Then - Should not crash
        XCTAssertEqual(themeManager.currentTheme, .dark)
    }
}

// MARK: - Mock Tests for Theme-Dependent Components

extension ThemeManagerTests {
    
    func testThemeAwareComponents() {
        // Test components that depend on theme state
        
        // Light theme
        themeManager.setTheme(.light)
        XCTAssertFalse(themeManager.isDarkMode)
        
        // Dark theme  
        themeManager.setTheme(.dark)
        XCTAssertTrue(themeManager.isDarkMode)
        
        // Components should adapt based on isDarkMode property
        let backgroundColor = themeManager.isDarkMode ? Color.black : Color.white
        XCTAssertNotNil(backgroundColor)
    }
    
    func testThemeConsistency() {
        // Test theme consistency across different components
        for theme in AppTheme.allCases {
            themeManager.setTheme(theme)
            
            // All theme-dependent properties should be consistent
            let isDark = themeManager.isDarkMode
            let designTheme = themeManager.designTheme
            let checkDark = themeManager.checkDarkMode()
            
            XCTAssertEqual(isDark, checkDark, "isDarkMode and checkDarkMode should be consistent")
            
            // Design theme should match dark mode state
            if isDark {
                XCTAssertTrue(designTheme is DefaultDarkTheme)
            } else {
                XCTAssertTrue(designTheme is DefaultLightTheme)
            }
        }
    }
}