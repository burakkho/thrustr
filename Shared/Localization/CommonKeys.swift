import Foundation

/// Common keys shared across all features
enum CommonKeys {
    // MARK: - Tab Bar
    enum TabBar {
        static let dashboard = "tab.dashboard"
        static let training = "tab.training"
        static let nutrition = "tab.nutrition"
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
}