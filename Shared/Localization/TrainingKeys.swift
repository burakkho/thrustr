import Foundation

/// Training feature localization keys
enum TrainingKeys {
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
        static let seeMore = "training.history.seeMore"
        static let `repeat` = "training.history.repeat"
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
        // Added keys for multi-active UI
        static let multipleTitle = "training.active.multiple.title"
        
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
    
    enum CardioSummary {
        static let congratulations = "cardio.summary.congratulations"
        static let workoutCompleted = "cardio.summary.workoutCompleted"
        static let duration = "cardio.summary.duration"
        static let distance = "cardio.summary.distance"
        static let calories = "cardio.summary.calories"
        static let yourRoute = "cardio.summary.yourRoute"
        static let routeStart = "cardio.summary.routeStart"
        static let routeEnd = "cardio.summary.routeEnd"
        static let detailedStats = "cardio.summary.detailedStats"
        static let averagePace = "cardio.summary.averagePace"
        static let averageSpeed = "cardio.summary.averageSpeed"
        static let elevation = "cardio.summary.elevation"
        static let perceivedEffort = "cardio.summary.perceivedEffort"
        static let heartRateStats = "cardio.summary.heartRateStats"
        static let average = "cardio.summary.average"
        static let maximum = "cardio.summary.maximum"
        static let bpm = "cardio.summary.bpm"
        static let howAreYouFeeling = "cardio.summary.howAreYouFeeling"
        static let notesOptional = "cardio.summary.notesOptional"
        static let notesPlaceholder = "cardio.summary.notesPlaceholder"
        static let saveButton = "cardio.summary.saveButton"
        static let exitWithoutSaving = "cardio.summary.exitWithoutSaving"
        static let unitKilometers = "cardio.summary.unitKilometers"
        static let unitMeters = "cardio.summary.unitMeters"
    }
    
    enum CardioPreparation {
        static let preparation = "cardio.preparation.preparation"
        static let preparingWorkout = "cardio.preparation.preparingWorkout"
        static let gpsStatus = "cardio.preparation.gpsStatus"
        static let gpsSearching = "cardio.preparation.gpsSearching"
        static let gpsReady = "cardio.preparation.gpsReady"
        static let gpsWeak = "cardio.preparation.gpsWeak"
        static let gpsNoSignal = "cardio.preparation.gpsNoSignal"
        static let gpsNotNeeded = "cardio.preparation.gpsNotNeeded"
        static let stepCounter = "cardio.preparation.stepCounter"
        static let stepCounterChecking = "cardio.preparation.stepCounterChecking"
        static let stepCounterReady = "cardio.preparation.stepCounterReady"
        static let stepCounterNotAvailable = "cardio.preparation.stepCounterNotAvailable"
        static let stepCounterDenied = "cardio.preparation.stepCounterDenied"
        static let iphoneAppleWatch = "cardio.preparation.iphoneAppleWatch"
        static let settings = "cardio.preparation.settings"
        static let heartRateBand = "cardio.preparation.heartRateBand"
        static let heartRateBandNotConnected = "cardio.preparation.heartRateBandNotConnected"
        static let heartRateBandScanning = "cardio.preparation.heartRateBandScanning"
        static let heartRateBandConnected = "cardio.preparation.heartRateBandConnected"
        static let allReady = "cardio.preparation.allReady"
        static let canStartWorkout = "cardio.preparation.canStartWorkout"
        static let preparing = "cardio.preparation.preparing"
        static let start = "cardio.preparation.start"
        static let connect = "cardio.preparation.connect"
        static let retry = "cardio.preparation.retry"
        static let scanningDevices = "cardio.preparation.scanningDevices"
        static let pairingInstructions = "cardio.preparation.pairingInstructions"
        static let deviceNotFound = "cardio.preparation.deviceNotFound"
        static let ensureDeviceOn = "cardio.preparation.ensureDeviceOn"
        static let selectHeartRateBand = "cardio.preparation.selectHeartRateBand"
        static let rescan = "cardio.preparation.rescan"
        static let signal = "cardio.preparation.signal"
        static let waitingGps = "cardio.preparation.waitingGps"
        static let pleaseWait = "cardio.preparation.pleaseWait"
        static let cancel = "cardio.preparation.cancel"
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
        static let saveAsTemplate = "training.templates.saveAsTemplate"
        static let removeFromTemplates = "training.templates.removeFromTemplates"
        static let programsHeader = "training.templates.programsHeader"
        static let emptyPrograms = "training.templates.emptyPrograms"
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
    
    enum Celebration {
        static let congratulations = "training.celebration.congratulations"
        static let programCompleted = "training.celebration.programCompleted"
        static let achievementMessage = "training.celebration.achievementMessage"
        static let continueTraining = "training.celebration.continue"
        static let share = "training.celebration.share"
        static let shareText = "training.celebration.shareText"
    }
    
    enum Preview {
        static let previousPerformance = "training.preview.previousPerformance"
        static let lastPerformed = "training.preview.lastPerformed"
        static let duration = "training.preview.duration"
        static let totalVolume = "training.preview.totalVolume"
        static let sessions = "training.preview.sessions"
    }
    
    enum Part {
        // Revised part keys
        static let powerStrength = "training.part.powerStrength"
        static let metcon = "training.part.metcon"
        static let accessory = "training.part.accessory"
        static let cardio = "training.part.cardio"

        static let powerStrengthDesc = "training.part.powerStrength.desc"
        static let metconDesc = "training.part.metcon.desc"
        static let accessoryDesc = "training.part.accessory.desc"
        static let cardioDesc = "training.part.cardio.desc"
        
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
        static let copyPart = "training.part.copyPart"
        static let copyToNewWorkout = "training.part.copyToNewWorkout"
        
        // Legacy Status enum support
        enum Status {
            static let completed = "training.part.status.completed"
            static let inProgress = "training.part.status.inProgress"
        }
        
        // Legacy Description enum support (kept for compatibility)
        enum Description {
            static let strength = "training.part.powerStrength.desc"
            static let conditioning = "training.part.metcon.desc"
            static let accessory = "training.part.accessory.desc"
            static let warmup = "training.part.accessory.desc"
            static let functional = "training.part.metcon.desc"
            static let olympic = "training.part.powerStrength.desc"
            static let plyometric = "training.part.accessory.desc"
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
        static let suggestions = "training.exercise.suggestions"
        static let pr = "training.exercise.pr"
        static let noSets = "training.exercise.noSets"
        static let sets = "training.exercise.sets"
        
