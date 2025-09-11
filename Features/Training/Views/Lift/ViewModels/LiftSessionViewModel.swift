import Foundation
import SwiftData

// MARK: - Lift Session View Model
@MainActor
@Observable
final class LiftSessionViewModel {
    // MARK: - Published Properties
    var exercises: [ExerciseResultData] = []
    var isLoading = false
    var expandedExerciseId: UUID?
    var isEditingOrder = false
    
    // MARK: - Private Properties
    private var session: LiftSession?
    private var modelContext: ModelContext?
    
    // MARK: - Public Methods
    
    /// Load exercises from SwiftData session into DTO format
    func loadSession(_ session: LiftSession, context: ModelContext) {
        self.session = session
        self.modelContext = context
        
        isLoading = true
        defer { isLoading = false }
        
        // Convert SwiftData models to DTOs
        exercises = session.exerciseResults?.map { exerciseResult in
            ExerciseResultData(from: exerciseResult)
        } ?? []
        
        Logger.info("Loaded \(exercises.count) exercises for session")
    }
    
    /// Update exercise data and sync back to SwiftData
    func updateExercise(_ exerciseData: ExerciseResultData) {
        // Update DTO
        if let index = exercises.firstIndex(where: { $0.id == exerciseData.id }) {
            exercises[index] = exerciseData
        }
        
        // Sync to SwiftData
        syncExerciseToModel(exerciseData)
    }
    
    /// Add new set to exercise
    func addSet(to exerciseId: UUID) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].addNewSet()
            syncExerciseToModel(exercises[index])
        }
    }
    
    /// Complete a set
    func completeSet(exerciseId: UUID, setIndex: Int) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].completeSet(at: setIndex)
            syncExerciseToModel(exercises[index])
        }
    }
    
    /// Toggle exercise expansion
    func toggleExpansion(for exerciseId: UUID) {
        expandedExerciseId = expandedExerciseId == exerciseId ? nil : exerciseId
    }
    
    /// Start/stop editing order
    func toggleEditingOrder() {
        isEditingOrder.toggle()
        if isEditingOrder {
            expandedExerciseId = nil // Collapse all when editing
        }
    }
    
    /// Move exercises (for reordering)
    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        
        // Update order in SwiftData
        updateExerciseOrder()
    }
    
    /// Calculate session totals
    func calculateSessionTotals() -> (volume: Double, sets: Int, reps: Int) {
        let volume = exercises.reduce(0) { $0 + $1.totalVolume }
        let sets = exercises.reduce(0) { $0 + $1.completedSets }
        let reps = exercises.reduce(0) { $0 + $1.totalReps }
        
        return (volume: volume, sets: sets, reps: reps)
    }
    
    /// Get previous sets for comparison
    func getPreviousSets(for exerciseId: String) -> [SetData]? {
        // Implementation would query previous sessions
        // For now, return nil (placeholder)
        return nil
    }
    
    // MARK: - Private Methods
    
    /// Sync DTO changes back to SwiftData model
    private func syncExerciseToModel(_ exerciseData: ExerciseResultData) {
        guard let session = session,
              let exerciseResult = session.exerciseResults?.first(where: { $0.id == exerciseData.id }) else {
            Logger.warning("Could not find exercise result to sync")
            return
        }
        
        exerciseData.updateModel(exerciseResult)
        
        do {
            try modelContext?.save()
            Logger.info("Successfully synced exercise \(exerciseData.exerciseName)")
        } catch {
            Logger.error("Failed to sync exercise: \(error)")
        }
    }
    
    /// Update exercise order in SwiftData
    private func updateExerciseOrder() {
        guard let session = session else { return }
        
        for (index, exerciseData) in exercises.enumerated() {
            if let exerciseResult = session.exerciseResults?.first(where: { $0.id == exerciseData.id }) {
                exerciseResult.exercise?.orderIndex = index
            }
        }
        
        do {
            try modelContext?.save()
            Logger.info("Updated exercise order")
        } catch {
            Logger.error("Failed to update exercise order: \(error)")
        }
    }
}

// MARK: - Helper Extensions
extension LiftSessionViewModel {
    var hasExercises: Bool {
        !exercises.isEmpty
    }
    
    var completedExercisesCount: Int {
        exercises.filter { $0.isCompleted }.count
    }
    
    var totalExercisesCount: Int {
        exercises.count
    }
    
    var sessionCompletionPercentage: Double {
        guard totalExercisesCount > 0 else { return 0 }
        return Double(completedExercisesCount) / Double(totalExercisesCount)
    }
}