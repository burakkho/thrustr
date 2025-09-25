import Foundation

/// Profile feature localization keys
enum ProfileKeys {
    static let title = "profile.title"
    static let editProfile = "profile.edit_profile"
    static let personalInfo = "profile.personal_info"
    static let measurements = "profile.measurements"
    static let tools = "profile.tools"
    static let progressReports = "profile.progress_reports"
    static let settings = "profile.settings"
    static let premium = "profile.premium"
    static let help = "profile.help"
    static let logout = "profile.logout"
    static let version = "profile.version"
    
    static let name = "profile.name"
    static let age = "profile.age"
    static let height = "profile.height"
    static let weight = "profile.weight"
    static let gender = "profile.gender"
    static let male = "profile.male"
    static let female = "profile.female"
    static let fitnessGoal = "profile.fitness_goal"
    static let activityLevel = "profile.activity_level"
    
    enum Goal {
        static let cut = "profile.goal.cut"
        static let bulk = "profile.goal.bulk"
        static let maintain = "profile.goal.maintain"
    }
    
    enum Activity {
        static let sedentary = "profile.activity.sedentary"
        static let lightlyActive = "profile.activity.lightly_active"
        static let moderatelyActive = "profile.activity.moderately_active"
        static let veryActive = "profile.activity.very_active"
        static let extremelyActive = "profile.activity.extremely_active"
    }
    
    static let personalInfoSubtitle = "profile.personal_info_subtitle"
    static let accountManagement = "profile.account_management"
    static let accountSubtitle = "profile.account_subtitle"
    static let bodyTracking = "profile.body_tracking"
    static let weightTracking = "profile.weight_tracking"
    static let weightSubtitle = "profile.weight_subtitle"
    static let measurementsSubtitle = "profile.measurements_subtitle"
    static let progressPhotos = "profile.progress_photos"
    static let photosSubtitle = "profile.photos_subtitle"
    static let settingsSubtitle = "profile.settings_subtitle"
    static let progressCharts = "profile.progress_charts"
    static let chartsSubtitle = "profile.charts_subtitle"
    static let achievementsSubtitle = "profile.achievements_subtitle"
    static let goalTracking = "profile.goal_tracking"
    static let goalsSubtitle = "profile.goals_subtitle"
    
    // MARK: - Lifetime Achievements
    enum LifetimeAchievements {
        static let title = "profile.lifetime_achievements.title"
        static let subtitle = "profile.lifetime_achievements.subtitle"
        static let totalWeight = "profile.lifetime_achievements.total_weight"
        static let totalDistance = "profile.lifetime_achievements.total_distance"
        static let totalWorkouts = "profile.lifetime_achievements.total_workouts"
        static let activeDays = "profile.lifetime_achievements.active_days"
    }
    
    // MARK: - Units
    enum Units {
        static let kg = "profile.units.kg"
        static let lb = "profile.units.lb"
        static let tons = "profile.units.tons"
        static let km = "profile.units.km"
        static let mi = "profile.units.mi"
        static let cm = "profile.units.cm"
        static let inch = "profile.units.inch"
        static let percent = "profile.units.percent"
    }
    
    // MARK: - Messages
    enum Messages {
        static let measurementsSaved = "profile.messages.measurements_saved"
        static let measurementsSavedDesc = "profile.messages.measurements_saved_desc"
        static let calculationError = "profile.messages.calculation_error"
        static let validationError = "profile.messages.validation_error"
        static let saveError = "profile.messages.save_error"
        static let saveToProfile = "profile.messages.save_to_profile"
    }
    
    // MARK: - Measurement Instructions
    enum MeasurementInstructions {
        static let neck = "profile.instructions.neck"
        static let waistMale = "profile.instructions.waist_male"
        static let waistFemale = "profile.instructions.waist_female"
        static let hip = "profile.instructions.hip"
    }
    
    // MARK: - OneRM Calculator
    enum OneRMCalculator {
        static let title = "profile.oneRM.title"
        static let subtitle = "profile.oneRM.subtitle"
        static let calculate = "profile.oneRM.calculate"
        static let trainingInfo = "profile.oneRM.trainingInfo"
        static let results = "profile.oneRM.results"
        static let about = "profile.oneRM.about"
        static let weightLifted = "profile.oneRM.weightLifted"
        static let repCount = "profile.oneRM.repCount"
        static let calculationFormula = "profile.oneRM.calculationFormula"
        static let oneRMValue = "profile.oneRM.oneRMValue"
        static let percentageTable = "profile.oneRM.percentageTable"
        static let safety = "profile.oneRM.safety"
        static let safetyDesc = "profile.oneRM.safetyDesc"
        static let accuracy = "profile.oneRM.accuracy"
        static let accuracyDesc = "profile.oneRM.accuracyDesc"
        static let howToUse = "profile.oneRM.howToUse"
        static let howToUseDesc = "profile.oneRM.howToUseDesc"
    }
    
    // MARK: - Navy Method Calculator
    enum NavyMethodCalculator {
        static let title = "profile.navy.title"
        static let calculate = "profile.navy.calculate"
        static let male = "profile.navy.male"
        static let female = "profile.navy.female"
    }
    