        // Exercise types
        static let compound = "exercise.type.compound"
        static let isolation = "exercise.type.isolation" 
        static let other = "exercise.type.other"
        
        // Category descriptions
        static let pushDescription = "exercise.category.push.description"
        static let pullDescription = "exercise.category.pull.description"
        static let legsDescription = "exercise.category.legs.description"
        static let coreDescription = "exercise.category.core.description"
        static let cardioDescription = "exercise.category.cardio.description"
        static let olympicDescription = "exercise.category.olympic.description"
        static let functionalDescription = "exercise.category.functional.description"
        static let isolationDescription = "exercise.category.isolation.description"
        static let strengthDescription = "exercise.category.strength.description"
        static let flexibilityDescription = "exercise.category.flexibility.description"
        static let plyometricDescription = "exercise.category.plyometric.description"
        static let otherDescription = "exercise.category.other.description"
        
        // Equipment types
        static let bodyweight = "exercise.equipment.bodyweight"
        static let band = "exercise.equipment.band"
        static let pullupBar = "exercise.equipment.pullup_bar"
        static let otherEquipment = "exercise.equipment.other"
        
        // Workout formats
        static let forTimeDescription = "exercise.format.for_time.description"
        static let amrapDescription = "exercise.format.amrap.description"
        static let emomDescription = "exercise.format.emom.description"
        static let tabataDescription = "exercise.format.tabata.description"
        static let roundsDescription = "exercise.format.rounds.description"
        static let ladderDescription = "exercise.format.ladder.description"
        static let chipperDescription = "exercise.format.chipper.description"
        static let customDescription = "exercise.format.custom.description"
        
        // Difficulty levels
        static let beginner = "exercise.difficulty.beginner"
        static let intermediate = "exercise.difficulty.intermediate"
        static let advanced = "exercise.difficulty.advanced"
        
        // Experience descriptions
        static let intermediateExperience = "exercise.experience.intermediate"
        static let advancedExperience = "exercise.experience.advanced"
        static let eliteExperience = "exercise.experience.elite"
        
        // Fitness goals
        static let recompDescription = "exercise.goal.recomp.description"
        static let performanceDescription = "exercise.goal.performance.description"
        
        // Meal types
        static let breakfast = "exercise.meal.breakfast"
        static let lunch = "exercise.meal.lunch"
        static let dinner = "exercise.meal.dinner"
        static let snack = "exercise.meal.snack"
        static let preworkout = "exercise.meal.preworkout"
        static let postworkout = "exercise.meal.postworkout"
    }

    // MARK: - METCON
    enum WOD {
        static let title = "training.wod.title"
        static let result = "training.wod.result"
        static let add = "training.wod.add"
        static let addResult = "training.wod.addResult"
        static let editResult = "training.wod.editResult"
        static let create = "training.wod.create"
        static let favorites = "training.wod.favorites"
        static let benchmarks = "training.wod.benchmarks"
        static let forTime = "training.wod.forTime"
        static let amrap = "training.wod.amrap"
        static let emom = "training.wod.emom"
        static let custom = "training.wod.custom"
        static let customResult = "training.wod.customResult"
        static let enterTime = "training.wod.enterTime"
        static let rounds = "training.wod.rounds"
        static let reps = "training.wod.reps"
        static let emomCompleted = "training.wod.emomCompleted"
        static let total = "training.wod.total"

        static let movements = "training.wod.movements"
        static let manualCreate = "training.wod.manualCreate"
        static let startAction = "training.wod.start"
        static let scoreTitleCompact = "training.wod.scoreTitle"
        static let round = "training.wod.round"
        static let history = "training.wod.history"
        static let benchmark = "training.wod.benchmark"
        static let totalCompleted = "training.wod.totalCompleted"
        static let personalRecords = "training.wod.personalRecords"
        static let thisMonth = "training.wod.thisMonth"
        static let noHistoryTitle = "training.wod.noHistoryTitle"
        static let noHistoryDesc = "training.wod.noHistoryDesc"
        
        // Category display names
        static let myWODs = "training.wod.myWODs"
        static let theGirls = "training.wod.theGirls"
        static let heroWODs = "training.wod.heroWODs"
        static let openWODs = "training.wod.openWODs"
        
        // Category descriptions
        static let customDesc = "training.wod.customDesc"
        static let girlsDesc = "training.wod.girlsDesc"
        static let heroesDesc = "training.wod.heroesDesc"
        static let opensDesc = "training.wod.opensDesc"
        static let historyDesc = "training.wod.historyDesc"
        
        // Additional WOD interface keys
        static let searchPlaceholder = "wod.search_placeholder"
        static let createNewMETCON = "wod.create_new_metcon"
        static let buildCustomWorkout = "wod.build_custom_workout"
        static let scanQR = "wod.scan_qr"
        static let importSharedWorkouts = "wod.import_shared_workouts"
        static let noCustomMETCON = "wod.no_custom_metcon"
        static let createFirstMETCON = "wod.create_first_metcon"
        static let createMETCON = "wod.create_metcon"

        enum Builder {
            static let namePlaceholder = "training.wod.builder.namePlaceholder"
            static let schemePlaceholderForTime = "training.wod.builder.schemePlaceholderForTime"
            static let schemePlaceholderAmrap = "training.wod.builder.schemePlaceholderAmrap"
            static let movementsPlaceholder = "training.wod.builder.movementsPlaceholder"
            static let schemeHintForTime = "training.wod.builder.schemeHintForTime"
            static let schemeHintAmrap = "training.wod.builder.schemeHintAmrap"
            static let movementsHint = "training.wod.builder.movementsHint"
            static let start = "training.wod.builder.start"
            static let title = "training.wod.builder.title"
            // Examples for placeholders
            static let exampleName = "training.wod.builder.exampleName"
            static let exampleType = "training.wod.builder.exampleType"
            static let exampleMovements = "training.wod.builder.exampleMovements"
        }

        enum Runner {
            static let undo = "training.wod.runner.undo"
            static let addRound = "training.wod.runner.addRound"
            static let extraReps = "training.wod.runner.extraReps" // "%d reps"
            static let scoreButton = "training.wod.runner.scoreButton"
            static let finish = "training.wod.runner.finish"
            static let scoreTitle = "training.wod.runner.scoreTitle" // "Time (MM:SS)"
            static let roundsLabel = "training.wod.runner.roundsLabel" // "Rounds: %d"
            static let stepsProgress = "training.wod.runner.stepsProgress" // "%d/%d"
            static let tipTitle = "training.wod.runner.tipTitle"
            static let tipBody = "training.wod.runner.tipBody"
        }

