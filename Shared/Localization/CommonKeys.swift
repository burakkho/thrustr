import Foundation

/// Common keys shared across all features
enum CommonKeys {
    // MARK: - Tab Bar
    enum TabBar {
        static let dashboard = "tab.dashboard"
        static let training = "tab.training"
        static let nutrition = "tab.nutrition"
        static let analytics = "tab.analytics"
        static let profile = "tab.profile"
    }
    
    // MARK: - Action Keys (Legacy compatibility)
    enum Action {
        static let save = "action.save"
        static let cancel = "action.cancel"
    }
    
    // MARK: - Language
    enum Language {
        static let changeTitle = "language.change_title"
        static let changeMessage = "language.change_message"
        static let changeConfirm = "language.change_confirm"
        static let changeCancel = "language.change_cancel"
        static let restartRequired = "language.restart_required"
        static let restartMessage = "language.restart_message"
    }
    
    // MARK: - Preferences Extended
    enum PreferencesExtended {
        static let autoLanguage = "preferences.auto_language"
        static let systemDefault = "preferences.system_default"
        static let alwaysLight = "preferences.always_light"
        static let alwaysDark = "preferences.always_dark"
        static let notificationsAll = "preferences.notifications_all"
        static let workoutRemindersDesc = "preferences.workout_reminders_desc"
        static let nutritionRemindersDesc = "preferences.nutrition_reminders_desc"
        static let soundEffects = "preferences.sound_effects"
        static let timerSounds = "preferences.timer_sounds"
        static let hapticFeedback = "preferences.haptic_feedback"
        static let vibrationFeedback = "preferences.vibration_feedback"
        static let soundEffectsTitle = "PREFERENCES.SOUND_EFFECTS"
        static let appInfoTitle = "PREFERENCES.APP_INFO"
    }

    // MARK: - Settings (standardized for UI usage)
    enum Settings {
        static let title = "settings.title"
        static let appPreferences = "settings.app_preferences"
        static let language = "settings.language"
        static let units = "settings.units"
        static let theme = "settings.theme"
        static let notifications = "settings.notifications"
        static let systemTheme = "settings.system_theme"
        static let lightMode = "settings.light_mode"
        static let darkMode = "settings.dark_mode"
        static let metric = "settings.metric"
        static let imperial = "settings.imperial"
        static let allowNotifications = "settings.allow_notifications"
        static let workoutReminders = "settings.workout_reminders"
        static let nutritionReminders = "settings.nutrition_reminders"
        static let cloudSync = "settings.cloud_sync"
        static let icloudSync = "settings.icloud_sync"
        static let syncStatus = "settings.sync_status"
        static let syncNow = "settings.sync_now"
        static let syncError = "settings.sync_error"
        static let version = "settings.version"
        static let privacyPolicy = "settings.privacy_policy"
        static let termsOfService = "settings.terms_of_service"
    }
    
    // MARK: - Progress Photos Extended
    enum ProgressPhotosExtended {
        static let title = "progress_photos.title"
        static let subtitle = "progress_photos.subtitle"
        static let addFirst = "progress_photos.add_first"
    }
    
    // MARK: - Body Measurements Extended
    enum BodyMeasurementsExtended {
        static let subtitle = "body_measurements.subtitle"
        static let currentMeasurements = "body_measurements.current_measurements"
    }
    
    // MARK: - Personal Info Extended
    enum PersonalInfoExtended {
        static let updateTitle = "personal_info.update_title"
        static let updateSubtitle = "personal_info.update_subtitle"
        static let basicInfo = "personal_info.basic_info"
        static let name = "personal_info.name"
        static let age = "personal_info.age"
        static let ageFormat = "personal_info.age_format"
        static let gender = "personal_info.gender"
        static let physicalMeasurements = "personal_info.physical_measurements"
        static let height = "personal_info.height"
        static let currentWeight = "personal_info.current_weight"
        static let goalsActivity = "personal_info.goals_activity"
        static let fitnessGoal = "personal_info.fitness_goal"
        static let activityLevel = "personal_info.activity_level"
        static let calculatedValues = "personal_info.calculated_values"
        static let basalMetabolism = "personal_info.basal_metabolism"
        static let dailyExpenditure = "personal_info.daily_expenditure"
        static let calorieGoal = "personal_info.calorie_goal"
        static let dailyTarget = "personal_info.daily_target"
        static let infoUpdated = "personal_info.info_updated"
        static let updateSuccess = "personal_info.update_success"
    }
    
    // MARK: - Gender
    enum Gender {
        static let male = "gender.male"
        static let female = "gender.female"
    }
    
    // MARK: - Account Management
    enum Account {
        static let title = "account.title"
        static let info = "account.info"
        static let localAccount = "account.local_account"
        static let registrationDate = "account.registration_date"
        static let currentWeight = "account.current_weight"
        static let goal = "account.goal"
        static let activity = "account.activity"
        static let dataManagement = "account.data_management"
        static let backupData = "account.backup_data"
        static let exportDesc = "account.export_desc"
        static let appInfo = "account.app_info"
        static let version = "account.version"
        static let dangerousActions = "account.dangerous_actions"
        static let resetData = "account.reset_data"
        static let resetDesc = "account.reset_desc"
        static let deleteAccount = "account.delete_account"
        static let deleteDesc = "account.delete_desc"
        static let cannotUndo = "account.cannot_undo"
    }
    
