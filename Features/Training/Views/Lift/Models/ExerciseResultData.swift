import Foundation

// MARK: - Exercise Result Data Transfer Object
/// Clean DTO for SwiftUI binding, separates UI concerns from SwiftData
struct ExerciseResultData: Identifiable, Sendable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String
    let targetSets: Int
    let targetReps: Int
    let targetWeight: Double?
    var sets: [SetData]
    var notes: String?
    var isPersonalRecord: Bool
    var isCompleted: Bool
    
    // MARK: - Computed Properties
    var completedSets: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    var totalVolume: Double {
        sets.reduce(0) { total, set in
            guard set.isCompleted else { return total }
            return total + set.volume
        }
    }
    
    var maxWeight: Double? {
        sets.compactMap { $0.weight }.max()
    }
    
    var totalReps: Int {
        sets.filter { $0.isCompleted }.reduce(0) { $0 + $1.reps }
    }
    
    var completionPercentage: Double {
        guard targetSets > 0 else { return 0 }
        return Double(completedSets) / Double(targetSets)
    }
    
    // MARK: - Initialization
    init(from exerciseResult: LiftExerciseResult) {
        self.id = exerciseResult.id
        self.exerciseId = exerciseResult.exercise?.exerciseId ?? ""
        self.exerciseName = exerciseResult.exercise?.exerciseName ?? "Unknown Exercise"
        self.targetSets = exerciseResult.exercise?.targetSets ?? 0
        self.targetReps = exerciseResult.exercise?.targetReps ?? 0
        self.targetWeight = exerciseResult.exercise?.targetWeight
        self.sets = exerciseResult.sets
        self.notes = exerciseResult.notes
        self.isPersonalRecord = exerciseResult.isPersonalRecord
        self.isCompleted = exerciseResult.completedSets >= (exerciseResult.exercise?.targetSets ?? 0)
    }
}

// MARK: - Extensions
extension ExerciseResultData {
    /// Updates the original SwiftData model with changes from this DTO
    func updateModel(_ model: LiftExerciseResult) {
        model.sets = self.sets
        model.notes = self.notes
        model.isPersonalRecord = self.isPersonalRecord
    }
    
    /// Creates a new set with smart defaults
    mutating func addNewSet() {
        let lastSet = sets.last
        let newSet = SetData(
            setNumber: sets.count + 1,
            weight: lastSet?.weight ?? targetWeight,
            reps: lastSet?.reps ?? targetReps,
            isWarmup: false,
            isCompleted: false
        )
        sets.append(newSet)
    }
    
    /// Marks a set as completed
    mutating func completeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets[index].isCompleted = true
        sets[index].timestamp = Date()
        
        // Check for PR
        if let weight = sets[index].weight,
           let currentMax = maxWeight,
           weight > currentMax {
            isPersonalRecord = true
        }
    }
}