        enum TimePlaceholder {
            static let mm = "training.wod.time.mm"
            static let ss = "training.wod.time.ss"
        }
    }
    
    // MARK: - Cardio
    enum Cardio {
        static let title = "training.cardio.title"
        
        // Main tabs
        static let templates = "training.cardio.templates"
        static let history = "training.cardio.history"
        // Exercise types
        static let running = "training.cardio.running"
        static let cycling = "training.cardio.cycling"
        static let rowing = "training.cardio.rowing"
        static let skiing = "training.cardio.skiing"
        static let walking = "training.cardio.walking"
        
        // Session types
        static let distanceGoal = "training.cardio.distanceGoal"
        static let timeGoal = "training.cardio.timeGoal"
        static let sessionType = "training.cardio.sessionType"
        static let target = "training.cardio.target"
        
        // Session input
        static let newSession = "training.cardio.newSession"
        static let setGoal = "training.cardio.setGoal"
        static let notes = "training.cardio.notes"
        static let notesPlaceholder = "training.cardio.notesPlaceholder"
        static let equipmentOptions = "training.cardio.equipmentOptions"
        static let startSession = "training.cardio.startSession"
        static let logResults = "training.cardio.logResults"
        static let sessionTracking = "training.cardio.sessionTracking"
        static let completeSession = "training.cardio.completeSession"
        static let targetProgress = "training.cardio.targetProgress"
        static let duration = "training.cardio.duration"
        
        // Main view keys
        static let train = "training.cardio.train"
        static let quickStart = "training.cardio.quickStart"
        static let quickStartDesc = "training.cardio.quickStartDesc"
        static let viewHistory = "training.cardio.viewHistory"
        static let viewHistoryDesc = "training.cardio.viewHistoryDesc"
        static let recentSessions = "training.cardio.recentSessions"
        static let sessionInProgress = "training.cardio.sessionInProgress"
        static let distance = "training.cardio.distance"
        static let avgSpeed = "training.cardio.avgSpeed"
        static let pace = "training.cardio.pace"
        static let averagePace = "training.cardio.averagePace"
        static let elevation = "training.cardio.elevation"
        static let calories = "training.cardio.calories"
        static let personalRecord = "training.cardio.personalRecord"
        static let performance = "training.cardio.performance"
        static let additionalInfo = "training.cardio.additionalInfo"
        static let quickSelect = "training.cardio.quickSelect"
        static let customDistance = "training.cardio.customDistance"
        static let customDuration = "training.cardio.customDuration"
        
        // Live tracking
        static let finishAndSave = "training.cardio.finishAndSave"
        static let confirmFinishMessage = "training.cardio.confirmFinishMessage"
        static let start = "training.cardio.start"
        static let connectHeartRate = "training.cardio.connectHeartRate"
        static let heartRateNotConnected = "training.cardio.heartRateNotConnected"
        static let intervals = "training.cardio.intervals"
        static let searchingDevices = "training.cardio.searchingDevices"
        static let steps = "training.cardio.steps"
        static let speed = "training.cardio.speed"
        static let heartRate = "training.cardio.heartRate"
        static let feeling = "training.cardio.feeling"
        static let sessionNotes = "training.cardio.sessionNotes"
        static let sessionNotesPlaceholder = "training.cardio.sessionNotesPlaceholder"
        static let saveSession = "training.cardio.saveSession"
        static let complete = "training.cardio.complete"
        
        // Feelings
        static let feelingGreat = "training.cardio.feeling.great"
        static let feelingGood = "training.cardio.feeling.good"
        static let feelingOkay = "training.cardio.feeling.okay"
        static let feelingTired = "training.cardio.feeling.tired"
        static let feelingExhausted = "training.cardio.feeling.exhausted"
        
        // Weather
        static let weatherSunny = "training.cardio.weather.sunny"
        static let weatherCloudy = "training.cardio.weather.cloudy"
        static let weatherRainy = "training.cardio.weather.rainy"
        static let weatherWindy = "training.cardio.weather.windy"
        static let weatherHot = "training.cardio.weather.hot"
        static let weatherCold = "training.cardio.weather.cold"
        
        // Workout details
        static let workoutDetails = "training.cardio.workoutDetails"
        static let type = "training.cardio.type"
        static let activity = "training.cardio.activity"
        static let flexibility = "training.cardio.flexibility"
        static let anyDistanceTime = "training.cardio.anyDistanceTime"
        static let equipment = "training.cardio.equipment"
        static let statistics = "training.cardio.statistics"
        static let totalSessions = "training.cardio.totalSessions"
        static let lastPerformed = "training.cardio.lastPerformed"
        static let startWorkout = "training.cardio.startWorkout"
        static let duplicate = "training.cardio.duplicate"
        static let delete = "training.cardio.delete"
        
        // History and results
        static let noHistory = "training.cardio.noHistory"
        static let noHistoryMessage = "training.cardio.noHistoryMessage"
        static let browseTemplates = "training.cardio.browseTemplates"
        
        // Environment and tracking
        static let outdoor = "training.cardio.outdoor"
        static let indoor = "training.cardio.indoor"
        
        // Metric labels for live tracking
        static let effort = "training.cardio.effort"
        static let zone = "training.cardio.zone"
        static let bpm = "training.cardio.bpm"
        static let rpe = "training.cardio.rpe"
        static let time = "training.cardio.time"
        static let personalRecordBadge = "training.cardio.personalRecordBadge"
        static let lastSession = "training.cardio.lastSession"
        
        // Quick start modal
        static let quickStartModal = "training.cardio.quickStartModal"
        static let activityType = "training.cardio.activityType"
        static let selectActivityToStart = "training.cardio.selectActivityToStart"
        static let modalLocation = "training.cardio.modalLocation"
        static let modalFeatures = "training.cardio.modalFeatures"
        static let modalStart = "training.cardio.modalStart"
        static let cancel = "training.cardio.cancel"
        static let gpsRealTimeTracking = "training.cardio.gpsRealTimeTracking"
        static let routeMapAfterWorkout = "training.cardio.routeMapAfterWorkout"
        static let instantSpeedPace = "training.cardio.instantSpeedPace"
        static let elevationChanges = "training.cardio.elevationChanges"
        static let timeTracking = "training.cardio.timeTracking"
        static let estimatedCalories = "training.cardio.estimatedCalories"
        static let heartRateSupport = "training.cardio.heartRateSupport"
        static let manualDistanceInput = "training.cardio.manualDistanceInput"
        
