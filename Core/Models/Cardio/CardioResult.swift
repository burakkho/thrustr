import Foundation
import SwiftData

// MARK: - Cardio Result Model (Per-Exercise Results)
@Model
final class CardioResult {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var isCompleted: Bool = false
    
    // Performance Data
    var completionTime: Int? // in seconds (for distance workouts)
    var distanceCovered: Double? // in meters (for time workouts or actual distance)
    var targetDistance: Int? // original target from exercise
    var targetTime: Int? // original target from exercise
    
    // Intensity and Effort
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var perceivedEffort: Int? // 1-10 RPE scale
    var caloriesBurned: Int? // estimated for this specific exercise
    
    // Performance Metrics
    var averagePace: Double? // seconds per km (calculated or manual)
    var averageSpeed: Double? // km/h
    var splitTimes: [Int]? // array of split times in seconds
    
    // Environment and Conditions
    var temperature: Double? // celsius
    var humidity: Int? // percentage
    var windConditions: String?
    
    // Equipment and Setup
    var equipmentUsed: String? // actual equipment used
    var resistance: Int? // for erg machines
    var incline: Double? // for treadmill
    
    // Notes and Feedback
    var exerciseNotes: String?
    var isPersonalRecord: Bool = false
    var prType: String? // "fastest_time", "longest_distance", "best_pace"
    
    // GPS and Route Data (for outdoor exercises)
    var gpsData: Data? // serialized GPS points for this specific exercise
    var elevationGain: Double? // meters
    var routeID: String? // reference to saved route
    
    // Timestamps
    var startedAt: Date?
    var createdAt: Date = Date()
    
    // Relationships
    var exercise: CardioExercise?
    var session: CardioSession?
    var user: User?
    
    init(
        exercise: CardioExercise? = nil,
        session: CardioSession? = nil,
        completionTime: Int? = nil,
        distanceCovered: Double? = nil
    ) {
        self.id = UUID()
        self.completedAt = Date()
        self.isCompleted = false
        
        self.completionTime = completionTime
        self.distanceCovered = distanceCovered
        self.targetDistance = exercise?.targetDistance
        self.targetTime = exercise?.targetTime
        
        self.averageHeartRate = nil
        self.maxHeartRate = nil
        self.perceivedEffort = nil
        self.caloriesBurned = nil
        
        self.averagePace = nil
        self.averageSpeed = nil
        self.splitTimes = nil
        
        self.temperature = nil
        self.humidity = nil
        self.windConditions = nil
        
        self.equipmentUsed = exercise?.equipment
        self.resistance = nil
        self.incline = nil
        
        self.exerciseNotes = nil
        self.isPersonalRecord = false
        self.prType = nil
        
        self.gpsData = nil
        self.elevationGain = nil
        self.routeID = nil
        
        self.startedAt = nil
        self.createdAt = Date()
        
        self.exercise = exercise
        self.session = session
        self.user = session?.user
    }
}

// MARK: - Computed Properties
extension CardioResult {
    var formattedTime: String? {
        guard let time = completionTime else { return nil }
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        } else if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    @MainActor
    var formattedDistance: String? {
        guard let distance = distanceCovered else { return nil }
        return UnitsFormatter.formatDistance(meters: distance, system: UnitSettings.shared.unitSystem)
    }
    
    @MainActor
    var formattedPace: String? {
        let paceSeconds = calculatePace()
        guard let paceSeconds = paceSeconds else { return nil }
        let paceMinPerKm = Double(paceSeconds) / 60.0
        return UnitsFormatter.formatPace(minPerKm: paceMinPerKm, system: UnitSettings.shared.unitSystem)
    }
    
    @MainActor
    var formattedSpeed: String? {
        guard let speed = calculateSpeed() else { return nil }
        return UnitsFormatter.formatSpeed(kmh: speed, system: UnitSettings.shared.unitSystem)
    }
    
    var percentageOfTarget: Double? {
        if let targetDist = targetDistance, let actualDist = distanceCovered {
            return (actualDist / Double(targetDist)) * 100.0
        } else if let targetT = targetTime, let actualT = completionTime {
            return (Double(actualT) / Double(targetT)) * 100.0
        }
        return nil
    }
    
