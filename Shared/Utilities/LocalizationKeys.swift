// LocalizationKeys.swift
// SporHocam - Legacy Compatible Localization Keys

import Foundation

/// Centralized localization keys for type-safe string access
/// This version maintains compatibility with existing code structure
enum LocalizationKeys {
    
    // MARK: - Tab Bar
    enum TabBar {
        static let dashboard = "tab.dashboard"
        static let training = "tab.training"
        static let nutrition = "tab.nutrition"
        static let profile = "tab.profile"
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = "dashboard.title"
        static let welcome = "dashboard.welcome"
        static let howFeeling = "dashboard.howFeeling"
        static let quickActions = "dashboard.quickActions"
        static let recentWorkouts = "dashboard.recentWorkouts"
        static let thisWeek = "dashboard.thisWeek"
        static let seeAll = "dashboard.seeAll"
        
        enum Stats {
            static let today = "dashboard.stats.today"
            static let steps = "dashboard.stats.steps"
            static let calories = "dashboard.stats.calories"
            static let kcal = "dashboard.stats.kcal"
            static let weight = "dashboard.stats.weight"
            static let lastMeasurement = "dashboard.stats.lastMeasurement"
            static let bmi = "dashboard.stats.bmi"
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
    }
    
    // MARK: - Training
    enum Training {
        static let title = "training.title"
        static let history = "training.history"
        static let active = "training.active"
        static let templates = "training.templates"
        
        enum History {
            static let emptyTitle = "training.history.empty.title"
            static let emptySubtitle = "training.history.empty.subtitle"
            static let defaultName = "training.history.defaultName"
            static let noParts = "training.history.noParts"
            static let totalVolume = "training.history.totalVolume"
        }
        
        enum Active {
            static let emptyTitle = "training.active.empty.title"
            static let emptySubtitle = "training.active.empty.subtitle"
            static let emptyStartButton = "training.active.empty.startButton"
            static let title = "training.active.title"
            static let duration = "training.active.duration"
            static let continueAction = "training.active.continue"
            static let finish = "training.active.finish"
            static let statusActive = "training.active.status.active"
            static let statusCompleted = "training.active.status.completed"
            
            // Direct access properties for compatibility
            static let startButton = "training.active.empty.startButton"
            static let continueButton = "training.active.continue"
            
            // Legacy Status enum support
            enum Status {
                static let active = "training.active.status.active"
                static let completed = "training.active.status.completed"
            }
        }
        
        enum Stats {
            static let parts = "training.stats.parts"
            static let sets = "training.stats.sets"
            static let volume = "training.stats.volume"
            static let duration = "training.stats.duration"
        }
        
        enum New {
            static let title = "training.new.title"
            static let subtitle = "training.new.subtitle"
            static let nameLabel = "training.new.nameLabel"
            static let namePlaceholder = "training.new.namePlaceholder"
            static let quickStart = "training.new.quickStart"
            static let emptyTitle = "training.new.empty.title"
            static let emptySubtitle = "training.new.empty.subtitle"
            static let functionalTitle = "training.new.functional.title"
            static let functionalSubtitle = "training.new.functional.subtitle"
            static let cardioTitle = "training.new.cardio.title"
            static let cardioSubtitle = "training.new.cardio.subtitle"
            static let cancel = "training.new.cancel"
            
            // Nested enum support for dot notation
            enum Empty {
                static let title = "training.new.empty.title"
                static let subtitle = "training.new.empty.subtitle"
            }
            
            enum Functional {
                static let title = "training.new.functional.title"
                static let subtitle = "training.new.functional.subtitle"
            }
            
            enum Cardio {
                static let title = "training.new.cardio.title"
                static let subtitle = "training.new.cardio.subtitle"
            }
        }
        
        enum Templates {
            static let title = "training.templates.title"
            static let empty = "training.templates.empty"
        }
        
        enum Detail {
            static let back = "training.detail.back"
            static let finish = "training.detail.finish"
            static let finishWorkout = "training.detail.finishWorkout"
            static let defaultName = "training.detail.defaultName"
            static let emptyTitle = "training.detail.empty.title"
            static let emptySubtitle = "training.detail.empty.subtitle"
            static let emptyAddPart = "training.detail.empty.addPart"
            static let addPart = "training.detail.addPart"
            
