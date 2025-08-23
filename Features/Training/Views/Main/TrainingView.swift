import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @State private var coordinator = TrainingCoordinator()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Unified Tab Selector
                TrainingTabSelector(
                    selection: Binding(
                        get: { coordinator.selectedWorkoutType.rawValue },
                        set: { coordinator.selectWorkoutType(WorkoutType(rawValue: $0) ?? .dashboard) }
                    ),
                    tabs: [
                        TrainingTab(title: LocalizationKeys.Training.Dashboard.title.localized, icon: "house.fill"),
                        TrainingTab(title: "training.lift.title".localized, icon: "dumbbell.fill"),
                        TrainingTab(title: LocalizationKeys.Training.Cardio.title.localized, icon: "heart.fill"),
                        TrainingTab(title: LocalizationKeys.Training.WOD.title.localized, icon: "flame.fill"),
                        TrainingTab(title: LocalizationKeys.Training.Analytics.title.localized, icon: "chart.bar.fill")
                    ]
                )
                
                // Content based on selected workout type
                Group {
                    switch coordinator.selectedWorkoutType {
                    case .dashboard:
                        TrainingDashboardView()
                            .environment(coordinator)
                    case .lift:
                        LiftMainView()
                            .environment(coordinator)
                    case .cardio:
                        CardioMainView()
                            .environment(coordinator)
                    case .wod:
                        WODMainView()
                            .environment(coordinator)
                    case .analytics:
                        TrainingAnalyticsView(modelContext: modelContext)
                            .environment(coordinator)
                    }
                }
            }
            .navigationTitle(LocalizationKeys.Training.title.localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
#Preview {
    TrainingView()
        .environmentObject(TabRouter())
        .modelContainer(for: [
            LiftProgram.self,
            LiftWorkout.self,
            LiftSession.self,
            CardioWorkout.self,
            CardioSession.self,
            WOD.self,
            WODResult.self,
            User.self
        ], inMemory: true)
}
