import SwiftData
import Foundation

/**
 * Activity tracking enums and metadata structures
 * 
 * Defines all activity types, their metadata structures,
 * and formatting helpers for the activity feed system.
 */

// MARK: - ActivityType Enum

// MARK: - ActivityType Enum

enum ActivityType: String, CaseIterable {
        // Workout Activities
        case workoutCompleted = "workout_completed"
        case cardioCompleted = "cardio_completed" 
        case wodCompleted = "wod_completed"
        case personalRecord = "personal_record"
        
        // Nutrition Activities
        case nutritionLogged = "nutrition_logged"
        case mealCompleted = "meal_completed"
        case calorieGoalReached = "calorie_goal_reached"
        
        // Measurement Activities  
        case measurementUpdated = "measurement_updated"
        case weightUpdated = "weight_updated"
        case bodyFatUpdated = "body_fat_updated"
        
        // Goal & Achievement Activities
        case goalCompleted = "goal_completed"
        case streakMilestone = "streak_milestone"
        case weeklyGoalReached = "weekly_goal_reached"
        
        // Health Integration
        case stepsGoalReached = "steps_goal_reached"
        case healthDataSynced = "health_data_synced"
        case sleepLogged = "sleep_logged"
        
        // Program & Planning
        case programStarted = "program_started"
        case programCompleted = "program_completed"
        case planUpdated = "plan_updated"
        
        // Test Activities
        case strengthTestCompleted = "strength_test_completed"
        
        // Settings & Profile
        case settingsUpdated = "settings_updated"
        case profileUpdated = "profile_updated"
        case unitSystemChanged = "unit_system_changed"
        
        var defaultIcon: String {
            switch self {
            case .workoutCompleted: return "dumbbell.fill"
            case .cardioCompleted: return "figure.run"
            case .wodCompleted: return "flame.fill"
            case .personalRecord: return "trophy.fill"
            case .nutritionLogged: return "fork.knife"
            case .mealCompleted: return "fork.knife.circle"
            case .calorieGoalReached: return "target"
            case .measurementUpdated: return "ruler"
            case .weightUpdated: return "scalemass"
            case .bodyFatUpdated: return "percent"
            case .goalCompleted: return "checkmark.circle.fill"
            case .streakMilestone: return "flame.fill"
            case .weeklyGoalReached: return "calendar.badge.checkmark"
            case .stepsGoalReached: return "figure.walk"
            case .healthDataSynced: return "heart.fill"
            case .sleepLogged: return "bed.double.fill"
            case .programStarted: return "play.circle.fill"
            case .programCompleted: return "checkmark.seal.fill"
            case .planUpdated: return "calendar"
            case .strengthTestCompleted: return "chart.bar.fill"
            case .settingsUpdated: return "gear"
            case .profileUpdated: return "person.circle"
            case .unitSystemChanged: return "slider.horizontal.2.gobackward"
            }
        }
        
        func iconForMeal(_ mealType: String) -> String {
            let lowercased = mealType.lowercased()
            switch lowercased {
            case "kahvaltı", "breakfast": return "sunrise.fill"
            case "öğle yemeği", "lunch": return "sun.max.fill"
            case "akşam yemeği", "dinner": return "moon.fill"
            case "atıştırmalık", "snack": return "leaf.fill"
            default: return "fork.knife"
            }
        }
        
        var priority: Int {
            switch self {
            case .personalRecord: return 10
            case .goalCompleted, .streakMilestone: return 9
            case .workoutCompleted, .cardioCompleted, .wodCompleted: return 8
            case .calorieGoalReached, .weeklyGoalReached: return 7
            case .nutritionLogged, .mealCompleted: return 6
            case .measurementUpdated, .weightUpdated, .bodyFatUpdated: return 5
            case .programStarted, .programCompleted, .strengthTestCompleted: return 4
            case .stepsGoalReached, .healthDataSynced: return 3
            case .sleepLogged, .planUpdated: return 2
            case .settingsUpdated, .profileUpdated, .unitSystemChanged: return 1
            }
        }
    }

// MARK: - ActivitySource Enum

enum ActivitySource: String, CaseIterable {
    case manual = "manual"      // User created activity
    case sync = "sync"          // CloudKit sync created activity  
    case automatic = "automatic" // System created activity (goals, streaks, etc.)
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .sync: return "Synced"
        case .automatic: return "Automatic"
        }
    }
    
    var shouldDisplayInFeed: Bool {
        switch self {
        case .manual, .automatic: return true
        case .sync: return false  // Hide sync-created duplicate activities
        }
    }
}

// MARK: - ActivityMetadata

@Model
final class ActivityMetadata {
    // Workout metadata
    var duration: TimeInterval?
    var volume: Double?
    var sets: Int?
    var reps: Int?
    var distance: Double?
    var calories: Double?
    
    // Nutrition metadata
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var mealType: String?
    
    // Measurement metadata
    var value: Double?
    var previousValue: Double?
    var unit: String?
    var measurementType: String?
    
    // Goal metadata
    var goalName: String?
    var targetValue: Double?
    var currentValue: Double?
    var isCompleted: Bool?
    
    // Program metadata
    var programName: String?
    var weekNumber: Int?
    var dayNumber: Int?
    
    // Health metadata
    var stepCount: Int?
    var heartRate: Int?
    var sleepDuration: TimeInterval?
    
    // Custom metadata
    var customData: [String: String]?
    
    // Relationships
    var activityEntry: ActivityEntry?
    
    init(
        duration: TimeInterval? = nil,
        volume: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        distance: Double? = nil,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        value: Double? = nil,
        previousValue: Double? = nil,
        unit: String? = nil,
        customData: [String: String]? = nil
    ) {
        self.duration = duration
        self.volume = volume
        self.sets = sets
        self.reps = reps
        self.distance = distance
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.value = value
        self.previousValue = previousValue
        self.unit = unit
        self.customData = customData
    }
}

// MARK: - ActivityMetadata Factory Methods

extension ActivityMetadata {
    
    static func workout(
        duration: TimeInterval,
        volume: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil
    ) -> ActivityMetadata {
        return ActivityMetadata(
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps
        )
    }
    
    static func nutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) -> ActivityMetadata {
        return ActivityMetadata(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }
    
    static func measurement(
        value: Double,
        previousValue: Double? = nil,
        unit: String
    ) -> ActivityMetadata {
        return ActivityMetadata(
            value: value,
            previousValue: previousValue,
            unit: unit
        )
    }
    
    static func goal(
        goalName: String,
        targetValue: Double,
        currentValue: Double,
        isCompleted: Bool = false
    ) -> ActivityMetadata {
        let metadata = ActivityMetadata()
        metadata.goalName = goalName
        metadata.targetValue = targetValue
        metadata.currentValue = currentValue
        metadata.isCompleted = isCompleted
        return metadata
    }
}