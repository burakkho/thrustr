import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for ProgressChartsView with clean NVVM pattern.
 *
 * Manages UI state and coordinates with ProgressChartsService for business logic.
 * Follows modern iOS 17+ patterns with @MainActor @Observable.
 *
 * Responsibilities:
 * - UI state management for chart display
 * - Time range and chart type selection
 * - Loading state coordination
 * - Data filtering and preparation coordination
 */
@MainActor
@Observable
class ProgressChartsViewModel {

    // MARK: - Observable Properties

    var selectedTimeRange: TimeRange = .month3
    var selectedChartType: ChartType = .weight
    var isLoading = true
    var showingChartDetail = false
    var selectedDataPoint: Date? = nil

    // User data
    var currentUser: User? = nil

    // Filtered data properties
    var filteredWeightEntries: [WeightEntry] = []
    var filteredLiftSessions: [LiftSession] = []
    var filteredCardioSessions: [CardioSession] = []
    var filteredBodyMeasurements: [BodyMeasurement] = []

    // Chart-specific data
    var chartData: ProgressChartsData = ProgressChartsData()
    var statisticsData: StatisticsData = StatisticsData()
    var insightsData: InsightsData = InsightsData()

    // MARK: - Dependencies

    private let progressChartsService = ProgressChartsService.self

    // MARK: - Public Methods

    /**
     * Loads progress charts data with filtered results.
     *
     * Coordinates with service layer to filter data and prepare charts.
     * Manages loading states and updates UI data properties.
     */
    func loadProgressData(
        allWeightEntries: [WeightEntry],
        allLiftSessions: [LiftSession],
        allCardioSessions: [CardioSession],
        allBodyMeasurements: [BodyMeasurement],
        user: User?
    ) {
        isLoading = true

        // Set current user
        currentUser = user

        // Filter data based on selected time range
        let cutoffDate = progressChartsService.calculateCutoffDate(for: selectedTimeRange)

        filteredWeightEntries = progressChartsService.filterWeightEntries(
            allWeightEntries,
            cutoffDate: cutoffDate
        )

        filteredLiftSessions = progressChartsService.filterLiftSessions(
            allLiftSessions,
            cutoffDate: cutoffDate
        )

        filteredCardioSessions = progressChartsService.filterCardioSessions(
            allCardioSessions,
            cutoffDate: cutoffDate
        )

        filteredBodyMeasurements = progressChartsService.filterBodyMeasurements(
            allBodyMeasurements,
            cutoffDate: cutoffDate
        )

        // Prepare chart data
        prepareChartData()

        // Calculate statistics
        calculateStatistics(user: user)

        // Generate insights
        generateInsights()

        // Simulate loading delay for smooth UX
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }

