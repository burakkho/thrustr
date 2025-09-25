// LocalizationKeys.swift
// Thrustr - Minimized Localization Keys with Feature-based Architecture

import Foundation

/// Centralized localization keys with feature-based modular architecture
/// This file now serves as a lightweight delegate to feature-specific key files
enum LocalizationKeys {
    
    // MARK: - Feature-based Keys (New Architecture)
    static let dashboard = DashboardKeys.self
    static let training = TrainingKeys.self
    static let nutrition = NutritionKeys.self
    static let profile = ProfileKeys.self
    static let common = CommonKeys.self
    
    // MARK: - Legacy Support (Backward Compatibility)
    // These delegates ensure existing code continues to work without changes
    
    enum TabBar {
        static let dashboard = CommonKeys.TabBar.dashboard
        static let training = CommonKeys.TabBar.training
        static let nutrition = CommonKeys.TabBar.nutrition
        static let profile = CommonKeys.TabBar.profile
    }
    
    enum Dashboard {
        static let title = DashboardKeys.title
        static let welcome = DashboardKeys.welcome
        static let quickActions = DashboardKeys.quickActions
        static let recentWorkouts = DashboardKeys.recentWorkouts

        enum Activities {
            static let today = DashboardKeys.Activities.today
            static let yesterday = DashboardKeys.Activities.yesterday
            static let thisWeek = DashboardKeys.Activities.thisWeek
        }
    }
    
    enum Training {
        static let title = TrainingKeys.title
        static let history = TrainingKeys.history
        static let active = TrainingKeys.active
        static let templates = TrainingKeys.templates

        enum Analytics {
            static let title = "training.analytics.title"
            static let progress = "training.analytics.progress"
            static let recent_prs = "training.analytics.recent_prs"
            static let view_all_prs = "training.analytics.view_all_prs"
            static let no_recent_prs = "training.analytics.no_recent_prs"
            static let start_lifting = "training.analytics.start_lifting"
            static let goals_motivation = "training.analytics.goals_motivation"
            static let your_potential = "training.analytics.your_potential"
            static let strength_goals = "training.analytics.strength_goals"
            static let achievement_unlock = "training.analytics.achievement_unlock"
            static let progress_tracking = "training.analytics.progress_tracking"
            static let personal_records = "training.analytics.personal_records"
            static let total_prs = "training.analytics.total_prs"
            static let all_time = "training.analytics.all_time"
            static let great_job = "training.analytics.great_job"
            static let keep_going = "training.analytics.keep_going"
            static let on_fire = "training.analytics.on_fire"
            static let days_estimate = "training.analytics.days_estimate"
            static let weeks_estimate = "training.analytics.weeks_estimate"
            static let months_estimate = "training.analytics.months_estimate"
        }

        enum Cardio {
            static let title = TrainingKeys.Cardio.title
            static let running = TrainingKeys.Cardio.running
            static let walking = TrainingKeys.Cardio.walking
            static let cycling = TrainingKeys.Cardio.cycling
            static let exerciseTypes = TrainingKeys.Cardio.exerciseTypes
            static let customSessions = TrainingKeys.Cardio.customSessions
            static let noHistory = TrainingKeys.Cardio.noHistory
            static let noHistoryMessage = TrainingKeys.Cardio.noHistoryMessage
            static let browseTemplates = TrainingKeys.Cardio.browseTemplates
        }

        enum Lift {
            static let title = TrainingKeys.Lift.title
            static let train = TrainingKeys.Lift.train
            static let programs = TrainingKeys.Lift.programs
            static let routines = TrainingKeys.Lift.routines
            static let history = TrainingKeys.Lift.history
        }

        enum StrengthTraining {
            static let title = "training.strength.title"
            static let session_complete = "training.strength.session_complete"
            static let workout_summary = "training.strength.workout_summary"
        }
    }
    
    enum Nutrition {
        static let title = NutritionKeys.title
        static let addFood = NutritionKeys.addFood
        static let calories = NutritionKeys.calories
        static let scanBarcode = NutritionKeys.scanBarcode

