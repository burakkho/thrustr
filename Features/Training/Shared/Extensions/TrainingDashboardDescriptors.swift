import SwiftData
import Foundation

// MARK: - SwiftData Descriptors for Performance Optimization
extension TrainingDashboardView {
    static var recentLiftSessionsDescriptor: FetchDescriptor<LiftSession> {
        var descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return descriptor
    }
    
    static var recentCardioSessionsDescriptor: FetchDescriptor<CardioSession> {
        var descriptor = FetchDescriptor<CardioSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return descriptor
    }
    
    static var recentWODResultsDescriptor: FetchDescriptor<WODResult> {
        var descriptor = FetchDescriptor<WODResult>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return descriptor
    }
}