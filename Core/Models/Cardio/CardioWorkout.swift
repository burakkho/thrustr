import Foundation
import SwiftData

// MARK: - Cardio Workout Model (Templates)
@Model
final class CardioWorkout {
    var id: UUID = UUID()
    var name: String = ""
    var nameEN: String = ""
    var nameTR: String = ""
    var nameES: String = ""
    var nameDE: String = ""
    
    // Workout Configuration
    var type: String = "distance" // "distance", "time", "circuit"
    var category: String = "custom" // "benchmark", "custom"
    var workoutDescription: String = ""
    var descriptionTR: String = ""
    var descriptionES: String = ""
    var descriptionDE: String = ""
    
    // Target Parameters (optional suggestions)
    var targetDistance: Int? // in meters
    var targetTime: Int? // in seconds
    var estimatedCalories: Int? = nil
    var difficulty: String = "intermediate" // "beginner", "intermediate", "advanced"
    
    // Template Properties
    var isTemplate: Bool = true
    var isCustom: Bool = false
    var isFavorite: Bool = false
    var shareCode: String? = nil
    
    // Equipment Requirements
    var equipmentItems: [EquipmentItem]?
    
    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \CardioExercise.workout) var exercises: [CardioExercise]?
    @Relationship(deleteRule: .cascade, inverse: \CardioSession.originalWorkout) var sessions: [CardioSession]?
    
    init(
        name: String,
        nameEN: String = "",
        nameTR: String = "",
        nameES: String = "",
        nameDE: String = "",
        type: String = "distance",
        category: String = "custom",
        description: String = "",
        descriptionTR: String = "",
        descriptionES: String = "",
        descriptionDE: String = "",
        targetDistance: Int? = nil,
        targetTime: Int? = nil,
        estimatedCalories: Int? = nil,
        difficulty: String = "intermediate",
        equipment: [String] = ["outdoor"],
        isTemplate: Bool = true,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN.isEmpty ? name : nameEN
        self.nameTR = nameTR.isEmpty ? name : nameTR
        self.nameES = nameES.isEmpty ? name : nameES
        self.nameDE = nameDE.isEmpty ? name : nameDE
        
        self.type = type
        self.category = category
        self.workoutDescription = description
        self.descriptionTR = descriptionTR
        self.descriptionES = descriptionES
        self.descriptionDE = descriptionDE
        
        self.targetDistance = targetDistance
        self.targetTime = targetTime
        self.estimatedCalories = estimatedCalories
        self.difficulty = difficulty
        
        self.isTemplate = isTemplate
        self.isCustom = isCustom
        self.isFavorite = false
        self.shareCode = nil
        
        // Initialize equipment items from string array
        self.equipmentItems = equipment.enumerated().map { index, equipmentName in
            EquipmentItem(name: equipmentName, orderIndex: index)
        }
        
        self.createdAt = Date()
        self.updatedAt = Date()
        
        self.exercises = []
        self.sessions = []
    }
}

// MARK: - Computed Properties
extension CardioWorkout {
    var localizedName: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "tr": return nameTR.isEmpty ? nameEN : nameTR
        case "es": return nameES.isEmpty ? nameEN : nameES
        case "de": return nameDE.isEmpty ? nameEN : nameDE
        default: return nameEN.isEmpty ? name : nameEN
        }
    }
    
    var localizedDescription: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "tr": return descriptionTR.isEmpty ? workoutDescription : descriptionTR
        case "es": return descriptionES.isEmpty ? workoutDescription : descriptionES
        case "de": return descriptionDE.isEmpty ? workoutDescription : descriptionDE
        default: return workoutDescription
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
    
    // Backward compatibility - converts equipmentItems to [String]
    var equipment: [String] {
        get {
            return equipmentItems?.sorted(by: { $0.orderIndex < $1.orderIndex }).map { $0.name } ?? []
        }
        set {
            // Remove existing equipment items
            equipmentItems?.removeAll()
            // Create new equipment items from string array
            self.equipmentItems = newValue.enumerated().map { index, equipmentName in
                EquipmentItem(name: equipmentName, orderIndex: index)
            }
        }
    }
    
    var displayEquipment: String {
        let equipmentNames = equipment.map { equipmentKey in
            switch equipmentKey {
            case "outdoor": return "Outdoor"
            case "treadmill": return "Treadmill"
            case "row_erg": return "Row Erg"
            case "bike_erg": return "Bike Erg"
            case "ski_erg": return "Ski Erg"
            default: return equipmentKey.capitalized
            }
        }
        return equipmentNames.joined(separator: ", ")
    }
    
    // Get personal record for this workout
    var personalRecord: CardioResult? {
        guard let sessions = sessions else { return nil }
        let completedSessions = sessions.filter { $0.isCompleted }
        let allResults = completedSessions.flatMap { $0.results ?? [] }
        
        switch type {
        case "distance":
            // For distance workouts, fastest time is best
            let validResults = allResults.filter { $0.completionTime != nil && $0.completionTime! > 0 }
            return validResults.min { result1, result2 in
                (result1.completionTime ?? Int.max) < (result2.completionTime ?? Int.max)
            }
        case "time":
            // For time-based workouts, longest distance is best
            let validResults = allResults.filter { $0.distanceCovered != nil && $0.distanceCovered! > 0 }
            return validResults.max { result1, result2 in
                (result1.distanceCovered ?? 0) < (result2.distanceCovered ?? 0)
            }
        default:
            return allResults.first
        }
    }
    
    var lastPerformed: Date? {
        sessions?.filter { $0.isCompleted }.map { $0.completedAt ?? $0.startDate }.max()
    }
    
    var totalSessions: Int {
        sessions?.filter { $0.isCompleted }.count ?? 0
    }
    
    var averagePerformance: Double? {
        guard let sessions = sessions else { return nil }
        let completedResults = sessions.filter { $0.isCompleted }.flatMap { $0.results ?? [] }
        guard !completedResults.isEmpty else { return nil }
        
        switch type {
        case "distance":
            let times = completedResults.compactMap { $0.completionTime }
            guard !times.isEmpty else { return nil }
            return Double(times.reduce(0, +)) / Double(times.count)
        case "time":
            let distances = completedResults.compactMap { $0.distanceCovered }
            guard !distances.isEmpty else { return nil }
            return distances.reduce(0, +) / Double(distances.count)
        default:
            return nil
        }
    }
}