        // Categories
        static let exerciseTypes = "training.cardio.exerciseTypes"
        static let customSessions = "training.cardio.customSessions"
        
        // Empty states
        static let noSessions = "training.cardio.noSessions"
        static let noSessionsDesc = "training.cardio.noSessionsDesc"
        static let noExerciseTypes = "training.cardio.noExerciseTypes"
        static let adjustSearch = "training.cardio.adjustSearch"
        static let clearSearch = "training.cardio.clearSearch"
        static let neverAttempted = "training.cardio.neverAttempted"
        
        // Equipment types (moved from duplicate section below)
        static let treadmill = "training.cardio.treadmill"
        static let rowErg = "training.cardio.rowErg"
        static let bikeErg = "training.cardio.bikeErg"
        static let skiErg = "training.cardio.skiErg"
        
        // Feelings
        static let terrible = "training.cardio.terrible"
        static let bad = "training.cardio.bad"
        static let okay = "training.cardio.okay"
        static let good = "training.cardio.good"
        static let great = "training.cardio.great"
        
        // Units and formatting
        static let km = "training.cardio.km"
        static let meters = "training.cardio.meters"
        static let minutes = "training.cardio.minutes"
        
        // Quick Start and UI
        static let selectActivityAndStart = "training.cardio.selectActivityAndStart"
        static let uiLocation = "training.cardio.uiLocation"
        static let ergometer = "training.cardio.ergometer"
        static let selectActivity = "training.cardio.selectActivity"
        static let noActivities = "training.cardio.noActivities"
        static let noActivitiesDescription = "training.cardio.noActivitiesDescription"
        static let uiFeatures = "training.cardio.uiFeatures"
        
        // Feature descriptions
        static let gpsTracking = "training.cardio.gpsTracking"
        static let routeMapping = "training.cardio.routeMapping"
        static let autoDistance = "training.cardio.autoDistance"
        static let heartRateMonitoring = "training.cardio.heartRateMonitoring"
        static let timerTracking = "training.cardio.timerTracking"
        static let manualDistanceEntry = "training.cardio.manualDistanceEntry"
        static let calorieEstimation = "training.cardio.calorieEstimation"
        static let pm5Compatible = "training.cardio.pm5Compatible"
        static let powerMetrics = "training.cardio.powerMetrics"
        static let splitTracking = "training.cardio.splitTracking"
        static let seconds = "training.cardio.seconds"
        static let hours = "training.cardio.hours"
        static let kcal = "training.cardio.kcal"
        static let minPerKm = "training.cardio.minPerKm"
        static let kmPerHour = "training.cardio.kmPerHour"
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
        static let strength = "training.category.strength"
        static let flexibility = "training.category.flexibility"
        static let plyometric = "training.category.plyometric"
        static let other = "training.category.other"
    }
    
    enum Set {
        static let back = "training.set.back"
        static let save = "training.set.save"
        static let equipment = "training.set.equipment"
        static let reorder = "training.set.reorder"
        static let quickFill = "training.set.quickFill"
        static let bulkAdd = "training.set.bulkAdd"
        static let noDataToSave = "training.set.noDataToSave"
        static let advancedEdit = "training.set.advancedEdit"
        static let advancedEditDescription = "training.set.advancedEditDescription"
        
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
        static let lb = "training.set.lb"
        static let reps = "training.set.reps"
        static let meters = "training.set.meters"
        static let completed = "training.set.completed"
        static let sameAsLast = "training.set.same_as_last"
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

    // Active workout conflict dialog
    enum ActiveConflict {
        static let title = "training.activeConflict.title"
        static let message = "training.activeConflict.message"
        static let `continue` = "training.activeConflict.continue"
        static let finishAndStart = "training.activeConflict.finishAndStart"
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = "training.dashboard.title"
        static let welcome = "training.dashboard.welcome"
        static let welcomeBack = "training.dashboard.welcomeBack"
        static let quickActions = "training.dashboard.quickActions"
        static let recentActivity = "training.dashboard.recentActivity"
        static let thisWeek = "training.dashboard.thisWeek"
        static let lastWorkout = "training.dashboard.lastWorkout"
        static let motivation = "training.dashboard.motivation"
        static let motivationalMessage = "training.dashboard.motivationalMessage"
        static let streak = "training.dashboard.streak"
        static let dayStreak = "training.dashboard.dayStreak"
        static let workouts = "training.dashboard.workouts"
        static let workoutsCompleted = "training.dashboard.workoutsCompleted"
        static let totalTime = "training.dashboard.totalTime"
        static let duration = "training.dashboard.duration"
        static let when = "training.dashboard.when"
        static let quickStart = "training.dashboard.quickStart"
        static let quickLift = "training.dashboard.quickLift"
        static let quickCardio = "training.dashboard.quickCardio"
        static let dailyWOD = "training.dashboard.dailyWOD"
        static let browsePrograms = "training.dashboard.browsePrograms"
        static let startStrengthTraining = "training.dashboard.startStrengthTraining"
        static let startCardioSession = "training.dashboard.startCardioSession"
        static let todaysWorkout = "training.dashboard.todaysWorkout"
        static let findProgram = "training.dashboard.findProgram"
        static let startWorkout = "training.dashboard.startWorkout"
        static let seeAll = "training.dashboard.seeAll"
        static let continueProgram = "training.dashboard.continueProgram"
        static let noRecentActivity = "training.dashboard.noRecentActivity"
        static let emptyStateDescription = "training.dashboard.emptyStateDescription"
        
        // Pills Navigation
        static let overview = "training.dashboard.pills.overview"
        static let analytics = "training.dashboard.pills.analytics"
        static let tests = "training.dashboard.pills.tests"
        static let goals = "training.dashboard.pills.goals"
        
        // Deep Navigation
        static let viewDetailedAnalytics = "training.dashboard.viewDetailedAnalytics"
        static let takeStrengthTest = "training.dashboard.takeStrengthTest"
        static let manageGoals = "training.dashboard.manageGoals"
    }
    