            // Legacy Empty enum support
            enum Empty {
                static let title = "training.detail.empty.title"
                static let subtitle = "training.detail.empty.subtitle"
                static let addPart = "training.detail.empty.addPart"
            }
        }
        
        enum Part {
            static let strength = "training.part.strength"
            static let conditioning = "training.part.conditioning"
            static let accessory = "training.part.accessory"
            static let warmup = "training.part.warmup"
            static let functional = "training.part.functional"
            
            static let strengthDesc = "training.part.strength.desc"
            static let conditioningDesc = "training.part.conditioning.desc"
            static let accessoryDesc = "training.part.accessory.desc"
            static let warmupDesc = "training.part.warmup.desc"
            static let functionalDesc = "training.part.functional.desc"
            
            static let statusCompleted = "training.part.status.completed"
            static let statusInProgress = "training.part.status.inProgress"
            static let noExercise = "training.part.noExercise"
            static let addExercise = "training.part.addExercise"
            static let result = "training.part.result"
            
            // Legacy Status enum support
            enum Status {
                static let completed = "training.part.status.completed"
                static let inProgress = "training.part.status.inProgress"
            }
            
            // Legacy Description enum support
            enum Description {
                static let strength = "training.part.strength.desc"
                static let conditioning = "training.part.conditioning.desc"
                static let accessory = "training.part.accessory.desc"
                static let warmup = "training.part.warmup.desc"
                static let functional = "training.part.functional.desc"
            }
        }
        
        enum AddPart {
            static let title = "training.addPart.title"
            static let subtitle = "training.addPart.subtitle"
            static let nameLabel = "training.addPart.nameLabel"
            static let namePlaceholder = "training.addPart.namePlaceholder"
            static let typeLabel = "training.addPart.typeLabel"
            static let add = "training.addPart.add"
            static let cancel = "training.addPart.cancel"
        }
        
        enum Exercise {
            static let title = "training.exercise.title"
            static let searchPlaceholder = "training.exercise.searchPlaceholder"
            static let clear = "training.exercise.clear"
            static let all = "training.exercise.all"
            static let cancel = "training.exercise.cancel"
            static let addCustom = "training.exercise.addCustom"
            static let emptyTitle = "training.exercise.empty.title"
            static let emptySubtitle = "training.exercise.empty.subtitle"
            static let emptySearchTitle = "training.exercise.empty.searchTitle"
            static let emptySearchSubtitle = "training.exercise.empty.searchSubtitle"
            
            static let setCount = "training.exercise.setCount"
            static let addSet = "training.exercise.addSet"
            static let setNumber = "training.exercise.setNumber"
            static let moreSets = "training.exercise.moreSets"
        }
        
        enum Category {
            static let push = "training.category.push"
            static let pull = "training.category.pull"
            static let legs = "training.category.legs"
            static let core = "training.category.core"
            static let cardio = "training.category.cardio"
            static let olympic = "training.category.olympic"
            static let functional = "training.category.functional"
            static let isolation = "training.category.isolation"
            static let other = "training.category.other"
        }
        
        enum Set {
            static let back = "training.set.back"
            static let save = "training.set.save"
            static let equipment = "training.set.equipment"
            
            enum Header {
                static let set = "training.set.header.set"
                static let weight = "training.set.header.weight"
                static let reps = "training.set.header.reps"
                static let time = "training.set.header.time"
                static let distance = "training.set.header.distance"
                static let rpe = "training.set.header.rpe"
            }
            
            static let addSet = "training.set.addSet"
            static let notes = "training.set.notes"
            static let notesPlaceholder = "training.set.notesPlaceholder"
            static let rest = "training.set.rest"
            static let finishExercise = "training.set.finishExercise"
            
            static let kg = "training.set.kg"
            static let reps = "training.set.reps"
            static let meters = "training.set.meters"
            static let completed = "training.set.completed"
        }
        
        enum Rest {
            static let title = "training.rest.title"
            static let close = "training.rest.close"
            static let remaining = "training.rest.remaining"
            static let reset = "training.rest.reset"
            static let start = "training.rest.start"
            static let pause = "training.rest.pause"
            static let skip = "training.rest.skip"
            
