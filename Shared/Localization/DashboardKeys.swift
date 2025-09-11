import Foundation

/// Dashboard feature localization keys
enum DashboardKeys {
    static let title = "dashboard.title"
    static let welcome = "dashboard.welcome"
    static let howFeeling = "dashboard.howFeeling"
    static let quickActions = "dashboard.quickActions"
    static let recentWorkouts = "dashboard.recentWorkouts"
    static let thisWeek = "dashboard.thisWeek"
    static let seeAll = "dashboard.seeAll"
    
    enum Greeting {
        static let goodMorning = "dashboard.greeting.goodMorning"
        static let goodAfternoon = "dashboard.greeting.goodAfternoon"
        static let goodEvening = "dashboard.greeting.goodEvening"
        static let goodNight = "dashboard.greeting.goodNight"
    }
    
    enum Stats {
        static let today = "dashboard.stats.today"
        static let steps = "dashboard.stats.steps"
        static let calories = "dashboard.stats.calories"
        static let kcal = "dashboard.stats.kcal"
        static let weight = "dashboard.stats.weight"
        static let lastMeasurement = "dashboard.stats.lastMeasurement"
        static let bmi = "dashboard.stats.bmi"
        static let consumed = "dashboard.stats.consumed"
    }
    
    enum Actions {
        static let startWorkout = "dashboard.actions.startWorkout"
        static let startWorkoutDesc = "dashboard.actions.startWorkout.desc"
        static let logWeight = "dashboard.actions.logWeight"
        static let logWeightDesc = "dashboard.actions.logWeight.desc"
        static let nutrition = "dashboard.actions.nutrition"
        static let nutritionDesc = "dashboard.actions.nutrition.desc"
    }
    
    enum NoWorkouts {
        static let title = "dashboard.noWorkouts.title"
        static let subtitle = "dashboard.noWorkouts.subtitle"
    }
    
    // Legacy support for existing code
    enum EmptyState {
        static let noWorkoutsTitle = "dashboard.noWorkouts.title"
        static let noWorkoutsSubtitle = "dashboard.noWorkouts.subtitle"
    }
    
    enum Weekly {
        static let workoutCount = "dashboard.weekly.workoutCount"
        static let totalVolume = "dashboard.weekly.totalVolume"
        static let totalTime = "dashboard.weekly.totalTime"
    }
    
    enum Workout {
        static let defaultName = "dashboard.workout.defaultName"
        static let duration = "dashboard.workout.duration"
        static let volume = "dashboard.workout.volume"
    }
    
    // Legacy support for WorkoutCard
    enum WorkoutCard {
        static let defaultName = "dashboard.workout.defaultName"
        static let duration = "dashboard.workout.duration"
        static let volume = "dashboard.workout.volume"
    }
    
    enum WeightEntry {
        static let title = "dashboard.weightEntry.title"
        static let label = "dashboard.weightEntry.label"
        static let placeholder = "dashboard.weightEntry.placeholder"
        static let save = "dashboard.weightEntry.save"
        static let cancel = "dashboard.weightEntry.cancel"
    }
    
    enum Time {
        static let hours = "dashboard.time.hours"
        static let minutes = "dashboard.time.minutes"
    }

    enum HealthKit {
        static let infoTitle = "dashboard.healthkit.infoTitle"
        static let stepsInfoMessage = "dashboard.healthkit.stepsInfoMessage"
        static let caloriesInfoMessage = "dashboard.healthkit.caloriesInfoMessage"
    }

    enum HealthPermission {
        static let message = "dashboard.healthPermission.message"
        static let allow = "dashboard.healthPermission.allow"
    }
    
    enum QuickStatus {
        static let weeklyVolume = "dashboard.quickStatus.weeklyVolume"
        static let weeklyDistance = "dashboard.quickStatus.weeklyDistance"
        static let dailyCalories = "dashboard.quickStatus.dailyCalories"
        
