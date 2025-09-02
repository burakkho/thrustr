import SwiftUI

/**
 * Quick status section with interactive health cards.
 * 
 * Displays the 3 main fitness metrics (Lift, Cardio, Nutrition) as tappable cards
 * that navigate to their respective sections. Shows progress bars and contextual data.
 */

struct QuickStatusSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var tabRouter: TabRouter
    
    // MARK: - Properties
    @ObservedObject var viewModel: DashboardViewModel
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            HStack(spacing: theme.spacing.m) {
                liftCard
                cardioCard  
                nutritionCard
            }
            
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DashboardKeys.QuickActions.quickStatus.localized)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    
    // MARK: - Card Components
    private var liftCard: some View {
        let metrics = viewModel.temporalMetrics.lift
        return ActionableStatCard(
            icon: "dumbbell.fill",
            title: "",
            dailyValue: metrics.daily,
            weeklyValue: metrics.weekly,
            monthlyValue: metrics.monthly,
            dailySubtitle: DashboardKeys.QuickStatus.todayVolume.localized,
            weeklySubtitle: DashboardKeys.QuickStatus.weeklyAverage.localized, 
            monthlySubtitle: DashboardKeys.QuickStatus.monthlyAverage.localized,
            color: Color.blue,
            onNavigate: navigateToLift
        )
    }
    
    private var cardioCard: some View {
        let metrics = viewModel.temporalMetrics.cardio
        return ActionableStatCard(
            icon: "figure.run",
            title: "",
            dailyValue: metrics.daily,
            weeklyValue: metrics.weekly,
            monthlyValue: metrics.monthly,
            dailySubtitle: DashboardKeys.QuickStatus.todayDistance.localized,
            weeklySubtitle: DashboardKeys.QuickStatus.weeklyAverage.localized,
            monthlySubtitle: DashboardKeys.QuickStatus.monthlyAverage.localized,
            color: Color.green,
            onNavigate: navigateToCardio
        )
    }
    
    private var nutritionCard: some View {
        let metrics = viewModel.temporalMetrics.calories
        return ActionableStatCard(
            icon: "fork.knife",
            title: "",
            dailyValue: metrics.daily,
            weeklyValue: metrics.weekly,
            monthlyValue: metrics.monthly,
            dailySubtitle: DashboardKeys.QuickStatus.todayCalories.localized,
            weeklySubtitle: DashboardKeys.QuickStatus.weeklyAverage.localized,
            monthlySubtitle: DashboardKeys.QuickStatus.monthlyAverage.localized,
            color: Color.orange,
            onNavigate: navigateToNutrition
        )
    }
    
    // MARK: - Navigation Actions
    
    /// Navigate to Training tab, Lift section
    private func navigateToLift() {
        tabRouter.selected = 1
        NotificationCenter.default.post(name: .navigateToLift, object: nil)
    }
    
    /// Navigate to Training tab, Cardio section
    private func navigateToCardio() {
        tabRouter.selected = 1
        NotificationCenter.default.post(name: .navigateToCardio, object: nil)
    }
    
    /// Navigate to Nutrition tab
    private func navigateToNutrition() {
        tabRouter.selected = 2
    }
}

// MARK: - Navigation Notification Names
extension Notification.Name {
    static let navigateToLift = Notification.Name("NavigateToLift")
    static let navigateToCardio = Notification.Name("NavigateToCardio")
}

// MARK: - Preview
#Preview {
    let viewModel = DashboardViewModel(healthKitService: HealthKitService(), unitSettings: UnitSettings.shared)
    
    QuickStatusSection(viewModel: viewModel)
        .environmentObject(TabRouter())
        .padding()
}