    // MARK: - Analytics
    enum Analytics {
        static let title = "training.analytics.title"
        static let comingSoon = "training.analytics.comingSoon"
        static let comingSoonDesc = "training.analytics.comingSoon.desc"
        static let progressCharts = "training.analytics.progressCharts"
        static let performanceMetrics = "training.analytics.performanceMetrics"
        static let bodyMetrics = "training.analytics.bodyMetrics"
        static let achievements = "training.analytics.achievements"
        
        // Additional analytics strings
        static let trackProgress = "training.analytics.trackProgress"
        static let thisWeek = "training.analytics.thisWeek"
        static let sessions = "training.analytics.sessions"
        static let totalTime = "training.analytics.totalTime"
        static let streak = "training.analytics.streak"
        static let prs = "training.analytics.prs"
        static let days = "training.analytics.days"
        
        // Empty states
        static let noStrengthDataTitle = "training.analytics.noStrengthDataTitle"
        static let noStrengthDataDesc = "training.analytics.noStrengthDataDesc"
        static let noWorkoutsTitle = "training.analytics.noWorkoutsTitle"
        static let noWorkoutsDesc = "training.analytics.noWorkoutsDesc"
        static let noPRsTitle = "training.analytics.noPRsTitle"
        static let noPRsDesc = "training.analytics.noPRsDesc"
        static let monthlyGoals = "training.analytics.monthlyGoals"
        static let monthlyGoalsDesc = "training.analytics.monthlyGoalsDesc"
        static let weeklyGoals = "training.analytics.weeklyGoals"
        static let weeklyGoalsDesc = "training.analytics.weeklyGoalsDesc"
        static let editGoals = "training.analytics.editGoals"
        static let distance = "training.analytics.distance"
        static let viewAll = "training.analytics.viewAll"
        static let recentPRs = "training.analytics.recentPRs"
        static let noPRsYet = "training.analytics.noPRsYet"
        static let noPRsMessage = "training.analytics.noPRsMessage"
        static let startTraining = "training.analytics.startTraining"
        static let noUserProfile = "training.analytics.noUserProfile"
        static let setupProfileMessage = "training.analytics.setupProfileMessage"
        static let setupProfile = "training.analytics.setupProfile"
        static let thisWeekLower = "training.analytics.thisWeekLower"
        static let thisMonth = "training.analytics.thisMonth"
        static let subtitle = "training.analytics.subtitle"
        static let weekly = "training.analytics.weekly"
        static let monthly = "training.analytics.monthly"
        static let noActivityData = "training.analytics.noActivityData"
        static let noActivityDesc = "training.analytics.noActivityDesc"
        static let thisWeekActivity = "training.analytics.thisWeekActivity"
        static let day = "training.analytics.day"
        static let liftSessions = "training.analytics.liftSessions"
        static let cardioSessions = "training.analytics.cardioSessions"
        
        // PR Timeline specific keys
        static let totalPRs = "training.analytics.totalPRs"
        static let latestPR = "training.analytics.latestPR"
        static let strengthProfile = "training.analytics.strengthProfile"
        static let levelGuide = "training.analytics.levelGuide"
        static let generalScore = "training.analytics.generalScore"
        static let recordFirstPR = "training.analytics.recordFirstPR"
        static let startStrengthTest = "training.analytics.startStrengthTest"
        static let startFirstCardio = "training.analytics.startFirstCardio"
        static let updateOneRMs = "training.analytics.updateOneRMs"
        
        // Common time periods
        static let average = "training.analytics.average"
        static let maximum = "training.analytics.maximum"
        
        // PR Analytics keys
        static let endurance = "analytics.category.endurance"
        static let prDataLoading = "analytics.pr_data_loading"
        static let noPRRecords = "analytics.no_pr_records"
        static let startBreaking = "analytics.start_breaking"
        static let today = "analytics.date.today"
        static let yesterday = "analytics.date.yesterday"
        
        // Missing analytics strings from dashboard
        static let performanceOverview = "training.analytics.performanceOverview"
        static let monthlyTraining = "training.analytics.monthlyTraining"
        static let totalDuration = "training.analytics.totalDuration"
        static let thisMonthLower = "training.analytics.thisMonthLower"
        static let weeklyTrend = "training.analytics.weeklyTrend"
        static let consistency = "training.analytics.consistency"
        static let increasing = "training.analytics.increasing"
        static let stable = "training.analytics.stable"
        static let strong = "training.analytics.strong"
        static let improving = "training.analytics.improving"
        static let viewDetailedAnalytics = "training.analytics.viewDetailedAnalytics"
    }
    
    // MARK: - Tests & Strength
    enum Tests {
        static let title = "training.tests.title"
        static let strengthTitle = "training.tests.strength.title"
        static let newTest = "training.tests.newTest"
        static let takeTest = "training.tests.takeTest"
        static let testResults = "training.tests.results"
        static let noTests = "training.tests.noTests"
        static let noTestsDesc = "training.tests.noTestsDesc"
        static let lastTest = "training.tests.lastTest"
        static let overallScore = "training.tests.overallScore"
        static let strengthLevel = "training.tests.strengthLevel"
        static let testHistory = "training.tests.testHistory"
        static let viewDetails = "training.tests.viewDetails"
        
        // Test Results
        static let testCompleted = "training.tests.testCompleted"
        static let performanceAnalysis = "training.tests.performanceAnalysis"
        static let exerciseDetails = "training.tests.exerciseDetails"
        static let exerciseAnalysisDesc = "training.tests.exerciseAnalysisDesc"
        static let bodyBalanceAnalysis = "training.tests.bodyBalanceAnalysis"
        static let strengthLevelsMeaning = "training.tests.strengthLevelsMeaning"
        static let recommendations = "training.tests.recommendations"
        static let personalizedRecommendations = "training.tests.personalizedRecommendations"
        static let loadingRecommendations = "training.tests.loadingRecommendations"
        static let saveResults = "training.tests.saveResults"
        static let levelScale = "training.tests.levelScale"
        static let aboutStandards = "training.tests.aboutStandards"
    }
    
    enum Strength {
        static let title = "strength.main.title"
        static let error = "strength.error.title"
        static let noUser = "strength.error.noUser"
        static let noUserSubtitle = "strength.error.noUserSubtitle"
        static let testCompleted = "strength.testCompleted"
        static let level = "strength.level"
        static let score = "strength.score"
        static let exercises = "strength.exercises"
        static let testDate = "strength.testDate"
        static let retakeTest = "strength.retakeTest"
        static let viewHistory = "strength.viewHistory"
    }
    