    var targetComparison: String? {
        guard let percentage = percentageOfTarget else { return nil }
        
        if let _ = targetDistance {
            // Distance target - higher percentage is better
            if percentage >= 100 {
                return "Target exceeded by \(Int(percentage - 100))%"
            } else {
                return "Target missed by \(Int(100 - percentage))%"
            }
        } else if let _ = targetTime {
            // Time target - lower percentage is better
            if percentage <= 100 {
                return "Beat target by \(Int(100 - percentage))%"
            } else {
                return "Over target by \(Int(percentage - 100))%"
            }
        }
        return nil
    }
    
    var effortLevel: String {
        guard let effort = perceivedEffort else { return "Unknown" }
        switch effort {
        case 1...2: return "Very Easy"
        case 3...4: return "Easy"
        case 5...6: return "Moderate"
        case 7...8: return "Hard"
        case 9...10: return "Very Hard"
        default: return "Unknown"
        }
    }
    
    var prBadge: String? {
        guard isPersonalRecord else { return nil }
        switch prType {
        case "fastest_time": return "🏃‍♂️ Fastest"
        case "longest_distance": return "🚀 Furthest"
        case "best_pace": return "⚡ Best Pace"
        default: return "🏆 PR"
        }
    }
}

// MARK: - Calculation Methods
extension CardioResult {
    func calculatePace() -> Double? {
        // Calculate pace in seconds per kilometer
        guard let time = completionTime, let distance = distanceCovered else { return nil }
        guard distance > 0 else { return nil }
        
        let distanceKm = distance / 1000.0
        return Double(time) / distanceKm
    }
    
    func calculateSpeed() -> Double? {
        // Calculate speed in km/h
        guard let time = completionTime, let distance = distanceCovered else { return nil }
        guard time > 0 else { return nil }
        
        let distanceKm = distance / 1000.0
        let timeHours = Double(time) / 3600.0
        return distanceKm / timeHours
    }
    
    func estimateCalories() -> Int? {
        guard let user = user, let time = completionTime else { return nil }
        
        // Basic calorie estimation based on MET values
        let durationHours = Double(time) / 3600.0
        let weightKg = user.currentWeight
        
        // MET values for different activities (approximate)
        let metValue: Double
        if let pace = calculatePace() {
            // Running MET based on pace
            let paceMinPerKm = pace / 60.0
            switch paceMinPerKm {
            case 0..<4: metValue = 15.0 // Very fast
            case 4..<5: metValue = 12.0 // Fast
            case 5..<6: metValue = 10.0 // Moderate
            case 6..<7: metValue = 8.0  // Slow
            default: metValue = 6.0     // Very slow
            }
        } else {
            // Default moderate intensity
            metValue = 8.0
        }
        
        let calories = metValue * weightKg * durationHours
        return Int(calories)
    }
}

// MARK: - Methods
extension CardioResult {
    func completeExercise(
        time: Int? = nil,
        distance: Double? = nil,
        heartRate: (avg: Int, max: Int)? = nil,
        effort: Int? = nil,
        notes: String? = nil
    ) {
        if let time = time { completionTime = time }
        if let distance = distance { distanceCovered = distance }
        if let hr = heartRate {
            averageHeartRate = hr.avg
            maxHeartRate = hr.max
        }
        if let effort = effort { perceivedEffort = effort }
        if let notes = notes { exerciseNotes = notes }
        
        // Calculate derived metrics
        averagePace = calculatePace()
        averageSpeed = calculateSpeed()
        caloriesBurned = estimateCalories()
        
        isCompleted = true
        completedAt = Date()
        
        // Check if this is a personal record
        checkForPersonalRecord()
    }
    
