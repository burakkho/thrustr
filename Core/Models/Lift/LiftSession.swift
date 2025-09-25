import Foundation
import SwiftData

// MARK: - Lift Session Model
@Model
final class LiftSession: @unchecked Sendable {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var isCompleted: Bool = false
    var notes: String?
    var totalVolume: Double = 0.0
    var totalSets: Int = 0
    var totalReps: Int = 0
    var rating: Int? // 1-5 workout rating
    var feeling: Int? // 1-5 feeling scale
    
    // Relationships
    var workout: LiftWorkout?
    var user: User?
    @Relationship(deleteRule: .cascade) var exerciseResults: [LiftExerciseResult]?
    @Relationship(inverse: \CompletedWorkout.liftSession) var completedWorkout: CompletedWorkout?
    
    init(
        workout: LiftWorkout,
        user: User? = nil,
        programExecution: ProgramExecution? = nil
    ) {
        self.id = UUID()
        self.startDate = Date()
        self.endDate = nil
        self.isCompleted = false
        self.notes = nil
        self.totalVolume = 0
        self.totalSets = 0
        self.totalReps = 0
        self.rating = nil
        self.feeling = nil
        self.workout = workout
        self.user = user
        self.exerciseResults = []
        
        // Initialize exercise results from workout template with smart defaults
        initializeExerciseResults(user: user, programExecution: programExecution)
    }
}

// MARK: - Computed Properties
extension LiftSession {
    /// Display date for UI consistency
    var displayDate: Date {
        return endDate ?? startDate
    }

    var duration: TimeInterval {
        if let endDate = endDate {
            return endDate.timeIntervalSince(startDate)
        }
        return Date().timeIntervalSince(startDate)
    }
    
    var formattedDuration: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var completionPercentage: Double {
        guard let workoutExercises = workout?.exercises else { return 0 }
        let totalTargetSets = workoutExercises.reduce(0) { $0 + $1.targetSets }
        guard totalTargetSets > 0 else { return 0 }
        
        guard let results = exerciseResults else { return 0 }
        let completedSets = results.reduce(0) { total, result in
            total + result.sets.filter { $0.isCompleted }.count
        }
        
        return Double(completedSets) / Double(totalTargetSets)
    }
    
    var prsHit: [String] {
        var prs: [String] = []
        
        guard let results = exerciseResults else { return prs }
        for result in results {
            if result.isPersonalRecord {
                prs.append(result.exercise?.exerciseName ?? "")
            }
        }
        
        return prs
    }
    
    var averageRPE: Double? {
        guard let results = exerciseResults else { return nil }
        let rpes = results.flatMap { result in
            result.sets.compactMap { $0.rpe }
        }
        
        guard !rpes.isEmpty else { return nil }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }
    
    var exercises: [LiftExercise] {
        workout?.exercises ?? []
    }
}

// MARK: - Methods
extension LiftSession {
    private func initializeExerciseResults(user: User?, programExecution: ProgramExecution?) {
        guard let workoutExercises = workout?.exercises else { return }
        
        for exercise in workoutExercises {
            let result = LiftExerciseResult(
                exercise: exercise,
                session: self
            )
            
            // Pre-populate sets with smart defaults if user data is available
            if let user = user {
                populateDefaultSets(for: result, user: user, programExecution: programExecution)
            }
            
            exerciseResults?.append(result)
        }
    }
    
    private func populateDefaultSets(for result: LiftExerciseResult, user: User, programExecution: ProgramExecution?) {
        guard let exercise = result.exercise else { return }
        let workingWeight = exercise.calculateCurrentWorkingWeight(user: user, programExecution: programExecution)
        
        // Add only working sets with program targets (no warm-up sets)
        for i in 0..<exercise.targetSets {
            let workingSet = SetData(
                setNumber: i + 1,
                weight: workingWeight,
                reps: exercise.targetReps,
                isWarmup: false,
                isCompleted: false
            )
            result.sets.append(workingSet)
        }
    }
    
    func complete() {
        endDate = Date()
        isCompleted = true
        calculateTotals()
    }
    
    func calculateTotals() {
        totalVolume = 0
        totalSets = 0
        totalReps = 0
        
        guard let results = exerciseResults else { return }
        for result in results {
            for set in result.sets where set.isCompleted {
                totalSets += 1
                totalReps += set.reps
                if let weight = set.weight {
                    totalVolume += weight * Double(set.reps)
                }
            }
        }
    }
    
    func addExerciseResult(_ result: LiftExerciseResult) {
        if exerciseResults == nil {
            exerciseResults = []
        }
        exerciseResults?.append(result)
        result.session = self
    }
    
    func removeExerciseResult(_ result: LiftExerciseResult) {
        exerciseResults?.removeAll { $0.id == result.id }
        calculateTotals()
    }
    
