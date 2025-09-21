import Foundation

/// Analytics feature localization keys
enum AnalyticsKeys {
    static let title = "analytics.title"
    static let health = "analytics.health"
    static let training = "analytics.training"
    static let nutrition = "analytics.nutrition"

    enum Insights {
        static let title = "analytics.insights.title"
        static let insights = "analytics.insights.insights"
        static let priority_insights = "analytics.insights.priority_insights"
        static let recovery_insights = "analytics.insights.recovery_insights"
        static let training_insights = "analytics.insights.training_insights"
        static let no_insights = "analytics.insights.no_insights"
        static let no_insights_message = "analytics.insights.no_insights_message"
    }

    enum Goals {
        static let active_goals = "analytics.goals.active_goals"
        static let completed_goals = "analytics.goals.completed_goals"
        static let progress = "analytics.goals.progress"
        static let no_active_goals = "analytics.goals.no_active_goals"
        static let create_goal = "analytics.goals.create_goal"
    }

    enum Charts {
        static let no_data_available = "analytics.charts.no_data_available"
        static let no_data_message = "analytics.charts.no_data_message"
        static let loading_data = "analytics.charts.loading_data"
        static let period_1m = "analytics.charts.period_1m"
        static let period_3m = "analytics.charts.period_3m"
        static let period_6m = "analytics.charts.period_6m"
        static let period_1y = "analytics.charts.period_1y"
        static let period_all = "analytics.charts.period_all"
    }

    enum Strength {
        static let progression = "analytics.strength.progression"
        static let strength_assessment = "analytics.strength.assessment"
        static let one_rm_progression = "analytics.strength.one_rm_progression"
        static let volume_progression = "analytics.strength.volume_progression"
        static let exercise = "analytics.strength.exercise"
        static let current_max = "analytics.strength.current_max"
        static let previous_max = "analytics.strength.previous_max"
        static let improvement = "analytics.strength.improvement"
    }

    enum Performance {
        static let detailed_stats = "analytics.performance.detailed_stats"
        static let performance = "analytics.performance.performance"
        static let average_performance = "analytics.performance.average_performance"
        static let best_performance = "analytics.performance.best_performance"
        static let recent_performance = "analytics.performance.recent_performance"
    }

    enum Recovery {
        static let recovery_score = "analytics.recovery.recovery_score"
        static let sleep_quality = "analytics.recovery.sleep_quality"
        static let hrv = "analytics.recovery.hrv"
        static let workout_load = "analytics.recovery.workout_load"
        static let recovery_trend = "analytics.recovery.recovery_trend"
    }

    enum Fitness {
        static let fitness_level = "analytics.fitness.fitness_level"
        static let vo2_max = "analytics.fitness.vo2_max"
        static let cardio_fitness = "analytics.fitness.cardio_fitness"
        static let strength_level = "analytics.fitness.strength_level"
        static let overall_fitness = "analytics.fitness.overall_fitness"
    }

    enum Time {
        static let this_week = "analytics.time.this_week"
        static let this_month = "analytics.time.this_month"
        static let last_week = "analytics.time.last_week"
        static let last_month = "analytics.time.last_month"
        static let last_30_days = "analytics.time.last_30_days"
        static let last_90_days = "analytics.time.last_90_days"
    }

    enum Actions {
        static let view_details = "analytics.actions.view_details"
        static let export_data = "analytics.actions.export_data"
        static let share_progress = "analytics.actions.share_progress"
        static let set_goal = "analytics.actions.set_goal"
    }

    enum Empty {
        static let no_data_title = "analytics.empty.no_data_title"
        static let no_data_message = "analytics.empty.no_data_message"
        static let start_tracking = "analytics.empty.start_tracking"
        static let import_data = "analytics.empty.import_data"
    }
}