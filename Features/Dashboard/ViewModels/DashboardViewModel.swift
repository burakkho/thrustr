import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var recentWorkouts: [Workout] = []
    @Published var todayNutritionEntries: [NutritionEntry] = []
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    @Published var isLoading = true
    @Published var showingWeightEntry = false
    
    // MARK: - Services
    private let healthKitService: HealthKitService
    private let userService = UserService()
    private let workoutService = WorkoutService()
    
    // MARK: - Cache Management
    private var cacheManager = DashboardCacheManager()
    
    // MARK: - Constants
    private struct Constants {
        static let recentWorkoutsLimit = 5
        static let cacheValidityDuration: TimeInterval = 60 // 1 minute
    }
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    // MARK: - Public Methods
    func loadData(with modelContext: ModelContext) async {
        isLoading = true
        
        // Load user data
        await loadUserData(modelContext: modelContext)
        
        // Request HealthKit permissions and sync
        _ = await healthKitService.requestPermissions()
        await refreshHealthData(modelContext: modelContext)
        
        // Load workout data
        await loadWorkoutData(modelContext: modelContext)
        
        // Load nutrition data
        await loadNutritionData(modelContext: modelContext)
        
        isLoading = false
    }
    
    func refreshHealthData(modelContext: ModelContext) async {
        guard let user = currentUser else { return }
        userService.setModelContext(modelContext)
        await userService.syncWithHealthKit(user: user)
    }
    
    func invalidateCache() {
        cacheManager.invalidateAll()
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
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\Workout.startTime, order: .reverse)]
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            recentWorkouts = Array(allWorkouts.prefix(Constants.recentWorkoutsLimit))
            
            // Update workout service statistics
            workoutService.loadWorkoutStats(workouts: allWorkouts)
            weeklyStats = WeeklyStats(
                workoutCount: workoutService.weeklyWorkoutCount,
                totalVolume: workoutService.weeklyVolume,
                totalDuration: workoutService.weeklyDuration
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
            
            todayNutritionEntries = allEntries.filter { 
                calendar.isDate($0.date, inSameDayAs: today) 
            }
        } catch {
            print("Error loading nutrition data: \(error)")
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

// MARK: - Cache Manager
class DashboardCacheManager {
    private var lastUpdate: Date = Date.distantPast
    private let validityDuration: TimeInterval = 60
    
    var isValid: Bool {
        Date().timeIntervalSince(lastUpdate) < validityDuration
    }
    
    func markUpdated() {
        lastUpdate = Date()
    }
    
    func invalidateAll() {
        lastUpdate = Date.distantPast
    }
}