    func moveExercise(from sourceIndices: IndexSet, to destination: Int) {
        guard var results = exerciseResults else { return }
        // Safe move operation with bounds checking
        guard destination >= 0 && destination <= results.count else { return }
        guard !sourceIndices.isEmpty else { return }
        
        results.move(fromOffsets: sourceIndices, toOffset: destination)
        exerciseResults = results
        
        // Update order indices in underlying workout exercises
        for (index, result) in results.enumerated() {
            result.exercise?.orderIndex = index
        }
        
        // Update order indices in workout exercises array too
        guard let workoutExercises = workout?.exercises else { return }
        for (index, exercise) in workoutExercises.enumerated() {
            if let matchingResult = results.first(where: { $0.exercise?.exerciseId == exercise.exerciseId }) {
                workout?.exercises?[index].orderIndex = results.firstIndex(of: matchingResult) ?? index
            }
        }
        
        // Sort workout exercises by new order
        workout?.exercises?.sort { $0.orderIndex < $1.orderIndex }
    }
    
    func safeAddExerciseResult(_ result: LiftExerciseResult) {
        guard let results = exerciseResults else { 
            addExerciseResult(result)
            return 
        }
        // Prevent duplicate additions
        guard !results.contains(where: { $0.id == result.id }) else { return }
        
        // Set proper order index
        result.exercise?.orderIndex = results.count
        
        // Add to session
        addExerciseResult(result)
    }
    
    func safeRemoveExerciseResult(by id: UUID) {
        guard let results = exerciseResults else { return }
        // Find and remove by ID
        if let index = results.firstIndex(where: { $0.id == id }) {
            let result = results[index]
            removeExerciseResult(result)
            
            // Re-index remaining exercises
            guard let updatedResults = exerciseResults else { return }
            for (newIndex, remainingResult) in updatedResults.enumerated() {
                remainingResult.exercise?.orderIndex = newIndex
            }
        }
    }
}

// MARK: - Lift Exercise Result Model
@Model
final class LiftExerciseResult {
    var id: UUID = UUID()
    var performedAt: Date = Date()
    var sets: [SetData] = []
    var notes: String?
    var videoURL: String?
    var isPersonalRecord: Bool = false
    var isCompleted: Bool = false
    
    // Relationships
    var exercise: LiftExercise?
    var session: LiftSession?
    
    init(
        exercise: LiftExercise,
        session: LiftSession? = nil
    ) {
        self.id = UUID()
        self.performedAt = Date()
        self.sets = []
        self.notes = nil
        self.videoURL = nil
        self.isPersonalRecord = false
        self.exercise = exercise
        self.session = session
        
        // Sets will be added manually when needed
    }
}

// MARK: - Computed Properties
extension LiftExerciseResult {
    var completedSets: Int {
        return sets.filter { $0.isCompleted }.count
    }
    
    var totalVolume: Double {
        return sets.reduce(0) { total, set in
            guard set.isCompleted else { return total }
            return total + set.volume
        }
    }
    
    var maxWeight: Double? {
        return sets.compactMap { $0.weight }.max()
    }
    
    var averageWeight: Double? {
        let weights = sets.compactMap { $0.weight }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }
    
    var totalReps: Int {
        return sets.filter { $0.isCompleted }.reduce(0) { $0 + $1.reps }
    }

    var estimatedOneRM: Double {
        let completedSets = sets.filter { $0.isCompleted && $0.weight != nil }
        guard let bestSet = completedSets.max(by: {
            ($0.weight ?? 0) * (1 + Double($0.reps) / 30) < ($1.weight ?? 0) * (1 + Double($1.reps) / 30)
        }) else { return 0 }

        guard let weight = bestSet.weight, bestSet.reps > 0 else { return 0 }

        // Use Epley formula: 1RM = weight * (1 + reps/30)
        return weight * (1 + Double(bestSet.reps) / 30.0)
    }
}

// MARK: - Methods
extension LiftExerciseResult {
    func addSet() {
        let lastSet = sets.last
        let previousWeight = exercise?.lastPerformedWeight
        let newSet = SetData(
            setNumber: sets.count + 1,
            weight: lastSet?.weight ?? previousWeight ?? exercise?.targetWeight,
            reps: lastSet?.reps ?? exercise?.targetReps ?? 5,
            isWarmup: false,
            isCompleted: false
        )
        sets.append(newSet)
    }
    
    func removeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets.remove(at: index)
        
        // Renumber remaining sets
        for (i, set) in sets.enumerated() {
            var updatedSet = set
            updatedSet.setNumber = i + 1
            sets[i] = updatedSet
        }
    }
    
    func completeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets[index].isCompleted = true
        sets[index].timestamp = Date()
        
        // Check if this is a PR
        if let weight = sets[index].weight,
           let pr = exercise?.personalRecord,
           weight > pr {
            isPersonalRecord = true
        }
    }
    
    func updateSet(at index: Int, weight: Double?, reps: Int) {
        guard sets.indices.contains(index) else { return }
        sets[index].weight = weight
        sets[index].reps = reps
    }
}