// MARK: - Methods
extension CardioWorkout {
    func addExercise(_ exercise: CardioExercise) {
        if exercises == nil {
            exercises = []
        }
        exercise.orderIndex = exercises?.count ?? 0
        exercises?.append(exercise)
        exercise.workout = self
        updatedAt = Date()
    }
    
    func removeExercise(_ exercise: CardioExercise) {
        exercises?.removeAll { $0.id == exercise.id }
        // Reorder remaining exercises
        if let exercises = exercises {
            for (index, ex) in exercises.enumerated() {
                ex.orderIndex = index
            }
        }
        updatedAt = Date()
    }
    
    func startSession(for user: User) -> CardioSession {
        let session = CardioSession(workout: self, user: user)
        if sessions == nil {
            sessions = []
        }
        sessions?.append(session)
        return session
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
    
    func addEquipment(_ equipmentName: String) {
        if equipmentItems == nil {
            equipmentItems = []
        }
        let newItem = EquipmentItem(name: equipmentName, orderIndex: equipmentItems?.count ?? 0)
        equipmentItems?.append(newItem)
        updatedAt = Date()
    }
    
    func removeEquipment(_ equipmentName: String) {
        equipmentItems?.removeAll { $0.name == equipmentName }
        // Reorder remaining equipment items
        if let equipmentItems = equipmentItems {
            for (index, item) in equipmentItems.enumerated() {
                item.orderIndex = index
            }
        }
        updatedAt = Date()
    }
    
    func duplicate() -> CardioWorkout {
        let newWorkout = CardioWorkout(
            name: name + " (Copy)",
            nameEN: nameEN + " (Copy)",
            nameTR: nameTR + " (Kopya)",
            nameES: nameES + " (Copia)",
            nameDE: nameDE + " (Kopie)",
            type: type,
            category: "custom",
            description: workoutDescription,
            descriptionTR: descriptionTR,
            descriptionES: descriptionES,
            descriptionDE: descriptionDE,
            targetDistance: targetDistance,
            targetTime: targetTime,
            estimatedCalories: estimatedCalories,
            difficulty: difficulty,
            equipment: equipment,
            isTemplate: true,
            isCustom: true
        )
        
        // Duplicate exercises
        if let exercises = exercises {
            for exercise in exercises {
                let newExercise = exercise.duplicate()
                newWorkout.addExercise(newExercise)
            }
        }
        
        return newWorkout
    }
}

// MARK: - Cardio Types
enum CardioType: String, CaseIterable {
    case exercise = "exercise"
    
    var displayName: String {
        switch self {
        case .exercise: return "Exercise"
        }
    }
    
    var icon: String {
        switch self {
        case .exercise: return "heart.fill"
        }
    }
}

enum CardioDifficulty: String, CaseIterable {
    case any = "any"
    
    var displayName: String {
        switch self {
        case .any: return "Any Level"
        }
    }
    
    var color: String {
        switch self {
        case .any: return "blue"
        }
    }
}