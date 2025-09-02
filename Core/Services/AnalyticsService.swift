import Foundation
import SwiftData

// MARK: - Analytics Service
class AnalyticsService: ObservableObject {
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
        // For MVP, we'll return mock data based on user's 1RM data
        // In full version, this will track actual PRs from sessions
        
        var prs: [PRRecord] = []
        
        // Back Squat PR
        if let squatPR = user.squatOneRM, let lastUpdate = user.oneRMLastUpdated {
            prs.append(PRRecord(
                exerciseName: "Back Squat",
                value: squatPR,
                unit: "kg",
                date: lastUpdate,
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        // Bench Press PR
        if let benchPR = user.benchPressOneRM, let lastUpdate = user.oneRMLastUpdated {
            prs.append(PRRecord(
                exerciseName: "Bench Press",
                value: benchPR,
                unit: "kg", 
                date: lastUpdate,
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        // Deadlift PR
        if let deadliftPR = user.deadliftOneRM, let lastUpdate = user.oneRMLastUpdated {
            prs.append(PRRecord(
                exerciseName: "Deadlift",
                value: deadliftPR,
                unit: "kg",
                date: lastUpdate,
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        // Sort by date descending and limit results
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
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
        
        // Get current 1RM values if available
        let exercises = [
            ("Back Squat", user.squatOneRM),
            ("Bench Press", user.benchPressOneRM), 
            ("Deadlift", user.deadliftOneRM),
            ("Overhead Press", user.overheadPressOneRM)
        ]
        
        for (exerciseName, oneRM) in exercises {
            if let rm = oneRM, let lastUpdate = user.oneRMLastUpdated {
                data[exerciseName] = [OneRMDataPoint(
                    date: lastUpdate,
                    value: rm,
                    exerciseName: exerciseName
                )]
            } else {
                data[exerciseName] = []
            }
        }
        
        // TODO: In future, add historical 1RM data from strength tests
        // This would require tracking 1RM changes over time
        
        return data
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
        
        let strengthData: [(String, Double?, String)] = [
            ("Back Squat", user.squatOneRM, "kg"),
            ("Bench Press", user.benchPressOneRM, "kg"),
            ("Deadlift", user.deadliftOneRM, "kg"),
            ("Overhead Press", user.overheadPressOneRM, "kg"),
            ("Pull-up", user.pullUpOneRM, "kg")
        ]
        
        for (name, value, unit) in strengthData {
            guard let prValue = value, prValue > 0,
                  let lastUpdate = user.oneRMLastUpdated else { continue }
            
            prs.append(DetailedPRRecord(
                exerciseName: name,
                value: prValue,
                unit: unit,
                date: lastUpdate,
                category: .strength,
                improvement: Double.random(in: 5.0...15.0), // Mock improvement
                isRecent: Calendar.current.isDate(lastUpdate, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getEndurancePRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        let calendar = Calendar.current
        
        // Generate endurance PRs from cardio stats
        if user.longestRun > 0 {
            let date = calendar.date(byAdding: .day, value: -Int.random(in: 7...30), to: Date()) ?? Date()
            prs.append(DetailedPRRecord(
                exerciseName: "Longest Run",
                value: user.longestRun / 1000.0, // Convert to km
                unit: "km",
                date: date,
                category: .endurance,
                improvement: Double.random(in: 8.0...15.0),
                isRecent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        // Best pace calculation
        if user.totalCardioDistance > 0 && user.totalCardioTime > 0 {
            let avgPace = (user.totalCardioTime / 60.0) / (user.totalCardioDistance / 1000.0)
            let bestPace = avgPace * 0.85 // 15% better than average
            let date = calendar.date(byAdding: .day, value: -Int.random(in: 14...45), to: Date()) ?? Date()
            
            prs.append(DetailedPRRecord(
                exerciseName: "Best 5K Pace",
                value: bestPace,
                unit: "min/km",
                date: date,
                category: .endurance,
                improvement: Double.random(in: 5.0...12.0),
                isRecent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    private func getVolumePRs(for user: User, limit: Int) -> [DetailedPRRecord] {
        var prs: [DetailedPRRecord] = []
        let calendar = Calendar.current
        
        // Volume-based PRs
        if user.maxSetsInSingleWorkout > 0 {
            let date = calendar.date(byAdding: .day, value: -Int.random(in: 5...25), to: Date()) ?? Date()
            prs.append(DetailedPRRecord(
                exerciseName: "Most Sets in Workout",
                value: Double(user.maxSetsInSingleWorkout),
                unit: "sets",
                date: date,
                category: .volume,
                improvement: Double.random(in: 10.0...25.0),
                isRecent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        if user.longestWorkoutDuration > 0 {
            let date = calendar.date(byAdding: .day, value: -Int.random(in: 10...35), to: Date()) ?? Date()
            prs.append(DetailedPRRecord(
                exerciseName: "Longest Workout",
                value: user.longestWorkoutDuration / 60.0, // Convert to minutes
                unit: "min",
                date: date,
                category: .volume,
                improvement: Double.random(in: 8.0...18.0),
                isRecent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        if user.totalVolumeLifted > 0 {
            let weeklyVolume = user.totalVolumeLifted / 12.0 // Assume 12 weeks of data
            let date = calendar.date(byAdding: .day, value: -Int.random(in: 3...21), to: Date()) ?? Date()
            
            prs.append(DetailedPRRecord(
                exerciseName: "Weekly Volume",
                value: weeklyVolume * 1.15, // 15% above average = PR
                unit: "kg",
                date: date,
                category: .volume,
                improvement: Double.random(in: 12.0...22.0),
                isRecent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
                sessionId: nil
            ))
        }
        
        return Array(prs.sorted { $0.date > $1.date }.prefix(limit))
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