        enum CustomFood {
            static let title = NutritionKeys.CustomFood.title
            static let newFood = NutritionKeys.CustomFood.newFood
            static let addNewFood = NutritionKeys.CustomFood.addNewFood
            static let subtitle = NutritionKeys.CustomFood.subtitle
            static let basicInfo = NutritionKeys.CustomFood.basicInfo
            static let foodName = NutritionKeys.CustomFood.foodName
            static let foodNameRequired = NutritionKeys.CustomFood.foodNameRequired
            static let foodNamePlaceholder = NutritionKeys.CustomFood.foodNamePlaceholder
            static let brand = NutritionKeys.CustomFood.brand
            static let brandOptional = NutritionKeys.CustomFood.brandOptional
            static let brandPlaceholder = NutritionKeys.CustomFood.brandPlaceholder
            static let category = NutritionKeys.CustomFood.category
            static let nutritionValues = NutritionKeys.CustomFood.nutritionValues
            static let per100g = NutritionKeys.CustomFood.per100g
            static let caloriesRequired = NutritionKeys.CustomFood.caloriesRequired
            static let protein = NutritionKeys.CustomFood.protein
            static let carbs = NutritionKeys.CustomFood.carbs
            static let fat = NutritionKeys.CustomFood.fat
            static let preview = NutritionKeys.CustomFood.preview
            static let addFood = NutritionKeys.CustomFood.addFood
            static let cancel = NutritionKeys.CustomFood.cancel
            static let error = NutritionKeys.CustomFood.error
            static let ok = NutritionKeys.CustomFood.ok
        }

        enum Units {
            static let kcal = NutritionKeys.Units.kcal
            static let grams = NutritionKeys.Units.grams
            static let g = NutritionKeys.Units.g
        }
    }
    
    enum Profile {
        static let title = ProfileKeys.title
        static let editProfile = ProfileKeys.editProfile
        static let personalInfo = ProfileKeys.personalInfo
        static let measurements = ProfileKeys.measurements
        
        enum LifetimeAchievements {
            static let title = ProfileKeys.LifetimeAchievements.title
            static let subtitle = ProfileKeys.LifetimeAchievements.subtitle
            static let totalWeight = ProfileKeys.LifetimeAchievements.totalWeight
            static let totalDistance = ProfileKeys.LifetimeAchievements.totalDistance
            static let totalWorkouts = ProfileKeys.LifetimeAchievements.totalWorkouts
            static let activeDays = ProfileKeys.LifetimeAchievements.activeDays
        }
        
        enum Units {
            static let kg = ProfileKeys.Units.kg
            static let lb = ProfileKeys.Units.lb
            static let tons = ProfileKeys.Units.tons
            static let km = ProfileKeys.Units.km
            static let mi = ProfileKeys.Units.mi
            static let cm = ProfileKeys.Units.cm
            static let inch = ProfileKeys.Units.inch
            static let percent = ProfileKeys.Units.percent
        }
    }

    // MARK: - Achievements (Profile Analytics)
    enum Achievements {
        static let title = "achievements.title"
        static let subtitle = "achievements.subtitle"

        enum Category {
            static let all = "achievements.category.all"
            static let workout = "achievements.category.workout"
            static let weight = "achievements.category.weight"
            static let nutrition = "achievements.category.nutrition"
            static let streak = "achievements.category.streak"
            static let social = "achievements.category.social"
        }

        enum Item {
            static let firstWorkoutTitle = "achievements.item.first_workout.title"
            static let firstWorkoutDesc = "achievements.item.first_workout.desc"

            static let w10Title = "achievements.item.workout_10.title"
            static let w10Desc = "achievements.item.workout_10.desc"

            static let w50Title = "achievements.item.workout_50.title"
            static let w50Desc = "achievements.item.workout_50.desc"

            static let w100Title = "achievements.item.workout_100.title"
            static let w100Desc = "achievements.item.workout_100.desc"

            static let weekendWarriorTitle = "achievements.item.weekend_warrior.title"
            static let weekendWarriorDesc = "achievements.item.weekend_warrior.desc"

