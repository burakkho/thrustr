import Foundation
import SwiftData

// MARK: - Program Execution Model
@Model
final class ProgramExecution {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var currentWeek: Int = 1
    var currentDay: Int = 1
    var isCompleted: Bool = false
    var isPaused: Bool = false
    var notes: String?
    
    // Relationships
    var program: LiftProgram?
    var user: User?
    @Relationship(deleteRule: .cascade, inverse: \CompletedWorkout.execution) var completedWorkouts: [CompletedWorkout]?
    
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
        guard let program = program else { return 1 }
        let totalDays = ((currentWeek - 1) * program.daysPerWeek) + currentDay
        return ((totalDays - 1) % program.daysPerWeek) + 1
    }
    
    var progressPercentage: Double {
        guard let program = program else { return 0.0 }
        let totalWorkouts = program.weeks * program.daysPerWeek
        let completedWorkoutsCount = (completedWorkouts ?? []).count
        return Double(completedWorkoutsCount) / Double(totalWorkouts)
    }
    
    var remainingWeeks: Int {
        guard let program = program else { return 0 }
        return max(0, program.weeks - currentWeek + 1)
    }
    
    var currentWorkout: LiftWorkout? {
        // For StrongLifts: A-B-A-B pattern
        // Week 1: A-B-A, Week 2: B-A-B, Week 3: A-B-A, etc.
        guard let program = program, let workouts = program.workouts else { return nil }
        let workoutIndex = getWorkoutIndex()
        guard workoutIndex < workouts.count else { return nil }
        return workouts[workoutIndex]
    }
    
    private func getWorkoutIndex() -> Int {
        // Calculate which workout (A or B) based on week and day
        guard let program = program, let workouts = program.workouts else { return 0 }
        let totalWorkoutsSoFar = ((currentWeek - 1) * program.daysPerWeek) + (currentDay - 1)
        return totalWorkoutsSoFar % workouts.count
    }
    
    var isLastWeek: Bool {
        guard let program = program else { return false }
        return currentWeek == program.weeks
    }
    
    var formattedProgress: String {
        guard let program = program else { return "Week \(currentWeek)" }
        return "Week \(currentWeek) of \(program.weeks)"
    }
    
    var completedWorkoutsThisWeek: Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        
        return (completedWorkouts ?? []).filter { workout in
            workout.completedAt >= startOfWeek && 
            workout.weekNumber == currentWeek &&
            !workout.isSkipped
        }.count
    }
    
    var currentStreak: Int {
        let sortedWorkouts = (completedWorkouts ?? [])
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
    @MainActor
    func completeCurrentWorkout() {
        guard let workout = currentWorkout else { return }
        
        let completedWorkout = CompletedWorkout(
            workout: workout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self
        )
        
        if completedWorkouts == nil {
            completedWorkouts = []
        }
        completedWorkouts?.append(completedWorkout)
        
        // Advance to next workout
        advanceToNextWorkout()
    }
    
    @MainActor
    private func advanceToNextWorkout() {
        guard let program = program else { return }
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
    
    @MainActor
    func completeProgram() {
        endDate = Date()
        isCompleted = true
        
        // Log program completion activity
        let _ = (completedWorkouts ?? []).filter { !$0.isSkipped }.count
        let programName = program?.localizedName ?? "Unknown Program"

        // Log directly in same SwiftData context - no async boundary
        ActivityLoggerService.shared.logWorkoutCompleted(
            workoutType: programName,
            duration: 0, // Program completion
            user: user
        )
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
        completedWorkouts?.removeAll()
    }
    
    @MainActor
    func skipCurrentWorkout(reason: String? = nil) {
        let skippedWorkout = CompletedWorkout(
            workout: currentWorkout,
            weekNumber: currentWeek,
            dayNumber: currentDay,
            execution: self,
            isSkipped: true,
            skipReason: reason
        )
        
        if completedWorkouts == nil {
            completedWorkouts = []
        }
        completedWorkouts?.append(skippedWorkout)
        advanceToNextWorkout()
    }
}

// MARK: - Completed Workout Model
@Model
final class CompletedWorkout {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var weekNumber: Int = 1
    var dayNumber: Int = 1
    var isSkipped: Bool = false
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