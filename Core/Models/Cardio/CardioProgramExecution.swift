import Foundation
import SwiftData

// MARK: - Cardio Program Execution Model
@Model
final class CardioProgramExecution {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var currentWeek: Int
    var currentDay: Int
    var isCompleted: Bool
    var isPaused: Bool
    var notes: String?
    
    // Cardio-specific tracking
    var totalDistanceCovered: Double // in meters
    var averagePaceAchieved: Double? // in minutes per km
    var personalBests: [String] // JSON array of personal bests
    
    // Relationships
    var program: CardioProgram
    var user: User?
    var completedSessions: [CompletedCardioSession]
    
    init(
        program: CardioProgram,
        user: User? = nil
    ) {
        self.id = UUID()
        self.startDate = Date()
        self.endDate = nil
        self.currentWeek = 1
        self.currentDay = 1
        self.isCompleted = false
        self.isPaused = false
        self.notes = nil
        self.totalDistanceCovered = 0
        self.averagePaceAchieved = nil
        self.personalBests = []
        self.program = program
        self.user = user
        self.completedSessions = []
    }
}

// MARK: - Computed Properties
extension CardioProgramExecution {
    var duration: Int? {
        guard let endDate = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day
    }
    
    var currentDayOfWeek: Int {
        let totalDays = ((currentWeek - 1) * program.daysPerWeek) + currentDay
        return ((totalDays - 1) % program.daysPerWeek) + 1
    }
    
    var progressPercentage: Double {
        let totalSessions = program.weeks * program.daysPerWeek
        let completedSessionsCount = completedSessions.filter { !$0.isSkipped }.count
        return Double(completedSessionsCount) / Double(totalSessions)
    }
    
    var remainingWeeks: Int {
        max(0, program.weeks - currentWeek + 1)
    }
    
    var currentWorkout: CardioWorkout? {
        // For Couch to 5K: Different workouts for each week
        let workoutIndex = getWorkoutIndex()
        guard workoutIndex < program.workouts.count else { return nil }
        return program.workouts[workoutIndex]
    }
    
    private func getWorkoutIndex() -> Int {
        // For Couch to 5K, each week has the same workout repeated 3 times
        // Week 1: Workout 0, Week 2: Workout 1, etc.
        return min(currentWeek - 1, program.workouts.count - 1)
    }
    
    var isLastWeek: Bool {
        currentWeek == program.weeks
    }
    
    var formattedProgress: String {
        "Week \(currentWeek) of \(program.weeks)"
    }
    