    // MARK: - Goal Types Extended
    enum GoalTypesExtended {
        static let strength = "goal_type_strength"
        static let endurance = "goal_type_endurance"
        static let flexibility = "goal_type_flexibility"
        static let newGoalTitle = "new_goal.title"
        static let addGoal = "add_goal.title"
        static let goalTitle = "goal.title"
        static let goalDescription = "goal.description"
        static let goalValue = "goal.value"
        static let setEndDate = "goal.set_end_date"
        static let goalTitlePlaceholder = "goal.title_placeholder"
        static let goalDescriptionPlaceholder = "goal.description_placeholder"
    }
    
    // MARK: - Validation
    enum Validation {
        // Distance validation
        static let distanceRequired = "validation.distance.required"
        static let distanceInvalidFormat = "validation.distance.invalidFormat"
        static let distanceMustBePositive = "validation.distance.mustBePositive"
        static let distanceMinimum = "validation.distance.minimum"
        static let distanceMaximum = "validation.distance.maximum"
        static let distancePrecision = "validation.distance.precision"
        
        // Heart rate validation
        static let heartRateRequired = "validation.heartRate.required"
        static let heartRateInvalidFormat = "validation.heartRate.invalidFormat"
        static let heartRateMinimum = "validation.heartRate.minimum"
        static let heartRateMaximum = "validation.heartRate.maximum"
        static let heartRateAgeWarning = "validation.heartRate.ageWarning"
        
        // Duration validation
        static let durationRequired = "validation.duration.required"
        static let durationInvalidFormat = "validation.duration.invalidFormat"
        static let durationMustBePositive = "validation.duration.mustBePositive"
        static let durationMinimum = "validation.duration.minimum"
        static let durationMaximum = "validation.duration.maximum"
        
        // Time format validation
        static let timeRequired = "validation.time.required"
        static let timeInvalidFormat = "validation.time.invalidFormat"
        static let timeInvalidNumbers = "validation.time.invalidNumbers"
        static let hoursRange = "validation.time.hoursRange"
        static let minutesRange = "validation.time.minutesRange"
        static let secondsRange = "validation.time.secondsRange"
        
        // User validation
        static let nameEmpty = "validation.user.name.empty"
        static let nameMinLength = "validation.user.name.min_length"
        static let nameMaxLength = "validation.user.name.max_length"
        static let ageMinimum = "validation.user.age.minimum"
        static let ageMaximum = "validation.user.age.maximum"
        static let heightMinimum = "validation.user.height.minimum"
        static let weightMinimum = "validation.user.weight.minimum"
        static let invalidData = "validation.user.invalid_data"
        static let heightMaximum = "validation.user.height.maximum"
        static let weightMaximum = "validation.user.weight.maximum"
        static let ffmiAverage = "validation.ffmi.average"
        static let ffmiElite = "validation.ffmi.elite"
        
        // Body measurements validation
        static let chestRange = "validation.measurement.chest.range"
        static let waistRange = "validation.measurement.waist.range"
        static let hipRange = "validation.measurement.hip.range"
        static let neckRange = "validation.measurement.neck.range"
        static let bicepRange = "validation.measurement.bicep.range"
        static let thighRange = "validation.measurement.thigh.range"
        static let invalidMeasurements = "validation.measurement.invalid"
        
        // FFMI Categories
        static let ffmiNotCalculable = "validation.ffmi.not_calculable"
        static let ffmiLow = "validation.ffmi.low"
        static let ffmiBelowAverage = "validation.ffmi.below_average"
        static let ffmiGood = "validation.ffmi.good"
        static let ffmiVeryGood = "validation.ffmi.very_good"
        static let ffmiExcellent = "validation.ffmi.excellent"
        
        // Database errors
        static let databaseNotFound = "validation.database.not_found"
        static let userNotFound = "validation.database.user_not_found"
        
        // Error type prefixes
        static let ageError = "error.type.age"
        static let heightError = "error.type.height"
        static let weightError = "error.type.weight"
        static let nameError = "error.type.name"
        static let measurementError = "error.type.measurement"
        
        // Body part names
        static let chestName = "body.part.chest"
        static let waistName = "body.part.waist"
        static let hipName = "body.part.hip"
        static let neckName = "body.part.neck"
        static let bicepName = "body.part.bicep"
        static let thighName = "body.part.thigh"
        static let measurementsName = "body.part.measurements"

        // Calories validation
        static let caloriesRequired = "validation.calories.required"
        static let caloriesInvalidFormat = "validation.calories.invalidFormat"
        static let caloriesMustBePositive = "validation.calories.mustBePositive"
        static let caloriesMinimum = "validation.calories.minimum"
        static let caloriesMaximum = "validation.calories.maximum"
        static let caloriesUnrealistic = "validation.calories.unrealistic"
    }
    
