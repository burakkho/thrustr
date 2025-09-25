import Foundation
import SwiftData

struct GoalService: GoalServiceProtocol, @unchecked Sendable {

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let healthKitService: HealthKitService?

    // MARK: - Initialization
    init(modelContext: ModelContext, healthKitService: HealthKitService? = nil) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
    }

    // MARK: - Goal Management
    func fetchGoals() async throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            sortBy: [SortDescriptor(\Goal.createdDate, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchCurrentUser() async throws -> User? {
        let descriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(descriptor)
        return users.first
    }

    func createGoal(
        title: String,
        description: String,
        targetValue: Double,
        type: GoalType,
        deadline: Date?
    ) async throws -> Goal {
        let goal = Goal(
            title: title,
            description: description,
            type: type,
            targetValue: targetValue,
            currentValue: 0,
            deadline: deadline
        )

        modelContext.insert(goal)
        try modelContext.save()

        return goal
    }

    func updateGoal(_ goal: Goal) async throws -> Goal {
        // Update progress if needed
        goal.currentValue = await calculateCurrentValue(for: goal)

        // Check if goal is completed
        if goal.currentValue >= goal.targetValue && !goal.isCompleted {
            goal.isCompleted = true
            goal.completedDate = Date()
        }

        try modelContext.save()
        return goal
    }

    func deleteGoal(_ goal: Goal) async throws {
        modelContext.delete(goal)
        try modelContext.save()
    }

    func calculateProgress(for goal: Goal) -> Double {
        guard goal.targetValue > 0 else { return 0 }
        let progress = (goal.currentValue / goal.targetValue) * 100
        return min(progress, 100) // Cap at 100%
    }

    // MARK: - Private Helpers
    private func calculateCurrentValue(for goal: Goal) async -> Double {
        switch goal.typeEnum {
        case .weight:
            return await calculateWeightProgress(for: goal)
        case .bodyFat:
            return await calculateBodyFatProgress(for: goal)
        case .muscle:
            return await calculateMuscleProgress(for: goal)
        case .strength:
            return calculateStrengthProgress(for: goal)
        case .endurance:
            return calculateEnduranceProgress(for: goal)
        case .flexibility:
            return calculateFlexibilityProgress(for: goal)
        }
    }

    private func calculateWeightProgress(for goal: Goal) async -> Double {
        // Try to get current weight from HealthKit first
        if let healthKitService = healthKitService {
            let healthKitWeight = await healthKitService.currentWeight
            if let healthKitWeight = healthKitWeight, healthKitWeight > 0 {
                Logger.info("Using HealthKit weight data for goal progress: \(healthKitWeight) kg")
                return healthKitWeight
            }
        }

        // Fallback: Try to get latest manual weight entry from database
        do {
            let weightDescriptor = FetchDescriptor<WeightEntry>(
                sortBy: [SortDescriptor(\WeightEntry.date, order: .reverse)]
            )
            let weightEntries = try modelContext.fetch(weightDescriptor)
            if let latestWeight = weightEntries.first {
                Logger.info("Using manual weight entry for goal progress: \(latestWeight.weight) kg from \(latestWeight.displayDate)")
                return latestWeight.weight
            }
        } catch {
            // If database query fails, log error but continue with fallback
            Logger.error("Failed to fetch weight entries for goal progress: \(error)")
        }

        // Final fallback: return manually set current value
        Logger.warning("No HealthKit or database weight data available, using manual goal value: \(goal.currentValue) kg")
        return goal.currentValue
    }

    private func calculateBodyFatProgress(for goal: Goal) async -> Double {
        // Try to get body fat percentage from HealthKit first
        if let healthKitService = healthKitService {
            let healthKitBodyFat = await healthKitService.bodyFatPercentage
            if let healthKitBodyFat = healthKitBodyFat, healthKitBodyFat > 0 {
                Logger.info("Using HealthKit body fat data for goal progress: \(healthKitBodyFat)%")
                return healthKitBodyFat
            }
        }

        // Fallback: Try to get latest body fat from weight entries
        do {
            let weightDescriptor = FetchDescriptor<WeightEntry>(
                sortBy: [SortDescriptor(\WeightEntry.date, order: .reverse)]
            )
            let weightEntries = try modelContext.fetch(weightDescriptor)

            // Find the most recent weight entry with body fat data
            if let entryWithBodyFat = weightEntries.first(where: { $0.bodyFat != nil && $0.bodyFat! > 0 }) {
                Logger.info("Using weight entry body fat data for goal progress: \(entryWithBodyFat.bodyFat!)% from \(entryWithBodyFat.displayDate)")
                return entryWithBodyFat.bodyFat!
            }
        } catch {
            Logger.error("Failed to fetch weight entries for body fat progress: \(error)")
        }

        // Additional fallback: Try to get body fat from progress photos
        do {
            let photoDescriptor = FetchDescriptor<ProgressPhoto>(
                sortBy: [SortDescriptor(\ProgressPhoto.date, order: .reverse)]
            )
            let progressPhotos = try modelContext.fetch(photoDescriptor)

            if let photoWithBodyFat = progressPhotos.first(where: { $0.bodyFat != nil && $0.bodyFat! > 0 }) {
                Logger.info("Using progress photo body fat data for goal progress: \(photoWithBodyFat.bodyFat!)% from \(photoWithBodyFat.displayDate)")
                return photoWithBodyFat.bodyFat!
            }
        } catch {
            Logger.error("Failed to fetch progress photos for body fat progress: \(error)")
        }

        // Final fallback: return manually set current value
        Logger.warning("No HealthKit, weight entry, or photo body fat data available, using manual goal value: \(goal.currentValue)%")
        return goal.currentValue
    }

    private func calculateMuscleProgress(for goal: Goal) async -> Double {
        // Try to get lean body mass from HealthKit first
        if let healthKitService = healthKitService {
            let healthKitLeanMass = await healthKitService.leanBodyMass
            if let healthKitLeanMass = healthKitLeanMass, healthKitLeanMass > 0 {
                Logger.info("Using HealthKit lean body mass for goal progress: \(healthKitLeanMass) kg")
                return healthKitLeanMass
            }
        }

        // Fallback: Try to get muscle mass from weight entries
        do {
            let weightDescriptor = FetchDescriptor<WeightEntry>(
                sortBy: [SortDescriptor(\WeightEntry.date, order: .reverse)]
            )
            let weightEntries = try modelContext.fetch(weightDescriptor)

            // Find the most recent weight entry with muscle mass data
            if let entryWithMuscle = weightEntries.first(where: { $0.muscleMass != nil && $0.muscleMass! > 0 }) {
                Logger.info("Using weight entry muscle mass for goal progress: \(entryWithMuscle.muscleMass!) kg from \(entryWithMuscle.displayDate)")
                return entryWithMuscle.muscleMass!
            }

            // Additional calculation: Use weight and body fat to estimate lean mass
            if let recentEntry = weightEntries.first,
               let bodyFat = recentEntry.bodyFat, bodyFat > 0 {
                let estimatedLeanMass = recentEntry.weight * (1 - bodyFat / 100)
                Logger.info("Calculated lean mass from weight and body fat: \(estimatedLeanMass) kg (Weight: \(recentEntry.weight) kg, Body Fat: \(bodyFat)%)")
                return estimatedLeanMass
            }
        } catch {
            Logger.error("Failed to fetch weight entries for muscle progress: \(error)")
        }

        // Final fallback: return manually set current value
        Logger.warning("No HealthKit or calculated muscle mass data available, using manual goal value: \(goal.currentValue) kg")
        return goal.currentValue
    }

    private func calculateStrengthProgress(for goal: Goal) -> Double {
        // Calculate strength progress based on recent lift sessions
        do {
            let sessionDescriptor = FetchDescriptor<LiftSession>(
                predicate: #Predicate { $0.isCompleted == true },
                sortBy: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
            )
            let sessions = try modelContext.fetch(sessionDescriptor)

            // Get recent 4 weeks of data for trend analysis
            let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
            let recentSessions = sessions.filter { $0.startDate >= fourWeeksAgo }

            if !recentSessions.isEmpty {
                // Calculate average total volume over recent sessions
                let totalVolume = recentSessions.reduce(0) { $0 + $1.totalVolume }
                let averageVolume = totalVolume / Double(recentSessions.count)

                Logger.info("Using recent lift session data for strength progress: \(averageVolume) kg average volume from \(recentSessions.count) sessions")
                return averageVolume
            }

            // Fallback: Use most recent session if no recent data
            if let latestSession = sessions.first {
                Logger.info("Using latest lift session for strength progress: \(latestSession.totalVolume) kg volume from \(latestSession.displayDate)")
                return latestSession.totalVolume
            }
        } catch {
            Logger.error("Failed to fetch lift sessions for strength progress: \(error)")
        }

        // Final fallback: return manually set current value
        Logger.warning("No lift session data available, using manual goal value: \(goal.currentValue)")
        return goal.currentValue
    }

    private func calculateEnduranceProgress(for goal: Goal) -> Double {
        // Calculate endurance progress based on recent cardio sessions
        do {
            let sessionDescriptor = FetchDescriptor<CardioSession>(
                predicate: #Predicate { $0.isCompleted == true },
                sortBy: [SortDescriptor(\CardioSession.startDate, order: .reverse)]
            )
            let sessions = try modelContext.fetch(sessionDescriptor)

            // Get recent 4 weeks of data for trend analysis
            let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
            let recentSessions = sessions.filter { $0.startDate >= fourWeeksAgo }

            if !recentSessions.isEmpty {
                // Calculate average distance covered over recent sessions
                let totalDistance = recentSessions.reduce(0) { $0 + $1.totalDistance }
                let averageDistance = totalDistance / Double(recentSessions.count)

                Logger.info("Using recent cardio session data for endurance progress: \(averageDistance) km average distance from \(recentSessions.count) sessions")
                return averageDistance
            }

            // Fallback: Use most recent session if no recent data
            if let latestSession = sessions.first {
                Logger.info("Using latest cardio session for endurance progress: \(latestSession.totalDistance) km distance from \(latestSession.displayDate)")
                return latestSession.totalDistance
            }
        } catch {
            Logger.error("Failed to fetch cardio sessions for endurance progress: \(error)")
        }

        // Final fallback: return manually set current value
        Logger.warning("No cardio session data available, using manual goal value: \(goal.currentValue)")
        return goal.currentValue
    }

    private func calculateFlexibilityProgress(for goal: Goal) -> Double {
        // Flexibility tracking is not implemented in the app yet
        // Return manually set current value
        Logger.info("Flexibility tracking not implemented, using manual goal value: \(goal.currentValue)")
        return goal.currentValue
    }
}

