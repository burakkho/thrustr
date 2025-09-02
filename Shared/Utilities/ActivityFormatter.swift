import Foundation

/**
 * ActivityFormatter - Activity display formatting utilities
 * 
 * Provides consistent formatting for different activity types,
 * handles localization and unit conversions for the activity feed.
 */
struct ActivityFormatter {
    
    // MARK: - Nutrition Formatting
    
    static func mealSubtitle(
        foodCount: Int,
        calories: Double
    ) -> String {
        var components: [String] = []
        
        // Add food count
        if foodCount == 1 {
            components.append(DashboardKeys.Activities.oneFood.localized)
        } else {
            components.append(String(format: DashboardKeys.Activities.multipleFood.localized, foodCount))
        }
        
        // Add calories
        components.append(formatCalories(calories))
        
        return components.joined(separator: " | ")
    }
    
    // MARK: - Workout Formatting
    
    static func workoutSubtitle(
        duration: TimeInterval,
        volume: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil
    ) -> String {
        var components: [String] = []
        
        // Add sets info if available
        if let sets = sets {
            if let totalReps = reps {
                components.append("\(sets) set | \(totalReps) reps")
            } else {
                components.append("\(sets) set")
            }
        }
        
        // Add volume if available
        if let volume = volume {
            components.append(formatVolume(volume))
        }
        
        // Add duration
        components.append(formatDuration(duration))
        
        return components.joined(separator: " | ")
    }
    
    static func cardioSubtitle(
        distance: Double,
        duration: TimeInterval,
        calories: Double? = nil
    ) -> String {
        var components: [String] = []
        
        // Add distance
        components.append(formatDistance(distance))
        
        // Add duration  
        components.append(formatDuration(duration))
        
        // Add calories if available
        if let calories = calories {
            components.append("\(Int(calories)) cal")
        }
        
        return components.joined(separator: " | ")
    }
    
    // MARK: - Nutrition Formatting
    
    static func nutritionSubtitle(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) -> String {
        return "\(Int(calories)) cal | \(Int(protein))g P | \(Int(carbs))g C | \(Int(fat))g F"
    }
    
    // MARK: - Measurement Formatting
    
    static func measurementSubtitle(
        value: Double,
        previousValue: Double? = nil,
        unit: String
    ) -> String {
        let currentValueStr = formatMeasurementValue(value, unit: unit)
        
        if let prev = previousValue {
            let prevValueStr = formatMeasurementValue(prev, unit: unit)
            let change = value - prev
            let changeStr = change >= 0 ? "+\(formatMeasurementValue(abs(change), unit: unit))" : "-\(formatMeasurementValue(abs(change), unit: unit))"
            return "\(prevValueStr) → \(currentValueStr) (\(changeStr))"
        } else {
            return currentValueStr
        }
    }
    
    static func personalRecordSubtitle(
        newValue: Double,
        previousValue: Double?,
        unit: String
    ) -> String {
        let newValueStr = formatMeasurementValue(newValue, unit: unit)
        
        if let prev = previousValue {
            let prevValueStr = formatMeasurementValue(prev, unit: unit)
            return "\(newValueStr) (previous: \(prevValueStr))"
        } else {
            return newValueStr
        }
    }
    
    // MARK: - Goal Formatting
    
    static func goalProgressSubtitle(
        current: Double,
        target: Double,
        unit: String? = nil
    ) -> String {
        let percentage = min((current / target) * 100, 100)
        
        if let unit = unit {
            return "\(formatMeasurementValue(current, unit: unit))/\(formatMeasurementValue(target, unit: unit)) (\(Int(percentage))%)"
        } else {
            return "\(Int(current))/\(Int(target)) (\(Int(percentage))%)"
        }
    }
    