    // MARK: - Heart Rate Zones
    enum HeartRate {
        static let zone1 = "heartRate.zone1"
        static let zone2 = "heartRate.zone2"
        static let zone3 = "heartRate.zone3"
        static let zone4 = "heartRate.zone4"
        static let zone5 = "heartRate.zone5"
        static let unknown = "heartRate.unknown"
    }
    
    // MARK: - Onboarding - FLAT STRUCTURE for Legacy Support
    enum Onboarding {
        static let back = "onboarding.back"
        
        // Flat structure properties for existing code compatibility
        static let welcomeTitle = "onboarding.welcome.title"
        static let welcomeSubtitle = "onboarding.welcome.subtitle"
        static let welcomeStart = "onboarding.welcome.start"
        
        static let featureWorkout = "onboarding.feature.workout"
        static let featureProgress = "onboarding.feature.progress"
        static let featureNutrition = "onboarding.feature.nutrition"
        static let featureGoals = "onboarding.feature.goals"
        
        static let step = "onboarding.progress.step"
        
        static let personalInfoTitle = "onboarding.personalInfo.title"
        static let personalInfoSubtitle = "onboarding.personalInfo.subtitle"
        static let nameLabel = "onboarding.personalInfo.name"
        static let namePlaceholder = "onboarding.personalInfo.name.placeholder"
        static let ageLabel = "onboarding.personalInfo.age"
        static let ageYears = "onboarding.personalInfo.age.years"
        static let genderLabel = "onboarding.personalInfo.gender"
        static let genderMale = "onboarding.personalInfo.gender.male"
        static let genderFemale = "onboarding.personalInfo.gender.female"
        static let heightLabel = "onboarding.personalInfo.height"
        static let weightLabel = "onboarding.personalInfo.weight"
        
        static let goalsTitle = "onboarding.goals.title"
        static let goalsSubtitle = "onboarding.goals.subtitle"
        static let mainGoalLabel = "onboarding.goals.mainGoal"
        static let activityLevelLabel = "onboarding.goals.activityLevel"
        static let targetWeightLabel = "onboarding.goals.targetWeight"
        static let targetWeightToggle = "onboarding.goals.targetWeight.toggle"
        
        static let goalCutTitle = "onboarding.goals.cut.title"
        static let goalCutSubtitle = "onboarding.goals.cut.subtitle"
        static let goalBulkTitle = "onboarding.goals.bulk.title"
        static let goalBulkSubtitle = "onboarding.goals.bulk.subtitle"
        static let goalMaintainTitle = "onboarding.goals.maintain.title"
        static let goalMaintainSubtitle = "onboarding.goals.maintain.subtitle"
        
        static let activitySedentary = "onboarding.activity.sedentary"
        static let activitySedentaryDesc = "onboarding.activity.sedentary.desc"
        static let activityLight = "onboarding.activity.light"
        static let activityLightDesc = "onboarding.activity.light.desc"
        static let activityModerate = "onboarding.activity.moderate"
        static let activityModerateDesc = "onboarding.activity.moderate.desc"
        static let activityActive = "onboarding.activity.active"
        static let activityActiveDesc = "onboarding.activity.active.desc"
        static let activityVeryActive = "onboarding.activity.veryActive"
        static let activityVeryActiveDesc = "onboarding.activity.veryActive.desc"
        
        static let summaryTitle = "onboarding.summary.title"
        static let summarySubtitle = "onboarding.summary.subtitle"
        static let profileSummary = "onboarding.summary.profile"
        static let goals = "onboarding.summary.goals"
        static let calculatedValues = "onboarding.summary.calculatedValues"
        static let macroGoals = "onboarding.summary.macroGoals"
        
        static let labelName = "onboarding.summary.label.name"
        static let labelAge = "onboarding.summary.label.age"
        static let labelGender = "onboarding.summary.label.gender"
        static let labelHeight = "onboarding.summary.label.height"
        static let labelWeight = "onboarding.summary.label.weight"
        static let labelTargetWeight = "onboarding.summary.label.targetWeight"
        static let labelMainGoal = "onboarding.summary.label.mainGoal"
        static let labelActivity = "onboarding.summary.label.activity"
        static let labelBMR = "onboarding.summary.label.bmr"
        static let labelBMRKatch = "onboarding.summary.label.bmr.katch"
        static let labelBMRMifflin = "onboarding.summary.label.bmr.mifflin"
        static let labelLBM = "onboarding.summary.label.lbm"
        static let labelBodyFat = "onboarding.summary.label.bodyFat"
        static let labelTDEE = "onboarding.summary.label.tdee"
        static let labelDailyCalorie = "onboarding.summary.label.dailyCalorie"
        static let labelProtein = "onboarding.summary.label.protein"
        static let labelCarbs = "onboarding.summary.label.carbs"
        static let labelFat = "onboarding.summary.label.fat"
        
        static let ageFormat = "onboarding.summary.age_format"
        
