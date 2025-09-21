import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for StrengthProgressionDetailView with clean separation of concerns.
 *
 * Manages strength progression analytics, exercise comparisons, and progress tracking.
 * Handles all business logic for detailed strength analytics.
 */
@MainActor
@Observable
class StrengthProgressionDetailViewModel {

    // MARK: - State
    var selectedTimeRange: TimeRange = .sixMonths
    var selectedExercise: String = "Bench Press"
    var isLoading = false
    var currentUser: User? = nil

    // Data properties
    var progressData: [ProgressDataPoint] = []
    var exerciseComparison: [ExerciseComparison] = []
    var availableExercises: [String] = ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull Up"]

    // MARK: - Dependencies
    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    /**
     * Current max weight for selected exercise
     */
    var currentMax: Double {
        guard let user = currentUser else { return 0 }
        switch selectedExercise {
        case "Bench Press": return user.benchPressOneRM ?? 0
        case "Squat": return user.squatOneRM ?? 0
        case "Deadlift": return user.deadliftOneRM ?? 0
        case "Overhead Press": return user.overheadPressOneRM ?? 0
        default: return 0
        }
    }

    /**
     * Total improvement percentage
     */
    var totalImprovement: Double {
        guard progressData.count > 1 else { return 0 }
        let first = progressData.first?.weight ?? 0
        let last = progressData.last?.weight ?? 0
        guard first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }

    /**
     * Last PR date formatted
     */
    var lastPRDate: String {
        guard let lastPoint = progressData.last else { return "--" }
        return formatDate(lastPoint.date, short: true)
    }

    /**
     * Training frequency (sessions per week)
     */
    var trainingFrequency: Int {
        guard let context = modelContext else { return 0 }

        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let liftSessions = getLiftSessionsFromLast4Weeks(since: fourWeeksAgo, context: context)
        return max(1, liftSessions.count / 4)
    }

    // MARK: - Initialization

    init() {
        // No dependencies needed at init
    }

    // MARK: - Public Methods

    /**
     * Sets up the ViewModel with model context and user data
     */
    func setup(modelContext: ModelContext, user: User?) {
        self.modelContext = modelContext
        self.currentUser = user
        generateProgressData()
        generateExerciseComparison()
    }

    /**
     * Updates selected time range and regenerates data
     */
    func updateTimeRange(_ newRange: TimeRange) {
        selectedTimeRange = newRange
        generateProgressData()
    }

    /**
     * Updates selected exercise and regenerates data
     */
    func updateSelectedExercise(_ exercise: String) {
        selectedExercise = exercise
        generateProgressData()
    }

    /**
     * Refreshes all data
     */
    func refreshData() {
        generateProgressData()
        generateExerciseComparison()
    }

    // MARK: - Private Methods

    /**
     * Generates progress data for selected exercise and time range
     */
    private func generateProgressData() {
        let endDate = Date()
        let baseWeight = currentMax > 0 ? currentMax * 0.85 : 60.0

        var data: [ProgressDataPoint] = []
        let numberOfPoints = min(selectedTimeRange.months * 2, 12)

        for i in 0..<numberOfPoints {
            let date = Calendar.current.date(byAdding: .weekOfYear, value: i * 2 - numberOfPoints * 2, to: endDate) ?? endDate
            let progressionFactor = Double(i) / Double(numberOfPoints - 1)
            let weight = baseWeight + (currentMax - baseWeight) * progressionFactor

            data.append(ProgressDataPoint(
                date: date,
                weight: weight,
                exercise: selectedExercise
            ))
        }

        progressData = data.sorted { $0.date < $1.date }
    }

    /**
     * Generates exercise comparison data
     */
    private func generateExerciseComparison() {
        exerciseComparison = availableExercises.map { exercise in
            ExerciseComparison(
                exercise: exercise,
                currentMax: getCurrentMax(for: exercise),
                improvement: getImprovement(for: exercise)
            )
        }
    }

    /**
     * Gets current max for specific exercise
     */
    private func getCurrentMax(for exercise: String) -> Double {
        guard let user = currentUser else { return 0 }
        switch exercise {
        case "Bench Press": return user.benchPressOneRM ?? 0
        case "Squat": return user.squatOneRM ?? 0
        case "Deadlift": return user.deadliftOneRM ?? 0
        case "Overhead Press": return user.overheadPressOneRM ?? 0
        case "Pull Up": return user.pullUpOneRM ?? 0
        default: return 0
        }
    }

    /**
     * Calculates improvement for specific exercise
     */
    private func getImprovement(for exercise: String) -> Double {
        guard let context = modelContext else { return 0.0 }

        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()

        let recentResults = getExerciseResults(for: exercise, since: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), context: context)
        let olderResults = getExerciseResults(for: exercise, since: twoMonthsAgo, until: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), context: context)

        guard let recentMax = recentResults.compactMap({ $0.maxWeight }).max(),
              let olderMax = olderResults.compactMap({ $0.maxWeight }).max(),
              olderMax > 0 else {
            return 0.0
        }

        return ((recentMax - olderMax) / olderMax) * 100.0
    }

    /**
     * Fetches lift sessions from last 4 weeks
     */
    private func getLiftSessionsFromLast4Weeks(since date: Date, context: ModelContext) -> [LiftSession] {
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                (session.endDate ?? session.startDate) >= date
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    /**
     * Fetches exercise results for specific exercise and date range
     */
    private func getExerciseResults(for exerciseName: String, since startDate: Date, until endDate: Date? = nil, context: ModelContext) -> [LiftExerciseResult] {
        let end = endDate ?? Date()

        let descriptor = FetchDescriptor<LiftExerciseResult>(
            predicate: #Predicate<LiftExerciseResult> { result in
                result.exercise?.exerciseName == exerciseName &&
                result.performedAt >= startDate &&
                result.performedAt <= end
            },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    /**
     * Formats date with optional short format
     */
    func formatDate(_ date: Date, short: Bool = false) -> String {
        let formatter = DateFormatter()
        if short {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

