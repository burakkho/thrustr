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
        static let distance = "training.cardio.distance"
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
        static let pace = "training.cardio.pace"
        static let speed = "training.cardio.speed"
        static let calories = "training.cardio.calories"
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
        static let personalRecord = "training.cardio.personalRecord"
        static let statistics = "training.cardio.statistics"
        static let totalSessions = "training.cardio.totalSessions"
        static let lastPerformed = "training.cardio.lastPerformed"
        static let recentSessions = "training.cardio.recentSessions"
        static let startWorkout = "training.cardio.startWorkout"
        static let duplicate = "training.cardio.duplicate"
        static let delete = "training.cardio.delete"
        
        // History and results
        static let noHistory = "training.cardio.noHistory"
        static let noHistoryMessage = "training.cardio.noHistoryMessage"
        static let browseTemplates = "training.cardio.browseTemplates"
        static let personalRecordBadge = "training.cardio.personalRecordBadge"
        static let lastSession = "training.cardio.lastSession"
        
        // Categories
        static let exerciseTypes = "training.cardio.exerciseTypes"
        static let customSessions = "training.cardio.customSessions"
        
        // Empty states
        static let noExerciseTypes = "training.cardio.noExerciseTypes"
        static let adjustSearch = "training.cardio.adjustSearch"
        static let clearSearch = "training.cardio.clearSearch"
        static let neverAttempted = "training.cardio.neverAttempted"
        
        // Equipment types
        static let outdoor = "training.cardio.outdoor"
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
        static let quickStart = "training.cardio.quickStart"
        static let selectActivityAndStart = "training.cardio.selectActivityAndStart"
        static let location = "training.cardio.location"
        static let indoor = "training.cardio.indoor"
        static let ergometer = "training.cardio.ergometer"
        static let selectActivity = "training.cardio.selectActivity"
        static let noActivities = "training.cardio.noActivities"
        static let noActivitiesDescription = "training.cardio.noActivitiesDescription"
        static let features = "training.cardio.features"
        
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
        static let bpm = "training.cardio.bpm"
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
    }
    
    enum OneRM {
        static let enterWeight = "training.oneRM.enterWeight"
        static let estimateHelp = "training.oneRM.estimateHelp"
        static let underestimateWarning = "training.oneRM.underestimateWarning"
        static let previous = "training.oneRM.previous"
        static let next = "training.oneRM.next"
        static let calculateWeights = "training.oneRM.calculateWeights"
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
}