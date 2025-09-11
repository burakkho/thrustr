import Foundation
import SwiftData

// MARK: - Lift Exercise Model
@Model
final class LiftExercise {
    var id: UUID = UUID()
    var exerciseId: UUID = UUID() // Reference to Exercise model
    var exerciseName: String = "" // Cached for performance
    var orderIndex: Int = 0
    var targetSets: Int = 3
    var targetReps: Int = 10
    var targetWeight: Double?
    var restTime: Int? // seconds between sets
    var tempo: String? // e.g., "3-1-1-0" (eccentric-pause-concentric-pause)
    var notes: String?
    var isWarmup: Bool = false
    var isSupersetWith: Int? // orderIndex of paired exercise
    
    // Relationships
    var workout: LiftWorkout?
    var lift: Lift?
    @Relationship(deleteRule: .cascade) var results: [LiftExerciseResult]?
    
    init(
        exerciseId: UUID,
        exerciseName: String,
        orderIndex: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetWeight: Double? = nil,
        restTime: Int? = 90,
        tempo: String? = nil,
        notes: String? = nil,
        isWarmup: Bool = false,
        isSupersetWith: Int? = nil
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restTime = restTime
        self.tempo = tempo
        self.notes = notes
        self.isWarmup = isWarmup
        self.isSupersetWith = isSupersetWith
        self.results = []
    }
}

// MARK: - Computed Properties
extension LiftExercise {
    var targetVolume: Double {
        guard let weight = targetWeight else { return 0 }
        return weight * Double(targetSets * targetReps)
    }
    
    var isSuperset: Bool {
        return isSupersetWith != nil || restTime == 0
    }
    
    var displaySets: String {
        return "\(targetSets) × \(targetReps)"
    }
    
    var displayWeight: String {
        if let weight = targetWeight {
            return "\(Int(weight))kg"
        }
        return "BW" // Body weight
    }
    
    var formattedRestTime: String? {
        guard let rest = restTime, rest > 0 else { return nil }
        let minutes = rest / 60
        let seconds = rest % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    var lastPerformedWeight: Double? {
        return results?
            .sorted { $0.performedAt > $1.performedAt }
            .first?
            .sets
            .compactMap { $0.weight }
            .max()
    }
    
    var personalRecord: Double? {
        return results?
            .flatMap { $0.sets }
            .compactMap { $0.weight }
            .max()
    }
    
    func calculateCurrentWorkingWeight(user: User, programExecution: ProgramExecution?) -> Double {
        // If this exercise has a target weight set, use it
        if let targetWeight = targetWeight {
            return user.roundToPlateIncrement(targetWeight, system: .metric)
        }
        
        // If we have previous performed weight, use progression
        if let lastWeight = lastPerformedWeight {
            // Add 2.5kg progression for StrongLifts-style programs
            let newWeight = lastWeight + 2.5
            return user.roundToPlateIncrement(newWeight, system: .metric)
        }
        
        // Otherwise, calculate from user's 1RM starting weights
        let exerciseKey = getExerciseKey()
        let startingWeights = user.calculateStartingWeights()
        
        // Add progression based on current program day/week
        let baseWeight = startingWeights[exerciseKey] ?? 20.0 // Default fallback
        let progressionAmount = calculateProgressionAmount(execution: programExecution)
        let totalWeight = baseWeight + progressionAmount
        
        return user.roundToPlateIncrement(totalWeight, system: .metric)
    }
    
    private func getExerciseKey() -> String {
        let name = exerciseName.lowercased()
        if name.contains("squat") {
            return "squat"
        } else if name.contains("bench") {
            return "bench"
        } else if name.contains("deadlift") {
            return "deadlift"
        } else if name.contains("overhead") || name.contains("press") {
            return "ohp"
        } else if name.contains("row") {
            return "row"
        }
        return "squat" // Default fallback
    }
    
    private func calculateProgressionAmount(execution: ProgramExecution?) -> Double {
        guard let execution = execution else { return 0.0 }
        
        // StrongLifts progression: +2.5kg per workout
        // Calculate total completed workouts for this exercise
        let completedWorkouts = execution.completedWorkouts?.count ?? 0
        return Double(completedWorkouts) * 2.5
    }
}

// MARK: - Methods
extension LiftExercise {
    func duplicate() -> LiftExercise {
        return LiftExercise(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            orderIndex: orderIndex,
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: targetWeight,
            restTime: restTime,
            tempo: tempo,
            notes: notes,
            isWarmup: isWarmup,
            isSupersetWith: isSupersetWith
        )
    }
    
    func updateFromPrevious(result: LiftExerciseResult) {
        // Update target based on previous performance
        if let maxWeight = result.sets.compactMap({ $0.weight }).max() {
            // Progressive overload: add 2.5kg if all sets completed successfully
            let allSetsCompleted = result.sets.allSatisfy { $0.isCompleted }
            if allSetsCompleted {
                targetWeight = maxWeight + 2.5
            } else {
                targetWeight = maxWeight
            }
        }
    }
    
    func createWarmupSets() -> [LiftExercise] {
        guard let weight = targetWeight, weight > 20 else { return [] }
        
        var warmupSets: [LiftExercise] = []
        
        // Warmup progression: 40%, 60%, 80% of working weight
        let percentages = [0.4, 0.6, 0.8]
        let reps = [10, 5, 3]
        
        for (index, percentage) in percentages.enumerated() {
            let warmup = LiftExercise(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                orderIndex: orderIndex,
                targetSets: 1,
                targetReps: reps[index],
                targetWeight: weight * percentage,
                restTime: 60,
                isWarmup: true
            )
            warmupSets.append(warmup)
        }
        
        return warmupSets
    }
}

// MARK: - Set Data Structure
struct SetData: Codable, Identifiable {
    let id: UUID
    var setNumber: Int
    var weight: Double?
    var reps: Int
    var isWarmup: Bool
    var isCompleted: Bool
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var rir: Int? // Reps in Reserve
    var notes: String?
    var timestamp: Date
    
    init(
        setNumber: Int,
        weight: Double? = nil,
        reps: Int,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        rpe: Int? = nil,
        rir: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID() // Stable ID set once in init
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.rpe = rpe
        self.rir = rir
        self.notes = notes
        self.timestamp = Date()
    }
    
    var volume: Double {
        guard let weight = weight else { return 0 }
        return weight * Double(reps)
    }
    
    var displayText: String {
        if let weight = weight {
            return "\(Int(weight))kg × \(reps)"
        } else {
            return "BW × \(reps)"
        }
    }
}