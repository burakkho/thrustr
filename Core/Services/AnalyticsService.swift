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
}

// MARK: - Supporting Data Structures
struct DailyActivity {
    let date: Date
    let dayName: String
    let liftSessions: Int
    let cardioSessions: Int
    let totalSessions: Int
}