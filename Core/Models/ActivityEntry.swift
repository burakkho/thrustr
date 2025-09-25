import SwiftData
import Foundation
// Import required for ActivityTimeFormatter if not automatically resolved
// (The file is in Shared/Utilities/ActivityTimeFormatter.swift)

/**
 * ActivityEntry - User activity tracking model
 * 
 * Tracks all user activities in the app including workouts, nutrition,
 * measurements, goals, and system events for the dashboard activity feed.
 */
@Model
final class ActivityEntry {
    // MARK: - Core Properties
    var timestamp: Date = Date()
    var type: String = "workout_completed"  // Store as string for SwiftData compatibility
    var title: String = ""
    var subtitle: String?
    var icon: String = ""
    var source: String = "manual"  // manual, sync, automatic
    
    // MARK: - Metadata
    var metadata: ActivityMetadata?
    var isArchived: Bool = false
    
    // MARK: - Relations
    var user: User?
    
    // MARK: - Computed Properties
    var typeEnum: ActivityType {
        return ActivityType(rawValue: type) ?? .workoutCompleted
    }
    
    var sourceEnum: ActivitySource {
        return ActivitySource(rawValue: source) ?? .manual
    }
    
    var timeAgoFormatted: String {
        timeAgo
    }
    
    var displayIcon: String {
        return icon.isEmpty ? typeEnum.defaultIcon : icon
    }
    
    // MARK: - Initialization
    init(
        type: ActivityType,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        metadata: ActivityMetadata? = nil,
        user: User? = nil,
        source: ActivitySource = .manual
    ) {
        self.timestamp = Date()
        self.type = type.rawValue  // Store as string
        self.title = title
        self.subtitle = subtitle
        self.icon = icon ?? type.defaultIcon
        self.metadata = metadata
        self.user = user
        self.source = source.rawValue
    }
}

// MARK: - ActivityEntry Extensions

extension ActivityEntry {
    