            enum Preset {
                static let title = "training.rest.preset.title"
                static let subtitle = "training.rest.preset.subtitle"
                static let cancel = "training.rest.preset.cancel"
                static let short = "training.rest.preset.short"
                static let shortDesc = "training.rest.preset.short.desc"
                static let medium = "training.rest.preset.medium"
                static let mediumDesc = "training.rest.preset.medium.desc"
                static let long = "training.rest.preset.long"
                static let longDesc = "training.rest.preset.long.desc"
                static let power = "training.rest.preset.power"
                static let powerDesc = "training.rest.preset.power.desc"
                static let custom = "training.rest.preset.custom"
                static let customDesc = "training.rest.preset.custom.desc"
            }
            
            enum Custom {
                static let title = "training.rest.custom.title"
                static let label = "training.rest.custom.label"
                static let minutes = "training.rest.custom.minutes"
                static let set = "training.rest.custom.set"
                static let cancel = "training.rest.custom.cancel"
            }
        }
        
        enum Time {
            static let hours = "training.time.hours"
            static let minutes = "training.time.minutes"
            static let seconds = "training.time.seconds"
        }
    }
    
    // MARK: - Nutrition
    enum Nutrition {
        static let title = "nutrition.title"
        static let addFood = "nutrition.addFood"
        static let calories = "nutrition.calories"
        
        enum DailySummary {
            static let title = "nutrition.dailySummary.title"
            static let total = "nutrition.dailySummary.total"
            static let protein = "nutrition.dailySummary.protein"
            static let carbs = "nutrition.dailySummary.carbs"
            static let fat = "nutrition.dailySummary.fat"
        }
        
        enum DailyGoals {
            static let title = "nutrition.dailyGoals.title"
            static let per100g = "nutrition.dailyGoals.per100g"
            static let achievementMessage = "nutrition.dailyGoals.achievementMessage"
        }
        
        enum FoodSelection {
            static let title = "nutrition.foodSelection.title"
            static let searchPlaceholder = "nutrition.foodSelection.searchPlaceholder"
            static let clear = "nutrition.foodSelection.clear"
            static let all = "nutrition.foodSelection.all"
            static let cancel = "nutrition.foodSelection.cancel"
            static let addNew = "nutrition.foodSelection.addNew"
            static let noResults = "nutrition.foodSelection.noResults"
            static let noResultsForSearch = "nutrition.foodSelection.noResultsForSearch"
            static let tryDifferentTerms = "nutrition.foodSelection.tryDifferentTerms"
        }
        
        enum MealEntry {
            static let title = "nutrition.mealEntry.title"
            static let addToMeal = "nutrition.mealEntry.addToMeal"
            static let cancel = "nutrition.mealEntry.cancel"
            static let portion = "nutrition.mealEntry.portion"
            static let portionGrams = "nutrition.mealEntry.portionGrams"
            static let meal = "nutrition.mealEntry.meal"
            static let total = "nutrition.mealEntry.total"
            static let per100gCalories = "nutrition.mealEntry.per100gCalories"
            
            enum MealTypes {
                static let breakfast = "nutrition.mealEntry.mealTypes.breakfast"
                static let lunch = "nutrition.mealEntry.mealTypes.lunch"
                static let dinner = "nutrition.mealEntry.mealTypes.dinner"
                static let snack = "nutrition.mealEntry.mealTypes.snack"
            }
        }
        
