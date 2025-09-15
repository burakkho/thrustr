import Foundation

// MARK: - Tab Router for TabView coordination
// Moved from ThemeManager.swift to maintain separation of concerns

@Observable
final class TabRouter {
    var selected: Int = 0
}