        static let infoTitle = "onboarding.summary.info.title"
        static let infoWithNavy = "onboarding.summary.info.withNavy"
        static let infoWithoutNavy = "onboarding.summary.info.withoutNavy"
        static let startApp = "onboarding.summary.startApp"
        
        static let continueAction = "onboarding.continue"
        static let continueButton = "onboarding.continue"
        
        // MARK: - Missing Measurements Keys
        static let navyMethodTitle = "onboarding.measurements.navyMethod.title"
        static let navyMethodDesc = "onboarding.measurements.navyMethod.desc"
        static let neckLabel = "onboarding.measurements.neck.label"
        static let waistMaleLabel = "onboarding.measurements.waist.male.label"
        static let waistFemaleLabel = "onboarding.measurements.waist.female.label"
        static let hipLabel = "onboarding.measurements.hip.label"
        static let bodyFatTitle = "onboarding.measurements.bodyFat.title"
        static let bodyFatNavy = "onboarding.measurements.bodyFat.navy"
        static let optionalInfo = "onboarding.measurements.optional.info"
        static let optionalDesc = "onboarding.measurements.optional.desc"
        static let skipStep = "onboarding.measurements.skipStep"
        static let optional = "onboarding.measurements.optional"
        
        // MARK: - Direct access properties for legacy compatibility
        static let measurementsTitle = "onboarding.measurements.title"
        static let measurementsSubtitle = "onboarding.measurements.subtitle"
        
        // MARK: - Consent
        enum Consent {
            static let title = "onboarding.consent.title"
            static let subtitle = "onboarding.consent.subtitle"
            static let dataCollection = "onboarding.consent.data_collection"
            static let dataProcessing = "onboarding.consent.data_processing"
            static let privacyPolicy = "onboarding.consent.privacy_policy"
            static let termsOfService = "onboarding.consent.terms_of_service"
            static let acceptTerms = "onboarding.consent.accept_terms"
            static let marketingOptIn = "onboarding.consent.marketing_opt_in"
            static let agreeToTerms = "onboarding.consent.agree_to_terms"
            static let agreeToPrivacy = "onboarding.consent.agree_to_privacy"
            static let marketingEmails = "onboarding.consent.marketing_emails"
        }
        
        // MARK: - Routine
        enum Routine {
            static let completed = "routine.completed"
            static let remaining = "routine.remaining"
            static let week = "routine.week"
            static let day = "routine.day"
            static let showDetails = "routine.show_details"
            static let hideDetails = "routine.hide_details"
            static let nextWorkout = "routine.next_workout"
            static let noNextWorkout = "routine.no_next_workout"
        }
        
        // MARK: - Common
        enum Common {
            static let ok = "common.ok"
            static let cancel = "common.cancel"
            static let save = "common.save"
            static let delete = "common.delete"
            static let edit = "common.edit"
            static let done = "common.done"
            static let close = "common.close"
            static let back = "common.back"
            static let next = "common.next"
            static let previous = "common.previous"
            static let skip = "common.skip"
            static let retry = "common.retry"
            static let loading = "common.loading"
            static let error = "common.error"
            static let success = "common.success"
            static let warning = "common.warning"
            static let info = "common.info"
            static let yes = "common.yes"
            static let no = "common.no"
            static let finish = "common.finish"
            static let add = "common.add"
            static let change = "common.change"
            static let continueAnyway = "common.continue_anyway"
            static let search = "common.search"
            static let all = "common.all"
            static let completed = "common.completed"
        }
    }
    
    // MARK: - Error Handling
    enum ErrorHandling {
        static let databaseError = "error.database"
        static let networkError = "error.network" 
        static let healthKitError = "error.healthkit"
        static let dataCorruption = "error.data_corruption"
        static let unknownError = "error.unknown"
        static let databaseRecovery = "error.database.recovery"
        static let networkRecovery = "error.network.recovery"
        static let healthKitRecovery = "error.healthkit.recovery"
        static let dataCorruptionRecovery = "error.data_corruption.recovery"
        static let unknownRecovery = "error.unknown.recovery"
        static let okButton = "error.ok_button"
        static let retryButton = "error.retry_button"
    }
    
    // MARK: - Navigation
    enum Navigation {
        static let programDetails = "navigation.program_details"
        static let saveResult = "navigation.save_result"
        static let trainingGoals = "navigation.training_goals"
        static let programSetup = "navigation.program_setup"
        static let startingWeights = "navigation.starting_weights"
        static let workoutPreview = "navigation.workout_preview"
        static let notes = "navigation.notes"
        static let summary = "navigation.summary"
        static let logLiftResult = "navigation.log_lift_result"
        static let newCardio = "navigation.new_cardio"
        static let addMovement = "navigation.add_movement"
        static let wodHistory = "navigation.wod_history"
        static let enterBestSets = "navigation.enter_best_sets"
        static let wodHistoryFormat = "navigation.wod_history_format"
    }
    