        enum CustomFood {
            static let title = "nutrition.customFood.title"
            static let newFood = "nutrition.customFood.newFood"
            static let addNewFood = "nutrition.customFood.addNewFood"
            static let subtitle = "nutrition.customFood.subtitle"
            static let basicInfo = "nutrition.customFood.basicInfo"
            static let foodName = "nutrition.customFood.foodName"
            static let foodNameRequired = "nutrition.customFood.foodNameRequired"
            static let foodNamePlaceholder = "nutrition.customFood.foodNamePlaceholder"
            static let brand = "nutrition.customFood.brand"
            static let brandOptional = "nutrition.customFood.brandOptional"
            static let brandPlaceholder = "nutrition.customFood.brandPlaceholder"
            static let category = "nutrition.customFood.category"
            static let nutritionValues = "nutrition.customFood.nutritionValues"
            static let per100g = "nutrition.customFood.per100g"
            static let caloriesRequired = "nutrition.customFood.caloriesRequired"
            static let protein = "nutrition.customFood.protein"
            static let carbs = "nutrition.customFood.carbs"
            static let fat = "nutrition.customFood.fat"
            static let preview = "nutrition.customFood.preview"
            static let addFood = "nutrition.customFood.addFood"
            static let cancel = "nutrition.customFood.cancel"
            static let error = "nutrition.customFood.error"
            static let ok = "nutrition.customFood.ok"
        }
        
        enum Favorites {
            static let favorites = "nutrition.favorites.favorites"
            static let recent = "nutrition.favorites.recent"
            static let popular = "nutrition.favorites.popular"
            static let timesUsed = "nutrition.favorites.timesUsed"
        }
        
        enum Analytics {
            static let title = "nutrition.analytics.title"
            static let weeklyAnalysis = "nutrition.analytics.weeklyAnalysis"
            static let dailyCalories = "nutrition.analytics.dailyCalories"
            static let weeklyAverage = "nutrition.analytics.weeklyAverage"
        }
        
        enum Test {
            static let addTestFood = "nutrition.test.addTestFood"
            static let clear = "nutrition.test.clear"
        }
        
        enum Units {
            static let kcal = "nutrition.units.kcal"
            static let grams = "nutrition.units.grams"
            static let g = "nutrition.units.g"
        }
        
        enum Days {
            static let sunday = "nutrition.days.sunday"
            static let monday = "nutrition.days.monday"
            static let tuesday = "nutrition.days.tuesday"
            static let wednesday = "nutrition.days.wednesday"
            static let thursday = "nutrition.days.thursday"
            static let friday = "nutrition.days.friday"
            static let saturday = "nutrition.days.saturday"
        }
    }
    
    // MARK: - Profile
    enum Profile {
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
        
        // MARK: - Nested structure for new code (Optional)
        enum Welcome {
            static let title = "onboarding.welcome.title"
            static let subtitle = "onboarding.welcome.subtitle"
            static let start = "onboarding.welcome.start"
        }
        
        enum Feature {
            static let workout = "onboarding.feature.workout"
            static let progress = "onboarding.feature.progress"
            static let nutrition = "onboarding.feature.nutrition"
            static let goals = "onboarding.feature.goals"
        }
        
        enum Progress {
            static let step = "onboarding.progress.step"
        }
        
        enum PersonalInfo {
            static let title = "onboarding.personalInfo.title"
            static let subtitle = "onboarding.personalInfo.subtitle"
            static let name = "onboarding.personalInfo.name"
            static let namePlaceholder = "onboarding.personalInfo.name.placeholder"
            static let age = "onboarding.personalInfo.age"
            static let ageYears = "onboarding.personalInfo.age.years"
            static let gender = "onboarding.personalInfo.gender"
            static let genderMale = "onboarding.personalInfo.gender.male"
            static let genderFemale = "onboarding.personalInfo.gender.female"
            static let height = "onboarding.personalInfo.height"
            static let weight = "onboarding.personalInfo.weight"
        }
        
        enum Goals {
            static let title = "onboarding.goals.title"
            static let subtitle = "onboarding.goals.subtitle"
            static let mainGoal = "onboarding.goals.mainGoal"
            static let activityLevel = "onboarding.goals.activityLevel"
            static let targetWeight = "onboarding.goals.targetWeight"
            static let targetWeightToggle = "onboarding.goals.targetWeight.toggle"
            
            enum Cut {
                static let title = "onboarding.goals.cut.title"
                static let subtitle = "onboarding.goals.cut.subtitle"
            }
            
            enum Bulk {
                static let title = "onboarding.goals.bulk.title"
                static let subtitle = "onboarding.goals.bulk.subtitle"
            }
            
            enum Maintain {
                static let title = "onboarding.goals.maintain.title"
                static let subtitle = "onboarding.goals.maintain.subtitle"
            }
        }
        