            static let weightHunterTitle = "achievements.item.weight_hunter.title"
            static let weightHunterDesc = "achievements.item.weight_hunter.desc"

            static let firstWeightTitle = "achievements.item.first_weight.title"
            static let firstWeightDesc = "achievements.item.first_weight.desc"

            static let trackerTitle = "achievements.item.tracker_30.title"
            static let trackerDesc = "achievements.item.tracker_30.desc"

            static let firstMealTitle = "achievements.item.first_meal.title"
            static let firstMealDesc = "achievements.item.first_meal.desc"

            static let nutritionExpertTitle = "achievements.item.nutrition_100.title"
            static let nutritionExpertDesc = "achievements.item.nutrition_100.desc"

            static let streak3Title = "achievements.item.streak_3.title"
            static let streak3Desc = "achievements.item.streak_3.desc"

            static let streak7Title = "achievements.item.streak_7.title"
            static let streak7Desc = "achievements.item.streak_7.desc"

            static let sharerTitle = "achievements.item.sharer.title"
            static let sharerDesc = "achievements.item.sharer.desc"

            static let motivatorTitle = "achievements.item.motivator_5.title"
            static let motivatorDesc = "achievements.item.motivator_5.desc"
        }
    }
    
    enum Onboarding {
        static let welcomeTitle = CommonKeys.Onboarding.welcomeTitle
        static let continueAction = CommonKeys.Onboarding.continueAction
    }
    
    enum Validation {
        static let distanceRequired = CommonKeys.Validation.distanceRequired
        static let distanceInvalidFormat = CommonKeys.Validation.distanceInvalidFormat
        static let distanceMustBePositive = CommonKeys.Validation.distanceMustBePositive
        static let distanceMinimum = CommonKeys.Validation.distanceMinimum
        static let distanceMaximum = CommonKeys.Validation.distanceMaximum
        static let distancePrecision = CommonKeys.Validation.distancePrecision
        static let heartRateRequired = CommonKeys.Validation.heartRateRequired
        static let heartRateInvalidFormat = CommonKeys.Validation.heartRateInvalidFormat
        static let heartRateMinimum = CommonKeys.Validation.heartRateMinimum
        static let heartRateMaximum = CommonKeys.Validation.heartRateMaximum
        static let heartRateAgeWarning = CommonKeys.Validation.heartRateAgeWarning
        static let durationRequired = CommonKeys.Validation.durationRequired
        static let durationInvalidFormat = CommonKeys.Validation.durationInvalidFormat
        static let durationMustBePositive = CommonKeys.Validation.durationMustBePositive
        static let durationMinimum = CommonKeys.Validation.durationMinimum
        static let durationMaximum = CommonKeys.Validation.durationMaximum
        static let timeRequired = CommonKeys.Validation.timeRequired
        static let timeInvalidFormat = CommonKeys.Validation.timeInvalidFormat
        static let timeInvalidNumbers = CommonKeys.Validation.timeInvalidNumbers
        static let hoursRange = CommonKeys.Validation.hoursRange
        static let minutesRange = CommonKeys.Validation.minutesRange
        static let secondsRange = CommonKeys.Validation.secondsRange
    }
    
    enum HeartRate {
        static let zone1 = CommonKeys.HeartRate.zone1
        static let zone2 = CommonKeys.HeartRate.zone2
        static let zone3 = CommonKeys.HeartRate.zone3
        static let zone4 = CommonKeys.HeartRate.zone4
        static let zone5 = CommonKeys.HeartRate.zone5
        static let unknown = CommonKeys.HeartRate.unknown
    }
    