    // MARK: - Empty States
    enum EmptyState {
        static let noWorkoutsTitle = "empty_state.no_workouts.title"
        static let noWorkoutsSubtitle = "empty_state.no_workouts.subtitle"
        static let noResultsTitle = "empty_state.no_results.title"
        static let noResultsSubtitle = "empty_state.no_results.subtitle"
        static let noCustomMETCONTitle = "empty_state.no_custom_metcon.title"
        static let noCustomMETCONSubtitle = "empty_state.no_custom_metcon.subtitle"
        static let noMETCONFoundTitle = "empty_state.no_metcon_found.title"
        static let noMETCONFoundSubtitle = "empty_state.no_metcon_found.subtitle"
    }
    
    // MARK: - Time Formatting
    enum TimeFormatting {
        static let now = "time.now"
        static let minutesAgo = "time.minutes_ago"
        static let hoursAgo = "time.hours_ago" 
        static let yesterday = "time.yesterday"
        static let hoursShort = "time.hours_short"
        static let minutesShort = "time.minutes_short"
        static let hourUnit = "time.hour_unit"
        static let minuteUnit = "time.minute_unit"
        static let secondUnit = "time.second_unit"
        static let hours = "time.hours"
        static let minutes = "time.minutes"
        static let seconds = "time.seconds"
    }
    
    // MARK: - Training Actions
    enum TrainingActions {
        static let editWOD = "training.edit_wod"
        static let nextDeadline = "training.next_deadline"
        static let days = "training.days"
        static let none = "training.none"
        static let backgroundContent = "training.background_content"
        static let normalFeeling = "training.normal_feeling"
        static let trainingSessions = "training.sessions"
        static let saveGoals = "training.save_goals"
        static let weeklyGoals = "training.weekly_goals"
        static let dashboardProgressTargets = "training.dashboard_progress_targets"
        static let notesOptional = "training.notes_optional"
        static let calculateStartingWeights = "training.calculate_starting_weights"
    }
    
    // MARK: - HealthKit Integration
    enum HealthKit {
        // Health Intelligence
        static let healthIntelligenceTitle = "health.intelligence.title"
        static let recoveryScoreTitle = "health.recovery_score.title"
        static let recoveryScoreSubtitle = "health.recovery_score.subtitle"
        static let fitnessLevelTitle = "health.fitness_level.title"
        static let healthInsightsTitle = "health.insights.title"
        static let overallLevelTitle = "health.overall_level.title"
        static let consistencyTitle = "health.consistency.title"
        static let cardioTitle = "health.cardio.title"
        static let strengthTitle = "health.strength.title"
        static let loadingMessage = "health.loading.message"
        static let unavailableTitle = "health.unavailable.title"
        static let unavailableMessage = "health.unavailable.message"
        static let noInsightsTitle = "health.no_insights.title"
        static let noInsightsMessage = "health.no_insights.message"
        
        // Health Trends
        static let trendsTitle = "health.trends.title"
        static let trendsSubtitle = "health.trends.subtitle"
        static let stepsTitle = "health.trends.steps"
        static let heartRateTitle = "health.trends.heart_rate"
        static let weightTitle = "health.trends.weight"
        static let last30Days = "health.trends.last_30_days"
        static let last90Days = "health.trends.last_90_days"
        static let noTrendsData = "health.trends.no_data"
        
        // Authorization
        static let authorizationTitle = "health.authorization.title"
        static let authorizationSubtitle = "health.authorization.subtitle"
        static let refreshPermissions = "health.authorization.refresh"
        static let openHealthApp = "health.authorization.open_app"
        static let detailedPermissions = "health.authorization.detailed"
        static let authorized = "health.authorization.authorized"
        static let denied = "health.authorization.denied"
        static let notDetermined = "health.authorization.not_determined"
        
        // Categories
        static let activityCategory = "health.category.activity"
        static let activityDescription = "health.category.activity_desc"
        static let heartCategory = "health.category.heart"
        static let heartDescription = "health.category.heart_desc"
        static let bodyCategory = "health.category.body"
        static let bodyDescription = "health.category.body_desc"
        static let sleepCategory = "health.category.sleep"
        static let sleepDescription = "health.category.sleep_desc"
        static let workoutCategory = "health.category.workout"
        static let workoutDescription = "health.category.workout_desc"
        static let nutritionCategory = "health.category.nutrition"
        static let nutritionDescription = "health.category.nutrition_desc"
        
        // Score Details
        static let sleepScore = "health.score.sleep"
        static let hrvScore = "health.score.hrv"
        static let workloadScore = "health.score.workload"
        static let restingHRScore = "health.score.resting_hr"
        
        // Metrics
        static let stepsMetric = "health.metrics.steps"
        static let weightMetric = "health.metrics.weight"
        static let heartRateMetric = "health.metrics.heart_rate"
        static let stepsUnit = "health.units.steps"
        static let weightUnit = "health.units.weight"
        static let heartRateUnit = "health.units.heart_rate"
        
        // Workout Trends
        static let workoutTrendsTitle = "health.workout_trends.title"
        static let activityBreakdownTitle = "health.activity_breakdown.title"
        static let weekLabel = "health.chart.week"
        static let workoutLabel = "health.chart.workout"
        static let dateLabel = "health.chart.date"
        static let valueLabel = "health.chart.value"
        