        enum Activity {
            static let sedentary = "onboarding.activity.sedentary"
            static let sedentaryDesc = "onboarding.activity.sedentary.desc"
            static let light = "onboarding.activity.light"
            static let lightDesc = "onboarding.activity.light.desc"
            static let moderate = "onboarding.activity.moderate"
            static let moderateDesc = "onboarding.activity.moderate.desc"
            static let active = "onboarding.activity.active"
            static let activeDesc = "onboarding.activity.active.desc"
            static let veryActive = "onboarding.activity.veryActive"
            static let veryActiveDesc = "onboarding.activity.veryActive.desc"
        }
        
        enum Measurements {
            static let title = "onboarding.measurements.title"
            static let subtitle = "onboarding.measurements.subtitle"
            static let navyMethod = "onboarding.measurements.navyMethod"
            static let navyMethodDesc = "onboarding.measurements.navyMethod.desc"
            static let neck = "onboarding.measurements.neck"
            static let waistMale = "onboarding.measurements.waist.male"
            static let waistFemale = "onboarding.measurements.waist.female"
            static let hip = "onboarding.measurements.hip"
            
            enum BodyFat {
                static let title = "onboarding.measurements.bodyFat.title"
                static let navy = "onboarding.measurements.bodyFat.navy"
            }
            
            enum Optional {
                static let info = "onboarding.measurements.optional.info"
                static let desc = "onboarding.measurements.optional.desc"
            }
            
            static let skip = "onboarding.measurements.skip"
            static let optional = "onboarding.measurements.optional"
        }
        
        enum Summary {
            static let title = "onboarding.summary.title"
            static let subtitle = "onboarding.summary.subtitle"
            static let profile = "onboarding.summary.profile"
            static let goals = "onboarding.summary.goals"
            static let calculatedValues = "onboarding.summary.calculatedValues"
            static let macroGoals = "onboarding.summary.macroGoals"
            
            enum Info {
                static let title = "onboarding.summary.info.title"
                static let withNavy = "onboarding.summary.info.withNavy"
                static let withoutNavy = "onboarding.summary.info.withoutNavy"
            }
            
            static let startApp = "onboarding.summary.startApp"
            
            enum Label {
                static let name = "onboarding.summary.label.name"
                static let age = "onboarding.summary.label.age"
                static let gender = "onboarding.summary.label.gender"
                static let height = "onboarding.summary.label.height"
                static let weight = "onboarding.summary.label.weight"
                static let targetWeight = "onboarding.summary.label.targetWeight"
                static let mainGoal = "onboarding.summary.label.mainGoal"
                static let activity = "onboarding.summary.label.activity"
                static let bmr = "onboarding.summary.label.bmr"
                static let bmrKatch = "onboarding.summary.label.bmr.katch"
                static let bmrMifflin = "onboarding.summary.label.bmr.mifflin"
                static let lbm = "onboarding.summary.label.lbm"
                static let bodyFat = "onboarding.summary.label.bodyFat"
                static let tdee = "onboarding.summary.label.tdee"
                static let dailyCalorie = "onboarding.summary.label.dailyCalorie"
                static let protein = "onboarding.summary.label.protein"
                static let carbs = "onboarding.summary.label.carbs"
                static let fat = "onboarding.summary.label.fat"
            }
        }
    }
    
    // Mevcut LocalizationKeys.swift dosyanıza aşağıdaki bölümleri ekleyin
    // Profile bölümünden sonra, Common bölümünden önce ekleyin

        // MARK: - Measurements (EKSİK BÖLÜM - EKLE)
        enum Measurements {
            static let title = "measurements.title"
            static let bodyMeasurements = "measurements.body_measurements"
            static let addMeasurement = "measurements.add_measurement"
            static let editMeasurement = "measurements.edit_measurement"
            static let date = "measurements.date"
            static let weight = "measurements.weight"
            static let bodyFat = "measurements.body_fat"
            static let neck = "measurements.neck"
            static let waist = "measurements.waist"
            static let hips = "measurements.hips"
            static let notes = "measurements.notes"
            static let save = "measurements.save"
            static let cancel = "measurements.cancel"
            static let delete = "measurements.delete"
            static let confirmDelete = "measurements.confirm_delete"
            static let deleteMessage = "measurements.delete_message"
            static let noMeasurements = "measurements.no_measurements"
            static let addFirstMeasurement = "measurements.add_first_measurement"
            static let kg = "measurements.kg"
            static let cm = "measurements.cm"
            static let percent = "measurements.percent"
        }
        
