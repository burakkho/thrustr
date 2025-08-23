import SwiftUI
import SwiftData

enum WorkoutType: Int, CaseIterable {
    case dashboard = 0
    case lift = 1
    case cardio = 2
    case wod = 3
    case analytics = 4
    
    var title: String {
        switch self {
        case .dashboard: return LocalizationKeys.Training.Dashboard.title.localized
        case .lift: return "training.lift.title".localized
        case .cardio: return LocalizationKeys.Training.Cardio.title.localized
        case .wod: return LocalizationKeys.Training.WOD.title.localized
        case .analytics: return LocalizationKeys.Training.Analytics.title.localized
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .lift: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .wod: return "flame.fill"
        case .analytics: return "chart.bar.fill"
        }
    }
}

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
    
    init() {}
    
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