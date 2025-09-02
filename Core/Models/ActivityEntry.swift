import SwiftData
import Foundation

/**
 * ActivityEntry - User activity tracking model
 * 
 * Tracks all user activities in the app including workouts, nutrition,
 * measurements, goals, and system events for the dashboard activity feed.
 */
@Model
final class ActivityEntry {
    // MARK: - Core Properties
    var timestamp: Date
    var type: String  // Store as string for SwiftData compatibility
    var title: String
    var subtitle: String?
    var icon: String
    
    // MARK: - Metadata
    var metadata: ActivityMetadata
    var isArchived: Bool = false
    
    // MARK: - Relations
    var user: User?
    
    // MARK: - Computed Properties
    var typeEnum: ActivityType {
        return ActivityType(rawValue: type) ?? .workoutCompleted
    }
    
    var timeAgo: String {
        ActivityTimeFormatter.timeAgo(from: timestamp)
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
        metadata: ActivityMetadata = ActivityMetadata(),
        user: User? = nil
    ) {
        self.timestamp = Date()
        self.type = type.rawValue  // Store as string
        self.title = title
        self.subtitle = subtitle
        self.icon = icon ?? type.defaultIcon
        self.metadata = metadata
        self.user = user
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
            title: "\(mealType) tamamlandı",
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
            ? "Önceki rekor: \(String(format: "%.1f", previousPR!)) \(unit) (+\(String(format: "%.1f", improvement)))"
            : "Yeni rekor: \(String(format: "%.1f", value)) \(unit)"
        
        return ActivityEntry(
            type: ActivityType.personalRecord,
            title: "\(exerciseName) Rekor!",
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
            title: "\(programName) başladı",
            subtitle: "\(duration) sürecek",
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
            title: "\(programName) tamamlandı!",
            subtitle: "\(totalWorkouts) antrenman, \(duration) sürede",
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
            title: "Kuvvet testi tamamlandı",
            subtitle: "Seviye: \(strengthLevel) (\(String(format: "%.0f", overallScore))%)",
            icon: "chart.bar.fill", 
            metadata: metadata,
            user: user
        )
    }
}

// MARK: - Time Formatter Helper

struct ActivityTimeFormatter {
    static func timeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 3600 { // Less than 1 hour
            let minutes = Int(interval / 60)
            return "\(minutes) dk önce"
        } else if interval < 86400 { // Less than 1 day
            let hours = Int(interval / 3600)
            return "\(hours) saat önce"
        } else if Calendar.current.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "dün \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}