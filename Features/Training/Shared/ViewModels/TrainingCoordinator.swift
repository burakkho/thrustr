import SwiftUI
import SwiftData

enum WorkoutType: Int, CaseIterable, Sendable {
    case dashboard = 0
    case lift = 1
    case cardio = 2
    case wod = 3
    
    var title: String {
        switch self {
        case .dashboard: return TrainingKeys.Dashboard.title.localized
        case .lift: return TrainingKeys.Lift.title.localized
        case .cardio: return TrainingKeys.Cardio.title.localized
        case .wod: return TrainingKeys.WOD.title.localized
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .lift: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .wod: return "flame.fill"
        }
    }
}


@MainActor
@Observable
class TrainingCoordinator {
    // Navigation State
    var selectedWorkoutType: WorkoutType = .dashboard
    var navigationPath = NavigationPath()
    
    
    // Shared UI State
    var showingNewWorkout = false
    var selectedWorkout: (any Identifiable)?
    var showingWorkoutDetail = false
    
    // Search & Filter
    var searchText = ""
    var selectedFilter: String?
    
    // Quick Actions
    var showingQuickStart = false
    var showingProgramSelection = false
    
    // Active Sessions
    private(set) var hasActiveSession = false
    private(set) var activeSessionType: WorkoutType?
    
    // MARK: - Navigation Methods
    
    func selectWorkoutType(_ type: WorkoutType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedWorkoutType = type
            clearFilters()
        }
    }
    
    func navigateToWorkout(_ workout: any Identifiable) {
        selectedWorkout = workout
        showingWorkoutDetail = true
    }
    
    func navigateToNewWorkout() {
        showingNewWorkout = true
    }
    
    func navigateToProgramSelection() {
        showingProgramSelection = true
    }
    
    func navigateToWODHistory() {
        selectedWorkoutType = .wod
    }
    
    func navigateToHistory() {
        navigationPath.append("workout_history")
    }
    
    func navigateToOneRMSetup() {
        navigationPath.append("one_rm_setup")
    }
    
    func navigateToPRDetail() {
        navigationPath.append("pr_detail")
    }
    
    func navigateToGoalSettings() {
        print("🚀 Navigating to goal_settings")
        navigationPath.append("goal_settings")
    }
    
    // Listen for navigation notifications
    init() {
        NotificationCenter.default.addObserver(
            forName: .navigateToWODHistory,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWODHistoryNavigation()
            }
        }
    }
    
    @objc private func handleWODHistoryNavigation() {
        navigateToWODHistory()
    }
    
    // MARK: - Session Management
    
    func startSession(type: WorkoutType) {
        hasActiveSession = true
        activeSessionType = type
    }
    
    func endSession() {
        hasActiveSession = false
        activeSessionType = nil
    }
    
    // MARK: - Filter Management
    
    func clearFilters() {
        searchText = ""
        selectedFilter = nil
    }
    
    func applySearch(_ text: String) {
        searchText = text
    }
    
    // MARK: - Quick Actions
    
    func performQuickAction(_ action: QuickAction) {
        switch action {
        case .emptyWorkout:
            createEmptyWorkout()
        case .pickRoutine:
            navigateToRoutines()
        case .startProgram:
            navigateToProgramSelection()
        case .quickCardio:
            startQuickCardio()
        case .wodOfTheDay:
            showWODOfTheDay()
        }
    }
    
    private func createEmptyWorkout() {
        // Implementation based on workout type
        showingQuickStart = true
    }
    
    private func navigateToRoutines() {
        // Navigate to routines section
    }
    
    private func startQuickCardio() {
        selectedWorkoutType = .cardio
        showingQuickStart = true
    }
    
    private func showWODOfTheDay() {
        selectedWorkoutType = .wod
        // Show WOD of the day
    }
}

enum QuickAction {
    case emptyWorkout
    case pickRoutine
    case startProgram
    case quickCardio
    case wodOfTheDay
}

// MARK: - Shared Data Models

protocol WorkoutProtocol: Identifiable {
    var name: String { get }
    var workoutDescription: String? { get }
    var isFavorite: Bool { get }
    var lastPerformed: Date? { get }
}

// Extension for common workout operations
extension TrainingCoordinator {
    func toggleFavorite(for workout: any WorkoutProtocol) {
        // Toggle favorite status
    }
    
    func deleteWorkout(_ workout: any WorkoutProtocol) {
        // Delete workout with confirmation
    }
    
    func duplicateWorkout(_ workout: any WorkoutProtocol) {
        // Create a copy of the workout
    }
}