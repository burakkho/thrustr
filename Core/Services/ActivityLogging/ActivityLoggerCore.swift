import SwiftData
import Foundation

/**
 * Core activity logging service - handles basic activity recording.
 *
 * Responsibilities:
 * - Activity creation and validation
 * - Basic activity logging operations
 * - Data model management
 */
@MainActor
struct ActivityLoggerCore {

    // MARK: - Core Logging Methods

    /**
     * Logs a workout completion activity.
     */
    static func logWorkoutCompleted(
        workoutType: String,
        duration: TimeInterval,
        volume: Double? = nil,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.workoutCompleted(
            workoutType: workoutType,
            duration: duration,
            volume: volume,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("✅ Logged workout completion: \(workoutType)")
    }

    /**
     * Logs a WOD completion activity.
     */
    static func logWODCompleted(
        wodName: String,
        wodType: String,
        totalTime: TimeInterval,
        rounds: Int,
        extraReps: Int,
        isPR: Bool,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.wodCompleted(
            wodName: wodName,
            wodType: wodType,
            totalTime: totalTime,
            rounds: rounds,
            extraReps: extraReps,
            isPR: isPR,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("✅ Logged WOD completion: \(wodName)")
    }

    /**
     * Logs a cardio session completion.
     */
    static func logCardioCompleted(
        activityType: String,
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.cardioCompleted(
            exerciseType: activityType,
            distance: distance,
            duration: duration,
            calories: calories,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("✅ Logged cardio completion: \(activityType)")
    }

    /**
     * Logs a nutrition entry.
     */
    static func logNutritionEntry(
        foodName: String,
        calories: Double,
        meal: String,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.nutritionLogged(
            mealType: meal,
            calories: calories,
            protein: 0, // Default values since not provided
            carbs: 0,
            fat: 0,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("✅ Logged nutrition entry: \(foodName)")
    }

    /**
     * Logs a new PR achievement.
     */
    static func logNewPR(
        exerciseName: String,
        newRecord: Double,
        previousRecord: Double?,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.personalRecord(
            exerciseName: exerciseName,
            value: newRecord,
            unit: "kg",
            previousPR: previousRecord,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("🏆 Logged new PR: \(exerciseName) - \(newRecord)")
    }

    /**
     * Logs weight tracking entry.
     */
    static func logWeightEntry(
        weight: Double,
        user: User,
        modelContext: ModelContext
    ) {
        let activity = ActivityEntry.measurementUpdated(
            measurementType: "Weight",
            value: weight,
            previousValue: nil,
            unit: "kg",
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("⚖️ Logged weight entry: \(weight) kg")
    }

    /**
     * Logs program start activity.
     */
    static func logProgramStarted(
        programName: String,
        weeks: Int,
        daysPerWeek: Int,
        user: User,
        modelContext: ModelContext
    ) {
        let duration = "\(weeks) hafta, \(daysPerWeek) gün/hafta"
        let activity = ActivityEntry.programStarted(
            programName: programName,
            duration: duration,
            user: user
        )

        saveActivity(activity, modelContext: modelContext)
        Logger.info("🚀 Logged program start: \(programName)")
    }

    // MARK: - Helper Methods

    /**
     * Saves activity to SwiftData context.
     */
    private static func saveActivity(_ activity: ActivityEntry, modelContext: ModelContext) {
        do {
            modelContext.insert(activity)
            try modelContext.save()
        } catch {
            Logger.error("Failed to save activity: \(error)")
        }
    }

}