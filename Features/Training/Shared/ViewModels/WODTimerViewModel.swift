import SwiftUI
import SwiftData

@Observable
class WODTimerViewModel {
    // MARK: - Timer
    let timerViewModel = TimerViewModel()
    
    // MARK: - WOD Properties
    let wod: WOD
    let movements: [WODMovement]
    let isRX: Bool
    
    // MARK: - WOD State
    var completedRounds = 0
    var currentMovementIndex = 0
    var currentRepIndex = 0
    var movementSplits: [TimeInterval] = []
    var roundSplits: [TimeInterval] = []
    var splitMode = false
    
    // MARK: - UI State
    var showingResultEntry = false
    
    // MARK: - Computed Properties
    
    var currentMovement: WODMovement? {
        guard currentMovementIndex < movements.count else { return nil }
        return movements[currentMovementIndex]
    }
    
    var progressPercentage: Double {
        guard wod.wodType == .forTime, !wod.repScheme.isEmpty else { return 0 }
        
        let totalReps = wod.repScheme.reduce(0, +) * movements.count
        let completedReps = calculateCompletedReps()
        
        return min(Double(completedReps) / Double(totalReps), 1.0)
    }
    
    var formattedSplitTime: String {
        let lastSplit = roundSplits.last ?? 0
        let currentSplit = timerViewModel.elapsedTime - lastSplit
        let minutes = Int(currentSplit) / 60
        let seconds = Int(currentSplit) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(wod: WOD, movements: [WODMovement], isRX: Bool) {
        self.wod = wod
        self.movements = movements
        self.isRX = isRX
    }
    
    // MARK: - Public Methods
    
    func startWOD() {
        timerViewModel.startCountdown()
    }
    
    func pauseWOD() {
        timerViewModel.pauseTimer()
    }
    
    func resumeWOD() {
        timerViewModel.resumeTimer()
    }
    
    func stopWOD() {
        timerViewModel.stopTimer()
        showingResultEntry = true
    }
    
    func recordSplit() {
        movementSplits.append(timerViewModel.elapsedTime)
        HapticManager.shared.impact(.medium)
    }
    
    func nextMovement() {
        if currentMovementIndex < movements.count - 1 {
            currentMovementIndex += 1
            HapticManager.shared.impact(.light)
        } else {
            // End of round for For Time
            if wod.wodType == .forTime {
                if currentRepIndex < wod.repScheme.count - 1 {
                    currentRepIndex += 1
                    currentMovementIndex = 0
                    roundSplits.append(timerViewModel.elapsedTime)
                    playSound("round")
                } else {
                    // Workout complete
                    stopWOD()
                }
            }
        }
    }
    
    func completeRound() {
        completedRounds += 1
        currentMovementIndex = 0
        roundSplits.append(timerViewModel.elapsedTime)
        playSound("round")
        HapticManager.shared.notification(.success)
    }
    
    func saveWODResult(_ result: WODResult, modelContext: ModelContext, currentUser: User?) {
        modelContext.insert(result)
        result.wod = wod
        result.user = currentUser
        wod.results.append(result)
        
        // Save splits as JSON
        if !roundSplits.isEmpty {
            let splitsData = roundSplits.map { formatTime($0) }
            if let jsonData = try? JSONEncoder().encode(splitsData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                result.splits = jsonString
            }
        }
        
        do {
            try modelContext.save()
            
            // Check if this is a personal record
            let isPR = result == wod.personalRecord
            
            // Log activity for recent activity feed
            Task { @MainActor in
                ActivityLoggerService.shared.logWODCompleted(
                    wodName: wod.name,
                    wodType: wod.wodType.rawValue,
                    totalTime: result.totalTime,
                    rounds: result.rounds,
                    extraReps: result.extraReps,
                    isRX: result.isRX,
                    isPR: isPR,
                    user: currentUser
                )
            }
            
            HapticManager.shared.notification(.success)
        } catch {
            print("Error saving WOD result: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateCompletedReps() -> Int {
        guard wod.wodType == .forTime else { return 0 }
        
        var totalReps = 0
        
        // Calculate completed full rounds
        if currentRepIndex > 0 {
            for i in 0..<currentRepIndex {
                totalReps += wod.repScheme[i] * movements.count
            }
        }
        
        // Add current round progress
        if currentRepIndex < wod.repScheme.count {
            totalReps += wod.repScheme[currentRepIndex] * currentMovementIndex
        }
        
        return totalReps
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func playSound(_ soundName: String) {
        // Sound implementation can be added here
        // For now, just haptic feedback
        HapticManager.shared.impact(.medium)
    }
}
