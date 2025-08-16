import SwiftUI

// MARK: - Dashboard Spacing Constants
struct DashboardSpacing {
    static let sectionSpacing: CGFloat = 20
    static let contentPadding: CGFloat = 16
}

// MARK: - Dashboard Style Modifiers
extension View {
    func dashboardSurfaceStyle() -> some View {
        self
            .cardStyle()
    }
    
    func dashboardWelcomeCardStyle() -> some View {
        self
            .cardStyle()
    }
}