        // Current Health Data
        static let currentHealthDataTitle = "health.current_data.title"
        static let todayStepsTitle = "health.today_steps.title"
        static let activeCaloriesTitle = "health.active_calories.title"
        static let currentWeightTitle = "health.current_weight.title"
        static let restingHeartRateTitle = "health.resting_heart_rate.title"
        
        // Empty States
        static let dataNotFoundMessage = "health.data_not_found.message"
        static let loadingDataMessage = "health.loading_data.message"
        
        // Recovery Recommendations
        static let recoveryExcellentMessage = "health.recovery.recommendation.excellent"
        static let recoveryGoodMessage = "health.recovery.recommendation.good"
        static let recoveryModerateMessage = "health.recovery.recommendation.moderate"
        static let recoveryPoorMessage = "health.recovery.recommendation.poor"
        static let recoveryCriticalMessage = "health.recovery.recommendation.critical"
        
        // Fitness Level Descriptions
        static let fitnessBeginnerDesc = "health.fitness.description.beginner"
        static let fitnessIntermediateDesc = "health.fitness.description.intermediate"
        static let fitnessAdvancedDesc = "health.fitness.description.advanced"
        static let fitnessEliteDesc = "health.fitness.description.elite"
        
        // Health Insight Titles
        static let insightLowRecoveryTitle = "health.insight.title.low_recovery"
        static let insightSleepQualityTitle = "health.insight.title.sleep_quality"
        static let insightWorkoutFrequencyTitle = "health.insight.title.workout_frequency"
        static let insightIntenseTrainingTitle = "health.insight.title.intense_training"
        static let insightLowActivityTitle = "health.insight.title.low_activity"
        static let insightWeightChangeTitle = "health.insight.title.weight_change"
        
        // Health Insight Messages
        static let insightLowRecoveryMessage = "health.insight.message.low_recovery"
        static let insightSleepQualityMessage = "health.insight.message.sleep_quality"
        static let insightWorkoutFrequencyMessage = "health.insight.message.workout_frequency"
        static let insightIntenseTrainingMessage = "health.insight.message.intense_training"
        static let insightLowActivityMessage = "health.insight.message.low_activity"
        static let insightWeightChangeMessage = "health.insight.message.weight_change"
        
        // Health Insight Actions
        static let insightLowRecoveryAction = "health.insight.action.low_recovery"
        static let insightSleepQualityAction = "health.insight.action.sleep_quality"
        static let insightWorkoutFrequencyAction = "health.insight.action.workout_frequency"
        static let insightIntenseTrainingAction = "health.insight.action.intense_training"
        static let insightLowActivityAction = "health.insight.action.low_activity"
        static let insightWeightChangeAction = "health.insight.action.weight_change"
        
        // Weight Change Directions
        static let weightIncrease = "health.weight.direction.increase"
        static let weightDecrease = "health.weight.direction.decrease"
        
        // Health Insight Message Components
        static let weeklyWorkouts = "health.insight.weekly_workouts"
        static let workoutsDoing = "health.insight.workouts_doing"
        static let dailyAverageSteps = "health.insight.daily_average_steps"
        static let weightChangePeriod = "health.insight.weight_change_period"
        static let weightChangeExists = "health.insight.weight_change_exists"
        
        // HealthKit Statistics Section
        static let statisticsTitle = "health.statistics.title"
        static let totalDuration = "health.statistics.total_duration"
    }
    
    // MARK: - Navy Method Calculator
    enum Calculator {
        // Main interface
        static let navyMethodTitle = "calculator.navy_method.title"
        static let navyMethodSubtitle = "calculator.navy_method.subtitle"
        static let measurementsSection = "calculator.navy_method.measurements_section"
        static let resultsSection = "calculator.navy_method.results_section"
        static let aboutSection = "calculator.navy_method.about_section"
        
        // Form labels
        static let ageLabel = "calculator.navy_method.age_label"
        static let inchesLabel = "calculator.navy_method.inches_label"
        static let waistCircumference = "calculator.navy_method.waist_circumference"
        static let neckCircumference = "calculator.navy_method.neck_circumference"
        static let hipCircumference = "calculator.navy_method.hip_circumference"
        
        // Results
        static let bodyFatPercentageTitle = "calculator.navy_method.body_fat_percentage_title"
        static let bodyFatScaleTitle = "calculator.navy_method.body_fat_scale_title"
        
        // About section
        static let reliabilityTitle = "calculator.navy_method.reliability_title"
        static let reliabilityDescription = "calculator.navy_method.reliability_description"
        static let accuracyTitle = "calculator.navy_method.accuracy_title"
        static let accuracyDescription = "calculator.navy_method.accuracy_description"
        static let importantNoteTitle = "calculator.navy_method.important_note_title"
        static let importantNoteDescription = "calculator.navy_method.important_note_description"
        static let trackingTitle = "calculator.navy_method.tracking_title"
        static let trackingDescription = "calculator.navy_method.tracking_description"
        