    enum Health {
        static let insights = AnalyticsKeys.Insights.insights
        static let no_insights = AnalyticsKeys.Insights.no_insights
        static let no_insights_message = AnalyticsKeys.Insights.no_insights_message
        static let analyzing_health_data = "health.analyzing_health_data"
        static let recovery_score = AnalyticsKeys.Recovery.recovery_score
        static let sleep_quality = AnalyticsKeys.Recovery.sleep_quality
        static let hrv = AnalyticsKeys.Recovery.hrv
        static let vo2_max = AnalyticsKeys.Fitness.vo2_max
        static let cardio_fitness = AnalyticsKeys.Fitness.cardio_fitness
        static let overall_fitness = AnalyticsKeys.Fitness.overall_fitness
        static let poor = "health.fitness.poor"
        static let fair = "health.fitness.fair"
        static let good = "health.fitness.good"
        static let excellent = "health.fitness.excellent"
        static let elite = "health.fitness.elite"
        static let below_average = "health.fitness.below_average"
        static let above_average = "health.fitness.above_average"
        static let superior = "health.fitness.superior"
        static let trend_improving = "health.trend.improving"
        static let trend_stable = "health.trend.stable"
        static let trend_declining = "health.trend.declining"
        static let steps = "health.steps"
        static let heart_rate = "health.heart_rate"
        static let weight = "health.weight"
        static let fitness_level = "health.fitness_level"

        enum Intelligence {
            static let ai_summary = "health.intelligence.ai_summary"
            static let ai_powered_insights = "health.intelligence.ai_powered_insights"
            static let key_focus_areas = "health.intelligence.key_focus_areas"
            static let insights_title = "health.intelligence.insights_title"
            static let status_optimal = "health.intelligence.status_optimal"
            static let status_good = "health.intelligence.status_good"
            static let status_caution = "health.intelligence.status_caution"
            static let status_focus = "health.intelligence.status_focus"
            static let summary_excellent = "health.intelligence.summary_excellent"
            static let summary_good = "health.intelligence.summary_good"
            static let summary_caution = "health.intelligence.summary_caution"
            static let summary_focus = "health.intelligence.summary_focus"
            static let no_critical_areas = "health.intelligence.no_critical_areas"
            static let primary_focus = "health.intelligence.primary_focus"
            static let key_areas_two = "health.intelligence.key_areas_two"
            static let focus_areas_multiple = "health.intelligence.focus_areas_multiple"
            static let priority_insights = "health.intelligence.priority_insights"
            static let metrics_recovery = "health.intelligence.metrics_recovery"
            static let metrics_fitness = "health.intelligence.metrics_fitness"
            static let metrics_insights = "health.intelligence.metrics_insights"
            static let metrics_insights_unit = "health.intelligence.metrics_insights_unit"
            static let quick_actions = "health.intelligence.quick_actions"
            static let suggest_workout = "health.intelligence.suggest_workout"
            static let nutrition_advice = "health.intelligence.nutrition_advice"
            static let rest_recommendation = "health.intelligence.rest_recommendation"
            static let loading_title = "health.intelligence.loading_title"
            static let loading_subtitle = "health.intelligence.loading_subtitle"
            static let loading_reading_data = "health.intelligence.loading_reading_data"
            static let loading_recovery_analysis = "health.intelligence.loading_recovery_analysis"
            static let loading_fitness_assessment = "health.intelligence.loading_fitness_assessment"
            static let loading_generating_insights = "health.intelligence.loading_generating_insights"
            static let all_clear_title = "health.intelligence.all_clear_title"
            static let all_clear_message = "health.intelligence.all_clear_message"
            static let this_means = "health.intelligence.this_means"
            static let recovery_optimal = "health.intelligence.recovery_optimal"
            static let fitness_stable = "health.intelligence.fitness_stable"
            static let no_concerns = "health.intelligence.no_concerns"
            static let keep_great_work = "health.intelligence.keep_great_work"
            static let monitoring_message = "health.intelligence.monitoring_message"
            static let ready_unlock_title = "health.intelligence.ready_unlock_title"
            static let connect_data_message = "health.intelligence.connect_data_message"
            static let feature_recovery = "health.intelligence.feature_recovery"
            static let feature_fitness = "health.intelligence.feature_fitness"
            static let feature_trends = "health.intelligence.feature_trends"
            static let feature_ai_recommendations = "health.intelligence.feature_ai_recommendations"
            static let connect_apple_health = "health.intelligence.connect_apple_health"
            static let enable_insights = "health.intelligence.enable_insights"
            static let generate_insights = "health.intelligence.generate_insights"
            static let privacy_message = "health.intelligence.privacy_message"
            static let recommended_action = "health.intelligence.recommended_action"
            static let insight_details = "health.intelligence.insight_details"
            static let recovery_trend = "health.intelligence.recovery_trend"
        }

