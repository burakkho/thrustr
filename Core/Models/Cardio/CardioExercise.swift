import Foundation
import SwiftData

// MARK: - Cardio Exercise Model (Template Components)
@Model
final class CardioExercise {
    var id: UUID = UUID()
    var name: String = ""
    var exerciseType: String = "run" // "run", "bike", "row", "ski", "custom"
    var orderIndex: Int = 0
    
    // Exercise Parameters (suggestions for template)
    var targetDistance: Int? // in meters
    var targetTime: Int? // in seconds
    var targetPace: Double? // seconds per km
    var restTime: Int? // seconds between exercises in circuits
    
    // Equipment and Environment
    var equipment: String = "outdoor" // "outdoor", "treadmill", "row_erg", "bike_erg", "ski_erg"
    var environment: String? = nil // "outdoor", "indoor"
    
    // Instructions and Notes
    var instructions: String?
    var notes: String?
    
    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    var workout: CardioWorkout?
    var results: [CardioResult]?
    
    init(
        name: String,
        exerciseType: String = "run",
        orderIndex: Int = 0,
        targetDistance: Int? = nil,
        targetTime: Int? = nil,
        targetPace: Double? = nil,
        restTime: Int? = nil,
        equipment: String = "outdoor",
        environment: String? = nil,
        instructions: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.exerciseType = exerciseType
        self.orderIndex = orderIndex
        
        self.targetDistance = targetDistance
        self.targetTime = targetTime
        self.targetPace = targetPace
        self.restTime = restTime
        
        self.equipment = equipment
        self.environment = environment
        
        self.instructions = instructions
        self.notes = notes
        
        self.createdAt = Date()
        self.updatedAt = Date()
        
        self.results = []
    }
}

// MARK: - Computed Properties
extension CardioExercise {
    var exerciseIcon: String {
        switch exerciseType {
        case "run":
            return "figure.run"
        case "bike":
            return "bicycle"
        case "row":
            return "figure.rower"
        case "ski":
            return "figure.skiing.downhill"
        case "swim":
            return "figure.pool.swim"
        default:
            return "heart.fill"
        }
    }
    
    @MainActor
    var formattedDistance: String? {
        guard let distance = targetDistance else { return nil }
        return UnitsFormatter.formatDistance(meters: Double(distance), system: UnitSettings.shared.unitSystem)
    }
    
    var formattedTargetTime: String? {
        guard let time = targetTime else { return nil }
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
    var formattedPace: String? {
        guard let pace = targetPace else { return nil }
        let paceMinPerKm = Double(pace) / 60.0 // Convert seconds to minutes per km
        return UnitsFormatter.formatPace(minPerKm: paceMinPerKm, system: UnitSettings.shared.unitSystem)
    }
    
    var formattedRestTime: String? {
        guard let rest = restTime, rest > 0 else { return nil }
        if rest >= 60 {
            let minutes = rest / 60
            let seconds = rest % 60
            if seconds == 0 {
                return "\(minutes)min rest"
            } else {
                return "\(minutes):\(String(format: "%02d", seconds)) rest"
            }
        }
        return "\(rest)s rest"
    }
    
    var displayEquipment: String {
        switch equipment {
        case "outdoor": return "Outdoor"
        case "treadmill": return "Treadmill"
        case "row_erg": return "Row Erg"
        case "bike_erg": return "Bike Erg"
        case "ski_erg": return "Ski Erg"
        default: return equipment.capitalized
        }
    }
    
    
    // Get personal record for this specific exercise
    var personalRecord: CardioResult? {
        let completedResults = (results ?? []).filter { $0.isCompleted }
        
        if targetDistance != nil {
            // Distance-based exercise - fastest time is best
            let validTimeResults = completedResults.filter { $0.completionTime != nil && $0.completionTime! > 0 }
            return validTimeResults.min { result1, result2 in
                (result1.completionTime ?? Int.max) < (result2.completionTime ?? Int.max)
            }
        } else if targetTime != nil {
            // Time-based exercise - longest distance is best
            let validDistanceResults = completedResults.filter { $0.distanceCovered != nil && $0.distanceCovered! > 0 }
            return validDistanceResults.max { result1, result2 in
                (result1.distanceCovered ?? 0) < (result2.distanceCovered ?? 0)
            }
        }
        
        return completedResults.first
    }
    
    var averagePace: Double? {
        let completedResults = (results ?? []).filter { $0.isCompleted }
        let validPaces = completedResults.compactMap { result in
            result.calculatePace()
        }
        
        guard !validPaces.isEmpty else { return nil }
        return validPaces.reduce(0, +) / Double(validPaces.count)
    }
    
    var totalAttempts: Int {
        (results ?? []).filter { $0.isCompleted }.count
    }
}

// MARK: - Methods
extension CardioExercise {
    func duplicate() -> CardioExercise {
        return CardioExercise(
            name: name,
            exerciseType: exerciseType,
            orderIndex: orderIndex,
            targetDistance: targetDistance,
            targetTime: targetTime,
            targetPace: targetPace,
            restTime: restTime,
            equipment: equipment,
            environment: environment,
            instructions: instructions,
            notes: notes
        )
    }
    
    func updateTargets(distance: Int? = nil, time: Int? = nil, pace: Double? = nil) {
        if let distance = distance { targetDistance = distance }
        if let time = time { targetTime = time }
        if let pace = pace { targetPace = pace }
        updatedAt = Date()
    }
    
    func calculateSuggestedPace(basedOn lastResults: Int = 5) -> Double? {
        let recentResults = (results ?? [])
            .filter { $0.isCompleted }
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(lastResults)
        
        let validPaces = recentResults.compactMap { $0.calculatePace() }
        guard !validPaces.isEmpty else { return nil }
        
        return validPaces.reduce(0, +) / Double(validPaces.count)
    }
}

// MARK: - Exercise Types
enum CardioExerciseType: String, CaseIterable {
    case run = "run"
    case bike = "bike"
    case row = "row"
    case ski = "ski"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .run: return "Running"
        case .bike: return "Cycling"
        case .row: return "Rowing"
        case .ski: return "Ski Erg"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .run: return "figure.run"
        case .bike: return "bicycle"
        case .row: return "oar.2.crossed"
        case .ski: return "figure.skiing.crosscountry"
        case .custom: return "heart.fill"
        }
    }
    
    var defaultEquipment: [String] {
        switch self {
        case .run: return ["outdoor", "treadmill"]
        case .bike: return ["outdoor", "bike_erg"]
        case .row: return ["row_erg"]
        case .ski: return ["ski_erg"]
        case .custom: return ["outdoor"]
        }
    }
}

enum CardioEquipment: String, CaseIterable {
    case outdoor = "outdoor"
    case treadmill = "treadmill"
    case rowErg = "row_erg"
    case bikeErg = "bike_erg"
    case skiErg = "ski_erg"
    
    var displayName: String {
        switch self {
        case .outdoor: return "Outdoor"
        case .treadmill: return "Treadmill"
        case .rowErg: return "Row Erg"
        case .bikeErg: return "Bike Erg"
        case .skiErg: return "Ski Erg"
        }
    }
    
    var icon: String {
        switch self {
        case .outdoor: return "sun.max"
        case .treadmill: return "figure.run"
        case .rowErg: return "oar.2.crossed"
        case .bikeErg: return "bicycle"
        case .skiErg: return "figure.skiing.crosscountry"
        }
    }
}