    // MARK: - Lift Training
    enum Lift {
        static let title = "training.lift.title"
        
        // Tab titles
        static let train = "training.lift.train"
        static let programs = "training.lift.programs"
        static let routines = "training.lift.routines"
        static let history = "training.lift.history"
        static let seeAll = "training.lift.seeAll"
        
        // Status messages
        static let sessionInProgress = "training.lift.sessionInProgress"
        
        // Empty state messages
        static let noWorkouts = "training.lift.noWorkouts"
        static let noWorkoutsDesc = "training.lift.noWorkoutsDesc"
        static let startFirstWorkout = "training.lift.startFirstWorkout"
        
        // Menu actions
        static let newWorkout = "training.lift.newWorkout"
        static let browsePrograms = "training.lift.browsePrograms"
        static let quickStart = "training.lift.quickStart"
        
        // Common actions
        static let cancel = "training.lift.cancel"
        static let close = "training.lift.close"
        static let done = "training.lift.done"
        static let save = "training.lift.save"
        static let delete = "training.lift.delete"
        static let edit = "training.lift.edit"
    }
    
    // MARK: - Timer Controls
    enum TimerControls {
        static let cancel = "training.timer.cancel"
    }
    
    enum Navigation {
        static let wodDetails = "training.navigation.wodDetails"
        static let wodHistory = "training.navigation.wodHistory"
        static let newCardio = "training.navigation.newCardio"
        static let selectExercise = "training.navigation.selectExercise"
        static let shareWOD = "training.navigation.shareWOD"
        static let workoutSummary = "training.navigation.workoutSummary"
        static let heartRateSelect = "training.navigation.heartRateSelect"
        static let strengthTest = "training.navigation.strengthTest"
        static let getReady = "training.navigation.getReady"
    }
    
    enum Common {
        static let cancel = "training.common.cancel"
        static let done = "training.common.done"
        static let create = "training.common.create"
        static let startProgram = "training.common.startProgram"
        static let back = "training.common.back"
        static let details = "training.common.details"
        static let updateOneRMs = "training.common.updateOneRMs"
        static let congratulations = "training.common.congratulations"
        static let finishedProgram = "training.common.finishedProgram"
        static let scanAgain = "training.common.scanAgain"
    }
    
    enum Alerts {
        static let cancelWorkout = "training.alerts.cancelWorkout"
        static let cancelWorkoutMessage = "training.alerts.cancelWorkoutMessage"
        static let keepTraining = "training.alerts.keepTraining"
        static let cancelWorkoutAction = "training.alerts.cancelWorkoutAction"
        static let deleteSet = "training.alerts.deleteSet"
        static let deleteWorkout = "training.alerts.deleteWorkout"
        static let resultSaved = "training.alerts.resultSaved"
        static let newPRCongrats = "training.alerts.newPRCongrats"
        static let workoutRecorded = "training.alerts.workoutRecorded"
        static let finishWorkout = "training.alerts.finishWorkout"
        static let ok = "training.alerts.ok"
        static let delete = "training.alerts.delete"
    }
    
    enum Goals {
        static let setMonthlyGoals = "training.goals.setMonthlyGoals"
        static let trackProgress = "training.goals.trackProgress"
        static let trainingSessions = "training.goals.trainingSessions"
        static let cardioDistance = "training.goals.cardioDistance"
        static let liftSessions = "training.goals.liftSessions"
        static let cardioSessions = "training.goals.cardioSessions"
        static let weeklyDistance = "training.goals.weeklyDistance"
        static let saveGoals = "training.goals.saveGoals"
        static let sessions = "training.goals.sessions"
        static let weeklyTarget = "training.goals.weeklyTarget"
        static let cardioTarget = "training.goals.cardioTarget"
    }
    
    enum Status {
        static let preparing = "training.status.preparing"
        static let ready = "training.status.ready"
        static let inProgress = "training.status.inProgress"
        static let paused = "training.status.paused"
        static let completed = "training.status.completed"
        static let finishWorkout = "training.status.finishWorkout"
        static let finishAndSave = "training.status.finishAndSave"
        static let confirmFinishMessage = "training.status.confirmFinishMessage"
        static let start = "training.status.start"
        static let resume = "training.status.resume"
        static let pause = "training.status.pause"
        static let stop = "training.status.stop"
        static let finish = "training.status.finish"
        static let cancel = "training.status.cancel"
    }
    
    enum OneRM {
        static let enterWeight = "training.oneRM.enterWeight"
        static let estimateHelp = "training.oneRM.estimateHelp"
        static let underestimateWarning = "training.oneRM.underestimateWarning"
        static let previous = "training.oneRM.previous"
        static let next = "training.oneRM.next"
        static let calculateWeights = "training.oneRM.calculateWeights"
        static let startingWeightsMessage = "training.oneRM.startingWeightsMessage"
        static let fallbackProgram = "training.oneRM.fallbackProgram"
        static let setupComplete = "training.oneRM.setupComplete"
        static let startingWeightsCalculated = "training.oneRM.startingWeightsCalculated"
        static let oneRMTitle = "training.oneRM.title"
        static let estimateExample = "training.oneRM.estimateExample"
    }
    
    enum Programs {
        static let chooseProgramDesc = "training.programs.chooseProgramDesc"
        static let prsThisWeek = "training.programs.prsThisWeek"
        static let finishedProgramCongrats = "training.programs.finishedProgramCongrats"
    }
    
    
    enum Charts {
        static let sessionsThisWeek = "training.charts.sessionsThisWeek"
        static let of = "training.charts.of"
        static let oneRMProgression = "training.charts.oneRMProgression"
        static let weightChange = "training.charts.weightChange"
        static let kg = "training.charts.kg"
    }
    
    // MARK: - Units and Measurements
    enum Units {
        static let sessions = "training.units.sessions"
        static let minutes = "training.units.minutes"
        static let seconds = "training.units.seconds"
        static let hours = "training.units.hours"
        static let days = "training.units.days"
        static let weeks = "training.units.weeks"
        static let months = "training.units.months"
        static let rounds = "training.units.rounds"
        static let reps = "training.units.reps"
        static let bpm = "training.units.bpm"
        static let kcal = "training.units.kcal"
        static let minCap = "training.units.minCap"
        static let daysPerWeek = "training.units.daysPerWeek"
    }
    
