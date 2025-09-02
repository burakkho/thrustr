import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @State private var coordinator = TrainingCoordinator()
    @StateObject private var errorHandler = ErrorHandlingService.shared
    @Query private var programs: [LiftProgram]
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
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
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "workout_history":
                    WorkoutHistoryView()
                case "one_rm_setup":
                    if let defaultProgram = programs.first {
                        OneRMSetupView(program: defaultProgram, onComplete: { _ in })
                    } else {
                        EmptyStateView(
                            systemImage: "exclamationmark.triangle",
                            title: "No Programs Available",
                            message: "Please set up programs first.",
                            primaryTitle: "Back",
                            primaryAction: { coordinator.navigationPath.removeLast() }
                        )
                    }
                case "pr_detail":
                    EmptyStateView(
                        systemImage: "chart.bar.fill",
                        title: "Personal Records",
                        message: "Detailed PR tracking coming soon!",
                        primaryTitle: "Back",
                        primaryAction: { coordinator.navigationPath.removeLast() }
                    )
                default:
                    EmptyView()
                }
            }
            .sheet(isPresented: $coordinator.showingProgramSelection) {
                LiftProgramsSection()
                    .environment(coordinator)
            }
        }
        .toast($errorHandler.toastMessage, type: errorHandler.toastType)
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