        // Temporal display modes
        static let todayVolume = "dashboard.quickStatus.todayVolume"
        static let todayDistance = "dashboard.quickStatus.todayDistance"
        static let todayCalories = "dashboard.quickStatus.todayCalories"
        static let weeklyAverage = "dashboard.quickStatus.weeklyAverage"
        static let monthlyAverage = "dashboard.quickStatus.monthlyAverage"
    }
    
    enum Activities {
        static let title = "dashboard.activities.title"
        static let seeAll = "dashboard.activities.seeAll"
        static let empty = "dashboard.activities.empty"
        static let emptyDesc = "dashboard.activities.empty.desc"
        static let today = "dashboard.activities.today"
        static let yesterday = "dashboard.activities.yesterday"
        static let thisWeek = "dashboard.activities.thisWeek"
        static let activity = "dashboard.activities.activity"
        static let moreActivities = "dashboard.activities.moreActivities"
        static let startWorkout = "dashboard.activities.startWorkout"
        static let logNutrition = "dashboard.activities.logNutrition"
        static let logWeight = "dashboard.activities.logWeight"
        static let close = "dashboard.activities.close"
        
        // All Activities View
        static let allActivitiesTitle = "dashboard.activities.allActivitiesTitle"
        static let filterAll = "dashboard.activities.filterAll"
        static let filterWorkouts = "dashboard.activities.filterWorkouts"
        static let filterNutrition = "dashboard.activities.filterNutrition"
        static let filterMeasurements = "dashboard.activities.filterMeasurements"
        static let searchPlaceholder = "dashboard.activities.searchPlaceholder"
        static let totalActivities = "dashboard.activities.totalActivities"
        static let thisWeekStats = "dashboard.activities.thisWeekStats"
        static let noResultsTitle = "dashboard.activities.noResultsTitle"
        static let noResultsDesc = "dashboard.activities.noResultsDesc"
        static let clearFilters = "dashboard.activities.clearFilters"
        
        // Time Formatting
        static let inTheFuture = "dashboard.activities.inTheFuture"
        static let justNow = "dashboard.activities.justNow"
        static let oneMinuteAgo = "dashboard.activities.oneMinuteAgo"
        static let minutesAgo = "dashboard.activities.minutesAgo"
        static let oneHourAgo = "dashboard.activities.oneHourAgo"
        static let hoursAgo = "dashboard.activities.hoursAgo"
        
        // Activity Types
        static let workoutCompleted = "dashboard.activities.workoutCompleted"
        static let cardioCompleted = "dashboard.activities.cardioCompleted"
        static let wodCompleted = "dashboard.activities.wodCompleted"
        static let personalRecord = "dashboard.activities.personalRecord"
        static let nutritionLogged = "dashboard.activities.nutritionLogged"
        static let mealCompleted = "dashboard.activities.mealCompleted"
        static let calorieGoalReached = "dashboard.activities.calorieGoalReached"
        static let measurement = "dashboard.activities.measurement"
        static let measurementUpdated = "dashboard.activities.measurementUpdated"
        static let weightUpdated = "dashboard.activities.weightUpdated"
        static let bodyFatUpdated = "dashboard.activities.bodyFatUpdated"
        static let goal = "dashboard.activities.goal"
        static let goalCompleted = "dashboard.activities.goalCompleted"
        static let streakMilestone = "dashboard.activities.streakMilestone"
        static let weeklyGoalReached = "dashboard.activities.weeklyGoalReached"
        static let stepsGoalReached = "dashboard.activities.stepsGoalReached"
        static let healthDataSynced = "dashboard.activities.healthDataSynced"
        static let sleepLogged = "dashboard.activities.sleepLogged"
        static let programStarted = "dashboard.activities.programStarted"
        static let programCompleted = "dashboard.activities.programCompleted"
        static let planUpdated = "dashboard.activities.planUpdated"
        static let strengthTestCompleted = "dashboard.activities.strengthTestCompleted"
        static let setting = "dashboard.activities.setting"
        static let settingsUpdated = "dashboard.activities.settingsUpdated"
        static let profileUpdated = "dashboard.activities.profileUpdated"
        static let unitSystemChanged = "dashboard.activities.unitSystemChanged"
        static let wodPR = "dashboard.activities.wodPR"
        
