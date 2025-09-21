import Foundation
import SwiftData

struct PRCalculationService {

    // MARK: - PR Data Types

    struct PersonalRecord {
        let exercise: String
        let weight: Double
        let date: Date
        let isNew: Bool // Achieved within last 7 days
        let previousBest: Double?
        let improvement: Double?
    }

    // MARK: - PR Calculation

    static func calculatePersonalRecords(from liftResults: [LiftExerciseResult], limit: Int = 5) -> [PersonalRecord] {
        let exerciseGroups = Dictionary(grouping: liftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        return exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }

            // Find all-time max for this exercise
            let sortedResults = results.sorted { $0.performedAt > $1.performedAt }
            guard let bestResult = sortedResults.max(by: { ($0.maxWeight ?? 0) < ($1.maxWeight ?? 0) }),
                  let maxWeight = bestResult.maxWeight else { return nil }

            // Check if this is a new PR (within last week)
            let isNew = bestResult.performedAt >= oneWeekAgo

            // Find previous best (before the current best)
            let previousResults = results.filter { $0.performedAt < bestResult.performedAt }
            let previousBest = previousResults.compactMap { $0.maxWeight }.max()

            let improvement = previousBest != nil ? maxWeight - previousBest! : nil

            return PersonalRecord(
                exercise: exerciseName,
                weight: maxWeight,
                date: bestResult.performedAt,
                isNew: isNew,
                previousBest: previousBest,
                improvement: improvement
            )
        }
        .sorted { first, second in
            // Sort by: new PRs first, then by date (most recent first)
            if first.isNew && !second.isNew { return true }
            if !first.isNew && second.isNew { return false }
            return first.date > second.date
        }
        .prefix(limit)
        .map { $0 }
    }

    // MARK: - PR Statistics

    static func calculatePRStatistics(from prs: [PersonalRecord]) -> (
        totalPRs: Int,
        newPRsThisWeek: Int,
        averageImprovement: Double,
        strongestLift: PersonalRecord?
    ) {
        let newPRsThisWeek = prs.filter { $0.isNew }.count

        let improvements = prs.compactMap { $0.improvement }
        let averageImprovement = improvements.isEmpty ? 0 : improvements.reduce(0, +) / Double(improvements.count)

        let strongestLift = prs.max { $0.weight < $1.weight }

        return (prs.count, newPRsThisWeek, averageImprovement, strongestLift)
    }

    // MARK: - PR Progression Analysis

    static func analyzePRProgression(for exercise: String, from liftResults: [LiftExerciseResult]) -> PRProgression? {
        let exerciseResults = liftResults.filter {
            $0.exercise?.exerciseName.lowercased() == exercise.lowercased()
        }.sorted { $0.performedAt < $1.performedAt }

        guard exerciseResults.count >= 2 else { return nil }

        let weights = exerciseResults.compactMap { $0.maxWeight }
        guard weights.count >= 2 else { return nil }

        let firstWeight = weights.first!
        let lastWeight = weights.last!
        let totalImprovement = lastWeight - firstWeight

        // Calculate progression rate (improvement per month)
        let timeSpan = exerciseResults.last!.performedAt.timeIntervalSince(exerciseResults.first!.performedAt)
        let monthsSpan = timeSpan / (30 * 24 * 60 * 60) // Convert to months
        let progressionRate = monthsSpan > 0 ? totalImprovement / monthsSpan : 0

        // Find all PRs for this exercise
        var prs: [(weight: Double, date: Date)] = []
        var currentMax: Double = 0

        for result in exerciseResults {
            if let weight = result.maxWeight, weight > currentMax {
                currentMax = weight
                prs.append((weight: weight, date: result.performedAt))
            }
        }

        return PRProgression(
            exercise: exercise,
            startingWeight: firstWeight,
            currentWeight: lastWeight,
            totalImprovement: totalImprovement,
            progressionRate: progressionRate,
            milestones: prs,
            consistency: calculateConsistency(from: exerciseResults)
        )
    }

    // MARK: - Helper Methods

    private static func calculateConsistency(from results: [LiftExerciseResult]) -> Double {
        guard results.count >= 2 else { return 0 }

        let dates = results.map { $0.performedAt }.sorted()
        let timeSpan = dates.last!.timeIntervalSince(dates.first!)
        let expectedSessions = timeSpan / (7 * 24 * 60 * 60) // Expected weekly sessions

        return expectedSessions > 0 ? min(100, Double(results.count) / expectedSessions * 100) : 0
    }

    // MARK: - PR Goals & Predictions

    static func predictNextPRMilestone(for exercise: String, from liftResults: [LiftExerciseResult]) -> PRPrediction? {
        guard let progression = analyzePRProgression(for: exercise, from: liftResults),
              progression.progressionRate > 0 else { return nil }

        let currentWeight = progression.currentWeight

        // Calculate next realistic milestone (usually 2.5-5kg increment)
        let incrementSize: Double = {
            if currentWeight < 60 { return 2.5 }
            if currentWeight < 100 { return 5.0 }
            return 5.0
        }()

        let nextMilestone = currentWeight + incrementSize

        // Predict time to reach milestone based on current rate
        let timeToMilestone = incrementSize / progression.progressionRate * 30 // Convert to days
        let predictedDate = Calendar.current.date(byAdding: .day, value: Int(timeToMilestone), to: Date())

        return PRPrediction(
            exercise: exercise,
            currentWeight: currentWeight,
            nextMilestone: nextMilestone,
            incrementNeeded: incrementSize,
            estimatedTimeInDays: Int(timeToMilestone),
            predictedDate: predictedDate ?? Date(),
            confidence: calculatePredictionConfidence(progression: progression)
        )
    }

    private static func calculatePredictionConfidence(progression: PRProgression) -> Double {
        // Confidence based on consistency and progression rate
        let consistencyFactor = progression.consistency / 100.0
        let rateFactor = min(1.0, progression.progressionRate / 2.0) // Cap at reasonable rate

        return (consistencyFactor + rateFactor) / 2.0 * 100
    }
}

// MARK: - Supporting Types

struct PRProgression {
    let exercise: String
    let startingWeight: Double
    let currentWeight: Double
    let totalImprovement: Double
    let progressionRate: Double // kg per month
    let milestones: [(weight: Double, date: Date)]
    let consistency: Double // 0-100%
}

struct PRPrediction {
    let exercise: String
    let currentWeight: Double
    let nextMilestone: Double
    let incrementNeeded: Double
    let estimatedTimeInDays: Int
    let predictedDate: Date
    let confidence: Double // 0-100%
}