    // MARK: - FFMI Calculator
    enum FFMICalculator {
        static let title = "profile.ffmi.title"
        static let subtitle = "profile.ffmi.subtitle"
        static let calculate = "profile.ffmi.calculate"
        static let measurements = "profile.ffmi.measurements"
        static let results = "profile.ffmi.results"
        static let scale = "profile.ffmi.scale"
        static let about = "profile.ffmi.about"
        static let heightLabel = "profile.ffmi.height"
        static let weightLabel = "profile.ffmi.weight"
        static let weight = "profile.ffmi.weight"
        static let bodyFatLabel = "profile.ffmi.bodyFat"
        static let resultsTitle = "profile.ffmi.resultsTitle"
        static let ffmiScore = "profile.ffmi.score"
        static let ffmiValue = "profile.ffmi.ffmiValue"
        static let ffmiNormalizedScore = "profile.ffmi.normalizedScore"
        static let interpretation = "profile.ffmi.interpretation"
        static let category = "profile.ffmi.category"
        static let leanMass = "profile.ffmi.leanMass"
        static let bodyFatMass = "profile.ffmi.bodyFatMass"
        static let whatIsFFMI = "profile.ffmi.whatIsFFMI"
        static let whatIsFFMIDesc = "profile.ffmi.whatIsFFMIDesc"
        static let naturalLimit = "profile.ffmi.naturalLimit"
        static let naturalLimitDesc = "profile.ffmi.naturalLimitDesc"
        static let targets = "profile.ffmi.targets"
        static let targetsDesc = "profile.ffmi.targetsDesc"
        static let note = "profile.ffmi.note"
        static let noteDesc = "profile.ffmi.noteDesc"
        
        // FFMI Categories
        static let belowAverage = "profile.ffmi.belowAverage"
        static let average = "profile.ffmi.average"
        static let aboveAverage = "profile.ffmi.aboveAverage"
        static let excellent = "profile.ffmi.excellent"
        static let superior = "profile.ffmi.superior"
        static let suspicious = "profile.ffmi.suspicious"
    }
    
    // MARK: - Body Fat Categories
    enum BodyFatCategories {
        static let essential = "profile.bodyFat.essential"
        static let athlete = "profile.bodyFat.athlete"
        static let fitness = "profile.bodyFat.fitness"
        static let average = "profile.bodyFat.average"
        static let obese = "profile.bodyFat.obese"
    }
    
    // MARK: - Fitness Levels
    enum FitnessLevels {
        static let beginner = "profile.fitness.beginner"
        static let intermediate = "profile.fitness.intermediate"
        static let good = "profile.fitness.good"
        static let advanced = "profile.fitness.advanced"
        static let elite = "profile.fitness.elite"
    }
    
    // MARK: - Analytics & Charts
    enum Analytics {
        static let progressAnalytics = "analytics.progress_analytics"
        static let timeRange = "analytics.time_range"
        static let chartType = "analytics.chart_type"
        static let statistics = "analytics.statistics"
        static let insights = "analytics.insights"
        static let weeklyProgress = "analytics.weekly_progress"
        static let averageProgress = "analytics.average_progress"
        static let nextDeadline = "analytics.next_deadline"
        static let completedThisMonth = "analytics.completed_this_month"
        static let successRate = "analytics.success_rate"
        static let currentGoals = "analytics.current_goals"
        static let completedGoals = "analytics.completed_goals"
        static let goalSettingTips = "analytics.goal_setting_tips"
        static let smartGoals = "analytics.smart_goals"
        static let smartGoalsDesc = "analytics.smart_goals_desc"
        static let smallSteps = "analytics.small_steps"
        static let smallStepsDesc = "analytics.small_steps_desc"
        static let regularTracking = "analytics.regular_tracking"
        static let regularTrackingDesc = "analytics.regular_tracking_desc"
        static let motivation = "analytics.motivation"
        static let motivationDesc = "analytics.motivation_desc"
        static let noDataAvailable = "analytics.no_data_available"
        static let weightChange = "analytics.weight_change"
        static let averageWeight = "analytics.average_weight"
        static let entries = "analytics.entries"
        static let latest = "analytics.latest"
        static let totalWorkouts = "analytics.total_workouts"
        static let weeklyAverage = "analytics.weekly_average"
        static let totalVolume = "analytics.total_volume"
        static let averageVolume = "analytics.average_volume"
        static let weightTrend = "analytics.weight_trend"
        static let workoutConsistency = "analytics.workout_consistency"
        static let trendingUpward = "analytics.trending_upward"
        static let trendingDownward = "analytics.trending_downward"
        static let stableTrend = "analytics.stable_trend"
        static let excellentConsistency = "analytics.excellent_consistency"
        static let goodConsistency = "analytics.good_consistency"
        static let averageConsistency = "analytics.average_consistency"
        static let lowConsistency = "analytics.low_consistency"
        static let insufficientData = "analytics.insufficient_data"
        static let categoryStats = "analytics.category_stats"
        static let calculating = "analytics.calculating"
        static let change = "analytics.change"
        static let average = "analytics.average"

        // Additional Analytics Keys
        static let totalSessions = "analytics.total_sessions"
        static let averageOneRM = "analytics.average_one_rm"
        static let topExercise = "analytics.top_exercise"
        static let personalRecords = "analytics.personal_records"
        static let noStrengthData = "analytics.no_strength_data"
        static let noCardioData = "analytics.no_cardio_data"
        static let totalDistance = "analytics.total_distance"
        static let totalDuration = "analytics.total_duration"
        static let totalCalories = "analytics.total_calories"
        static let averageHeartRate = "analytics.average_heart_rate"
        static let averageDistance = "analytics.average_distance"
    }
    
    // MARK: - Time Ranges
    enum TimeRange {
        static let week1 = "analytics.time_range.week1"
        static let month1 = "analytics.time_range.month1"
        static let month3 = "analytics.time_range.month3"
        static let month6 = "analytics.time_range.month6"
        static let year1 = "analytics.time_range.year1"
    }
    
    // MARK: - Chart Types
    enum ChartType {
        static let weightChange = "analytics.chart_type.weight_change"
        static let workoutVolume = "analytics.chart_type.workout_volume"
        static let workoutFrequency = "analytics.chart_type.workout_frequency"
        static let bodyMeasurements = "analytics.chart_type.body_measurements"
    }
}