    var completedSessionsThisWeek: Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        
        return completedSessions.filter { session in
            session.completedAt >= startOfWeek && 
            session.weekNumber == currentWeek &&
            !session.isSkipped
        }.count
    }
    
    var currentStreak: Int {
        let sortedSessions = completedSessions
            .filter { !$0.isSkipped }
            .sorted { $0.completedAt > $1.completedAt }
        
        var streak = 0
        for session in sortedSessions {
            let daysSince = Calendar.current.dateComponents([.day], from: session.completedAt, to: Date()).day ?? 0
            if daysSince <= 7 { // Son 7 günde
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    var formattedTotalDistance: String {
        if totalDistanceCovered >= 1000 {
            return String(format: "%.1f km", totalDistanceCovered / 1000)
        } else {
            return String(format: "%.0f m", totalDistanceCovered)
        }
    }
    
    var formattedAveragePace: String? {
        guard let pace = averagePaceAchieved else { return nil }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// MARK: - Methods
extension CardioProgramExecution {
    func completeCurrentSession(distance: Double, duration: TimeInterval, averagePace: Double?) {
        guard let workout = currentWorkout else { return }
        
        let completedSession = CompletedCardioSession(
            workout: workout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self,
            distance: distance,
            duration: duration,
            averagePace: averagePace
        )
        
        completedSessions.append(completedSession)
        
        // Update total distance
        totalDistanceCovered += distance
        
        // Update average pace
        updateAveragePace(newPace: averagePace)
        
        // Check for personal bests
        checkForPersonalBests(distance: distance, duration: duration, averagePace: averagePace)
        
        // Advance to next session
        advanceToNextSession()
    }
    
    private func updateAveragePace(newPace: Double?) {
        guard let newPace = newPace else { return }
        
        let completedRuns = completedSessions.filter { !$0.isSkipped && $0.averagePace != nil }
        if completedRuns.isEmpty {
            averagePaceAchieved = newPace
        } else {
            let totalPace = completedRuns.compactMap { $0.averagePace }.reduce(0, +)
            averagePaceAchieved = totalPace / Double(completedRuns.count)
        }
    }
    
    private func checkForPersonalBests(distance: Double, duration: TimeInterval, averagePace: Double?) {
        var newPBs: [String] = []
        
        // Distance PB
        let previousMaxDistance = completedSessions.compactMap { $0.distance }.max() ?? 0
        if distance > previousMaxDistance {
            newPBs.append("Longest Distance: \(String(format: "%.1f km", distance / 1000))")
        }
        
        // Best pace PB (lower is better)
        if let averagePace = averagePace {
            let previousBestPace = completedSessions.compactMap { $0.averagePace }.min()
            if previousBestPace == nil || averagePace < previousBestPace! {
                let minutes = Int(averagePace)
                let seconds = Int((averagePace - Double(minutes)) * 60)
                newPBs.append("Best Pace: \(minutes):\(String(format: "%02d", seconds)) /km")
            }
        }
        
        // Duration PB
        let previousMaxDuration = completedSessions.compactMap { $0.duration }.max() ?? 0
        if duration > previousMaxDuration {
            let minutes = Int(duration / 60)
            newPBs.append("Longest Run: \(minutes) minutes")
        }
        
        personalBests.append(contentsOf: newPBs)
    }
    
    private func advanceToNextSession() {
        currentDay += 1
        
        if currentDay > program.daysPerWeek {
            currentDay = 1
            currentWeek += 1
            
            // Check if program is completed
            if currentWeek > program.weeks {
                completeProgram()
            }
        }
    }
    
    func completeProgram() {
        endDate = Date()
        isCompleted = true
    }
    
    func pauseProgram() {
        isPaused = true
    }
    
    func resumeProgram() {
        isPaused = false
    }
    
    func resetProgram() {
        currentWeek = 1
        currentDay = 1
        isCompleted = false
        isPaused = false
        endDate = nil
        totalDistanceCovered = 0
        averagePaceAchieved = nil
        personalBests.removeAll()
        completedSessions.removeAll()
    }
    
    func skipCurrentSession(reason: String? = nil) {
        let skippedSession = CompletedCardioSession(
            workout: currentWorkout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self,
            isSkipped: true,
            skipReason: reason
        )
        
        completedSessions.append(skippedSession)
        advanceToNextSession()
    }
}

// MARK: - Completed Cardio Session Model
@Model
final class CompletedCardioSession {
    var id: UUID
    var completedAt: Date
    var weekNumber: Int
    var dayNumber: Int
    var isSkipped: Bool
    var skipReason: String?
    var duration: TimeInterval?
    var distance: Double?
    var averagePace: Double? // minutes per km
    var maxHeartRate: Int?
    var averageHeartRate: Int?
    var caloriesBurned: Int?
    var notes: String?
    
    // Relationships
    var workout: CardioWorkout?
    var execution: CardioProgramExecution?
    var cardioSession: CardioSession? // If this was executed as a cardio session
    
    init(
        workout: CardioWorkout?,
        weekNumber: Int,
        dayNumber: Int,
        execution: CardioProgramExecution? = nil,
        distance: Double? = nil,
        duration: TimeInterval? = nil,
        averagePace: Double? = nil,
        isSkipped: Bool = false,
        skipReason: String? = nil
    ) {
        self.id = UUID()
        self.completedAt = Date()
        self.weekNumber = weekNumber
        self.dayNumber = dayNumber
        self.isSkipped = isSkipped
        self.skipReason = skipReason
        self.duration = duration
        self.distance = distance
        self.averagePace = averagePace
        self.maxHeartRate = nil
        self.averageHeartRate = nil
        self.caloriesBurned = nil
        self.notes = nil
        self.workout = workout
        self.execution = execution
        self.cardioSession = nil
    }
}

// MARK: - Computed Properties
extension CompletedCardioSession {
    var workoutName: String {
        workout?.name ?? "Unknown Workout"
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedPace: String? {
        guard let pace = averagePace else { return nil }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    var formattedDate: String {
        completedAt.formatted(date: .abbreviated, time: .shortened)
    }
}