    // MARK: - Heart Rate & Devices
    enum HeartRate {
        static let heartRate = "training.heartRate.heartRate"
        static let bpm = "training.heartRate.bpm"
        static let connect = "training.heartRate.connect"
        static let notConnected = "training.heartRate.notConnected"
        static let searchingDevices = "training.heartRate.searchingDevices"
        static let selectDevice = "training.heartRate.selectDevice"
        static let rescan = "training.heartRate.rescan"
        static let signal = "training.heartRate.signal"
        static let battery = "training.heartRate.battery"
    }
    
    // MARK: - Search & Results
    enum Search {
        static let noResults = "training.search.noResults"
        static let tryDifferentTerm = "training.search.tryDifferentTerm"
        static let searchPlaceholder = "training.search.placeholder"
    }
    
    // MARK: - Intervals & Splits
    enum Intervals {
        static let intervals = "training.intervals.intervals"
        static let splits = "training.intervals.splits"
    }
    
    // MARK: - Program Completion
    enum ProgramCompletion {
        static let programCompleted = "training.program.completed"
        static let congratulations = "training.program.congratulations"
        static let readyToStart = "training.program.readyToStart"
        static let chooseFromPrograms = "training.program.chooseFromPrograms"
        static let browsePrograms = "training.program.browsePrograms"
        static let weekOf = "training.program.weekOf"
    }
    
    // MARK: - Welcome Messages
    enum Welcome {
        static let welcomeBack = "training.welcome.welcomeBack"
        static let quickLift = "training.welcome.quickLift"
        static let quickCardio = "training.welcome.quickCardio"
        static let createWOD = "training.welcome.createWOD"
        static let startStrengthTraining = "training.welcome.startStrengthTraining"
        static let startCardioSession = "training.welcome.startCardioSession"
        static let createWODSubtitle = "training.welcome.createWODSubtitle"
        static let findProgram = "training.welcome.findProgram"
    }
    
    // MARK: - Warmup
    enum Warmup {
        static let lightCardio = "training.warmup.lightCardio"
        static let dynamicStretching = "training.warmup.dynamicStretching"
        static let majorMuscleGroups = "training.warmup.majorMuscleGroups"
    }
    
    // MARK: - Goals Descriptions
    enum GoalsDesc {
        static let workoutSessionsPerMonth = "training.goalsDesc.workoutSessionsPerMonth"
        static let totalRunningCyclingDistance = "training.goalsDesc.totalRunningCyclingDistance"
    }
    
    // MARK: - Workout Types
    enum WorkoutTypes {
        static let forTime = "training.workoutTypes.forTime"
        static let amrap = "training.workoutTypes.amrap"
        static let emom = "training.workoutTypes.emom"
        static let customFormat = "training.workoutTypes.customFormat"
        static let forTimeWithCap = "training.workoutTypes.forTimeWithCap"
        static let amrapMinutes = "training.workoutTypes.amrapMinutes"
        static let emomMinutes = "training.workoutTypes.emomMinutes"
    }
    
    // MARK: - Test Results
    enum TestResults {
        // Status messages
        static let resultsNotReady = "training.test_results.not_ready"
        static let analysisComplete = "training.test_results.analysis_complete"
        static let recommendationTitle = "training.test_results.recommendation_title"
        static let details = "training.test_results.details"
        static let percentageSymbol = "training.test_results.percentage_symbol"
        
        // Context information
        static let baseStandards = "training.test_results.base_standards"
        static let demographicAdjustment = "training.test_results.demographic_adjustment"  
        static let percentileExplanation = "training.test_results.percentile_explanation"
        
        // Experience levels
        static let beginnerDescription = "training.test_results.beginner_description"
        static let intermediateDescription = "training.test_results.intermediate_description"
        static let advancedDescription = "training.test_results.advanced_description"
        
        // Body dominance
        static let upperBodyDominant = "training.test_results.upper_body_dominant"
        static let lowerBodyDominant = "training.test_results.lower_body_dominant" 
        static let unknownDominance = "training.test_results.unknown_dominance"
        
        // Goal formats
        static let repsGoalFormat = "training.test_results.reps_goal_format"
        static let weightGoalFormat = "training.test_results.weight_goal_format"
        
        // Additional levels
        static let noviceDescription = "training.test_results.novice_description"
        static let expertDescription = "training.test_results.expert_description"
        static let eliteDescription = "training.test_results.elite_description"
        
        // Labels
        static let currentLevel = "training.test_results.current_level"
        static let exercise = "training.test_results.exercise"
        static let personalRecord = "training.test_results.personal_record"
        static let balanced = "training.test_results.balanced"
        static let unknown = "training.test_results.unknown"
        static let completed = "training.test_results.completed"
        static let nextTarget = "training.test_results.next_target"
    }
    
    // MARK: - Activity Types
    enum ActivityTypes {
        static let running = "activity.type.running"
        static let cycling = "activity.type.cycling"
        static let swimming = "activity.type.swimming"
        static let walking = "activity.type.walking"
        static let strengthTraining = "activity.type.strength_training"
        static let rowing = "activity.type.rowing"
        static let coreTraining = "activity.type.core_training"
        static let hiit = "activity.type.hiit"
        static let jumpRope = "activity.type.jump_rope"
        static let wrestling = "activity.type.wrestling"
        static let martialArts = "activity.type.martial_arts"
        static let other = "activity.type.other"
    }
    
    // MARK: - Progress & Analytics Extended
    enum AnalyticsExtended {
        static let endurance = "analytics.category.endurance"
        static let prDataLoading = "analytics.pr_data_loading"
        static let noPRRecords = "analytics.no_pr_records"
        static let startBreaking = "analytics.start_breaking"
        static let today = "analytics.date.today"
        static let yesterday = "analytics.date.yesterday"
    }
    
    // MARK: - Strength Test
    enum StrengthTest {
        static let weight = "strength_test.weight"
        static let previous = "strength_test.previous"
        static let errorWeightReps = "strength_test.error.weight_reps"
    }
    
    // MARK: - Cardio Analytics
    enum CardioAnalytics {
        // Time periods
        static let oneMonth = "cardio.analytics.one_month"
        static let threeMonths = "cardio.analytics.three_months" 
        static let sixMonths = "cardio.analytics.six_months"
        static let lastYear = "cardio.analytics.last_year" 
        static let allTime = "cardio.analytics.all_time"
        
        // Metrics
        static let heartRate = "cardio.analytics.heart_rate"
        