        // MARK: - Analytics (EKSİK BÖLÜM - EKLE)
        enum Analytics {
            static let title = "analytics.title"
            static let progressAnalytics = "analytics.progress_analytics"
            static let goals = "analytics.goals"
            static let achievements = "analytics.achievements"
            static let weeklyProgress = "analytics.weekly_progress"
            static let bodyComposition = "analytics.body_composition"
            static let performanceMetrics = "analytics.performance_metrics"
            static let noData = "analytics.no_data"
            static let addDataToSeeAnalytics = "analytics.add_data_to_see_analytics"
            static let currentGoals = "analytics.current_goals"
            static let goalProgress = "analytics.goal_progress"
            static let weightGoal = "analytics.weight_goal"
            static let fitnessGoal = "analytics.fitness_goal"
            static let dailyCalories = "analytics.daily_calories"
            static let weeklyWorkouts = "analytics.weekly_workouts"
            static let targetWeight = "analytics.target_weight"
            static let currentWeight = "analytics.current_weight"
            static let totalWorkouts = "analytics.total_workouts"
            static let totalDuration = "analytics.total_duration"
            static let averageWorkout = "analytics.average_workout"
            static let personalRecords = "analytics.personal_records"
            static let streakDays = "analytics.streak_days"
            static let caloriesBurned = "analytics.calories_burned"
            static let thisWeek = "analytics.this_week"
            static let thisMonth = "analytics.this_month"
            static let last30Days = "analytics.last_30_days"
            static let allTime = "analytics.all_time"
        }

        // MARK: - Body Measurements (BodyMeasurementView için ek anahtarlar)
        enum BodyMeasurements {
            static let subtitle = "body_measurements.subtitle"
            static let measurementSaved = "body_measurements.measurement_saved"
            static let savedMessage = "body_measurements.saved_message"
            static let currentMeasurements = "body_measurements.current_measurements"
            static let progressSummary = "body_measurements.progress_summary"
            static let totalMeasurements = "body_measurements.total_measurements"
            static let last6Months = "body_measurements.last_6_months"
            static let weightEntries = "body_measurements.weight_entries"
            static let lastMeasurement = "body_measurements.last_measurement"
            static let activeMeasurementTypes = "body_measurements.active_tracking"
            static let measurementTypes = "body_measurements.measurement_types"
            static let recentEntries = "body_measurements.recent_entries"
            static let noMeasurements = "body_measurements.no_measurements"
            static let firstTip = "body_measurements.first_tip"
            static let measurementTips = "body_measurements.measurement_tips"
            static let correctTiming = "body_measurements.correct_timing"
            static let timingDesc = "body_measurements.timing_desc"
            static let correctTechnique = "body_measurements.correct_technique"
            static let techniqueDesc = "body_measurements.technique_desc"
            static let regularTracking = "body_measurements.regular_tracking"
            static let trackingDesc = "body_measurements.tracking_desc"
            static let trendFocus = "body_measurements.trend_focus"
            static let trendDesc = "body_measurements.trend_desc"
            static let addNew = "body_measurements.add_new"
        }
    
    // Mevcut LocalizationKeys.swift dosyanızın Profile bölümünden sonra,
    // Common bölümünden önce bu bölümleri ekleyin:

        
        
    // MARK: - Common
    enum Common {
        static let save = "common.save"
        static let cancel = "common.cancel"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let add = "common.add"
        static let close = "common.close"
        static let done = "common.done"
        static let ok = "common.ok"
        static let yes = "common.yes"
        static let no = "common.no"
        static let error = "common.error"
        static let success = "common.success"
        static let loading = "common.loading"
        static let retry = "common.retry"
        static let user = "common.user"
    }
    
    // MARK: - Action Keys (Legacy compatibility)
    enum Action {
        static let save = "action.save"
        static let cancel = "action.cancel"
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

