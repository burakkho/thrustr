import Foundation
import SwiftData

// MARK: - Cardio Session Model (Actual Performed Workouts)
@Model
final class CardioSession {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var completedAt: Date? = nil
    var isCompleted: Bool = false
    
    // Session Overview
    var sessionNotes: String?
    var feeling: String? // "great", "good", "okay", "tired", "exhausted"
    var weatherConditions: String? // for outdoor sessions
    var perceivedEffort: Int? // 1-10 RPE scale
    
    // Session Totals (calculated)
    var totalDuration: Int = 0 // seconds
    var totalDistance: Double = 0.0 // meters - internal metric storage
    var totalCaloriesBurned: Int? = nil
    var averageHeartRate: Int? = nil
    var maxHeartRate: Int? = nil
    
    // GPS and Route Data (optional)
    var routeData: Data? // serialized GPS coordinates
    var elevationGain: Double? // meters
    var averageSpeed: Double? // km/h
    
    // Personal Records
    var personalRecordsHit: [String] = [] // Types of PRs achieved in this session
    
    // Edit Tracking Flags
    var isDurationManuallyEdited: Bool = false
    var isDistanceManuallyEdited: Bool = false
    var isCaloriesManuallyEdited: Bool = false
    
    // Template Reference
    var originalWorkout: CardioWorkout? = nil
    var wasFromTemplate: Bool = false
    
    // Timestamps
    var createdAt: Date = Date()
    
    // Relationships
    var user: User?
    @Relationship(deleteRule: .cascade, inverse: \CardioResult.session) var results: [CardioResult]?
    
    init(
        workout: CardioWorkout? = nil,
        user: User? = nil,
        wasFromTemplate: Bool = true
    ) {
        self.id = UUID()
        self.startDate = Date()
        self.completedAt = nil
        self.isCompleted = false
        
        self.sessionNotes = nil
        self.feeling = nil
        self.weatherConditions = nil
        self.perceivedEffort = nil
        
        self.totalDuration = 0
        self.totalDistance = 0.0
        self.totalCaloriesBurned = nil
        self.averageHeartRate = nil
        self.maxHeartRate = nil
        
        self.routeData = nil
        self.elevationGain = nil
        self.averageSpeed = nil
        
        self.personalRecordsHit = []
        
        self.isDurationManuallyEdited = false
        self.isDistanceManuallyEdited = false
        self.isCaloriesManuallyEdited = false
        
        self.originalWorkout = workout
        self.wasFromTemplate = wasFromTemplate
        
        self.createdAt = Date()
        
        self.user = user
        self.results = []
        
        // Initialize results from template if available
        if let workout = workout {
            initializeResultsFromTemplate(workout)
        }
    }
}

// MARK: - Computed Properties
extension CardioSession {
    var duration: Int {
        if isCompleted, let completedAt = completedAt {
            return Int(completedAt.timeIntervalSince(startDate))
        }
        return totalDuration
    }
    
    func formattedDistance(using unitSystem: UnitSystem) -> String {
        return UnitsFormatter.formatDistance(meters: totalDistance, system: unitSystem)
    }
    
    @MainActor
    var formattedDistance: String {
        return UnitsFormatter.formatDistance(meters: totalDistance, system: UnitSettings.shared.unitSystem)
    }
    
    func formattedAveragePace(using unitSystem: UnitSystem) -> String? {
        guard totalDistance > 0 && totalDuration > 0 else { return nil }
        let paceMinPerKm = Double(totalDuration) / 60.0 / (totalDistance / 1000.0)
        return UnitsFormatter.formatPace(minPerKm: paceMinPerKm, system: unitSystem)
    }
    
    @MainActor
    var formattedAveragePace: String? {
        guard totalDistance > 0 && totalDuration > 0 else { return nil }
        let paceMinPerKm = Double(totalDuration) / 60.0 / (totalDistance / 1000.0)
        return UnitsFormatter.formatPace(minPerKm: paceMinPerKm, system: UnitSettings.shared.unitSystem)
    }
    
    var workoutName: String {
        return originalWorkout?.localizedName ?? "Cardio Session"
    }
    
    var feelingEmoji: String {
        guard let feeling = feeling else { return "😐" }
        return SessionFeeling(rawValue: feeling)?.emoji ?? "😐"
    }
    
    var formattedDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        let seconds = totalDuration % 60
        
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        } else if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    var averagePace: Double? {
        guard totalDistance > 0 && totalDuration > 0 else { return nil }
        return Double(totalDuration) / (totalDistance / 1000.0) // seconds per km
    }
    
    func formattedSpeed(using unitSystem: UnitSystem) -> String? {
        guard let speed = averageSpeed else { return nil }
        return UnitsFormatter.formatSpeed(kmh: speed, system: unitSystem)
    }
    
    @MainActor
    var formattedSpeed: String? {
        guard let speed = averageSpeed else { return nil }
        return UnitsFormatter.formatSpeed(kmh: speed, system: UnitSettings.shared.unitSystem)
    }
    
    var completionPercentage: Double {
        guard let workout = originalWorkout else { return 0.0 }
        
        let totalExpectedExercises = workout.exercises?.count ?? 0
        guard totalExpectedExercises > 0 else { return 0.0 }
        
        let completedExercises = results?.filter { $0.isCompleted }.count ?? 0
        return Double(completedExercises) / Double(totalExpectedExercises)
    }
}

// MARK: - Methods
extension CardioSession {
    private func initializeResultsFromTemplate(_ workout: CardioWorkout) {
        // Create a result for each exercise in the template
        if results == nil {
            results = []
        }
        for exercise in workout.exercises ?? [] {
            let result = CardioResult(
                exercise: exercise,
                session: self
            )
            results?.append(result)
        }
    }
    
