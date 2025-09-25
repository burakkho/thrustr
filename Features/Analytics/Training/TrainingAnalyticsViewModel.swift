import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for TrainingAnalyticsView with clean separation of concerns.
 *
 * Manages training data processing, strength progression analytics, and PR tracking.
 * Handles all business logic for training analytics dashboard.
 */
@MainActor
@Observable
class TrainingAnalyticsViewModel {

    // MARK: - State
    var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] = []
    var recentLiftResults: [LiftExerciseResult] = []
    var recentCardioResults: [CardioResult] = []
    var recentLiftSessions: [LiftSession] = []
    var strengthProgressionData: [StrengthProgressionData] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies
    private var modelContext: ModelContext?

    // MARK: - Formatting Methods

    /**
     * Formats weight for display using ViewModel delegation.
     */
    func formatWeight(_ weight: Double, unitSystem: UnitSystem) -> String {
        return TrainingAnalyticsService.formatWeight(weight, unitSystem: unitSystem)
    }

    /**
     * Formats weight difference for display using ViewModel delegation.
     */
    func formatWeightDifference(_ weight: Double, trend: TrendDirection, unitSystem: UnitSystem) -> String {
        return TrainingAnalyticsService.formatWeightDifference(weight, trend: trend, unitSystem: unitSystem)
    }

    // MARK: - Computed Properties

    /**
     * Whether there is sufficient data to show analytics.
     */
    var hasAnalyticsData: Bool {
        return !recentLiftResults.isEmpty
    }

    /**
     * Recent PRs calculation (last 30 days)
     */
    var recentPRs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentResults = recentLiftResults.filter { $0.performedAt >= thirtyDaysAgo }

        let exerciseGroups = Dictionary(grouping: recentResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        var prs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] = []

        for (exerciseName, results) in exerciseGroups {
            let validResults: [(result: LiftExerciseResult, weight: Double)] = results.compactMap { result in
                guard let maxWeight = result.maxWeight, maxWeight > 0 else { return nil }
                return (result: result, weight: maxWeight)
            }

            guard let bestResult = validResults.max(by: { $0.weight < $1.weight }) else { continue }

            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let isNew = bestResult.result.performedAt >= oneWeekAgo

            prs.append((
                exercise: exerciseName,
                weight: bestResult.weight,
                date: bestResult.result.performedAt,
                isNew: isNew
            ))
        }

        return Array(prs.prefix(3))
    }

    /**
     * Total workouts in the last 30 days.
     */
    var totalWorkouts: Int {
        let uniqueSessions = Set(recentLiftResults.compactMap { $0.session?.id })
        return uniqueSessions.count
    }

    /**
     * Average workouts per week.
     */
    var averageWorkoutsPerWeek: Double {
        return Double(totalWorkouts) * 7.0 / 30.0
    }

    /**
     * Training patterns data
     */
    var trainingPatterns: (mostActiveTime: String, favoriteDay: String, weeklyVolume: Double) {
        guard !recentLiftResults.isEmpty else {
            return ("No data", "No data", 0.0)
        }

        let allDates = recentLiftResults.map { $0.performedAt }

        // Most active time calculation
        let hourCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.hour, from: date)
        }.mapValues { $0.count }

        let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 0
        let endHour = (mostActiveHour + 2) % 24
        let mostActiveTime = String(format: "%02d:00-%02d:00", mostActiveHour, endHour)

        // Favorite workout day calculation
        let dayCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.weekday, from: date)
        }.mapValues { $0.count }

        let mostActiveDay = dayCounts.max(by: { $0.value < $1.value })?.key ?? 1
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let favoriteDay = formatter.weekdaySymbols[mostActiveDay - 1]

        // Weekly volume calculation
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentResults = recentLiftResults.filter { $0.performedAt >= oneWeekAgo }
        let weeklyVolume = recentResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }

        return (mostActiveTime, favoriteDay, weeklyVolume)
    }

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading Methods

    /**
     * Loads all training data from SwiftData context.
     */
    func loadTrainingData() {
        guard let context = modelContext else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Load lift exercise results (last 6 months)
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            let liftResultDescriptor = FetchDescriptor<LiftExerciseResult>(
                predicate: #Predicate { $0.performedAt >= sixMonthsAgo },
                sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
            )
            recentLiftResults = try context.fetch(liftResultDescriptor)

            // Load cardio results (last 6 months)
            let cardioResultDescriptor = FetchDescriptor<CardioResult>(
                predicate: #Predicate { $0.completedAt >= sixMonthsAgo },
                sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
            )
            recentCardioResults = try context.fetch(cardioResultDescriptor)

            // Load lift sessions (last 6 months)
            let liftSessionDescriptor = FetchDescriptor<LiftSession>(
                predicate: #Predicate { $0.startDate >= sixMonthsAgo },
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            recentLiftSessions = try context.fetch(liftSessionDescriptor)

            // Update computed properties
            updateExerciseMaxes()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /**
     * Sets the ModelContext for SwiftData queries.
     */
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        loadTrainingData()
    }

    // MARK: - Public Methods

    /**
     * Updates data with new lift exercise results and sessions.
     */
    func updateData(_ allLiftResults: [LiftExerciseResult], cardioResults: [CardioResult] = [], liftSessions: [LiftSession] = []) {
        // Filter to last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        recentLiftResults = allLiftResults.filter { result in
            result.performedAt >= thirtyDaysAgo
        }

        recentLiftSessions = liftSessions.filter { session in
            session.startDate >= thirtyDaysAgo
        }

        self.recentCardioResults = cardioResults

        // Calculate analytics
        updateExerciseMaxes()
        calculateStrengthProgression()
    }

    /**
     * Refreshes analytics data.
     */
    func refreshAnalytics(_ allLiftResults: [LiftExerciseResult]) {
        updateData(allLiftResults)
    }

    // MARK: - View Logic Methods (moved from TrainingAnalyticsView)

    /**
     * Calculate weekly workout frequency and trend
     */
    func calculateWeeklyFrequency(cardioResults: [CardioResult]) -> (thisWeek: Int, lastWeek: Int, trend: TrendDirection) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        let thisWeekLift = recentLiftResults.filter { $0.performedAt >= oneWeekAgo }.count
        let thisWeekCardio = cardioResults.filter { $0.completedAt >= oneWeekAgo }.count
        let thisWeekTotal = thisWeekLift + thisWeekCardio

        let lastWeekLift = recentLiftResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }.count
        let lastWeekCardio = cardioResults.filter { $0.completedAt >= twoWeeksAgo && $0.completedAt < oneWeekAgo }.count
        let lastWeekTotal = lastWeekLift + lastWeekCardio

        let trend: TrendDirection = {
            if thisWeekTotal > lastWeekTotal { return .increasing }
            if thisWeekTotal < lastWeekTotal { return .decreasing }
            return .stable
        }()

        return (thisWeekTotal, lastWeekTotal, trend)
    }

    /**
     * Update exercise maxes using service layer
     */
    private func updateExerciseMaxes() {
        exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: recentLiftResults)
    }

    /**
     * Calculate training insights grid data
     */
    func calculateTrainingInsights(cardioResults: [CardioResult]) -> (
        weeklyFrequency: Int,
        frequencyTrend: TrendDirection,
        avgDuration: Int,
        weeklyVolume: Double,
        volumeTrend: TrendDirection,
        bestDay: String
    ) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        // Weekly frequency
        let liftWorkouts = recentLiftResults.filter { $0.performedAt >= oneWeekAgo }.count
        let cardioWorkouts = cardioResults.filter { $0.completedAt >= oneWeekAgo }.count
        let weeklyFrequency = liftWorkouts + cardioWorkouts

        // Frequency trend
        let lastWeekLift = recentLiftResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }.count
        let lastWeekCardio = cardioResults.filter { $0.completedAt >= twoWeeksAgo && $0.completedAt < oneWeekAgo }.count
        let lastWeek = lastWeekLift + lastWeekCardio

        let frequencyTrend: TrendDirection = {
            if weeklyFrequency > lastWeek { return .increasing }
            if weeklyFrequency < lastWeek { return .decreasing }
            return .stable
        }()

        // Average duration (simplified)
        let avgDuration = 45

        // Weekly volume
        let recentResults = recentLiftResults.filter { $0.performedAt >= oneWeekAgo }
        let weeklyVolume = recentResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }

        // Volume trend
        let lastWeekResults = recentLiftResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }
        let lastWeekVolume = lastWeekResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }

        let volumeTrend: TrendDirection = {
            if weeklyVolume > lastWeekVolume * 1.1 { return .increasing }
            if weeklyVolume < lastWeekVolume * 0.9 { return .decreasing }
            return .stable
        }()

        // Best workout day
        let liftDates = recentLiftResults.map { $0.performedAt }
        let cardioDates = cardioResults.map { $0.completedAt }
        let allDates = liftDates + cardioDates

        let bestDay: String
        if !allDates.isEmpty {
            let dayCounts = Dictionary(grouping: allDates) { date in
                Calendar.current.component(.weekday, from: date)
            }.mapValues { $0.count }

            if let mostActiveDay = dayCounts.max(by: { $0.value < $1.value })?.key {
                let formatter = DateFormatter()
                bestDay = formatter.shortWeekdaySymbols[mostActiveDay - 1]
            } else {
                bestDay = "None"
            }
        } else {
            bestDay = "None"
        }

        return (weeklyFrequency, frequencyTrend, avgDuration, weeklyVolume, volumeTrend, bestDay)
    }

    /**
     * Format volume for display
     */
    func formatVolume(_ weightInKg: Double, unitSystem: UnitSystem) -> String {
        if weightInKg == 0 {
            return unitSystem == .metric ? "0 kg" : "0 lb"
        }

        if unitSystem == .metric {
            if weightInKg >= 1000 {
                let tons = weightInKg / 1000.0
                return String(format: "%.1f tons", tons)
            } else {
                return String(format: "%.0f kg", weightInKg)
            }
        } else {
            let weightInLbs = weightInKg * 2.20462
            if weightInLbs >= 2000 {
                let shortTons = weightInLbs / 2000.0
                return String(format: "%.1f tons", shortTons)
            } else {
                return String(format: "%.0f lb", weightInLbs)
            }
        }
    }

    // MARK: - Training Story Hero Card Methods

    /**
     * Calculate monthly PRs for hero card
     */
    func calculateMonthlyPRs() -> Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let monthlyResults = recentLiftResults.filter { $0.performedAt >= oneMonthAgo }

        // Group by exercise and find PRs
        let exerciseGroups = Dictionary(grouping: monthlyResults) { $0.exercise?.exerciseName ?? "Unknown" }

        return exerciseGroups.values.compactMap { results in
            results.compactMap { $0.maxWeight }.max()
        }.count
    }

    /**
     * Calculate total progress for hero card
     */
    func calculateTotalProgress() -> Int {
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        let oldResults = recentLiftResults.filter { $0.performedAt >= twoMonthsAgo && $0.performedAt < oneMonthAgo }
        let newResults = recentLiftResults.filter { $0.performedAt >= oneMonthAgo }

        let oldMax = oldResults.compactMap { $0.maxWeight }.max() ?? 0
        let newMax = newResults.compactMap { $0.maxWeight }.max() ?? 0

        return max(0, Int(newMax - oldMax))
    }

    /**
     * Calculate workout streak for hero card
     */
    func calculateStreak() -> Int {
        // Simple streak calculation - days with workouts
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let streakResults = recentLiftResults.filter { $0.performedAt >= last30Days }

        let workoutDays = Set(streakResults.map {
            Calendar.current.startOfDay(for: $0.performedAt)
        })

        return min(workoutDays.count, 30)
    }

    /**
     * Calculate next milestone for goals section
     */
    func calculateNextMilestone() -> String {
        let maxWeight = recentLiftResults.compactMap { $0.maxWeight }.max() ?? 0

        if maxWeight == 0 {
            return "Complete your first workout!"
        } else if maxWeight < 60 {
            return "Reach 60kg personal record"
        } else if maxWeight < 100 {
            return "Break the 100kg barrier"
        } else {
            let nextMilestone = ((Int(maxWeight) / 25) + 1) * 25
            return "Reach \(nextMilestone)kg milestone"
        }
    }

    /**
     * Calculate milestone progress for goals section
     */
    func calculateMilestoneProgress() -> Double {
        let maxWeight = recentLiftResults.compactMap { $0.maxWeight }.max() ?? 0

        if maxWeight == 0 {
            return 0.0
        } else if maxWeight < 60 {
            return maxWeight / 60.0
        } else if maxWeight < 100 {
            return (maxWeight - 60) / 40.0
        } else {
            let currentMilestone = (Int(maxWeight) / 25) * 25
            let _ = currentMilestone + 25
            return (maxWeight - Double(currentMilestone)) / 25.0
        }
    }

    /**
     * Calculate weekly workouts for goals section
     */
    func calculateWeeklyWorkouts() -> Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentLiftResults.filter { $0.performedAt >= oneWeekAgo }.count
    }

    // MARK: - Private Methods

    private func calculateExerciseMaxes() {
        let exerciseGroups = Dictionary(grouping: recentLiftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        exerciseMaxes = exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }

            // Find current max (best set from all results)
            let currentMax = results.compactMap { $0.maxWeight }.max() ?? 0.0

            // Calculate trend (compare last 2 weeks vs previous 2 weeks)
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()

            let recentResults = results.filter { $0.performedAt >= twoWeeksAgo }
            let previousResults = results.filter { $0.performedAt >= fourWeeksAgo && $0.performedAt < twoWeeksAgo }

            let recentMax = recentResults.compactMap { $0.maxWeight }.max() ?? 0.0
            let previousMax = previousResults.compactMap { $0.maxWeight }.max() ?? 0.0

            let improvement = recentMax - previousMax
            let trend: TrendDirection = {
                if improvement > 2.5 { return .increasing }
                if improvement < -2.5 { return .decreasing }
                return .stable
            }()

            return (name: exerciseName, currentMax: currentMax, trend: trend, improvement: improvement)
        }
        .sorted { $0.currentMax > $1.currentMax }
        .prefix(6)
        .map { $0 }
    }

    private func calculateStrengthProgression() {
        // Group by exercise and calculate progression over time
        let exerciseGroups = Dictionary(grouping: recentLiftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        strengthProgressionData = exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }

            let sortedResults = results.sorted { $0.performedAt < $1.performedAt }
            let progressionPoints = sortedResults.compactMap { result -> ProgressionPoint? in
                guard let maxWeight = result.maxWeight else { return nil }
                return ProgressionPoint(date: result.performedAt, weight: maxWeight)
            }

            guard !progressionPoints.isEmpty else { return nil }

            return StrengthProgressionData(
                exerciseName: exerciseName,
                progressionPoints: progressionPoints,
                currentMax: progressionPoints.map { $0.weight }.max() ?? 0.0
            )
        }
        .sorted { $0.currentMax > $1.currentMax }
    }
}

// MARK: - Supporting Types

struct StrengthProgressionData {
    let exerciseName: String
    let progressionPoints: [ProgressionPoint]
    let currentMax: Double
}

struct ProgressionPoint {
    let date: Date
    let weight: Double
}