        // Interface
        static let cardioTitle = "cardio.analytics.cardio_title"
        static let subtitle = "cardio.analytics.subtitle"
        static let dataLoading = "cardio.analytics.data_loading"
        static let noDataTitle = "cardio.analytics.no_data_title"
        static let noDataDescription = "cardio.analytics.no_data_description"
    }
    
    // MARK: - Strength Analytics
    enum StrengthAnalytics {
        static let strengthTitle = "strength.analytics.strength_title"
        static let noOneRMData = "strength.analytics.no_1rm_data"
        static let noOneRMDescription = "strength.analytics.no_1rm_description"
        static let oneYear = "strength.analytics.one_year"
        static let allTime = "strength.analytics.all_time"
        static let subtitle = "strength.analytics.subtitle"
        
        // Time periods
        static let oneMonth = "strength.analytics.one_month"
        static let threeMonths = "strength.analytics.three_months"
        static let sixMonths = "strength.analytics.six_months"
        
        // Exercise names
        static let squat = "strength.analytics.squat"
        static let bench = "strength.analytics.bench"
        static let deadlift = "strength.analytics.deadlift"
        static let ohp = "strength.analytics.ohp"
        static let pullup = "strength.analytics.pullup"
        
        // Chart labels
        static let dateLabel = "strength.analytics.date_label"
        static let weightLabel = "strength.analytics.weight_label"
    }
    
    // MARK: - Consistency Analytics
    enum ConsistencyAnalytics {
        static let title = "consistency.analytics.title"
        static let subtitle = "consistency.analytics.subtitle"
        static let dataLoading = "consistency.analytics.data_loading"
        
        // Metrics
        static let frequency = "consistency.analytics.frequency"
        static let streak = "consistency.analytics.streak"
        static let goals = "consistency.analytics.goals"
        
        // Time periods
        static let last12Weeks = "consistency.analytics.last_12_weeks"
        static let thisWeek = "consistency.analytics.this_week"
        static let average = "consistency.analytics.average"
        static let best = "consistency.analytics.best"
        static let perfectWeeks = "consistency.analytics.perfect_weeks"
        
        // Ring labels
        static let thisWeekSessions = "consistency.analytics.this_week_sessions"
        static let dailyStreak = "consistency.analytics.daily_streak"
        static let weeklyGoal = "consistency.analytics.weekly_goal"
    }
    
    // MARK: - PR Categories
    enum PRCategories {
        static let strength = "pr.categories.strength"
        static let endurance = "pr.categories.endurance"
        static let volume = "pr.categories.volume"
        
        // Strength exercises
        static let backSquat = "pr.strength.back_squat"
        static let benchPress = "pr.strength.bench_press"
        static let deadlift = "pr.strength.deadlift"
        static let overheadPress = "pr.strength.overhead_press"
        static let pullUp = "pr.strength.pull_up"
        
        // Endurance metrics
        static let longestRun = "pr.endurance.longest_run"
        static let bestAveragePace = "pr.endurance.best_average_pace"
        static let maxDistanceWeek = "pr.endurance.max_distance_week"
        static let best5KTime = "pr.endurance.best_5k_time"
        static let best10KTime = "pr.endurance.best_10k_time"
        
        // Volume metrics
        static let mostSetsInDay = "pr.volume.most_sets_in_day"
        static let weeklyVolume = "pr.volume.weekly_volume"
        static let mostRepsSet = "pr.volume.most_reps_set"
        static let longestWorkout = "pr.volume.longest_workout"
        static let sessionsThisMonth = "pr.volume.sessions_this_month"
        
        // Common
        static let subtitle = "pr.categories.subtitle"
    }
    
    // MARK: - Screen Lock
    enum ScreenLock {
        static let screenLocked = "training.screen_lock.screen_locked"
        static let accidentalPressProtection = "training.screen_lock.accidental_press_protection"
        static let or = "training.screen_lock.or"
        static let volumeButtonsHint = "training.screen_lock.volume_buttons_hint"
        static let slideToUnlock = "training.screen_lock.slide_to_unlock"
    }
    
    // MARK: - Program Dashboard
    enum ProgramDashboard {
        static let activeProgram = "training.program_dashboard.active_program"
        static let nextWorkout = "training.program_dashboard.next_workout"
        static let startWorkout = "training.program_dashboard.start_workout"
        static let resumeProgram = "training.program_dashboard.resume_program"
        static let startNewProgram = "training.program_dashboard.start_new_program"
        static let details = "training.program_dashboard.details"
    }
    
    // MARK: - Workout Preview
    enum WorkoutPreview {
        static let beginWorkout = "training.workout_preview.begin_workout"
        static let viewPreviousSessions = "training.workout_preview.view_previous_sessions"
    }
    
    // MARK: - Forms Extended
    enum FormsExtended {
        static let cancel = "training.forms.cancel"
        static let back = "training.forms.back"
        static let routineName = "training.forms.routine_name"
        static let quickSuggestions = "training.forms.quick_suggestions"
        static let weightPlaceholder = "training.forms.weight_placeholder"
        static let repsPlaceholder = "training.forms.reps_placeholder"
        static let setsPlaceholder = "training.forms.sets_placeholder"
    }
    
    // MARK: - Alerts Extended
    enum AlertsExtended {
        static let error = "training.alerts.error"
        static let deleteWorkout = "training.alerts.delete_workout"
        static let deleteSetConfirmation = "training.alerts.delete_set_confirmation"
    }
    
    // MARK: - Empty States Extended  
    enum EmptyStatesNew {
        static let noWorkoutHistory = "training.empty_states.no_workout_history"
        static let noWorkoutHistoryMessage = "training.empty_states.no_workout_history_message"
        static let startWorkout = "training.empty_states.start_workout"
        static let noExercisesFound = "training.empty_states.no_exercises_found"
        static let tryAdjustingFilters = "training.empty_states.try_adjusting_filters"
        static let startFirstWorkout = "training.empty_states.start_first_workout"
        static let firstWorkoutMessage = "training.empty_states.first_workout_message"
    }
    
    // MARK: - One RM Setup
    enum OneRMSetup {
        static let proTips = "training.one_rm_setup.pro_tips"
        static let startingConservativeTip = "training.one_rm_setup.starting_conservative_tip"
        static let progressionTip = "training.one_rm_setup.progression_tip"
        static let adjustWeightsTip = "training.one_rm_setup.adjust_weights_tip"
    }
}