    /**
     * Changes selected time range and reloads data.
     */
    func changeTimeRange(
        to newRange: TimeRange,
        allWeightEntries: [WeightEntry],
        allLiftSessions: [LiftSession],
        allCardioSessions: [CardioSession],
        allBodyMeasurements: [BodyMeasurement],
        user: User?
    ) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTimeRange = newRange
            loadProgressData(
                allWeightEntries: allWeightEntries,
                allLiftSessions: allLiftSessions,
                allCardioSessions: allCardioSessions,
                allBodyMeasurements: allBodyMeasurements,
                user: user
            )
        }
    }

    /**
     * Changes selected chart type and updates display.
     */
    func changeChartType(
        to newType: ChartType,
        allWeightEntries: [WeightEntry],
        allLiftSessions: [LiftSession],
        allCardioSessions: [CardioSession],
        allBodyMeasurements: [BodyMeasurement],
        user: User?
    ) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedChartType = newType
            loadProgressData(
                allWeightEntries: allWeightEntries,
                allLiftSessions: allLiftSessions,
                allCardioSessions: allCardioSessions,
                allBodyMeasurements: allBodyMeasurements,
                user: user
            )
        }
    }

    /**
     * Simulates initial loading delay for smooth UX.
     */
    func startInitialLoading() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }

    /**
     * Selects a data point for detailed view.
     */
    func selectDataPoint(_ date: Date) {
        withAnimation(.spring(response: 0.3)) {
            selectedDataPoint = date
        }
    }

    /**
     * Shows chart detail view.
     */
    func showChartDetail() {
        showingChartDetail = true
    }

    /**
     * Hides chart detail view.
     */
    func hideChartDetail() {
        showingChartDetail = false
        selectedDataPoint = nil
    }

    // MARK: - Private Methods

    /**
     * Prepares chart data based on selected chart type.
     */
    private func prepareChartData() {
        switch selectedChartType {
        case .weight:
            chartData.weightChartData = progressChartsService.prepareWeightChartData(
                from: filteredWeightEntries
            )
        case .workoutVolume:
            chartData.volumeChartData = progressChartsService.prepareVolumeChartData(
                from: filteredLiftSessions
            )
        case .workoutFrequency:
            chartData.frequencyChartData = progressChartsService.prepareFrequencyChartData(
                from: filteredLiftSessions
            )
        case .bodyMeasurements:
            chartData.measurementChartData = progressChartsService.prepareMeasurementChartData(
                from: filteredBodyMeasurements
            )
        case .strength:
            chartData.strengthChartData = progressChartsService.prepareStrengthChartData(
                from: filteredLiftSessions
            )
        case .cardio:
            chartData.cardioChartData = progressChartsService.prepareCardioChartData(
                from: filteredCardioSessions
            )
        }
    }

    /**
     * Calculates statistics for current chart type.
     */
    private func calculateStatistics(user: User?) {
        switch selectedChartType {
        case .weight:
            statisticsData.weightStats = progressChartsService.calculateWeightStatistics(
                from: filteredWeightEntries
            )
        case .workoutVolume, .workoutFrequency:
            statisticsData.workoutStats = progressChartsService.calculateWorkoutStatistics(
                from: filteredLiftSessions,
                timeRange: selectedTimeRange
            )
        case .bodyMeasurements:
            statisticsData.measurementStats = progressChartsService.calculateMeasurementStatistics(
                from: filteredBodyMeasurements
            )
        case .strength:
            statisticsData.strengthStats = progressChartsService.calculateStrengthStatistics(
                from: filteredLiftSessions,
                timeRange: selectedTimeRange
            )
        case .cardio:
            statisticsData.cardioStats = progressChartsService.calculateCardioStatistics(
                from: filteredCardioSessions,
                timeRange: selectedTimeRange
            )
        }
    }

    /**
     * Generates insights based on current data.
     */
    private func generateInsights() {
        insightsData.weightInsights = progressChartsService.generateWeightInsights(
            from: filteredWeightEntries
        )

        insightsData.workoutInsights = progressChartsService.generateWorkoutInsights(
            from: filteredLiftSessions,
            timeRange: selectedTimeRange
        )
    }
}

// MARK: - Supporting Data Models

/**
 * Container for all chart data types.
 */
struct ProgressChartsData {
    var weightChartData: [WeightChartData] = []
    var volumeChartData: [WeeklyVolumeData] = []
    var frequencyChartData: [FrequencyData] = []
    var measurementChartData: [MeasurementChartData] = []
    var strengthChartData: [StrengthProgressData] = []
    var cardioChartData: [CardioProgressData] = []
}

/**
 * Container for statistics data.
 */
struct StatisticsData {
    var weightStats: WeightStatistics?
    var workoutStats: WorkoutStatistics?
    var measurementStats: MeasurementStatistics?
    var strengthStats: StrengthStatistics?
    var cardioStats: CardioStatistics?
}

/**
 * Container for insights data.
 */
struct InsightsData {
    var weightInsights: WeightInsights?
    var workoutInsights: WorkoutInsights?
}

// MARK: - Statistics Models

struct WeightStatistics {
    let weightChange: Double
    let averageWeight: Double
    let entryCount: Int
    let latestWeight: Double
}

struct WorkoutStatistics {
    let totalWorkouts: Int
    let averageWorkoutsPerWeek: Double
    let totalVolume: Double
    let averageVolume: Double
}

struct MeasurementStatistics {
    let change: String
    let average: String
}

// MARK: - Insights Models

struct WeightInsights {
    let trend: String
    let trendDirection: ProgressTrendDirection
}

struct WorkoutInsights {
    let consistency: String
    let consistencyLevel: ConsistencyLevel
}

enum ProgressTrendDirection {
    case upward, downward, stable
}

enum ConsistencyLevel {
    case excellent, good, average, low
}