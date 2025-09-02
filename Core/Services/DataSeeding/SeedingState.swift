import SwiftUI

@MainActor
class SeedingState: ObservableObject {
    @Published var isFoodsReady: Bool = false
    @Published var isExercisesReady: Bool = false
    @Published var currentProgress: SeedingProgress? = nil
    
    func updateProgress(_ progress: SeedingProgress) {
        currentProgress = progress
        
        switch progress {
        case .benchmarkWODs:
            isFoodsReady = true
        case .crossFitMovements:
            isExercisesReady = true
            isFoodsReady = true
        case .completed:
            isFoodsReady = true
            isExercisesReady = true
        default:
            break
        }
    }
    
    var progressText: String {
        currentProgress?.title ?? ""
    }
    
    var progressValue: Double {
        currentProgress?.progressValue ?? 0.0
    }
}