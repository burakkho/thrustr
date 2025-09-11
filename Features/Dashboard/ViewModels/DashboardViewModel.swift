import SwiftUI
import SwiftData
import Foundation

@MainActor
@Observable
class DashboardViewModel {
    // MARK: - Observable Properties
    var currentUser: User?
    var weeklyStats: WeeklyStats = WeeklyStats()
    var weeklyCardioStats: WeeklyCardioStats = WeeklyCardioStats()
    var isLoading = true
    
    // Progressive loading states - Performance Enhancement
    var isUserDataLoaded = false
    var isHealthDataLoaded = false
    var isWorkoutDataLoaded = false
    var isNutritionDataLoaded = false
    
    // MARK: - Services
    private let healthKitService: HealthKitService
    private let userService = UserService()
    private let activityLogger = ActivityLoggerService.shared
    
    // MARK: - Unit Settings
    var unitSettings: UnitSettings
    
    // MARK: - Formatting Service
    private let metricsFormatter: DashboardMetricsFormatter
    
    // MARK: - Private Properties  
    private var todayNutritionEntriesCount: Int = 0
    private var todayCalorieCount: Double = 0
    private var todayLiftVolume: Double = 0
    private var todayCardioDistance: Double = 0
    
    // Weekly stats
    private var weeklyCalorieAverage: Double = 0
    
    // Monthly stats
    private var monthlyLiftVolume: Double = 0
    private var monthlyCardioDistance: Double = 0
    private var monthlyCalorieAverage: Double = 0
    
    // Caching for computed metrics  
    private var cachedMetrics: (lift: String, cardio: String, calories: String)?
    
    // Temporal metrics cache - Performance optimization
    private var cachedTemporalMetrics: (
        lift: (daily: String, weekly: String, monthly: String),
        cardio: (daily: String, weekly: String, monthly: String),
        calories: (daily: String, weekly: String, monthly: String)
    )?
    private var temporalCacheTimestamp: Date?
    private let temporalCacheTimeout: TimeInterval = 300 // 5 minutes
    
    init(healthKitService: HealthKitService, unitSettings: UnitSettings = UnitSettings.shared) {
        self.healthKitService = healthKitService
        self.unitSettings = unitSettings
        self.metricsFormatter = DashboardMetricsFormatter(unitSettings: unitSettings)
    }
    
    // MARK: - Public Methods
    func loadData(with modelContext: ModelContext) async {
        isLoading = true
        
        // Sequential loading to avoid Swift 6 concurrency issues
        // Load user data first (required for other operations)
        await loadUserData(modelContext: modelContext)
        isUserDataLoaded = true
        
        // Request HealthKit permissions and load health data
        _ = await healthKitService.requestPermissions()
        await refreshHealthData(modelContext: modelContext)
        isHealthDataLoaded = true
        
        // Load workout and cardio data
        await loadWorkoutData(modelContext: modelContext)
        await loadCardioData(modelContext: modelContext)
        isWorkoutDataLoaded = true
        
        // Load nutrition data  
        await loadNutritionData(modelContext: modelContext)
        isNutritionDataLoaded = true
        
        // Setup activity logger
        await setupActivityLogger(modelContext: modelContext)
        
        // Clear temporal cache to ensure fresh data after reload
        clearTemporalCache()
        
        // Pre-calculate temporal metrics for performance
        preCalculateTemporalMetrics()
        
        // Clear old cache after loading new data
        clearCache()
        isLoading = false
    }
    
    func refreshHealthData(modelContext: ModelContext) async {
        guard let user = currentUser else { return }
        userService.setModelContext(modelContext)
        await userService.syncWithHealthKit(user: user)
        
        // Recalculate temporal metrics after health data refresh
        preCalculateTemporalMetrics()
        
        // Clear old cache after refreshing health data
        clearCache()
    }
    
    // MARK: - Cache Management
    private func clearCache() {
        cachedMetrics = nil
    }
    
    private func clearTemporalCache() {
        cachedTemporalMetrics = nil
        temporalCacheTimestamp = nil
    }
    
