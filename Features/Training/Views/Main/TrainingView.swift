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
                        TrainingTab(title: TrainingKeys.Dashboard.title.localized, icon: "house.fill"),
                        TrainingTab(title: TrainingKeys.Lift.title.localized, icon: "dumbbell.fill"),
                        TrainingTab(title: TrainingKeys.Cardio.title.localized, icon: "heart.fill"),
                        TrainingTab(title: TrainingKeys.WOD.title.localized, icon: "flame.fill"),
                        TrainingTab(title: TrainingKeys.Strength.title.localized, icon: "chart.bar.doc.horizontal.fill"),
                        TrainingTab(title: TrainingKeys.Analytics.title.localized, icon: "chart.bar.fill")
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
                    case .tests:
                        TestsMainView()
                            .environment(coordinator)
                    case .analytics:
                        TrainingAnalyticsView(modelContext: modelContext)
                            .environment(coordinator)
                    }
                }
            }
            .navigationTitle(TrainingKeys.title.localized)
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
            StrengthTest.self,
            User.self
        ], inMemory: true)
}
