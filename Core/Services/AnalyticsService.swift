import Foundation
import SwiftData
import SwiftUI

// MARK: - Analytics Service
@Observable
class AnalyticsService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Weekly Summary Data
    struct WeeklySummary {
        let totalSessions: Int
        let totalDuration: TimeInterval
        let totalVolume: Double // For lift sessions
        let totalDistance: Double // For cardio sessions
        let liftSessions: Int
        let cardioSessions: Int
        let currentStreak: Int
        let weeklyPRs: Int
    }
    
    // MARK: - Monthly Goal Progress
    struct GoalProgress {
        let sessionProgress: Double // 0.0 - 1.0
        let distanceProgress: Double // 0.0 - 1.0
        let currentSessions: Int
        let targetSessions: Int
        let currentDistance: Double
        let targetDistance: Double
    }
    
    // MARK: - PR Record
    struct PRRecord {
        let exerciseName: String
        let value: Double
        let unit: String
        let date: Date
        let isRecent: Bool // Within last 7 days
    }
    
    // MARK: - Main Analytics Methods
    
    func getWeeklySummary(for user: User) -> WeeklySummary {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        // Get this week's sessions
        let liftSessions = getLiftSessionsThisWeek(startDate: startOfWeek)
        let cardioSessions = getCardioSessionsThisWeek(startDate: startOfWeek)
        
        let totalSessions = liftSessions.count + cardioSessions.count
        let totalDuration = calculateTotalDuration(liftSessions: liftSessions, cardioSessions: cardioSessions)
        let totalVolume = liftSessions.reduce(0) { $0 + $1.totalVolume }
        let totalDistance = cardioSessions.reduce(0) { $0 + $1.totalDistance }
        
        // Calculate current streak
        let currentStreak = calculateCurrentStreak(user: user)
        
        // Count weekly PRs (placeholder - will implement PR detection later)
        let weeklyPRs = user.totalPRsThisMonth > 0 ? 1 : 0
        
        return WeeklySummary(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            totalVolume: totalVolume,
            totalDistance: totalDistance,
            liftSessions: liftSessions.count,
            cardioSessions: cardioSessions.count,
            currentStreak: currentStreak,
            weeklyPRs: weeklyPRs
        )
    }
    
    func getMonthlyGoalProgress(for user: User) -> GoalProgress {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        // Get this month's sessions
        let liftSessions = getLiftSessionsThisMonth(startDate: startOfMonth)
        let cardioSessions = getCardioSessionsThisMonth(startDate: startOfMonth)
        
        let currentSessions = liftSessions.count + cardioSessions.count
        let currentDistance = cardioSessions.reduce(0) { $0 + $1.totalDistance }
        
        let sessionProgress = min(1.0, Double(currentSessions) / Double(user.monthlySessionGoal))
        let distanceProgress = min(1.0, currentDistance / user.monthlyDistanceGoal)
        
        return GoalProgress(
            sessionProgress: sessionProgress,
            distanceProgress: distanceProgress,
            currentSessions: currentSessions,
            targetSessions: user.monthlySessionGoal,
            currentDistance: currentDistance,
            targetDistance: user.monthlyDistanceGoal
        )
    }
    
    func getRecentPRs(for user: User, limit: Int = 5) -> [PRRecord] {
        var prs: [PRRecord] = []
        
        // Get real PRs from LiftExerciseResults
        let recentPRs = getActualPRsFromSessions(limit: limit * 2) // Get more to filter later
        prs.append(contentsOf: recentPRs)
        
        // If no recent session PRs, include 1RM data as fallback
        if prs.isEmpty {
            prs.append(contentsOf: getOneRMPRs(for: user))
        }
        
        // Sort by date descending and limit results
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getActualPRsFromSessions(limit: Int) -> [PRRecord] {
        var prs: [PRRecord] = []
        
        // Fetch recent LiftExerciseResults where isPersonalRecord = true
        let descriptor = FetchDescriptor<LiftExerciseResult>(
            predicate: #Predicate { result in
                result.isPersonalRecord == true
            },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        
        guard let prResults = try? modelContext.fetch(descriptor) else { return prs }
        
        for result in prResults.prefix(limit) {
            if let maxWeight = result.maxWeight,
               let exerciseName = result.exercise?.exerciseName {
                prs.append(PRRecord(
                    exerciseName: exerciseName,
                    value: maxWeight,
                    unit: "kg",
                    date: result.performedAt,
                    isRecent: Calendar.current.isDate(result.performedAt, equalTo: Date(), toGranularity: .weekOfYear)
                ))
            }
        }
        
        return prs
    }
    
    private func getOneRMPRs(for user: User) -> [PRRecord] {
        var prs: [PRRecord] = []
        
        let oneRMData: [(String, Double?)] = [
            ("Back Squat", user.squatOneRM),
            ("Bench Press", user.benchPressOneRM),
            ("Deadlift", user.deadliftOneRM),
            ("Overhead Press", user.overheadPressOneRM)
        ]
        
        for (exerciseName, oneRM) in oneRMData {
            if let value = oneRM, value > 0,
               let lastUpdate = user.oneRMLastUpdated {
                prs.append(PRRecord(
                    exerciseName: exerciseName,
                    value: value,
                    unit: "kg",
                    date: lastUpdate,
                    isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear)
                ))
            }
        }
        
        return prs
    }
    
    // MARK: - Daily Activity for Chart (7 days)
    func getDailyActivityData() -> [DailyActivity] {
        let calendar = Calendar.current
        let today = Date()
        var activities: [DailyActivity] = []
        
        // Get last 7 days
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let liftSessions = getLiftSessionsInDateRange(start: dayStart, end: dayEnd)
            let cardioSessions = getCardioSessionsInDateRange(start: dayStart, end: dayEnd)
            
            activities.append(DailyActivity(
                date: date,
                dayName: calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1],
                liftSessions: liftSessions.count,
                cardioSessions: cardioSessions.count,
                totalSessions: liftSessions.count + cardioSessions.count
            ))
        }
        
        return activities.reversed() // Show oldest to newest
    }
    
    // MARK: - Helper Methods
    
    private func getLiftSessionsThisWeek(startDate: Date) -> [LiftSession] {
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        return getLiftSessionsInDateRange(start: startDate, end: endDate)
    }
    
    private func getCardioSessionsThisWeek(startDate: Date) -> [CardioSession] {
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        return getCardioSessionsInDateRange(start: startDate, end: endDate)
    }
    
    private func getLiftSessionsThisMonth(startDate: Date) -> [LiftSession] {
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        return getLiftSessionsInDateRange(start: startDate, end: endDate)
    }
    
    private func getCardioSessionsThisMonth(startDate: Date) -> [CardioSession] {
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        return getCardioSessionsInDateRange(start: startDate, end: endDate)
    }
    
    private func getLiftSessionsInDateRange(start: Date, end: Date) -> [LiftSession] {
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate { session in
                session.startDate >= start && session.startDate < end && session.isCompleted
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func getCardioSessionsInDateRange(start: Date, end: Date) -> [CardioSession] {
        let descriptor = FetchDescriptor<CardioSession>(
            predicate: #Predicate { session in
                session.startDate >= start && session.startDate < end && session.isCompleted
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func calculateTotalDuration(liftSessions: [LiftSession], cardioSessions: [CardioSession]) -> TimeInterval {
        let liftDuration = liftSessions.reduce(0) { total, session in
            total + session.duration
        }
        let cardioDuration = cardioSessions.reduce(0) { total, session in
            total + TimeInterval(session.totalDuration)
        }
        return liftDuration + cardioDuration
    }
    
    private func calculateCurrentStreak(user: User) -> Int {
        // Simple implementation for MVP
        // In full version, this will check actual session dates against 3-day rule
        return user.currentWorkoutStreak
    }
    
    // MARK: - Update User Analytics
    func updateUserAnalytics(for user: User) {
        let weeklySummary = getWeeklySummary(for: user)
        let goalProgress = getMonthlyGoalProgress(for: user)
        
        // Update user's analytics fields
        user.currentWorkoutStreak = weeklySummary.currentStreak
        user.goalCompletionRate = (goalProgress.sessionProgress + goalProgress.distanceProgress) / 2.0
        user.averageSessionDuration = weeklySummary.totalDuration / Double(max(1, weeklySummary.totalSessions))
        user.lastAnalyticsUpdate = Date()
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to update user analytics: \(error)")
        }
    }
    
    // MARK: - 1RM Analytics Methods
    
    struct OneRMDataPoint {
        let date: Date
        let value: Double
        let exerciseName: String
    }
    
    func getOneRMProgressionData(for user: User) -> [String: [OneRMDataPoint]] {
        var data: [String: [OneRMDataPoint]] = [:]
        
        let exercises = [
            "Back Squat",
            "Bench Press", 
            "Deadlift",
            "Overhead Press"
        ]
        
        for exerciseName in exercises {
            var dataPoints: [OneRMDataPoint] = []
            
            // Get historical data from StrengthTestResults
            let historicalPoints = getHistoricalOneRMData(for: exerciseName)
            dataPoints.append(contentsOf: historicalPoints)
            
            // Add current 1RM if available and not already included
            if let currentRM = getCurrentOneRM(for: exerciseName, user: user),
               let lastUpdate = user.oneRMLastUpdated {
                
                // Only add if it's different from the latest historical point
                let shouldAddCurrent = historicalPoints.isEmpty || 
                    historicalPoints.last?.date != lastUpdate ||
                    historicalPoints.last?.value != currentRM
                
                if shouldAddCurrent {
                    dataPoints.append(OneRMDataPoint(
                        date: lastUpdate,
                        value: currentRM,
                        exerciseName: exerciseName
                    ))
                }
            }
            
            data[exerciseName] = dataPoints.sorted { $0.date < $1.date }
        }
        
        return data
    }
    
    private func getHistoricalOneRMData(for exerciseName: String) -> [OneRMDataPoint] {
        var dataPoints: [OneRMDataPoint] = []
        
        // Get StrengthTestResults for this exercise type
        let exerciseTypeRaw = mapExerciseNameToType(exerciseName)
        let descriptor = FetchDescriptor<StrengthTestResult>(
            predicate: #Predicate { result in
                result.exerciseType == exerciseTypeRaw
            },
            sortBy: [SortDescriptor(\.testDate, order: .forward)]
        )
        
        guard let testResults = try? modelContext.fetch(descriptor) else { return dataPoints }
        
        for result in testResults {
            // Calculate 1RM estimation based on the result value
            let estimatedOneRM = calculateOneRM(from: result)
            
            dataPoints.append(OneRMDataPoint(
                date: result.testDate,
                value: estimatedOneRM,
                exerciseName: exerciseName
            ))
        }
        
        return dataPoints
    }
    
    private func calculateOneRM(from result: StrengthTestResult) -> Double {
        // Simple 1RM estimation based on the test result
        // This is a basic approximation - could be enhanced with proper formulas
        
        switch result.exerciseTypeEnum {
        case .benchPress, .backSquat, .deadlift, .overheadPress:
            // For weight-based exercises, the value is already close to 1RM from strength tests
            return result.value
        case .pullUp:
            // For pull-ups, convert reps to estimated 1RM using bodyweight
            let bodyWeight = result.bodyWeightAtTest ?? 80.0
            if result.value > 1 {
                // Use Brzycki formula approximation: Weight = bodyweight * (1 + reps/30)
                return bodyWeight * (1 + result.value / 30.0)
            } else {
                return bodyWeight
            }
        }
    }
    
    private func getCurrentOneRM(for exerciseName: String, user: User) -> Double? {
        switch exerciseName {
        case "Back Squat":
            return user.squatOneRM
        case "Bench Press":
            return user.benchPressOneRM
        case "Deadlift":
            return user.deadliftOneRM
        case "Overhead Press":
            return user.overheadPressOneRM
        default:
            return nil
        }
    }
    
    private func mapExerciseNameToType(_ exerciseName: String) -> String {
        switch exerciseName {
        case "Back Squat":
            return "backSquat"
        case "Bench Press":
            return "benchPress"
        case "Deadlift":
            return "deadlift"
        case "Overhead Press":
            return "overheadPress"
        default:
            return "benchPress" // Default fallback
        }
    }
    
    func getLatestOneRMs(for user: User) -> [(name: String, value: Double?, date: Date?)] {
        return [
            ("Back Squat", user.squatOneRM, user.oneRMLastUpdated),
            ("Bench Press", user.benchPressOneRM, user.oneRMLastUpdated),
            ("Deadlift", user.deadliftOneRM, user.oneRMLastUpdated),
            ("Overhead Press", user.overheadPressOneRM, user.oneRMLastUpdated)
        ]
    }
    
    // MARK: - PR Analytics Methods
    
    struct DetailedPRRecord {
        let exerciseName: String
        let value: Double
        let unit: String
        let date: Date
        let category: PRCategory
        let improvement: Double?
        let isRecent: Bool
        let sessionId: UUID?
    }
    
    enum PRCategory: String, CaseIterable {
        case strength = "strength"
        case endurance = "endurance"
        case volume = "volume"
        
        var displayName: String {
            switch self {
            case .strength: return "training.analytics.strength".localized
            case .endurance: return "training.analytics.endurance".localized
            case .volume: return "training.analytics.volume".localized
            }
        }
        
        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .endurance: return "heart.fill"
            case .volume: return "chart.bar.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .strength: return .orange
            case .endurance: return .red
            case .volume: return .blue
            }
        }
    }
    
    func getPRsByCategory(for user: User, category: PRCategory, limit: Int = 10) -> [DetailedPRRecord] {
        switch category {
        case .strength:
            return getStrengthPRs(for: user, limit: limit)
        case .endurance:
            return getEndurancePRs(for: user, limit: limit)
        case .volume:
            return getVolumePRs(for: user, limit: limit)
        }
    }
    
    private func getStrengthPRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Get actual PRs from lift sessions
        let actualPRs = getStrengthPRsFromSessions(limit: limit)
        prs.append(contentsOf: actualPRs)
        
        // If not enough recent PRs, include 1RM data
        if prs.count < limit {
            let oneRMPRs = getStrengthPRsFromOneRM(for: user, limit: limit - prs.count)
            prs.append(contentsOf: oneRMPRs)
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getStrengthPRsFromSessions(limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        let descriptor = FetchDescriptor<LiftExerciseResult>(
            predicate: #Predicate { result in
                result.isPersonalRecord == true
            },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        
        guard let prResults = try? modelContext.fetch(descriptor) else { return prs }
        
        for result in prResults.prefix(limit) {
            if let maxWeight = result.maxWeight,
               let exerciseName = result.exercise?.exerciseName,
               let sessionId = result.session?.id {
                
                // Calculate real improvement
                let previousBest = getPreviousBest(for: exerciseName, before: result.performedAt)
                let improvement = previousBest > 0 ? ((maxWeight - previousBest) / previousBest) * 100.0 : nil
                
                prs.append(DetailedPRRecord(
                    exerciseName: exerciseName,
                    value: maxWeight,
                    unit: "kg",
                    date: result.performedAt,
                    category: .strength,
                    improvement: improvement,
                    isRecent: Calendar.current.isDate(result.performedAt, equalTo: Date(), toGranularity: .weekOfYear),
                    sessionId: sessionId
                ))
            }
        }
        
        return prs
    }
    
    private func getStrengthPRsFromOneRM(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        let strengthData: [(String, Double?)] = [
            ("Back Squat", user.squatOneRM),
            ("Bench Press", user.benchPressOneRM),
            ("Deadlift", user.deadliftOneRM),
            ("Overhead Press", user.overheadPressOneRM),
            ("Pull-up", user.pullUpOneRM)
        ]
        
        for (name, value) in strengthData {
            guard let prValue = value, prValue > 0,
                  let lastUpdate = user.oneRMLastUpdated else { continue }
            
            prs.append(DetailedPRRecord(
                exerciseName: name,
                value: prValue,
                unit: "kg",
                date: lastUpdate,
                category: .strength,
                improvement: nil, // No historical comparison for 1RM
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getPreviousBest(for exerciseName: String, before date: Date) -> Double {
        let descriptor = FetchDescriptor<LiftExerciseResult>(
            predicate: #Predicate { result in
                result.performedAt < date && result.exercise?.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        
        guard let results = try? modelContext.fetch(descriptor) else { return 0 }
        
        // Find the best weight before this date
        return results.compactMap { $0.maxWeight }.max() ?? 0
    }
    
    private func getEndurancePRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Get real endurance PRs from CardioSessions
        let cardioPRs = getEndurancePRsFromSessions(limit: limit)
        prs.append(contentsOf: cardioPRs)
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getEndurancePRsFromSessions(limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Get cardio sessions from last 6 months for PR analysis
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let cardioSessions = getCardioSessionsInDateRange(start: sixMonthsAgo, end: Date())
        
        // Group by exercise type for PR detection
        let exerciseGroups = Dictionary(grouping: cardioSessions) { session in
            // Use originalWorkout's name or a default based on session type
            return session.originalWorkout?.nameEN ?? "Running"
        }
        
        for (exerciseType, sessions) in exerciseGroups {
            // Find best distance PR
            if let bestDistanceSession = sessions.max(by: { $0.totalDistance < $1.totalDistance }),
               bestDistanceSession.totalDistance > 0 {
                
                let previousBest = getCardioDistancePreviousBest(
                    exerciseType: exerciseType,
                    before: bestDistanceSession.startDate,
                    sessions: sessions
                )
                let improvement = previousBest > 0 ? 
                    ((bestDistanceSession.totalDistance - previousBest) / previousBest) * 100.0 : nil
                
                prs.append(DetailedPRRecord(
                    exerciseName: "\(exerciseType.capitalized) Distance",
                    value: bestDistanceSession.totalDistance / 1000.0, // Convert to km
                    unit: "km",
                    date: bestDistanceSession.startDate,
                    category: .endurance,
                    improvement: improvement,
                    isRecent: Calendar.current.isDate(bestDistanceSession.startDate, equalTo: Date(), toGranularity: .weekOfYear),
                    sessionId: bestDistanceSession.id
                ))
            }
            
            // Find best pace PR (for distance > 1km)
            let longSessions = sessions.filter { $0.totalDistance > 1000 }
            if let bestPaceSession = longSessions.min(by: { 
                (Double($0.totalDuration) / $0.totalDistance) < (Double($1.totalDuration) / $1.totalDistance)
            }), bestPaceSession.totalDistance > 0 {
                
                let paceMinPerKm = (Double(bestPaceSession.totalDuration) / 60.0) / (bestPaceSession.totalDistance / 1000.0)
                let previousBestPace = getCardioPacePreviousBest(
                    exerciseType: exerciseType,
                    before: bestPaceSession.startDate,
                    sessions: longSessions
                )
                let improvement = previousBestPace > 0 ? 
                    ((previousBestPace - paceMinPerKm) / previousBestPace) * 100.0 : nil
                
                prs.append(DetailedPRRecord(
                    exerciseName: "\(exerciseType.capitalized) Best Pace",
                    value: paceMinPerKm,
                    unit: "min/km",
                    date: bestPaceSession.startDate,
                    category: .endurance,
                    improvement: improvement,
                    isRecent: Calendar.current.isDate(bestPaceSession.startDate, equalTo: Date(), toGranularity: .weekOfYear),
                    sessionId: bestPaceSession.id
                ))
            }
        }
        
        return Array(prs.prefix(limit))
    }
    
    private func getCardioDistancePreviousBest(exerciseType: String, before date: Date, sessions: [CardioSession]) -> Double {
        return sessions
            .filter { $0.startDate < date }
            .map { $0.totalDistance }
            .max() ?? 0
    }
    
    private func getCardioPacePreviousBest(exerciseType: String, before date: Date, sessions: [CardioSession]) -> Double {
        let previousSessions = sessions.filter { 
            $0.startDate < date && $0.totalDistance > 1000 
        }
        
        guard let bestSession = previousSessions.min(by: { 
            (Double($0.totalDuration) / $0.totalDistance) < (Double($1.totalDuration) / $1.totalDistance)
        }) else { return 0 }
        
        return (Double(bestSession.totalDuration) / 60.0) / (bestSession.totalDistance / 1000.0)
    }
    
    private func getVolumePRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Get real volume PRs from actual lift sessions
        let realVolumePRs = getRealVolumePRsFromSessions(limit: limit)
        prs.append(contentsOf: realVolumePRs)
        
        // If no session data available, use user profile data as fallback
        if prs.isEmpty {
            let fallbackPRs = getFallbackVolumePRs(for: user, limit: limit)
            prs.append(contentsOf: fallbackPRs)
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getRealVolumePRsFromSessions(limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Get lift sessions from last 6 months for volume analysis
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let liftSessions = getLiftSessionsInDateRange(start: sixMonthsAgo, end: Date())
        
        guard !liftSessions.isEmpty else { return prs }
        
        // Find PR for most sets in a single workout
        if let mostSetsSession = liftSessions.max(by: { $0.totalSets < $1.totalSets }) {
            let sessionDate = mostSetsSession.endDate ?? mostSetsSession.startDate
            let previousBestSets = getPreviousBestSets(before: sessionDate, sessions: liftSessions)
            let improvement = previousBestSets > 0 ? 
                ((Double(mostSetsSession.totalSets) - Double(previousBestSets)) / Double(previousBestSets)) * 100.0 : nil
            
            prs.append(DetailedPRRecord(
                exerciseName: "Most Sets in Workout",
                value: Double(mostSetsSession.totalSets),
                unit: "sets",
                date: sessionDate,
                category: .volume,
                improvement: improvement,
                isRecent: Calendar.current.isDate(sessionDate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: mostSetsSession.id
            ))
        }
        
        // Find PR for longest workout duration
        if let longestSession = liftSessions.max(by: { $0.duration < $1.duration }) {
            let sessionDate = longestSession.endDate ?? longestSession.startDate
            let previousBestDuration = getPreviousBestDuration(before: sessionDate, sessions: liftSessions)
            let improvement = previousBestDuration > 0 ? 
                ((longestSession.duration - previousBestDuration) / previousBestDuration) * 100.0 : nil
            
            prs.append(DetailedPRRecord(
                exerciseName: "Longest Workout",
                value: longestSession.duration / 60.0, // Convert to minutes
                unit: "min",
                date: sessionDate,
                category: .volume,
                improvement: improvement,
                isRecent: Calendar.current.isDate(sessionDate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: longestSession.id
            ))
        }
        
        // Find PR for highest weekly volume
        let weeklyVolumes = calculateWeeklyVolumes(from: liftSessions)
        if let bestWeek = weeklyVolumes.max(by: { $0.volume < $1.volume }) {
            let previousBestVolume = getPreviousBestWeeklyVolume(before: bestWeek.weekStart, weeklyVolumes: weeklyVolumes)
            let improvement = previousBestVolume > 0 ? 
                ((bestWeek.volume - previousBestVolume) / previousBestVolume) * 100.0 : nil
            
            prs.append(DetailedPRRecord(
                exerciseName: "Weekly Volume Record",
                value: bestWeek.volume,
                unit: "kg",
                date: bestWeek.weekEnd,
                category: .volume,
                improvement: improvement,
                isRecent: Calendar.current.isDate(bestWeek.weekEnd, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return prs
    }
    
    private func getFallbackVolumePRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        
        // Only create fallback PRs if user has actual data (no improvement calculation though)
        if user.maxSetsInSingleWorkout > 0, let lastUpdate = user.oneRMLastUpdated {
            prs.append(DetailedPRRecord(
                exerciseName: "Most Sets in Workout",
                value: Double(user.maxSetsInSingleWorkout),
                unit: "sets",
                date: lastUpdate,
                category: .volume,
                improvement: nil, // No historical comparison available
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        if user.longestWorkoutDuration > 0, let lastUpdate = user.oneRMLastUpdated {
            prs.append(DetailedPRRecord(
                exerciseName: "Longest Workout",
                value: user.longestWorkoutDuration / 60.0,
                unit: "min",
                date: lastUpdate,
                category: .volume,
                improvement: nil,
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return Array(prs.prefix(limit))
    }
    
    // MARK: - Volume Helper Methods
    
    private func getPreviousBestSets(before date: Date, sessions: [LiftSession]) -> Int {
        let previousSessions = sessions.filter { ($0.endDate ?? $0.startDate) < date }
        return previousSessions.map { $0.totalSets }.max() ?? 0
    }
    
    private func getPreviousBestDuration(before date: Date, sessions: [LiftSession]) -> TimeInterval {
        let previousSessions = sessions.filter { ($0.endDate ?? $0.startDate) < date }
        return previousSessions.map { $0.duration }.max() ?? 0
    }
    
    private func calculateWeeklyVolumes(from sessions: [LiftSession]) -> [(weekStart: Date, weekEnd: Date, volume: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            let sessionDate = session.endDate ?? session.startDate
            return calendar.dateInterval(of: .weekOfYear, for: sessionDate)?.start ?? sessionDate
        }
        
        return grouped.compactMap { (weekStart, sessions) in
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return nil }
            let totalVolume = sessions.reduce(0.0) { sum, session in
                sum + session.totalVolume
            }
            return (weekStart: weekStart, weekEnd: weekEnd, volume: totalVolume)
        }
    }
    
    private func getPreviousBestWeeklyVolume(before date: Date, weeklyVolumes: [(weekStart: Date, weekEnd: Date, volume: Double)]) -> Double {
        let previousWeeks = weeklyVolumes.filter { $0.weekStart < date }
        return previousWeeks.map { $0.volume }.max() ?? 0
    }
    
    // MARK: - Consistency Analytics Methods
    
    struct ConsistencyData {
        let overallRate: Double // 0.0 - 1.0
        let currentStreak: Int // days
        let weeklyConsistency: Double // 0.0 - 1.0
        let monthlyGoalProgress: Double // 0.0 - 1.0
        let perfectWeeks: Int // weeks with 100% target completion
        let averageSessionsPerWeek: Double
    }
    
    func getConsistencyData(for user: User) -> ConsistencyData {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate last 12 weeks
        var weeklyRates: [Double] = []
        var perfectWeekCount = 0
        var totalSessions = 0
        
        for weekOffset in 0..<12 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            let sessions = getSessionsInWeek(start: weekStart, end: weekEnd)
            let target = user.weeklySessionGoal > 0 ? user.weeklySessionGoal : 4
            let rate = min(1.0, Double(sessions) / Double(target))
            
            weeklyRates.append(rate)
            totalSessions += sessions
            
            if sessions >= target {
                perfectWeekCount += 1
            }
        }
        
        let overallRate = weeklyRates.reduce(0, +) / Double(weeklyRates.count)
        let avgSessions = Double(totalSessions) / 12.0
        
        // Current month progress
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthSessions = getSessionsInMonth(start: monthStart)
        let monthlyTarget = user.monthlySessionGoal > 0 ? user.monthlySessionGoal : 16
        let monthlyProgress = min(1.0, Double(monthSessions) / Double(monthlyTarget))
        
        return ConsistencyData(
            overallRate: overallRate,
            currentStreak: user.currentWorkoutStreak,
            weeklyConsistency: weeklyRates.first ?? 0.0, // This week
            monthlyGoalProgress: monthlyProgress,
            perfectWeeks: perfectWeekCount,
            averageSessionsPerWeek: avgSessions
        )
    }
    
    private func getSessionsInWeek(start: Date, end: Date) -> Int {
        let liftCount = getLiftSessionsInDateRange(start: start, end: end).count
        let cardioCount = getCardioSessionsInDateRange(start: start, end: end).count
        return liftCount + cardioCount
    }
    
    private func getSessionsInMonth(start: Date) -> Int {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return getSessionsInWeek(start: start, end: end)
    }
}

// MARK: - Supporting Data Structures
struct DailyActivity {
    let date: Date
    let dayName: String
    let liftSessions: Int
    let cardioSessions: Int
    let totalSessions: Int
}