import Foundation

/// Cardio-specific localization keys
enum CardioKeys {
    // MARK: - Common
    enum Common {
        static let cardioWorkout = "training.cardio.title"
        static let cardio = "training.cardio.name"
    }
    // MARK: - Time Periods
    enum TimePeriods {
        static let thisWeek = "cardio.time_periods.this_week"
        static let thisMonth = "cardio.time_periods.this_month"
        static let latest = "cardio.time_periods.latest"
    }
    
    // MARK: - Heart Rate Stats
    enum HeartRateStats {
        static let average = "cardio.heart_rate.average"
        static let maximum = "cardio.heart_rate.maximum"
        static let resting = "cardio.heart_rate.resting"
    }
    
    // MARK: - Progress
    enum Progress {
        static let totalPRs = "cardio.progress.total_prs"
        static let latestPR = "cardio.progress.latest_pr"
    }
    
    // MARK: - Actions
    enum Actions {
        static let save = "cardio.actions.save"
        static let cancel = "cardio.actions.cancel"
        static let rescan = "cardio.actions.rescan"
        static let retry = "cardio.actions.retry"
    }
    
    // MARK: - Time Units
    enum TimeUnits {
        static let hour = "cardio.time_units.hour"
        static let minute = "cardio.time_units.minute"
        static let second = "cardio.time_units.second"
        static let hours = "cardio.time_units.hours"
        static let minutes = "cardio.time_units.minutes"
        static let seconds = "cardio.time_units.seconds"
    }
    
    // MARK: - GPS Status
    enum GPSStatus {
        static let status = "cardio.gps.status"
        static let searching = "cardio.gps.searching"
        static let ready = "cardio.gps.ready"
        static let weak = "cardio.gps.weak"
        static let noSignal = "cardio.gps.no_signal"
        static let notNeeded = "cardio.gps.not_needed"
    }
    
    // MARK: - Stats Labels
    enum StatsLabels {
        static let averageStats = "cardio.stats.average_stats"
        static let maximumStats = "cardio.stats.maximum_stats"
        static let detailedStats = "cardio.stats.detailed_stats"
        static let performance = "cardio.stats.performance"
        static let notes = "cardio.stats.notes"
    }
    
    // MARK: - Form Labels  
    enum FormLabels {
        static let step = "cardio.form.step"
        static let completed = "cardio.form.completed"
        static let progressFormat = "cardio.form.progress_format" // "%d%% Completed"
        static let repetition = "cardio.form.repetition"
        static let repetitions = "cardio.form.repetitions"
    }
    
    // MARK: - Empty States
    enum EmptyStates {
        static let startFirstCardioSession = "cardio.empty.start_first_session"
    }
    
    // MARK: - Session Summary
    enum SessionSummary {
        // Navigation titles
        static let workoutSummaryTitle = "cardio.session.workout_summary_title"
        static let editDurationTitle = "cardio.session.edit_duration_title"
        static let editDistanceTitle = "cardio.session.edit_distance_title"
        static let editHeartRateTitle = "cardio.session.edit_heart_rate_title"
        static let editCaloriesTitle = "cardio.session.edit_calories_title"
        
        // Main messages
        static let workoutCompleted = "cardio.session.workout_completed"
        static let howDoYouFeel = "cardio.session.how_do_you_feel"
        static let notesPlaceholder = "cardio.session.notes_placeholder"
        static let exitWithoutSaving = "cardio.session.exit_without_saving"
        
        // Route section
        static let yourRoute = "cardio.session.your_route"
        static let startMarker = "cardio.session.start_marker"
        static let finishMarker = "cardio.session.finish_marker"
        
        // Stats section
        static let detailedStatistics = "cardio.session.detailed_statistics"
        static let perceivedEffort = "cardio.session.perceived_effort"
        static let heartRateStats = "cardio.session.heart_rate_stats"
        static let addHeartRateData = "cardio.session.add_heart_rate_data"
        static let edited = "cardio.session.edited"
        
        // Edit sections
        static let editDuration = "cardio.session.edit_duration"
        static let editDistance = "cardio.session.edit_distance"
        static let editHeartRate = "cardio.session.edit_heart_rate"
        static let editCalories = "cardio.session.edit_calories"
        
        // Edit descriptions
        static let durationDescription = "cardio.session.duration_description"
        static let distanceDescription = "cardio.session.distance_description"
        static let heartRateDescription = "cardio.session.heart_rate_description"
        static let caloriesDescription = "cardio.session.calories_description"
        
        // Form labels
        static let durationLabel = "cardio.session.duration_label"
        static let averageHeartRate = "cardio.session.average_heart_rate"
        static let maximumHeartRate = "cardio.session.maximum_heart_rate"
        static let burnedCalories = "cardio.session.burned_calories"
        static let averageHeartRateBpm = "cardio.session.average_heart_rate_bpm"
        static let maximumHeartRateBpm = "cardio.session.maximum_heart_rate_bpm"
        static let editCaloriesDescription = "cardio.session.edit_calories_description"
        static let caloriesBurnedLabel = "cardio.session.calories_burned_label"
        
        // Tips
        static let tipIcon = "cardio.session.tip_icon"
        static let heartRateTip = "cardio.session.heart_rate_tip"
        static let caloriesTip = "cardio.session.calories_tip"
        
        // Share text components
        static let shareWorkoutCompleted = "cardio.session.share_workout_completed"
        static let shareDurationPrefix = "cardio.session.share_duration_prefix"
        
        // Achievement notifications
        static let achievementTitle = "cardio.session.achievement_title"
        static let achievementBody = "cardio.session.achievement_body"
        static let achievementInApp = "cardio.session.achievement_in_app"
    }
}