        // Gender display names
        static let maleGender = "calculator.navy_method.gender.male"
        static let femaleGender = "calculator.navy_method.gender.female"
        
        // Body fat categories
        static let bodyFatEssential = "calculator.body_fat.category.essential"
        static let bodyFatAthlete = "calculator.body_fat.category.athlete"
        static let bodyFatFitness = "calculator.body_fat.category.fitness"
        static let bodyFatAverage = "calculator.body_fat.category.average"
        static let bodyFatObese = "calculator.body_fat.category.obese"
        
        // Body fat descriptions
        static let bodyFatEssentialDesc = "calculator.body_fat.description.essential"
        static let bodyFatAthleteDesc = "calculator.body_fat.description.athlete"
        static let bodyFatFitnessDesc = "calculator.body_fat.description.fitness"
        static let bodyFatAverageDesc = "calculator.body_fat.description.average"
        static let bodyFatObeseDesc = "calculator.body_fat.description.obese"
    }
    
    // MARK: - Common Actions
    enum Actions {
        static let save = "common.actions.save"
        static let cancel = "common.actions.cancel"
        static let retry = "common.actions.retry"
        static let continueAction = "common.actions.continue"
        static let done = "common.actions.done"
        static let share = "common.actions.share"
    }
    
    // MARK: - Activity Status
    enum Activity {
        static let completed = "activity.status.completed"
        static let started = "activity.status.started"
        static let willContinue = "activity.status.will_continue"
        static let workoutCount = "activity.status.workout_count"
        static let inDuration = "activity.status.in_duration"
        static let personalRecord = "activity.status.personal_record"
        static let previousRecord = "activity.status.previous_record"
        static let newRecord = "activity.status.new_record"
        static let strengthTestCompleted = "activity.status.strength_test_completed"
        static let level = "activity.status.level"
        static let updated = "activity.status.updated"
        static let logged = "activity.status.logged"
        static let goalCompleted = "activity.status.goal_completed"
        static let record = "activity.status.record"
        
        // Activity type display names
        static let running = "activity.type.running"
        static let cycling = "activity.type.cycling"
        static let swimming = "activity.type.swimming"
        static let walking = "activity.type.walking"
        static let traditionalStrengthTraining = "activity.type.traditional_strength_training"
        static let crossTraining = "activity.type.cross_training"
        static let rowing = "activity.type.rowing"
        static let elliptical = "activity.type.elliptical"
        static let yoga = "activity.type.yoga"
        static let functionalStrengthTraining = "activity.type.functional_strength_training"
        static let coreTraining = "activity.type.core_training"
        static let flexibility = "activity.type.flexibility"
        static let highIntensityIntervalTraining = "activity.type.hiit"
        static let jumpRope = "activity.type.jump_rope"
        static let stairs = "activity.type.stairs"
        static let kickboxing = "activity.type.kickboxing"
        static let pilates = "activity.type.pilates"
        static let dance = "activity.type.dance"
        static let taiChi = "activity.type.tai_chi"
        static let barre = "activity.type.barre"
        static let wrestling = "activity.type.wrestling"
        static let boxing = "activity.type.boxing"
        static let martialArts = "activity.type.martial_arts"
        static let other = "activity.type.other"
    }
    
    // MARK: - Units
    enum Units {
        static let kcal = "units.kcal"
        static let calories = "units.calories"
        static let meters = "units.meters"
        static let foods = "units.foods"
        static let kilometers = "units.kilometers"
        static let kg = "units.kg"
        static let lb = "units.lb"
        static let bpm = "units.bpm"
        static let minutes = "units.minutes"
        static let hours = "units.hours"
        static let seconds = "units.seconds"
        static let days = "units.days"
        static let weeks = "units.weeks"
        static let monthsUnit = "units.months"
        static let metersShort = "units.meters_short"
        static let kilometersShort = "units.kilometers_short"
        static let steps = "units.steps"
    }
    
    // MARK: - Bluetooth Signal Strength
    enum BluetoothSignal {
        static let strong = "bluetooth.signal.strong"
        static let medium = "bluetooth.signal.medium"
        static let weak = "bluetooth.signal.weak"
    }
    
    // MARK: - Language Display Names
    enum LanguageNames {
        static let system = "language.names.system"
        static let turkish = "language.names.turkish"
        static let english = "language.names.english"
        static let spanish = "language.names.spanish"
        static let german = "language.names.german"
        static let italian = "language.names.italian"
        static let french = "language.names.french"
        static let portuguese = "language.names.portuguese"
        static let indonesian = "language.names.indonesian"
        static let polish = "language.names.polish"
    }

    // MARK: - Analytics
    enum Analytics {
        // Common Analytics
        static let title = "analytics.title"
        static let viewAll = "analytics.view_all"
        static let viewDetails = "analytics.view_details"
        static let noData = "analytics.no_data"
        static let insufficientData = "analytics.insufficient_data"
        static let loading = "analytics.loading"

        // Journey Titles
        static let strengthJourney = "analytics.strength_journey"
        static let healthJourney = "analytics.health_journey"
        static let nutritionJourney = "analytics.nutrition_journey"

