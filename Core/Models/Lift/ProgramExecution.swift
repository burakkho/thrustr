import Foundation
import SwiftData

// MARK: - Program Execution Model
@Model
final class ProgramExecution {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var currentWeek: Int
    var currentDay: Int
    var isCompleted: Bool
    var isPaused: Bool
    var notes: String?
    
    // Relationships
    var program: LiftProgram
    var user: User?
    var completedWorkouts: [CompletedWorkout]
    
    init(
        program: LiftProgram,
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
        self.program = program
        self.user = user
        self.completedWorkouts = []
    }
}

// MARK: - Computed Properties
extension ProgramExecution {
    var duration: Int? {
        guard let endDate = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day
    }
    
    var currentDayOfWeek: Int {
        let totalDays = ((currentWeek - 1) * program.daysPerWeek) + currentDay
        return ((totalDays - 1) % program.daysPerWeek) + 1
    }
    
    var progressPercentage: Double {
        let totalWorkouts = program.weeks * program.daysPerWeek
        let completedWorkoutsCount = completedWorkouts.count
        return Double(completedWorkoutsCount) / Double(totalWorkouts)
    }
    
    var remainingWeeks: Int {
        max(0, program.weeks - currentWeek + 1)
    }
    
    var currentWorkout: LiftWorkout? {
        // For StrongLifts: A-B-A-B pattern
        // Week 1: A-B-A, Week 2: B-A-B, Week 3: A-B-A, etc.
        let workoutIndex = getWorkoutIndex()
        guard workoutIndex < program.workouts.count else { return nil }
        return program.workouts[workoutIndex]
    }
    
    private func getWorkoutIndex() -> Int {
        // Calculate which workout (A or B) based on week and day
        let totalWorkoutsSoFar = ((currentWeek - 1) * program.daysPerWeek) + (currentDay - 1)
        return totalWorkoutsSoFar % program.workouts.count
    }
    
    var isLastWeek: Bool {
        currentWeek == program.weeks
    }
    
    var formattedProgress: String {
        "Week \(currentWeek) of \(program.weeks)"
    }
    
    var completedWorkoutsThisWeek: Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        
        return completedWorkouts.filter { workout in
            workout.completedAt >= startOfWeek && 
            workout.weekNumber == currentWeek &&
            !workout.isSkipped
        }.count
    }
    
    var currentStreak: Int {
        let sortedWorkouts = completedWorkouts
            .filter { !$0.isSkipped }
            .sorted { $0.completedAt > $1.completedAt }
        
        var streak = 0
        for workout in sortedWorkouts {
            let daysSince = Calendar.current.dateComponents([.day], from: workout.completedAt, to: Date()).day ?? 0
            if daysSince <= 7 { // Son 7 günde
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Methods
extension ProgramExecution {
    func completeCurrentWorkout() {
        guard let workout = currentWorkout else { return }
        
        let completedWorkout = CompletedWorkout(
            workout: workout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self
        )
        
        completedWorkouts.append(completedWorkout)
        
        // Advance to next workout
        advanceToNextWorkout()
    }
    
    private func advanceToNextWorkout() {
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
        
        // Log program completion activity
        let weekCount = currentWeek - 1
        let totalCompletedWorkouts = completedWorkouts.filter { !$0.isSkipped }.count
        
        Task { @MainActor in
            ActivityLoggerService.shared.logProgramCompleted(
                programName: program.localizedName,
                totalWorkouts: totalCompletedWorkouts,
                weekCount: weekCount,
                user: user
            )
        }
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
        completedWorkouts.removeAll()
    }
    
    func skipCurrentWorkout(reason: String? = nil) {
        let skippedWorkout = CompletedWorkout(
            workout: currentWorkout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self,
            isSkipped: true,
            skipReason: reason
        )
        
        completedWorkouts.append(skippedWorkout)
        advanceToNextWorkout()
    }
}

// MARK: - Completed Workout Model
@Model
final class CompletedWorkout {
    var id: UUID
    var completedAt: Date
    var weekNumber: Int
    var dayNumber: Int
    var isSkipped: Bool
    var skipReason: String?
    var duration: Int? // in minutes
    var notes: String?
    
    // Relationships
    var workout: LiftWorkout?
    var execution: ProgramExecution?
    var liftSession: LiftSession? // If this was executed as a lift session
    
    init(
        workout: LiftWorkout?,
        weekNumber: Int,
        dayNumber: Int,
        execution: ProgramExecution? = nil,
        isSkipped: Bool = false,
        skipReason: String? = nil
    ) {
        self.id = UUID()
        self.completedAt = Date()
        self.weekNumber = weekNumber
        self.dayNumber = dayNumber
        self.isSkipped = isSkipped
        self.skipReason = skipReason
        self.duration = nil
        self.notes = nil
        self.workout = workout
        self.execution = execution
        self.liftSession = nil
    }
}

// MARK: - Computed Properties
extension CompletedWorkout {
    var workoutName: String {
        workout?.localizedName ?? "Unknown Workout"
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDate: String {
        completedAt.formatted(date: .abbreviated, time: .shortened)
    }
}