        enum Fitness {
            static let vo2_max_title = "health.fitness.vo2_max_title"
            static let vo2_max_unit = "health.fitness.vo2_max_unit"
            static let vo2_excellent = "health.fitness.vo2_excellent"
            static let vo2_good = "health.fitness.vo2_good"
            static let vo2_fair = "health.fitness.vo2_fair"
            static let vo2_poor = "health.fitness.vo2_poor"
            static let vo2_athlete_level = "health.fitness.vo2_athlete_level"
            static let vo2_above_average = "health.fitness.vo2_above_average"
            static let vo2_average = "health.fitness.vo2_average"
            static let vo2_below_average = "health.fitness.vo2_below_average"
            static let improvement_areas = "health.fitness.improvement_areas"
            static let cardio_training = "health.fitness.cardio_training"
            static let cardio_suggestion = "health.fitness.cardio_suggestion"
            static let strength_training = "health.fitness.strength_training"
            static let strength_suggestion = "health.fitness.strength_suggestion"
        }

        enum Recovery {
            static let title = "health.recovery.title"
            static let factors_title = "health.recovery.factors_title"
            static let sleep_quality = "health.recovery.sleep_quality"
            static let hrv = "health.recovery.hrv"
            static let workout_load = "health.recovery.workout_load"
        }

        enum Heart {
            static let resting_bpm = "health.heart.resting_bpm"
            static let active_bpm = "health.heart.active_bpm"
        }
    }

    enum Common {
        static let ok = CommonKeys.Onboarding.Common.ok
        static let cancel = CommonKeys.Onboarding.Common.cancel
        static let save = CommonKeys.Onboarding.Common.save
        static let delete = CommonKeys.Onboarding.Common.delete
        static let edit = CommonKeys.Onboarding.Common.edit
        static let done = CommonKeys.Onboarding.Common.done
        static let close = CommonKeys.Onboarding.Common.close
        static let back = CommonKeys.Onboarding.Common.back
        static let next = CommonKeys.Onboarding.Common.next
        static let error = CommonKeys.Onboarding.Common.error
        static let success = CommonKeys.Onboarding.Common.success
        static let loading = CommonKeys.Onboarding.Common.loading
        static let search = CommonKeys.Onboarding.Common.search
        static let all = CommonKeys.Onboarding.Common.all
        static let view_all = "common.view_all"
        static let updated = "common.updated"

        enum HealthKit {
            static let recoveryScoreTitle = CommonKeys.HealthKit.recoveryScoreTitle
            static let fitnessLevelTitle = CommonKeys.HealthKit.fitnessLevelTitle
            static let loadingMessage = CommonKeys.HealthKit.loadingMessage
        }

        enum Days {
            static let monday_short = "common.days.monday_short"
            static let tuesday_short = "common.days.tuesday_short"
            static let wednesday_short = "common.days.wednesday_short"
            static let thursday_short = "common.days.thursday_short"
            static let friday_short = "common.days.friday_short"
            static let saturday_short = "common.days.saturday_short"
            static let sunday_short = "common.days.sunday_short"
        }

        enum Time {
            static let hours = "common.time.hours"
            static let minutes = "common.time.minutes"
            static let seconds = "common.time.seconds"
            static let hour = "common.time.hour"
            static let minute = "common.time.minute"
            static let second = "common.time.second"
            static let days = "common.time.days"
            static let weeks = "common.time.weeks"
            static let months = "common.time.months"
        }
    }

    // MARK: - Analytics
    static let analytics = AnalyticsKeys.self

}

// MARK: - Convenience Extensions
extension LocalizationKeys {
    /// Gets localized string for the given key
    static func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    /// Gets localized string with format arguments
    static func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }
}