import SwiftUI
import SwiftData

struct LiftMainView: View {
    @Environment(\.theme) private var theme
    @Environment(TrainingCoordinator.self) private var coordinator
    @State private var selectedTab = 0 // Start with Train tab
    
    private let tabs = [
        TrainingTab(title: TrainingKeys.Lift.train.localized, icon: "dumbbell.fill"),
        TrainingTab(title: TrainingKeys.Lift.programs.localized, icon: "rectangle.3.group"),
        TrainingTab(title: TrainingKeys.Lift.routines.localized, icon: "list.bullet"),
        TrainingTab(title: TrainingKeys.Lift.history.localized, icon: "clock.arrow.circlepath")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            TrainingTabSelector(
                selection: $selectedTab,
                tabs: tabs
            )
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    LiftWorkoutsSection()
                        .environment(coordinator)
                case 1:
                    LiftProgramsSection()
                        .environment(coordinator)
                case 2:
                    LiftRoutinesSection()
                        .environment(coordinator)
                case 3:
                    LiftHistorySection()
                        .environment(coordinator)
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

#Preview {
    LiftMainView()
        .environment(TrainingCoordinator())
        .modelContainer(for: [
            LiftProgram.self,
            LiftWorkout.self,
            LiftSession.self,
            ProgramExecution.self,
            User.self
        ], inMemory: true)
}