import SwiftUI
import SwiftData

struct LiftMainView: View {
    @Environment(\.theme) private var theme
    @Environment(TrainingCoordinator.self) private var coordinator
    @State private var selectedTab = 0 // Start with Train tab
    
    private let tabs = [
        TrainingTab(title: LocalizationKeys.Training.Lift.train.localized),
        TrainingTab(title: LocalizationKeys.Training.Lift.programs.localized),
        TrainingTab(title: LocalizationKeys.Training.Lift.routines.localized),
        TrainingTab(title: LocalizationKeys.Training.Lift.history.localized)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
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
                case 1:
                    LiftProgramsSection()
                case 2:
                    LiftRoutinesSection()
                case 3:
                    LiftHistorySection()
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("training.lift.title".localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if coordinator.hasActiveSession && coordinator.activeSessionType == .lift {
                    Label(LocalizationKeys.Training.Lift.sessionInProgress.localized, systemImage: "circle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.success)
                }
            }
            
            Spacer()
            
            // Quick Actions Menu
            Menu {
                Button(action: { coordinator.navigateToNewWorkout() }) {
                    Label(LocalizationKeys.Training.Lift.newWorkout.localized, systemImage: "plus.circle")
                }
                
                Button(action: { coordinator.navigateToProgramSelection() }) {
                    Label(LocalizationKeys.Training.Lift.browsePrograms.localized, systemImage: "rectangle.3.group")
                }
                
                Button(action: { coordinator.performQuickAction(.emptyWorkout) }) {
                    Label(LocalizationKeys.Training.Lift.quickStart.localized, systemImage: "bolt.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.m)
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