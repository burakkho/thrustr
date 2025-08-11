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
            static let olympic = "training.part.olympic"
            static let plyometric = "training.part.plyometric"
            
            static let strengthDesc = "training.part.strength.desc"
            static let conditioningDesc = "training.part.conditioning.desc"
            static let accessoryDesc = "training.part.accessory.desc"
            static let warmupDesc = "training.part.warmup.desc"
            static let functionalDesc = "training.part.functional.desc"
            static let olympicDesc = "training.part.olympic.desc"
            static let plyometricDesc = "training.part.plyometric.desc"
            
            static let statusCompleted = "training.part.status.completed"
            static let statusInProgress = "training.part.status.inProgress"
            static let noExercise = "training.part.noExercise"
            static let addExercise = "training.part.addExercise"
            static let result = "training.part.result"
            // Context menu actions
            static let rename = "training.part.rename"
            static let moveUp = "training.part.moveUp"
            static let moveDown = "training.part.moveDown"
            static let markCompletedAction = "training.part.markCompleted"
            static let markInProgressAction = "training.part.markInProgress"
            static let deletePart = "training.part.deletePart"
            
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
                static let olympic = "training.part.olympic.desc"
                static let plyometric = "training.part.plyometric.desc"
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
                static let customLabel = "training.rest.preset.custom.label"
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



        // MARK: - Preferences
        enum Preferences {
            static let title = "preferences.title"
            static let language = "preferences.language"
            static let theme = "preferences.theme"
            static let units = "preferences.units"
            static let notifications = "preferences.notifications"
            static let soundEffects = "preferences.sound_effects"
            static let timerSounds = "preferences.timer_sounds"
            static let hapticFeedback = "preferences.haptic_feedback"
            static let vibrationFeedback = "preferences.vibration_feedback"
            static let appInfo = "preferences.app_info"
            static let systemDefault = "preferences.system_default"
            static let alwaysLight = "preferences.always_light"
            static let alwaysDark = "preferences.always_dark"
            static let autoLanguage = "preferences.auto_language"
            static let notificationsAll = "preferences.notifications_all"
            static let workoutRemindersDesc = "preferences.workout_reminders_desc"
            static let nutritionRemindersDesc = "preferences.nutrition_reminders_desc"
        }

        // MARK: - Progress Photos
        enum ProgressPhotos {
            static let title = "progress_photos.title"
            static let subtitle = "progress_photos.subtitle"
            static let addFirst = "progress_photos.add_first"
            static let addPhoto = "progress_photos.add_photo"
            static let photoType = "progress_photos.photo_type"
            static let selectPhoto = "progress_photos.select_photo"
            static let cameraGallery = "progress_photos.camera_gallery"
            static let notesOptional = "progress_photos.notes_optional"
            static let notesPlaceholder = "progress_photos.notes_placeholder"
            static let selectSource = "progress_photos.select_source"
            static let camera = "progress_photos.camera"
            static let gallery = "progress_photos.gallery"
            static let deletePhoto = "progress_photos.delete_photo"
            static let deleteMessage = "progress_photos.delete_message"
            static let photoTypes = "progress_photos.photo_types"
            static let noPhoto = "progress_photos.no_photo"
            static let photosCount = "progress_photos.photos_count"
            static let timeline = "progress_photos.timeline"
            static let fullScreen = "progress_photos.full_screen"
        }

        // MARK: - Measurement Types
        enum MeasurementTypes {
            static let chest = "measurement_chest"
            static let waist = "measurement_waist"
            static let hips = "measurement_hips"
            static let leftArm = "measurement_left_arm"
            static let rightArm = "measurement_right_arm"
            static let leftThigh = "measurement_left_thigh"
            static let rightThigh = "measurement_right_thigh"
            static let neck = "measurement_neck"
        }
        
        // MARK: - Achievements
        enum Achievements {
            static let title = "achievements.title"
            static let subtitle = "achievements.subtitle"
            static let noAchievements = "achievements.no_achievements"
            static let noAchievementsDesc = "achievements.no_achievements_desc"
            static let recentAchievements = "achievements.recent_achievements"
            static let allAchievements = "achievements.all_achievements"
            static let unlocked = "achievements.unlocked"
            static let locked = "achievements.locked"
            static let progress = "achievements.progress"
            static let points = "achievements.points"
            static let level = "achievements.level"
            static let nextLevel = "achievements.next_level"
            static let totalPoints = "achievements.total_points"

        // Categories
        enum Category {
            static let all = "achievements.category.all"
            static let workout = "achievements.category.workout"
            static let weight = "achievements.category.weight"
            static let nutrition = "achievements.category.nutrition"
            static let streak = "achievements.category.streak"
            static let social = "achievements.category.social"
        }

        // Items (Titles & Descriptions)
        enum Item {
            // Workout
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

            // Weight
            static let firstWeightTitle = "achievements.item.first_weight.title"
            static let firstWeightDesc = "achievements.item.first_weight.desc"
            static let trackerTitle = "achievements.item.tracker_30.title"
            static let trackerDesc = "achievements.item.tracker_30.desc"

            // Nutrition
            static let firstMealTitle = "achievements.item.first_meal.title"
            static let firstMealDesc = "achievements.item.first_meal.desc"
            static let nutritionExpertTitle = "achievements.item.nutrition_100.title"
            static let nutritionExpertDesc = "achievements.item.nutrition_100.desc"

            // Streak
            static let streak3Title = "achievements.item.streak_3.title"
            static let streak3Desc = "achievements.item.streak_3.desc"
            static let streak7Title = "achievements.item.streak_7.title"
            static let streak7Desc = "achievements.item.streak_7.desc"

            // Social
            static let sharerTitle = "achievements.item.sharer.title"
            static let sharerDesc = "achievements.item.sharer.desc"
            static let motivatorTitle = "achievements.item.motivator_5.title"
            static let motivatorDesc = "achievements.item.motivator_5.desc"
        }
        }
        
        // MARK: - Goal Tracking
        enum GoalTracking {
            static let title = "goal_tracking.title"
            static let subtitle = "goal_tracking.subtitle"
            static let currentGoals = "goal_tracking.current_goals"
            static let completedGoals = "goal_tracking.completed_goals"
            static let addGoal = "goal_tracking.add_goal"
            static let editGoal = "goal_tracking.edit_goal"
            static let deleteGoal = "goal_tracking.delete_goal"
            static let goalType = "goal_tracking.goal_type"
            static let goalTarget = "goal_tracking.goal_target"
            static let goalDeadline = "goal_tracking.goal_deadline"
            static let goalProgress = "goal_tracking.goal_progress"
            static let goalCompleted = "goal_tracking.goal_completed"
            static let goalFailed = "goal_tracking.goal_failed"
            static let goalInProgress = "goal_tracking.goal_in_progress"
        }
        
        // MARK: - Progress Charts
        enum ProgressCharts {
            static let title = "progress_charts.title"
            static let subtitle = "progress_charts.subtitle"
            static let weightChart = "progress_charts.weight_chart"
            static let bodyFatChart = "progress_charts.body_fat_chart"
            static let muscleChart = "progress_charts.muscle_chart"
            static let workoutChart = "progress_charts.workout_chart"
            static let nutritionChart = "progress_charts.nutrition_chart"
            static let timeRange = "progress_charts.time_range"
            static let week = "progress_charts.week"
            static let month = "progress_charts.month"
            static let year = "progress_charts.year"
            static let allTime = "progress_charts.all_time"
            static let noData = "progress_charts.no_data"
            static let noDataDesc = "progress_charts.no_data_desc"

            // Added: specific time shortcuts for chips
            static let range1w = "progress_charts.range_1w"
            static let range1m = "progress_charts.range_1m"
            static let range3m = "progress_charts.range_3m"
            static let range6m = "progress_charts.range_6m"
            static let range1y = "progress_charts.range_1y"

            // Added: chart type section and options used in UI chips
            static let chartType = "progress_charts.chart_type"
            static let typeWeightChange = "progress_charts.type.weight_change"
            static let typeWorkoutVolume = "progress_charts.type.workout_volume"
            static let typeWorkoutFrequency = "progress_charts.type.workout_frequency"
            static let typeBodyMeasurements = "progress_charts.type.body_measurements"

            // Added: empty state messages per chart
            static let emptyWeightChange = "progress_charts.empty.weight_change"
            static let emptyWorkoutVolume = "progress_charts.empty.workout_volume"
            static let emptyWorkoutFrequency = "progress_charts.empty.workout_frequency"
            static let emptyBodyMeasurements = "progress_charts.empty.body_measurements"

            // Added: axis labels and fallback note
            static let axisDate = "progress_charts.axis.date"
            static let axisWeight = "progress_charts.axis.weight"
            static let axisWeek = "progress_charts.axis.week"
            static let axisVolume = "progress_charts.axis.volume"
            static let axisFrequency = "progress_charts.axis.frequency"
            static let fallbackRequiresIOS16 = "progress_charts.fallback_requires_ios16"

            // Added: statistics and insights
            static let statsTitle = "progress_charts.stats.title"
            static let statsWeightChange = "progress_charts.stats.weight_change"
            static let statsAverageWeight = "progress_charts.stats.average_weight"
            static let statsEntryCount = "progress_charts.stats.entry_count"
            static let statsLatest = "progress_charts.stats.latest"
            static let statsTotalWorkouts = "progress_charts.stats.total_workouts"
            static let statsWeeklyAvg = "progress_charts.stats.weekly_avg"
            static let statsTotalVolume = "progress_charts.stats.total_volume"
            static let statsAverageVolume = "progress_charts.stats.average_volume"

            static let insightsTitle = "progress_charts.insights.title"
            static let insightsInsufficientData = "progress_charts.insights.insufficient_data"
            static let insightsTrendUp = "progress_charts.insights.trend_up"
            static let insightsTrendDown = "progress_charts.insights.trend_down"
            static let insightsTrendStable = "progress_charts.insights.trend_stable"
            static let insightsWeightTrend = "progress_charts.insights.weight_trend"
            static let insightsWorkoutConsistency = "progress_charts.insights.workout_consistency"
            static let consistencyExcellent = "progress_charts.insights.consistency.excellent"
            static let consistencyGood = "progress_charts.insights.consistency.good"
            static let consistencyAverage = "progress_charts.insights.consistency.average"
            static let consistencyLow = "progress_charts.insights.consistency.low"
            static let insightsEmptyDesc = "progress_charts.insights.empty_desc"
            static let bodyMeasurementsInfo = "progress_charts.body_measurements.info"
        }
        
        // MARK: - Weight Tracking
        enum WeightTracking {
            static let title = "weight_tracking.title"
            static let subtitle = "weight_tracking.subtitle"
            static let addWeight = "weight_tracking.add_weight"
            static let editWeight = "weight_tracking.edit_weight"
            static let deleteWeight = "weight_tracking.delete_weight"
            static let weightEntry = "weight_tracking.weight_entry"
            static let weightUnit = "weight_tracking.weight_unit"
            static let date = "weight_tracking.date"
            static let notes = "weight_tracking.notes"
            static let notesPlaceholder = "weight_tracking.notes_placeholder"
            static let currentWeight = "weight_tracking.current_weight"
            static let startingWeight = "weight_tracking.starting_weight"
            static let goalWeight = "weight_tracking.goal_weight"
            static let weightChange = "weight_tracking.weight_change"
            static let averageWeight = "weight_tracking.average_weight"
            static let trend = "weight_tracking.trend"
            static let gaining = "weight_tracking.gaining"
            static let losing = "weight_tracking.losing"
            static let maintaining = "weight_tracking.maintaining"
        }
        
        // MARK: - Body Tracking
        enum BodyTracking {
            static let title = "body_tracking.title"
            static let subtitle = "body_tracking.subtitle"
            static let bodyComposition = "body_tracking.body_composition"
            static let bodyFat = "body_tracking.body_fat"
            static let muscleMass = "body_tracking.muscle_mass"
            static let waterWeight = "body_tracking.water_weight"
            static let boneMass = "body_tracking.bone_mass"
            static let visceralFat = "body_tracking.visceral_fat"
            static let bmi = "body_tracking.bmi"
            static let bmr = "body_tracking.bmr"
            static let tdee = "body_tracking.tdee"
            static let lbm = "body_tracking.lbm"
            static let ffmi = "body_tracking.ffmi"
        }
        
        // MARK: - Help & Support
        enum Help {
            static let title = "help.title"
            static let subtitle = "help.subtitle"
            static let faq = "help.faq"
            static let contact = "help.contact"
            static let feedback = "help.feedback"
            static let bugReport = "help.bug_report"
            static let featureRequest = "help.feature_request"
            static let email = "help.email"
            static let website = "help.website"
            static let privacyPolicy = "help.privacy_policy"
            static let termsOfService = "help.terms_of_service"
            static let about = "help.about"
            static let version = "help.version"
            static let build = "help.build"
        }
        
        // MARK: - Logout
        enum Logout {
            static let title = "logout.title"
            static let message = "logout.message"
            static let confirm = "logout.confirm"
            static let cancel = "logout.cancel"
            static let success = "logout.success"
            static let error = "logout.error"
        }
        
        // MARK: - Tools
        enum Tools {
            static let title = "tools.title"
            static let subtitle = "tools.subtitle"
            static let calculators = "tools.calculators"
            static let converters = "tools.converters"
            static let planners = "tools.planners"
            static let trackers = "tools.trackers"
        }
        
        // MARK: - Progress Reports
        enum ProgressReports {
            static let title = "progress_reports.title"
            static let subtitle = "progress_reports.subtitle"
            static let generateReport = "progress_reports.generate_report"
            static let weeklyReport = "progress_reports.weekly_report"
            static let monthlyReport = "progress_reports.monthly_report"
            static let customReport = "progress_reports.custom_report"
            static let exportReport = "progress_reports.export_report"
            static let shareReport = "progress_reports.share_report"
            static let reportDate = "progress_reports.report_date"
            static let reportPeriod = "progress_reports.report_period"
        }
        
        // MARK: - Edit Profile
        enum EditProfile {
            static let title = "edit_profile.title"
            static let subtitle = "edit_profile.subtitle"
            static let saveChanges = "edit_profile.save_changes"
            static let discardChanges = "edit_profile.discard_changes"
            static let changesSaved = "edit_profile.changes_saved"
            static let errorSaving = "edit_profile.error_saving"
        }
        
        // MARK: - Calculator Specific
        enum FFMICalculator {
            static let title = "ffmi_calculator.title"
            static let subtitle = "ffmi_calculator.subtitle"
            static let height = "ffmi_calculator.height"
            static let weight = "ffmi_calculator.weight"
            static let bodyFat = "ffmi_calculator.body_fat"
            static let calculate = "ffmi_calculator.calculate"
            static let result = "ffmi_calculator.result"
            static let interpretation = "ffmi_calculator.interpretation"
        }
        
        enum OneRMCalculator {
            static let title = "one_rm_calculator.title"
            static let subtitle = "one_rm_calculator.subtitle"
            static let exercise = "one_rm_calculator.exercise"
            static let weight = "one_rm_calculator.weight"
            static let reps = "one_rm_calculator.reps"
            static let calculate = "one_rm_calculator.calculate"
            static let result = "one_rm_calculator.result"
            static let formula = "one_rm_calculator.formula"
        }
        
        enum NavyMethodCalculator {
            static let title = "navy_method_calculator.title"
            static let subtitle = "navy_method_calculator.subtitle"
            static let height = "navy_method_calculator.height"
            static let neck = "navy_method_calculator.neck"
            static let waist = "navy_method_calculator.waist"
            static let hip = "navy_method_calculator.hip"
            static let gender = "navy_method_calculator.gender"
            static let calculate = "navy_method_calculator.calculate"
            static let result = "navy_method_calculator.result"
            static let bodyFatPercentage = "navy_method_calculator.body_fat_percentage"
        }
        
        enum FitnessCalculators {
            static let title = "fitness_calculators.title"
            static let subtitle = "fitness_calculators.subtitle"
            static let bmr = "fitness_calculators.bmr"
            static let tdee = "fitness_calculators.tdee"
            static let bmi = "fitness_calculators.bmi"
            static let bodyFat = "fitness_calculators.body_fat"
            static let oneRM = "fitness_calculators.one_rm"
            static let ffmi = "fitness_calculators.ffmi"
        }
        
        // MARK: - BMI Categories
        enum BMI {
            static let underweight = "bmi_underweight"
            static let normal = "bmi_normal"
            static let overweight = "bmi_overweight"
            static let obese = "bmi_obese"
            static let unknown = "bmi_unknown"
        }
        
        // MARK: - Goal Status
        enum GoalStatus {
            static let completed = "goal_status_completed"
            static let expired = "goal_status_expired"
            static let daysRemaining = "goal_status_days_remaining"
            static let endsToday = "goal_status_ends_today"
            static let active = "goal_status_active"
        }
        
        // MARK: - Goal Units
        enum GoalUnits {
            static let weight = "goal_unit_weight"
            static let bodyFat = "goal_unit_body_fat"
            static let muscle = "goal_unit_muscle"
            static let workout = "goal_unit_workout"
            static let nutrition = "goal_unit_nutrition"
        }
        
        // MARK: - Goal Types
        enum GoalTypes {
            static let weight = "goal_type_weight"
            static let bodyFat = "goal_type_body_fat"
            static let muscle = "goal_type_muscle"
            static let workout = "goal_type_workout"
            static let nutrition = "goal_type_nutrition"
        }
        
        // MARK: - Measurement Categories
        enum MeasurementCategories {
            static let bodyComposition = "measurement_category_body_composition"
            static let bodyMeasurements = "measurement_category_body_measurements"
            static let performance = "measurement_category_performance"
            static let nutrition = "measurement_category_nutrition"
        }
        

        
        // MARK: - Photo Types
        enum PhotoTypes {
            static let front = "photo_type_front"
            static let back = "photo_type_back"
            static let side = "photo_type_side"
            static let progress = "photo_type_progress"
        }
        
        // MARK: - Photo Instructions
        enum PhotoInstructions {
            static let front = "photo_instruction_front"
            static let back = "photo_instruction_back"
            static let side = "photo_instruction_side"
            static let progress = "photo_instruction_progress"
        }
    
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
        static let completed = "common.completed"
        static let category = "common.category"
        static let categoryStats = "common.category_stats"
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