        // Training Analytics
        static let strengthProgression = "analytics.strength_progression"
        static let personalRecords = "analytics.personal_records"
        static let trainingPatterns = "analytics.training_patterns"
        static let workoutFrequency = "analytics.workout_frequency"
        static let strengthInsights = "analytics.strength_insights"
        static let strongestLift = "analytics.strongest_lift"
        static let totalVolume = "analytics.total_volume"
        static let thisMonth = "analytics.this_month"
        static let startTraining = "analytics.start_training"
        static let setGoals = "analytics.set_goals"
        static let prsThisMonth = "analytics.prs_this_month"
        static let totalProgress = "analytics.total_progress"
        static let streak = "analytics.streak"

        // Health Analytics
        static let healthIntelligence = "analytics.health_intelligence"
        static let aiHealthIntelligence = "analytics.ai_health_intelligence"
        static let fullReport = "analytics.full_report"
        static let healthActivityRings = "analytics.health_activity_rings"
        static let healthTrends = "analytics.health_trends"
        static let viewCharts = "analytics.view_charts"
        static let recoveryFactors = "analytics.recovery_factors"
        static let recommendedAction = "analytics.recommended_action"

        // Nutrition Analytics
        static let nutritionIntelligence = "analytics.nutrition_intelligence"
        static let macroTimeline = "analytics.macro_timeline"
        static let nutritionGoals = "analytics.nutrition_goals"
        static let editGoals = "analytics.edit_goals"
        static let avgCalories = "analytics.avg_calories"
        static let loggedDays = "analytics.logged_days"
        static let consistency = "analytics.consistency"
        static let dailyCalories = "analytics.daily_calories"
        static let proteinIntake = "analytics.protein_intake"
        static let loggingStreak = "analytics.logging_streak"
        static let eatingPattern = "analytics.eating_pattern"
        static let macroBalance = "analytics.macro_balance"
        static let goalProgress = "analytics.goal_progress"
        static let recommendation = "analytics.recommendation"

        // Time Periods
        static let week = "analytics.period.week"
        static let month = "analytics.period.month"
        static let threeMonths = "analytics.period.three_months"
        static let sixMonths = "analytics.period.six_months"
        static let year = "analytics.period.year"
        static let allTime = "analytics.period.all_time"

        // Time Period Labels
        static let lastWeek = "analytics.period.last_week"
        static let lastMonth = "analytics.period.last_month"
        static let lastThreeMonths = "analytics.period.last_three_months"
        static let lastSixMonths = "analytics.period.last_six_months"
        static let lastYear = "analytics.period.last_year"

        // PR Types
        static let strengthPRs = "analytics.pr_types.strength"
        static let endurancePRs = "analytics.pr_types.endurance"
        static let volumePRs = "analytics.pr_types.volume"

        // Empty States
        static let noStrengthData = "analytics.empty.no_strength_data"
        static let noStrengthMessage = "analytics.empty.no_strength_message"
        static let completeFirstWorkout = "analytics.empty.complete_first_workout"
        static let noWorkoutsThisWeek = "analytics.empty.no_workouts_this_week"
        static let startTrainingMessage = "analytics.empty.start_training_message"
        static let setPRMessage = "analytics.empty.set_pr_message"

        // Units
        static let kcal = "analytics.units.kcal"
        static let days = "analytics.units.days"
        static let grams = "analytics.units.grams"
        static let calories = "analytics.units.calories"
        static let protein = "analytics.units.protein"
        static let carbs = "analytics.units.carbs"
        static let fat = "analytics.units.fat"

        // Confidence Levels
        static let highConfidence = "analytics.confidence.high"
        static let mediumConfidence = "analytics.confidence.medium"
        static let lowConfidence = "analytics.confidence.low"

        // Interactive Elements
        static let tapToExplore = "analytics.tap_to_explore"
        static let detailedCharts = "analytics.detailed_charts"
        static let goalSettings = "analytics.goal_settings"

        // Error Messages
        static let noAnalyticsData = "analytics.error.no_data_available"
        static let invalidDateRange = "analytics.error.invalid_date_range"
        static let calculationFailed = "analytics.error.calculation_failed"
        static let unknownExercise = "analytics.error.unknown_exercise"
        static let noDataPeriod = "analytics.error.no_data_period"

        // Status Messages
        static let calculating = "analytics.status.calculating"
        static let processing = "analytics.status.processing"
        static let complete = "analytics.status.complete"

        // Milestone Messages
        static let nextMilestone = "analytics.milestone.next"
        static let reachWeight = "analytics.milestone.reach_weight"
        static let breakBarrier = "analytics.milestone.break_barrier"
        static let firstWorkout = "analytics.milestone.first_workout"

        // Exercise Names (fallbacks)
        static let benchPress = "analytics.exercise.bench_press"
        static let squat = "analytics.exercise.squat"
        static let deadlift = "analytics.exercise.deadlift"
        static let overheadPress = "analytics.exercise.overhead_press"
        static let pullUp = "analytics.exercise.pull_up"
    }
}