    // MARK: - Time Formatting
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)\(CommonKeys.TimeFormatting.hoursShort.localized) \(minutes)\(CommonKeys.TimeFormatting.minutesShort.localized)"
        } else {
            return "\(minutes)\(CommonKeys.TimeFormatting.minutesShort.localized)"
        }
    }
    
    static func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return CommonKeys.TimeFormatting.now.localized
        } else if interval < 3600 { // Less than 1 hour
            let minutes = Int(interval / 60)
            return String(format: CommonKeys.TimeFormatting.minutesAgo.localized, minutes)
        } else if interval < 86400 { // Less than 1 day
            let hours = Int(interval / 3600)
            return String(format: CommonKeys.TimeFormatting.hoursAgo.localized, hours)
        } else if Calendar.current.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return String(format: CommonKeys.TimeFormatting.yesterday.localized, formatter.string(from: date))
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Volume & Weight Formatting
    
    private static func formatVolume(_ volume: Double, system: UnitSystem = .metric) -> String {
        if volume >= 1000 {
            return String(format: "%.1ft", volume / 1000)
        } else {
            return UnitsFormatter.formatVolume(kg: volume, system: system)
        }
    }
    
    private static func formatDistance(_ distance: Double, system: UnitSystem = .metric) -> String {
        return UnitsFormatter.formatDistance(meters: distance, system: system)
    }
    
    private static func formatMeasurementValue(_ value: Double, unit: String) -> String {
        let unit = unit.lowercased()
        
        switch unit {
        case "kg", "kilogram":
            return String(format: "%.1f kg", value)
        case "lb", "pound":
            return String(format: "%.1f lb", value)
        case "cm", "centimeter":
            return "\(Int(value))cm"
        case "in", "inch":
            return String(format: "%.1fin", value)
        case "%", "percent":
            return String(format: "%.1f%%", value)
        case "cal", "calorie":
            return "\(Int(value)) cal"
        case "g", "gram":
            return "\(Int(value))g"
        default:
            return String(format: "%.1f \(unit)", value)
        }
    }
    
    // MARK: - Activity Type Localization
    
    static func localizedActivityTitle(
        for activityType: ActivityType,
        context: String? = nil
    ) -> String {
        switch activityType {
        case .workoutCompleted:
            return context ?? DashboardKeys.Activities.workoutCompleted.localized
        case .cardioCompleted:
            return context ?? DashboardKeys.Activities.cardioCompleted.localized
        case .wodCompleted:
            return context ?? DashboardKeys.Activities.wodCompleted.localized
        case .personalRecord:
            return context ?? DashboardKeys.Activities.personalRecord.localized
        case .nutritionLogged:
            return "\(context ?? DashboardKeys.Meals.meal.localized) \(DashboardKeys.Activities.nutritionLogged.localized)"
        case .mealCompleted:
            return context ?? DashboardKeys.Activities.mealCompleted.localized
        case .calorieGoalReached:
            return DashboardKeys.Activities.calorieGoalReached.localized
        case .measurementUpdated:
            return "\(context ?? DashboardKeys.Activities.measurement.localized) \(DashboardKeys.Activities.measurementUpdated.localized)"
        case .weightUpdated:
            return DashboardKeys.Activities.weightUpdated.localized
        case .bodyFatUpdated:
            return DashboardKeys.Activities.bodyFatUpdated.localized
        case .goalCompleted:
            return "\(context ?? DashboardKeys.Activities.goal.localized) \(DashboardKeys.Activities.goalCompleted.localized)"
        case .streakMilestone:
            return DashboardKeys.Activities.streakMilestone.localized
        case .weeklyGoalReached:
            return DashboardKeys.Activities.weeklyGoalReached.localized
        case .stepsGoalReached:
            return DashboardKeys.Activities.stepsGoalReached.localized
        case .healthDataSynced:
            return DashboardKeys.Activities.healthDataSynced.localized
        case .sleepLogged:
            return DashboardKeys.Activities.sleepLogged.localized
        case .programStarted:
            return DashboardKeys.Activities.programStarted.localized
        case .programCompleted:
            return DashboardKeys.Activities.programCompleted.localized
        case .planUpdated:
            return DashboardKeys.Activities.planUpdated.localized
        case .strengthTestCompleted:
            return DashboardKeys.Activities.strengthTestCompleted.localized
        case .settingsUpdated:
            return "\(context ?? DashboardKeys.Activities.setting.localized) \(DashboardKeys.Activities.settingsUpdated.localized)"
        case .profileUpdated:
            return DashboardKeys.Activities.profileUpdated.localized
        case .unitSystemChanged:
            return DashboardKeys.Activities.unitSystemChanged.localized
        }
    }
    
    // MARK: - Meal Type Icons
    
    static func iconForMealType(_ mealType: String) -> String {
        let lowercased = mealType.lowercased()
        
        // Check against localized meal names for all supported languages
        let breakfast = [DashboardKeys.Meals.breakfast.localized.lowercased(), "breakfast", "frühstück", "desayuno"]
        let lunch = [DashboardKeys.Meals.lunch.localized.lowercased(), "lunch", "mittagessen", "almuerzo"]
        let dinner = [DashboardKeys.Meals.dinner.localized.lowercased(), "dinner", "abendessen", "cena"]
        let snack = [DashboardKeys.Meals.snack.localized.lowercased(), "snack", "zwischenmahlzeit", "tentempié"]
        
        if breakfast.contains(lowercased) {
            return "sunrise.fill"
        } else if lunch.contains(lowercased) {
            return "sun.max.fill"
        } else if dinner.contains(lowercased) {
            return "moon.fill"
        } else if snack.contains(lowercased) {
            return "leaf.fill"
        } else {
            return "fork.knife"
        }
    }
    
    // MARK: - Activity Grouping
    
    static func groupActivitiesByDate(_ activities: [ActivityEntry]) -> [(String, [ActivityEntry])] {
        let calendar = Calendar.current
        let now = Date()
        
        struct DateGroup: Hashable {
            let title: String
            let order: Int
        }
        
        // First group nutrition activities
        let processedActivities = groupNutritionActivities(activities)
        
        let grouped = Dictionary(grouping: processedActivities) { activity in
            if calendar.isDateInToday(activity.timestamp) {
                return DateGroup(title: DashboardKeys.Activities.today.localized, order: 0)
            } else if calendar.isDateInYesterday(activity.timestamp) {
                return DateGroup(title: DashboardKeys.Activities.yesterday.localized, order: 1)
            } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(activity.timestamp) == true {
                return DateGroup(title: DashboardKeys.Activities.thisWeek.localized, order: 2)
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return DateGroup(title: formatter.string(from: activity.timestamp), order: 3)
            }
        }
        
        return grouped
            .sorted { $0.key.order < $1.key.order }
            .map { ($0.key.title, $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }
    
    // MARK: - Nutrition Activities Grouping
    
    static func groupNutritionActivities(_ activities: [ActivityEntry]) -> [ActivityEntry] {
        var result: [ActivityEntry] = []
        var processed: Set<String> = []
        
        for activity in activities.sorted(by: { $0.timestamp > $1.timestamp }) {
            // Skip if already processed
            if processed.contains(activity.title + activity.timestamp.description) {
                continue
            }
            
            // Check if this is a nutrition activity
            if activity.typeEnum == .nutritionLogged || activity.typeEnum == .mealCompleted {
                // Find similar nutrition activities on the same day
                let similarActivities = findSimilarNutritionActivities(
                    for: activity,
                    in: activities,
                    sameDay: true
                )
                
                if similarActivities.count > 1 {
                    // Create grouped activity
                    let groupedActivity = createGroupedNutritionActivity(from: similarActivities)
                    result.append(groupedActivity)
                    
                    // Mark all as processed
                    similarActivities.forEach { processedActivity in
                        processed.insert(processedActivity.title + processedActivity.timestamp.description)
                    }
                } else {
                    // Single activity, add as-is
                    result.append(activity)
                    processed.insert(activity.title + activity.timestamp.description)
                }
            } else {
                // Non-nutrition activity, add as-is
                result.append(activity)
                processed.insert(activity.title + activity.timestamp.description)
            }
        }
        
        return result.sorted { $0.timestamp > $1.timestamp }
    }
    
    private static func findSimilarNutritionActivities(
        for activity: ActivityEntry,
        in activities: [ActivityEntry],
        sameDay: Bool
    ) -> [ActivityEntry] {
        let calendar = Calendar.current
        
        return activities.filter { otherActivity in
            let isSameDay = calendar.isDate(activity.timestamp, inSameDayAs: otherActivity.timestamp)
            
            return isSameDay &&
            (otherActivity.typeEnum == .nutritionLogged || otherActivity.typeEnum == .mealCompleted) &&
            otherActivity.title.lowercased() == activity.title.lowercased() &&
            otherActivity.user?.id == activity.user?.id
        }
    }
    
    private static func createGroupedNutritionActivity(from activities: [ActivityEntry]) -> ActivityEntry {
        let latestActivity = activities.max(by: { $0.timestamp < $1.timestamp })!
        let totalCalories = activities.compactMap { $0.metadata.calories }.reduce(0, +)
        let totalProtein = activities.compactMap { $0.metadata.protein }.reduce(0, +)
        let totalCarbs = activities.compactMap { $0.metadata.carbs }.reduce(0, +)
        let totalFat = activities.compactMap { $0.metadata.fat }.reduce(0, +)
        let foodCount = activities.count
        
        let groupedMetadata = ActivityMetadata()
        groupedMetadata.calories = totalCalories
        groupedMetadata.protein = totalProtein
        groupedMetadata.carbs = totalCarbs
        groupedMetadata.fat = totalFat
        groupedMetadata.customData = [
            "grouped_count": "\(foodCount)",
            "is_grouped": "true"
        ]
        
        let subtitle = foodCount > 1 ? 
            "\(foodCount) yiyecek • \(Int(totalCalories)) kcal" :
            "\(Int(totalCalories)) kcal"
        
        let groupedActivity = ActivityEntry(
            type: .mealCompleted,
            title: latestActivity.title,
            subtitle: subtitle,
            icon: latestActivity.icon,
            metadata: groupedMetadata,
            user: latestActivity.user
        )
        groupedActivity.timestamp = latestActivity.timestamp
        
        return groupedActivity
    }
    
    private static func formatCalories(_ calories: Double) -> String {
        return "\(Int(calories)) kcal"
    }
}