    func checkForPersonalRecord() {
        guard let exercise = exercise, isCompleted else { return }
        
        // Get all previous completed results for this exercise
        let previousResults = (exercise.results ?? []).filter { result in
            result.id != self.id && result.isCompleted
        }
        
        // Check if this is a personal record
        var isPR = false
        var recordType: String?
        
        if let currentTime = completionTime, let _ = targetDistance {
            // Distance-based exercise - check for fastest time
            let previousTimes = previousResults.compactMap { $0.completionTime }
            if previousTimes.isEmpty || currentTime < previousTimes.min()! {
                isPR = true
                recordType = "fastest_time"
            }
        } else if let currentDistance = distanceCovered, let _ = targetTime {
            // Time-based exercise - check for longest distance
            let previousDistances = previousResults.compactMap { $0.distanceCovered }
            if previousDistances.isEmpty || currentDistance > previousDistances.max()! {
                isPR = true
                recordType = "longest_distance"
            }
        } else if let currentPace = calculatePace() {
            // Check for best pace regardless of workout type
            let previousPaces = previousResults.compactMap { $0.calculatePace() }
            if previousPaces.isEmpty || currentPace < previousPaces.min()! {
                isPR = true
                recordType = "best_pace"
            }
        }
        
        isPersonalRecord = isPR
        prType = recordType
        
        // Mark previous PRs of the same type as no longer current
        if isPR {
            for result in previousResults {
                if result.prType == recordType {
                    result.isPersonalRecord = false
                }
            }
        }
    }
    
    func addSplitTime(_ splitTime: Int) {
        if splitTimes == nil {
            splitTimes = []
        }
        splitTimes?.append(splitTime)
    }
    
    func setEnvironmentalData(temperature: Double? = nil, humidity: Int? = nil, wind: String? = nil) {
        self.temperature = temperature
        self.humidity = humidity
        self.windConditions = wind
    }
    
    func setEquipmentData(equipment: String? = nil, resistance: Int? = nil, incline: Double? = nil) {
        self.equipmentUsed = equipment
        self.resistance = resistance
        self.incline = incline
    }
    
    func addGPSData(_ data: Data, elevation: Double? = nil, routeID: String? = nil) {
        self.gpsData = data
        self.elevationGain = elevation
        self.routeID = routeID
    }
    
    func getComparisonWithPrevious() -> ResultComparison? {
        guard let exercise = exercise else { return nil }
        
        let previousResults = (exercise.results ?? [])
            .filter { $0.id != self.id && $0.isCompleted }
            .sorted { $0.completedAt > $1.completedAt }
        
        guard let lastResult = previousResults.first else { return nil }
        
        return ResultComparison(current: self, previous: lastResult)
    }
}

// MARK: - Result Comparison
struct ResultComparison {
    let current: CardioResult
    let previous: CardioResult
    
    var timeImprovement: Int? {
        guard let currentTime = current.completionTime,
              let previousTime = previous.completionTime else { return nil }
        return previousTime - currentTime // Positive means improvement
    }
    
    var distanceImprovement: Double? {
        guard let currentDistance = current.distanceCovered,
              let previousDistance = previous.distanceCovered else { return nil }
        return currentDistance - previousDistance // Positive means improvement
    }
    
    var paceImprovement: Double? {
        guard let currentPace = current.calculatePace(),
              let previousPace = previous.calculatePace() else { return nil }
        return previousPace - currentPace // Positive means improvement (faster pace)
    }
    
    @MainActor
    var improvementSummary: String {
        var improvements: [String] = []
        
        if let timeImpr = timeImprovement, timeImpr > 0 {
            improvements.append("⏱️ \(timeImpr)s faster")
        } else if let timeImpr = timeImprovement, timeImpr < 0 {
            improvements.append("⏱️ \(abs(timeImpr))s slower")
        }
        
        if let distImpr = distanceImprovement, distImpr > 0 {
            improvements.append("🚀 +\(String(format: "%.0f", distImpr))m further")
        } else if let distImpr = distanceImprovement, distImpr < 0 {
            improvements.append("🚀 \(String(format: "%.0f", abs(distImpr)))m shorter")
        }
        
        if let paceImpr = paceImprovement, paceImpr > 0 {
            let paceMinPerKm = Double(paceImpr) / 60.0
            let paceUnit = UnitsFormatter.formatPaceUnit(system: UnitSettings.shared.unitSystem)
            let paceFormatted = UnitsFormatter.formatDetailedPace(minPerKm: paceMinPerKm, system: UnitSettings.shared.unitSystem)
            improvements.append("⚡ \(paceFormatted) \(paceUnit) faster")
        }
        
        if improvements.isEmpty {
            return "Similar performance to last time"
        }
        
        return improvements.joined(separator: ", ")
    }
}