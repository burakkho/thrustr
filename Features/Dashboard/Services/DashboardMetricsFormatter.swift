import Foundation

/**
 * Dashboard metrics formatting service.
 * 
 * Separates formatting logic from ViewModel following Single Responsibility Principle.
 * Handles all dashboard-specific formatting with unit conversion support.
 */
@MainActor
struct DashboardMetricsFormatter {
    private let unitSettings: UnitSettings
    
    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }
    
    // MARK: - Daily Metrics Formatting
    
    func formatCaloriesPerDay(_ calories: Double) -> String {
        return String(format: "%.0f", calories)
    }
    
    func formatVolumePerDay(_ volume: Double) -> String {
        return UnitsFormatter.formatVolume(kg: volume, system: unitSettings.unitSystem)
    }
    
    func formatDistancePerDay(_ distance: Double) -> String {
        return UnitsFormatter.formatDistance(meters: distance, system: unitSettings.unitSystem)
    }
    
    // MARK: - Progress Calculations
    
    func calculateDailyCalorieProgress(currentCalories: Double, user: User?) -> Double {
        guard let user = user, user.dailyCalorieGoal > 0 else { return 0.0 }
        return currentCalories / user.dailyCalorieGoal
    }
    
    // MARK: - Temporal Metrics Formatting
    
    func formatTemporalLiftMetrics(
        daily: Double,
        weeklyAverage: Double, 
        monthlyAverage: Double
    ) -> (daily: String, weekly: String, monthly: String) {
        return (
            daily: formatVolumePerDay(daily),
            weekly: formatVolumePerDay(weeklyAverage),
            monthly: formatVolumePerDay(monthlyAverage)
        )
    }
    
    func formatTemporalCardioMetrics(
        daily: Double,
        weeklyAverage: Double,
        monthlyAverage: Double
    ) -> (daily: String, weekly: String, monthly: String) {
        return (
            daily: formatDistancePerDay(daily),
            weekly: formatDistancePerDay(weeklyAverage), 
            monthly: formatDistancePerDay(monthlyAverage)
        )
    }
    
    func formatTemporalCalorieMetrics(
        daily: Double,
        weekly: Double,
        monthly: Double
    ) -> (daily: String, weekly: String, monthly: String) {
        return (
            daily: formatCaloriesPerDay(daily),
            weekly: formatCaloriesPerDay(weekly),
            monthly: formatCaloriesPerDay(monthly)
        )
    }
}