    func addResult(_ result: CardioResult) {
        result.session = self
        if results == nil {
            results = []
        }
        results?.append(result)
    }
    
    func startSession() {
        startDate = Date()
        isCompleted = false
    }
    
    func completeSession() {
        completedAt = Date()
        isCompleted = true
        calculateTotals()
        
        // Update user stats
        if let user = user {
            user.addCardioSession(
                duration: TimeInterval(totalDuration),
                distance: totalDistance
            )
        }
    }
    
    func completeSession(with results: [CardioResult], feeling: String? = nil, notes: String? = nil) {
        self.results = results
        if let feeling = feeling {
            setFeeling(feeling)
        }
        if let notes = notes {
            sessionNotes = notes
        }
        
        completeSession()
        checkForPersonalRecords()
    }
    
    func calculateTotals() {
        // Calculate from completed results
        let completedResults = results?.filter { $0.isCompleted } ?? []
        
        // Only update duration if not manually edited
        if !isDurationManuallyEdited {
            totalDuration = completedResults.reduce(0) { total, result in
                total + (result.completionTime ?? 0)
            }
        }
        
        // Only update distance if not manually edited
        if !isDistanceManuallyEdited {
            totalDistance = completedResults.reduce(0.0) { total, result in
                total + (result.distanceCovered ?? 0.0)
            }
        }
        
        // Only update calories if not manually edited
        if !isCaloriesManuallyEdited {
            totalCaloriesBurned = estimateCalories()
        }
        
        // Calculate average speed (always recalculate based on current duration/distance)
        if totalDistance > 0 && totalDuration > 0 {
            averageSpeed = (totalDistance / 1000.0) / (Double(totalDuration) / 3600.0) // km/h
        }
        
        // Update completion date if not set
        if completedAt == nil {
            completedAt = Date()
        }
    }
    
    private func estimateCalories() -> Int? {
        // Basic calorie estimation based on duration and intensity
        guard let user = user, totalDuration > 0 else { return nil }
        
        // Base metabolic rate per minute
        let bmrPerMinute = user.bmr / (24 * 60)
        let durationMinutes = Double(totalDuration) / 60.0
        
        // Cardio multiplier based on perceived effort or intensity
        let intensityMultiplier: Double
        if let effort = perceivedEffort {
            intensityMultiplier = 3.0 + (Double(effort) * 0.5) // Range: 3.5 - 8.0
        } else {
            intensityMultiplier = 6.0 // Default moderate intensity
        }
        
        let estimatedCalories = bmrPerMinute * durationMinutes * intensityMultiplier
        return Int(estimatedCalories)
    }
    
    func addHeartRateData(average: Int, max: Int) {
        averageHeartRate = average
        maxHeartRate = max
    }
    
    func addGPSData(route: Data, elevation: Double?) {
        routeData = route
        elevationGain = elevation
    }
    
    func setFeeling(_ newFeeling: String) {
        feeling = newFeeling
    }
    
    func setPerceivedEffort(_ effort: Int) {
        perceivedEffort = max(1, min(10, effort)) // Clamp between 1-10
    }
    
    // Manual edit methods
    func updateDurationManually(_ newDuration: Int) {
        totalDuration = newDuration
        isDurationManuallyEdited = true
        
        // Recalculate dependent metrics
        if totalDistance > 0 && totalDuration > 0 {
            averageSpeed = (totalDistance / 1000.0) / (Double(totalDuration) / 3600.0)
        }
    }
    
    func updateDistanceManually(_ newDistance: Double) {
        totalDistance = newDistance
        isDistanceManuallyEdited = true
        
        // Recalculate dependent metrics
        if totalDistance > 0 && totalDuration > 0 {
            averageSpeed = (totalDistance / 1000.0) / (Double(totalDuration) / 3600.0)
        }
    }
    
    func updateCaloriesManually(_ newCalories: Int?) {
        totalCaloriesBurned = newCalories
        isCaloriesManuallyEdited = true
    }
    
    // Check if this session beat any personal records
    func checkForPersonalRecords() {
        personalRecordsHit.removeAll()
        
        for result in results?.filter({ $0.isCompleted }) ?? [] {
            result.checkForPersonalRecord()
            
            // Collect PR types achieved
            if result.isPersonalRecord, let prType = result.prType {
                personalRecordsHit.append(prType)
            }
        }
    }
    
    func duplicate() -> CardioSession {
        let newSession = CardioSession(
            workout: originalWorkout,
            user: user,
            wasFromTemplate: wasFromTemplate
        )
        
        newSession.sessionNotes = sessionNotes
        newSession.feeling = feeling
        newSession.perceivedEffort = perceivedEffort
        
        return newSession
    }
}

// MARK: - Session Feelings
enum SessionFeeling: String, CaseIterable {
    case great = "great"
    case good = "good"
    case okay = "okay"
    case tired = "tired"
    case exhausted = "exhausted"
    
    var displayName: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .tired: return "Tired"
        case .exhausted: return "Exhausted"
        }
    }
    
    var emoji: String {
        switch self {
        case .great: return "🔥"
        case .good: return "💪"
        case .okay: return "😊"
        case .tired: return "😓"
        case .exhausted: return "😫"
        }
    }
    
    var color: String {
        switch self {
        case .great: return "green"
        case .good: return "blue"
        case .okay: return "yellow"
        case .tired: return "orange"
        case .exhausted: return "red"
        }
    }
}

// MARK: - Weather Conditions
enum WeatherCondition: String, CaseIterable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case windy = "windy"
    case hot = "hot"
    case cold = "cold"
    
    var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .windy: return "Windy"
        case .hot: return "Hot"
        case .cold: return "Cold"
        }
    }
    
    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .windy: return "💨"
        case .hot: return "🔥"
        case .cold: return "❄️"
        }
    }
}