    func updateUnitSettings(_ settings: UnitSettings) {
        unitSettings = settings
        clearCache()
        clearTemporalCache()
        // Recalculate with new unit settings
        preCalculateTemporalMetrics()
    }
    
    
    // MARK: - Private Methods
    private func loadUserData(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\User.createdAt)])
        
        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                currentUser = user
            } else {
                // Create default user
                let newUser = User()
                modelContext.insert(newUser)
                try modelContext.save()
                currentUser = newUser
            }
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    private func loadWorkoutData(modelContext: ModelContext) async {
        var descriptor = FetchDescriptor<LiftSession>(
            sortBy: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
        )
        descriptor.predicate = #Predicate<LiftSession> { $0.isCompleted }
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            
            // Calculate today's stats
            let todayWorkouts = allWorkouts.filter { 
                calendar.isDate($0.startDate, inSameDayAs: today)
            }
            todayLiftVolume = todayWorkouts.reduce(0) { $0 + $1.totalVolume }
            
            // Calculate monthly stats
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let monthlyWorkouts = allWorkouts.filter { $0.startDate >= monthAgo }
            monthlyLiftVolume = monthlyWorkouts.reduce(0) { $0 + $1.totalVolume }
            
            // Calculate weekly stats
            let weeklyWorkouts = allWorkouts.filter { $0.startDate >= weekAgo }
            
            weeklyStats = WeeklyStats(
                workoutCount: weeklyWorkouts.count,
                totalVolume: weeklyWorkouts.reduce(0) { $0 + $1.totalVolume },
                totalDuration: weeklyWorkouts.reduce(0.0) { result, session in
                    result + session.duration // Already in seconds (TimeInterval)
                }
            )
        } catch {
            print("Error loading workout data: \(error)")
        }
    }
    
    private func loadNutritionData(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<NutritionEntry>(
            sortBy: [SortDescriptor(\NutritionEntry.date, order: .reverse)]
        )
        
        do {
            let allEntries = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            
            // Today's nutrition
            let todayEntries = allEntries.filter { 
                calendar.isDate($0.date, inSameDayAs: today) 
            }
            todayNutritionEntriesCount = todayEntries.count
            todayCalorieCount = todayEntries.reduce(0.0) { $0 + $1.calories }
            
            // Weekly nutrition average
            let weeklyEntries = allEntries.filter { $0.date >= weekAgo }
            let weeklyDays = Set(weeklyEntries.map { calendar.startOfDay(for: $0.date) }).count
            if weeklyDays > 0 {
                let weeklyTotal = weeklyEntries.reduce(0.0) { $0 + $1.calories }
                weeklyCalorieAverage = weeklyTotal / Double(weeklyDays)
            }
            
            // Monthly nutrition average  
            let monthlyEntries = allEntries.filter { $0.date >= monthAgo }
            let monthlyDays = Set(monthlyEntries.map { calendar.startOfDay(for: $0.date) }).count
            if monthlyDays > 0 {
                let monthlyTotal = monthlyEntries.reduce(0.0) { $0 + $1.calories }
                monthlyCalorieAverage = monthlyTotal / Double(monthlyDays)
            }
        } catch {
            print("Error loading nutrition data: \(error)")
        }
    }
    
    private func loadCardioData(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<CardioSession>(
            sortBy: [SortDescriptor(\CardioSession.startDate, order: .reverse)]
        )
        
        do {
            let allSessions = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            
            // Calculate today's cardio stats
            let todaySessions = allSessions.filter { 
                calendar.isDate($0.startDate, inSameDayAs: today) && $0.isCompleted
            }
            todayCardioDistance = todaySessions.reduce(0.0) { $0 + $1.totalDistance }
            
            // Calculate monthly cardio stats
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let monthlySessions = allSessions.filter { 
                $0.startDate >= monthAgo && $0.isCompleted
            }
            monthlyCardioDistance = monthlySessions.reduce(0.0) { $0 + $1.totalDistance }
            
            // Calculate weekly cardio stats
            let weeklySessions = allSessions.filter { 
                $0.startDate >= weekAgo && $0.isCompleted 
            }
            
            weeklyCardioStats = WeeklyCardioStats(
                sessionCount: weeklySessions.count,
                totalDistance: weeklySessions.reduce(0.0) { $0 + $1.totalDistance },
                totalDuration: weeklySessions.reduce(0.0) { result, session in
                    result + TimeInterval(session.totalDuration)
                }
            )
        } catch {
            print("Error loading cardio data: \(error)")
        }
    }
    
    // MARK: - Dashboard Helpers
    
    
    /**
     * Whether user has completed any strength tests.
     */
    var hasStrengthTestData: Bool {
        return currentUser?.strengthTestCompletionCount ?? 0 > 0
    }
    
    /**
     * Temporal metrics for cycling cards with performance cache.
     */
    var temporalMetrics: (
        lift: (daily: String, weekly: String, monthly: String),
        cardio: (daily: String, weekly: String, monthly: String), 
        calories: (daily: String, weekly: String, monthly: String)
    ) {
        // Check cache validity (5 minutes) - Performance optimization
        if let cached = cachedTemporalMetrics,
           let timestamp = temporalCacheTimestamp,
           Date().timeIntervalSince(timestamp) < temporalCacheTimeout {
            return cached
        }
        
        // Fallback: Calculate live (existing logic)
        return calculateTemporalMetricsLive()
    }
    
    
    // MARK: - Temporal Metric Calculations
    
    /**
     * Live calculation of temporal metrics (fallback for cache miss).
     */
    private func calculateTemporalMetricsLive() -> (
        lift: (daily: String, weekly: String, monthly: String),
        cardio: (daily: String, weekly: String, monthly: String),
        calories: (daily: String, weekly: String, monthly: String)
    ) {
        return (
            lift: calculateLiftMetrics(),
            cardio: calculateCardioMetrics(),
            calories: calculateCalorieMetrics()
        )
    }
    
    /**
     * Pre-calculate and cache temporal metrics for performance.
     */
    private func preCalculateTemporalMetrics() {
        let metrics = calculateTemporalMetricsLive()
        cachedTemporalMetrics = metrics
        temporalCacheTimestamp = Date()
    }
    
    private func calculateLiftMetrics() -> (daily: String, weekly: String, monthly: String) {
        let weeklyAverage = weeklyStats.totalVolume / 7.0
        let monthlyAverage = monthlyLiftVolume / 30.0
        
        return metricsFormatter.formatTemporalLiftMetrics(
            daily: todayLiftVolume,
            weeklyAverage: weeklyAverage,
            monthlyAverage: monthlyAverage
        )
    }
    
    private func calculateCardioMetrics() -> (daily: String, weekly: String, monthly: String) {
        let weeklyAverage = weeklyCardioStats.totalDistance / 7.0
        let monthlyAverage = monthlyCardioDistance / 30.0
        
        return metricsFormatter.formatTemporalCardioMetrics(
            daily: todayCardioDistance,
            weeklyAverage: weeklyAverage,
            monthlyAverage: monthlyAverage
        )
    }
    
    private func calculateCalorieMetrics() -> (daily: String, weekly: String, monthly: String) {
        return metricsFormatter.formatTemporalCalorieMetrics(
            daily: todayCalorieCount,
            weekly: weeklyCalorieAverage,
            monthly: monthlyCalorieAverage
        )
    }
    
    // MARK: - Progress Calculations
    
    var dailyCalorieProgress: Double {
        return metricsFormatter.calculateDailyCalorieProgress(
            currentCalories: todayCalorieCount,
            user: currentUser
        )
    }
    
    // MARK: - Activity Logger Integration
    
    private func setupActivityLogger(modelContext: ModelContext) async {
        activityLogger.setModelContext(modelContext)
        
        // Perform background cleanup
        Task.detached(priority: .background) {
            await self.activityLogger.performCleanup()
        }
    }
}

