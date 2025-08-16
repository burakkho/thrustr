import SwiftUI

struct QuickActionsSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var tabRouter: TabRouter
    let onWeightEntryTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(LocalizationKeys.Dashboard.quickActions.localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: theme.spacing.s) {
                StartWorkoutAction(onTap: navigateToWorkouts)
                LogWeightAction(onTap: onWeightEntryTap)
                NutritionAction(onTap: navigateToNutrition)
            }
        }
    }
    
    // MARK: - Action Handlers
    private func navigateToWorkouts() {
        tabRouter.selected = 1
    }
    
    private func navigateToNutrition() {
        tabRouter.selected = 2
    }
}

// MARK: - Individual Action Components
private struct StartWorkoutAction: View {
    let onTap: () -> Void
    
    var body: some View {
        GuideSection(
            title: LocalizationKeys.Dashboard.Actions.startWorkout.localized,
            icon: "dumbbell.fill",
            description: LocalizationKeys.Dashboard.Actions.startWorkoutDesc.localized,
            color: .blue,
            borderlessLight: true,
            action: onTap
        )
    }
}

private struct LogWeightAction: View {
    let onTap: () -> Void
    
    var body: some View {
        GuideSection(
            title: LocalizationKeys.Dashboard.Actions.logWeight.localized,
            icon: "scalemass.fill",
            description: LocalizationKeys.Dashboard.Actions.logWeightDesc.localized,
            color: .green,
            borderlessLight: true,
            action: onTap
        )
    }
}

private struct NutritionAction: View {
    let onTap: () -> Void
    
    var body: some View {
        GuideSection(
            title: LocalizationKeys.Dashboard.Actions.nutrition.localized,
            icon: "fork.knife",
            description: LocalizationKeys.Dashboard.Actions.nutritionDesc.localized,
            color: .orange,
            borderlessLight: true,
            action: onTap
        )
    }
}

#Preview {
    QuickActionsSection(onWeightEntryTap: {})
        .environmentObject(TabRouter())
        .padding()
}