    /**
     * Creates a workout completion activity entry
     */
    static func workoutCompleted(
        workoutType: String,
        duration: TimeInterval,
        volume: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata.workout(
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps
        )
        
        let subtitle = ActivityFormatter.workoutSubtitle(
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps
        )
        
        return ActivityEntry(
            type: ActivityType.workoutCompleted,
            title: workoutType,
            subtitle: subtitle,
            icon: "dumbbell.fill",
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a nutrition entry activity
     */
    static func nutritionLogged(
        mealType: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata.nutrition(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        let subtitle = ActivityFormatter.nutritionSubtitle(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        return ActivityEntry(
            type: ActivityType.nutritionLogged,
            title: mealType,
            subtitle: subtitle,
            icon: ActivityType.nutritionLogged.iconForMeal(mealType),
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a measurement update activity
     */
    static func measurementUpdated(
        measurementType: String,
        value: Double,
        previousValue: Double? = nil,
        unit: String,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata.measurement(
            value: value,
            previousValue: previousValue,
            unit: unit
        )
        
        let subtitle = ActivityFormatter.measurementSubtitle(
            value: value,
            previousValue: previousValue,
            unit: unit
        )
        
        return ActivityEntry(
            type: ActivityType.measurementUpdated,
            title: measurementType,
            subtitle: subtitle,
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a meal completed activity (grouped nutrition entry)
     */
    static func mealCompleted(
        mealType: String,
        foodCount: Int,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.calories = calories
        metadata.protein = protein
        metadata.carbs = carbs
        metadata.fat = fat
        
        let subtitle = ActivityFormatter.mealSubtitle(
            foodCount: foodCount,
            calories: calories
        )
        
        return ActivityEntry(
            type: ActivityType.mealCompleted,
            title: "\(mealType) \(CommonKeys.Activity.completed.localized)",
            subtitle: subtitle,
            icon: ActivityType.mealCompleted.iconForMeal(mealType),
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a personal record activity
     */
    static func personalRecord(
        exerciseName: String,
        value: Double,
        unit: String = "kg",
        previousPR: Double? = nil,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.value = value
        metadata.previousValue = previousPR
        metadata.unit = unit
        
        let improvement = previousPR != nil ? value - previousPR! : 0
        let subtitle = previousPR != nil 
            ? "\(CommonKeys.Activity.previousRecord.localized) \(String(format: "%.1f", previousPR!)) \(unit) (+\(String(format: "%.1f", improvement)))"
            : "\(CommonKeys.Activity.newRecord.localized) \(String(format: "%.1f", value)) \(unit)"
        
        return ActivityEntry(
            type: ActivityType.personalRecord,
            title: "\(exerciseName) \(CommonKeys.Activity.personalRecord.localized)",
            subtitle: subtitle,
            icon: "trophy.fill",
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a program started activity
     */
    static func programStarted(
        programName: String,
        duration: String,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.programName = programName
        
        return ActivityEntry(
            type: ActivityType.programStarted,
            title: "\(programName) \(CommonKeys.Activity.started.localized)",
            subtitle: "\(duration) \(CommonKeys.Activity.willContinue.localized)",
            icon: "play.circle.fill",
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a program completed activity
     */
    static func programCompleted(
        programName: String,
        duration: String,
        totalWorkouts: Int,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.programName = programName
        
        return ActivityEntry(
            type: ActivityType.programCompleted,
            title: "\(programName) \(CommonKeys.Activity.completed.localized)!",
            subtitle: "\(totalWorkouts) \(CommonKeys.Activity.workoutCount.localized), \(duration) \(CommonKeys.Activity.inDuration.localized)",
            icon: "checkmark.seal.fill",
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a strength test completed activity
     */
    static func strengthTestCompleted(
        overallScore: Double,
        strengthLevel: String,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.value = overallScore
        
        return ActivityEntry(
            type: ActivityType.strengthTestCompleted,
            title: CommonKeys.Activity.strengthTestCompleted.localized,
            subtitle: "\(CommonKeys.Activity.level.localized) \(strengthLevel) (\(String(format: "%.0f", overallScore))%)",
            icon: "chart.bar.fill", 
            metadata: metadata,
            user: user
        )
    }
    
    /**
     * Creates a WOD completed activity
     */
    static func wodCompleted(
        wodName: String,
        wodType: String,
        totalTime: TimeInterval,
        rounds: Int,
        extraReps: Int,
        isPR: Bool,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.duration = totalTime
        metadata.rounds = rounds
        metadata.extraReps = extraReps
        metadata.isPersonalRecord = isPR

        let subtitle = ActivityFormatter.wodSubtitle(
            wodType: wodType,
            totalTime: totalTime,
            rounds: rounds,
            extraReps: extraReps
        )

        return ActivityEntry(
            type: ActivityType.wodCompleted,
            title: "\(wodName) \(CommonKeys.Activity.completed.localized)",
            subtitle: subtitle,
            icon: "timer",
            metadata: metadata,
            user: user
        )
    }

    /**
     * Creates a cardio completed activity
     */
    static func cardioCompleted(
        exerciseType: String,
        distance: Double,
        duration: TimeInterval,
        calories: Double? = nil,
        user: User?
    ) -> ActivityEntry {
        let metadata = ActivityMetadata()
        metadata.distance = distance
        metadata.duration = duration
        metadata.calories = calories
        
        let subtitle = ActivityFormatter.cardioSubtitle(
            distance: distance,
            duration: duration,
            calories: calories
        )
        
        return ActivityEntry(
            type: ActivityType.cardioCompleted,
            title: "\(exerciseType) \(CommonKeys.Activity.completed.localized)",
            subtitle: subtitle,
            icon: "figure.run",
            metadata: metadata,
            user: user
        )
    }
    
}

// MARK: - ActivityTimeFormatter Extension
// Temporary inline implementation to resolve import issues
extension ActivityEntry {
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "Şimdi"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) dk önce"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) sa önce"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Dün"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}

