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
    }
    
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