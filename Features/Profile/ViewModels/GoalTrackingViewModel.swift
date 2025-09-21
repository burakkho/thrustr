import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class GoalTrackingViewModel {

    // MARK: - UI State
    var showingAddGoal = false
    var selectedGoalType: GoalType = .weight
    var isLoading = false
    var errorMessage: String?

    // MARK: - Data State
    var goals: [Goal] = []
    var currentUser: User?

    // MARK: - Computed Properties
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted && !$0.isExpired }
    }

    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }

    var averageProgress: Double {
        let activeGoals = self.activeGoals
        guard !activeGoals.isEmpty else { return 0 }
        return activeGoals.map { $0.progressPercentage }.reduce(0, +) / Double(activeGoals.count)
    }

    var daysUntilNextDeadline: Int {
        let activeGoalsWithDeadline = activeGoals.filter { $0.deadline != nil }
        guard let nextDeadline = activeGoalsWithDeadline.compactMap({ $0.deadline }).min() else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDeadline).day ?? 0
    }

    var goalsCompletedThisMonth: Int {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return completedGoals.filter { goal in
            guard let completedDate = goal.completedDate else { return false }
            return completedDate >= startOfMonth
        }.count
    }

    var successRate: Double {
        let totalGoals = goals.count
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals.count) / Double(totalGoals) * 100
    }

    // MARK: - Dependencies
    private let goalService: GoalServiceProtocol

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.goalService = GoalService(modelContext: modelContext)
    }

    // MARK: - Public Methods
    func loadGoals() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            goals = try await goalService.fetchGoals()
        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: ErrorSeverity.medium,
                source: "GoalTrackingViewModel.loadGoals"
            )
            errorMessage = context.error.errorDescription
        }
    }

    func loadUser() async {
        do {
            currentUser = try await goalService.fetchCurrentUser()
        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: ErrorSeverity.low,
                source: "GoalTrackingViewModel.loadUser"
            )
            errorMessage = context.error.errorDescription
        }
    }

    func addGoal(title: String, description: String, targetValue: Double, type: GoalType, deadline: Date?) async {
        do {
            _ = try await goalService.createGoal(
                title: title,
                description: description,
                targetValue: targetValue,
                type: type,
                deadline: deadline
            )
            goals = try await goalService.fetchGoals()
            showingAddGoal = false
        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: ErrorSeverity.medium,
                source: "GoalTrackingViewModel.addGoal"
            )
            errorMessage = context.error.errorDescription
        }
    }

    func updateGoal(_ goal: Goal) async {
        do {
            _ = try await goalService.updateGoal(goal)
            goals = try await goalService.fetchGoals()
        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: ErrorSeverity.medium,
                source: "GoalTrackingViewModel.updateGoal"
            )
            errorMessage = context.error.errorDescription
        }
    }

    func deleteGoal(_ goal: Goal) async {
        do {
            try await goalService.deleteGoal(goal)
            goals = try await goalService.fetchGoals()
        } catch {
            let context = ErrorService.shared.processError(
                error,
                severity: ErrorSeverity.medium,
                source: "GoalTrackingViewModel.deleteGoal"
            )
            errorMessage = context.error.errorDescription
        }
    }

    func refreshData() async {
        await loadGoals()
        await loadUser()
    }

    // MARK: - UI Actions
    func showAddGoal(with type: GoalType = .weight) {
        selectedGoalType = type
        showingAddGoal = true
    }

    func dismissAddGoal() {
        showingAddGoal = false
    }

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Goal Service Protocol
protocol GoalServiceProtocol {
    func fetchGoals() async throws -> [Goal]
    func fetchCurrentUser() async throws -> User?
    func createGoal(title: String, description: String, targetValue: Double, type: GoalType, deadline: Date?) async throws -> Goal
    func updateGoal(_ goal: Goal) async throws -> Goal
    func deleteGoal(_ goal: Goal) async throws
    func calculateProgress(for goal: Goal) -> Double
}