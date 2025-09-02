import SwiftData
import Foundation

/**
 * ActivityLoggerService - Core activity tracking service
 * 
 * Handles automatic activity logging, data validation, and cleanup.
 * Integrates with all major app components to track user activities.
 */
@MainActor
class ActivityLoggerService: ObservableObject {
    
    // MARK: - Properties
    private var modelContext: ModelContext?
    private let maxRetentionDays = 30
    private let unitSettings = UnitSettings.shared
    
    // MARK: - Singleton
    static let shared = ActivityLoggerService()
    private init() {}
    
    // MARK: - Configuration
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Core Logging Methods
    
    /**
     * Logs a workout completion activity
     */
    func logWorkoutCompleted(
        workoutType: String,
        duration: TimeInterval,
        volume: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        user: User?
    ) {
        let activity = ActivityEntry.workoutCompleted(
            workoutType: workoutType,
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs a cardio session completion
     */
    func logCardioCompleted(
        activityType: String,
        distance: Double,
        duration: TimeInterval,
        calories: Double? = nil,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.distance = distance
        metadata.duration = duration
        metadata.calories = calories
        
        let subtitle = ActivityFormatter.cardioSubtitle(
            distance: distance,
            duration: duration,
            calories: calories
        )
        
        let activity = ActivityEntry(
            type: ActivityType.cardioCompleted,
            title: activityType,
            subtitle: subtitle,
            icon: "figure.run",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs meal completion with multiple food items
     */
    func logMealCompleted(
        mealType: String,
        foodCount: Int,
        totalCalories: Double,
        totalProtein: Double,
        totalCarbs: Double,
        totalFat: Double,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.calories = totalCalories
        metadata.protein = totalProtein
        metadata.carbs = totalCarbs
        metadata.fat = totalFat
        
        _ = ActivityFormatter.mealSubtitle(
            foodCount: foodCount,
            calories: totalCalories
        )
        
        let activity = ActivityEntry.mealCompleted(
            mealType: mealType,
            foodCount: foodCount,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs individual nutrition entry (deprecated - use logMealCompleted instead)
     */
    func logNutritionEntry(
        mealType: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        user: User?
    ) {
        // Individual nutrition logging - consider deprecating in favor of meal-based logging
        let activity = ActivityEntry.nutritionLogged(
            mealType: mealType,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs measurement update
     */
    func logMeasurementUpdate(
        measurementType: String,
        value: Double,
        previousValue: Double? = nil,
        unit: String,
        user: User?
    ) {
        let activity = ActivityEntry.measurementUpdated(
            measurementType: measurementType,
            value: value,
            previousValue: previousValue,
            unit: unit,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs goal completion
     */
    func logGoalCompleted(
        goalName: String,
        targetValue: Double,
        currentValue: Double,
        user: User?
    ) {
        let metadata = ActivityMetadata.goal(
            goalName: goalName,
            targetValue: targetValue,
            currentValue: currentValue,
            isCompleted: true
        )
        
        let activity = ActivityEntry(
            type: ActivityType.goalCompleted,
            title: goalName,
            subtitle: DashboardKeys.Activities.goalAchieved.localized,
            icon: "checkmark.circle.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs personal record achievement
     */
    func logPersonalRecord(
        exerciseName: String,
        newValue: Double,
        previousValue: Double?,
        unit: String,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.value = newValue
        metadata.previousValue = previousValue
        metadata.unit = unit
        
        let subtitle = ActivityFormatter.personalRecordSubtitle(
            newValue: newValue,
            previousValue: previousValue,
            unit: unit
        )
        
        let activity = ActivityEntry(
            type: ActivityType.personalRecord,
            title: String(format: DashboardKeys.Activities.personalRecordTitle.localized, exerciseName),
            subtitle: subtitle,
            icon: "trophy.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs program start
     */
    func logProgramStarted(
        programName: String,
        programType: String,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.programName = programName
        metadata.customData = ["program_type": programType]
        
        let activity = ActivityEntry(
            type: ActivityType.programStarted,
            title: DashboardKeys.Activities.newProgramStarted.localized,
            subtitle: programName,
            icon: "play.circle.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs WOD completion
     */
    func logWODCompleted(
        wodName: String,
        wodType: String,
        totalTime: Int? = nil,
        rounds: Int? = nil,
        extraReps: Int? = nil,
        isRX: Bool = false,
        isPR: Bool = false,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        if let totalTime = totalTime {
            metadata.duration = TimeInterval(totalTime)
        }
        metadata.customData = [
            "wod_name": wodName,
            "wod_type": wodType,
            "rounds": rounds?.description ?? "",
            "extra_reps": extraReps?.description ?? "",
            "is_rx": isRX.description,
            "is_pr": isPR.description
        ]
        
        var subtitle: String
        if let totalTime = totalTime {
            let minutes = totalTime / 60
            let seconds = totalTime % 60
            subtitle = String(format: "%02d:%02d", minutes, seconds)
        } else if let rounds = rounds {
            subtitle = String(format: DashboardKeys.Activities.roundsFormat.localized, rounds)
            if let extraReps = extraReps, extraReps > 0 {
                subtitle += " + \(extraReps)"
            }
        } else {
            subtitle = DashboardKeys.Activities.completed.localized
        }
        
        let title = isPR ? String(format: DashboardKeys.Activities.wodPR.localized, wodName) : String(format: DashboardKeys.Activities.wodCompleted.localized, wodName)
        let activityType: ActivityType = isPR ? .personalRecord : .wodCompleted
        
        let activity = ActivityEntry(
            type: activityType,
            title: title,
            subtitle: subtitle,
            icon: isPR ? "trophy.fill" : "flame.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs strength test completion
     */
    func logStrengthTestCompleted(
        exerciseCount: Int,
        averageStrengthLevel: String,
        totalScore: Double,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.customData = [
            "exercise_count": "\(exerciseCount)",
            "average_strength_level": averageStrengthLevel,
            "total_score": "\(totalScore)"
        ]
        
        let subtitle = "\(exerciseCount) hareket | \(averageStrengthLevel) seviye"
        
        let activity = ActivityEntry(
            type: ActivityType.strengthTestCompleted,
            title: "Kuvvet testi tamamlandı",
            subtitle: subtitle,
            icon: "chart.bar.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs settings update
     */
    func logSettingsUpdate(
        settingName: String,
        oldValue: String,
        newValue: String,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.customData = [
            "setting_name": settingName,
            "old_value": oldValue,
            "new_value": newValue
        ]
        
        let subtitle = "\(oldValue) → \(newValue)"
        
        let activity = ActivityEntry(
            type: ActivityType.settingsUpdated,
            title: settingName,
            subtitle: subtitle,
            icon: "gear",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs program started activity
     */
    func logProgramStarted(
        programName: String,
        weeks: Int,
        daysPerWeek: Int,
        user: User?
    ) {
        let activity = ActivityEntry.programStarted(
            programName: programName,
            duration: "\(weeks) hafta",
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs program completion
     */
    func logProgramCompleted(
        programName: String,
        totalWorkouts: Int,
        weekCount: Int,
        user: User?
    ) {
        let activity = ActivityEntry.programCompleted(
            programName: programName,
            duration: "\(weekCount) hafta",
            totalWorkouts: totalWorkouts,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs strength test completion
     */
    func logStrengthTestCompleted(
        overallScore: Double,
        strengthLevel: String,
        user: User?
    ) {
        let activity = ActivityEntry.strengthTestCompleted(
            overallScore: overallScore,
            strengthLevel: strengthLevel,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs weekly goal achievement
     */
    func logWeeklyGoalReached(
        goalType: String,
        targetValue: Double,
        actualValue: Double,
        unit: String,
        user: User?
    ) {
        let metadata = ActivityMetadata.goal(
            goalName: goalType,
            targetValue: targetValue,
            currentValue: actualValue,
            isCompleted: true
        )
        
        let activity = ActivityEntry(
            type: ActivityType.weeklyGoalReached,
            title: "Haftalık hedef başarıldı!",
            subtitle: "\(goalType): \(String(format: "%.1f", actualValue)) \(unit)",
            icon: "calendar.badge.checkmark",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs streak milestone achievement
     */
    func logStreakMilestone(
        streakCount: Int,
        streakType: String,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.customData = [
            "streak_count": "\(streakCount)",
            "streak_type": streakType
        ]
        
        let activity = ActivityEntry(
            type: ActivityType.streakMilestone,
            title: "\(streakCount) günlük seri!",
            subtitle: "\(streakType) streği devam ediyor 🔥",
            icon: "flame.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs steps goal achievement
     */
    func logStepsGoalReached(
        stepCount: Int,
        goalSteps: Int,
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.stepCount = stepCount
        metadata.customData = ["goal_steps": "\(goalSteps)"]
        
        let activity = ActivityEntry(
            type: ActivityType.stepsGoalReached,
            title: "Adım hedefi başarıldı!",
            subtitle: "\(stepCount.formatted()) adım",
            icon: "figure.walk",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    /**
     * Logs HealthKit data sync
     */
    func logHealthDataSynced(
        dataTypes: [String],
        user: User?
    ) {
        let metadata = ActivityMetadata()
        metadata.customData = ["synced_types": dataTypes.joined(separator: ", ")]
        
        let activity = ActivityEntry(
            type: ActivityType.healthDataSynced,
            title: "Sağlık verileri senkronize edildi",
            subtitle: "\(dataTypes.count) veri türü güncellendi",
            icon: "heart.fill",
            metadata: metadata,
            user: user
        )
        saveActivity(activity)
    }
    
    // MARK: - Public Helper Method for Direct Activity Saving
    
    /**
     * Public method to save activities directly (for custom activities)
     */
    func saveActivityDirectly(_ activity: ActivityEntry) {
        saveActivity(activity)
    }
    
    // MARK: - Data Management
    
    /**
     * Fetches recent activities for dashboard
     */
    func fetchRecentActivities(limit: Int = 10, for user: User?) -> [ActivityEntry] {
        guard let modelContext = modelContext else { return [] }
        
        // Simplified predicate to avoid compiler issues
        let descriptor = FetchDescriptor<ActivityEntry>(
            sortBy: [SortDescriptor(\ActivityEntry.timestamp, order: .reverse)]
        )
        
        do {
            let allActivities = try modelContext.fetch(descriptor)
            
            // Manual filtering for better performance and compatibility
            let filteredActivities = allActivities.filter { activity in
                !activity.isArchived && activity.user?.id == user?.id
            }
            
            return Array(filteredActivities.prefix(limit))
        } catch {
            print("Error fetching activities: \(error)")
            return []
        }
    }
    
    /**
     * Fetches activities grouped by date
     */
    func fetchGroupedActivities(for user: User?) -> [String: [ActivityEntry]] {
        let activities = fetchRecentActivities(limit: 50, for: user)
        let calendar = Calendar.current
        let now = Date()
        
        var grouped: [String: [ActivityEntry]] = [:]
        
        for activity in activities {
            let dateKey: String
            
            if calendar.isDateInToday(activity.timestamp) {
                dateKey = DashboardKeys.Activities.today.localized
            } else if calendar.isDateInYesterday(activity.timestamp) {
                dateKey = DashboardKeys.Activities.yesterday.localized
            } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(activity.timestamp) == true {
                dateKey = DashboardKeys.Activities.thisWeek.localized
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                dateKey = formatter.string(from: activity.timestamp)
            }
            
            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(activity)
        }
        
        return grouped
    }
    
    /**
     * Performs cleanup of old activities
     */
    func performCleanup() {
        guard let modelContext = modelContext else { return }
        
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -maxRetentionDays,
            to: Date()
        ) ?? Date()
        
        let descriptor = FetchDescriptor<ActivityEntry>()
        
        do {
            let allActivities = try modelContext.fetch(descriptor)
            
            // Manual filtering for cleanup
            let oldActivities = allActivities.filter { activity in
                activity.timestamp < cutoffDate
            }
            
            for activity in oldActivities {
                modelContext.delete(activity)
            }
            try modelContext.save()
            print("Cleaned up \(oldActivities.count) old activities")
        } catch {
            print("Error during cleanup: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func saveActivity(_ activity: ActivityEntry) {
        guard let modelContext = modelContext else {
            print("ModelContext not set - cannot save activity")
            return
        }
        
        // Check for duplicates (prevent spam)
        if isDuplicateActivity(activity) {
            print("Duplicate activity detected, skipping save")
            return
        }
        
        do {
            modelContext.insert(activity)
            try modelContext.save()
            
            // Notify UI for real-time refresh
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .activityLogged, object: nil)
            }
        } catch {
            print("Error saving activity: \(error)")
        }
    }
    
    private func isDuplicateActivity(_ newActivity: ActivityEntry) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        // Check for identical activities in the last 5 minutes
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        
        let descriptor = FetchDescriptor<ActivityEntry>(
            sortBy: [SortDescriptor(\ActivityEntry.timestamp, order: .reverse)]
        )
        
        do {
            let recentActivities = try modelContext.fetch(descriptor)
            
            // Manual filtering for duplicates
            let similarActivities = recentActivities.filter { activity in
                activity.timestamp > fiveMinutesAgo &&
                activity.type == newActivity.type &&
                activity.title == newActivity.title &&
                activity.user?.id == newActivity.user?.id
            }
            
            return !similarActivities.isEmpty
        } catch {
            return false
        }
    }
}