// MARK: - Supporting Models
struct WeeklyStats {
    let workoutCount: Int
    let totalVolume: Double
    let totalDuration: TimeInterval
    
    init(workoutCount: Int = 0, totalVolume: Double = 0, totalDuration: TimeInterval = 0) {
        self.workoutCount = workoutCount
        self.totalVolume = totalVolume
        self.totalDuration = totalDuration
    }
}

struct WeeklyCardioStats {
    let sessionCount: Int
    let totalDistance: Double // meters
    let totalDuration: TimeInterval
    
    init(sessionCount: Int = 0, totalDistance: Double = 0, totalDuration: TimeInterval = 0) {
        self.sessionCount = sessionCount
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
    }
}

// MARK: - Dashboard Metrics Formatter
@MainActor
struct DashboardMetricsFormatter {
    private let unitSettings: UnitSettings
    
    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }
    
    func formatCaloriesPerDay(_ calories: Double) -> String {
        return String(format: "%.0f", calories)
    }
    
    func formatVolumePerDay(_ volume: Double) -> String {
        return UnitsFormatter.formatVolume(kg: volume, system: unitSettings.unitSystem)
    }
    
    func formatDistancePerDay(_ distance: Double) -> String {
        return UnitsFormatter.formatDistance(meters: distance, system: unitSettings.unitSystem)
    }
    
    func calculateDailyCalorieProgress(currentCalories: Double, user: User?) -> Double {
        guard let user = user, user.dailyCalorieGoal > 0 else { return 0.0 }
        return currentCalories / user.dailyCalorieGoal
    }
    
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