        // Contextual Empty State Messages
        static let weekendTitle = "dashboard.activities.weekend.title"
        static let morningTitle = "dashboard.activities.morning.title"
        static let afternoonTitle = "dashboard.activities.afternoon.title"
        static let eveningTitle = "dashboard.activities.evening.title"
        static let nightTitle = "dashboard.activities.night.title"
        
        static let weekendDesc = "dashboard.activities.weekend.desc"
        static let morningDesc = "dashboard.activities.morning.desc"
        static let afternoonDesc = "dashboard.activities.afternoon.desc"
        static let eveningDesc = "dashboard.activities.evening.desc"
        static let nightDesc = "dashboard.activities.night.desc"
        
        // Motivational messages
        static let morningMotivation = "dashboard.activities.morningMotivation"
        static let afternoonMotivation = "dashboard.activities.afternoonMotivation"
        static let eveningMotivation = "dashboard.activities.eveningMotivation"
        static let weekendMotivation = "dashboard.activities.weekendMotivation"
        static let nightMotivation = "dashboard.activities.nightMotivation"
        
        // ActivityLoggerService Support
        static let goalAchieved = "dashboard.activities.goalAchieved"
        static let personalRecordTitle = "dashboard.activities.personalRecordTitle"
        static let newProgramStarted = "dashboard.activities.newProgramStarted"
        static let roundsFormat = "dashboard.activities.roundsFormat"
        static let completed = "dashboard.activities.completed"
    }
    
    enum Profile {
        static let height = "dashboard.profile.height"
        static let weight = "dashboard.profile.weight"
        static let bodyFat = "dashboard.profile.bodyFat"
        static let strengthLevel = "dashboard.profile.strengthLevel"
        static let takeTest = "dashboard.profile.takeTest"
        static let testHint = "dashboard.profile.testHint"
        static let profileMetrics = "dashboard.profile.profileMetrics"
    }
    
    enum QuickActions {
        // Legacy support for existing code
        static let lift = "dashboard.quickActions.lift"
        static let cardio = "dashboard.quickActions.cardio"
        static let calories = "dashboard.quickActions.calories"
        static let quickStatus = "dashboard.quickActions.quickStatus"
    }
    
    enum StrengthLevels {
        static let beginner = "dashboard.strengthLevels.beginner"
        static let novice = "dashboard.strengthLevels.novice"
        static let intermediate = "dashboard.strengthLevels.intermediate"
        static let advanced = "dashboard.strengthLevels.advanced"
        static let expert = "dashboard.strengthLevels.expert"
        static let elite = "dashboard.strengthLevels.elite"
        static let beginnerShort = "dashboard.strengthLevels.beginnerShort"
        static let noviceShort = "dashboard.strengthLevels.noviceShort"
        static let intermediateShort = "dashboard.strengthLevels.intermediateShort"
        static let advancedShort = "dashboard.strengthLevels.advancedShort"
        static let expertShort = "dashboard.strengthLevels.expertShort"
        static let eliteShort = "dashboard.strengthLevels.eliteShort"
    }
    
    enum General {
        static let comingSoon = "dashboard.general.comingSoon"
        static let tapForDetails = "dashboard.general.tapForDetails"
        static let sectionLabel = "dashboard.general.sectionLabel"
        static let streakLabel = "dashboard.general.streakLabel"
    }
    
    enum Meals {
        static let breakfast = "dashboard.meals.breakfast"
        static let lunch = "dashboard.meals.lunch"
        static let dinner = "dashboard.meals.dinner"
        static let snack = "dashboard.meals.snack"
        static let meal = "dashboard.meals.meal"
    }
}