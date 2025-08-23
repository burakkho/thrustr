import Foundation
import SwiftData

// MARK: - Cardio Routine Model
@Model
final class CardioRoutine {
    var id: String
    var name: String
    var nameEN: String
    var nameTR: String
    var nameES: String?
    var nameDE: String?
    var routineDescription: String
    var descriptionTR: String?
    var exercise: String // "Running", "Rowing", "Cycling", etc.
    var distance: Int? // in meters (optional)
    var duration: Int? // in seconds (optional)  
    var estimatedTime: Int? // estimated completion time in seconds
    var category: String // "endurance", "speed", "hiit", "recovery"
    var difficulty: String // "beginner", "intermediate", "advanced"
    var icon: String // SF Symbol name
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // User relationship
    var creator: User?
    
    init(
        id: String,
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        nameES: String? = nil,
        nameDE: String? = nil,
        description: String = "",
        descriptionTR: String? = nil,
        exercise: String,
        distance: Int? = nil,
        duration: Int? = nil,
        estimatedTime: Int? = nil,
        category: String = "endurance",
        difficulty: String = "beginner",
        icon: String = "heart.fill",
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameEN = nameEN ?? name
        self.nameTR = nameTR ?? name
        self.nameES = nameES
        self.nameDE = nameDE
        self.routineDescription = description
        self.descriptionTR = descriptionTR
        self.exercise = exercise
        self.distance = distance
        self.duration = duration
        self.estimatedTime = estimatedTime
        self.category = category
        self.difficulty = difficulty
        self.icon = icon
        self.isCustom = isCustom
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Computed Properties
extension CardioRoutine {
    var localizedName: String {
        // For now use English as default to avoid MainActor issues
        // TODO: Implement proper localization without MainActor
        return nameEN.isEmpty ? name : nameEN
    }
    
    var localizedDescription: String {
        // For now use English as default to avoid MainActor issues
        // TODO: Implement proper localization without MainActor
        return routineDescription
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "" }
        
        if distance >= 1000 {
            let km = Double(distance) / 1000.0
            if km == floor(km) {
                return "\(Int(km))K"
            } else {
                return String(format: "%.1fK", km)
            }
        } else {
            return "\(distance)m"
        }
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        
        let minutes = duration / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedEstimatedTime: String {
        guard let estimatedTime = estimatedTime else { return "" }
        
        let minutes = estimatedTime / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    var primaryTarget: String {
        if distance != nil {
            return formattedDistance
        } else if duration != nil {
            return formattedDuration
        } else {
            return exercise
        }
    }
    
    var difficultyColor: String {
        switch difficulty.lowercased() {
        case "beginner":
            return "green"
        case "intermediate":
            return "orange"
        case "advanced":
            return "red"
        default:
            return "blue"
        }
    }
    
    var categoryColor: String {
        switch category.lowercased() {
        case "endurance":
            return "blue"
        case "speed":
            return "red"
        case "hiit":
            return "orange"
        case "recovery":
            return "green"
        default:
            return "gray"
        }
    }
}

// MARK: - Methods
extension CardioRoutine {
    func duplicate() -> CardioRoutine {
        return CardioRoutine(
            id: "\(id)_copy",
            name: "\(name) (Copy)",
            nameEN: "\(nameEN) (Copy)",
            nameTR: "\(nameTR) (Kopya)",
            nameES: nameES != nil ? "\(nameES!) (Copia)" : nil,
            nameDE: nameDE != nil ? "\(nameDE!) (Kopie)" : nil,
            description: routineDescription,
            descriptionTR: descriptionTR,
            exercise: exercise,
            distance: distance,
            duration: duration,
            estimatedTime: estimatedTime,
            category: category,
            difficulty: difficulty,
            icon: icon,
            isCustom: true
        )
    }
    
    func createSession(for user: User) -> CardioSession {
        let session = CardioSession(
            workout: nil,
            user: user,
            wasFromTemplate: false
        )
        
        if let distance = distance {
            session.totalDistance = Double(distance)
        }
        
        if let duration = duration {
            session.totalDuration = duration
        }
        
        return session
    }
}

// MARK: - Static Factory Methods
extension CardioRoutine {
    static func fromJSON(_ json: [String: Any]) -> CardioRoutine? {
        guard 
            let id = json["id"] as? String,
            let name = json["name"] as? String,
            let exercise = json["exercise"] as? String
        else { return nil }
        
        return CardioRoutine(
            id: id,
            name: name,
            nameEN: json["nameEN"] as? String ?? name,
            nameTR: json["nameTR"] as? String ?? name,
            nameES: json["nameES"] as? String,
            nameDE: json["nameDE"] as? String,
            description: json["description"] as? String ?? "",
            descriptionTR: json["descriptionTR"] as? String,
            exercise: exercise,
            distance: json["distance"] as? Int,
            duration: json["duration"] as? Int,
            estimatedTime: json["estimatedTime"] as? Int,
            category: json["category"] as? String ?? "endurance",
            difficulty: json["difficulty"] as? String ?? "beginner",
            icon: json["icon"] as? String ?? "heart.fill",
            isCustom: false
        )
    }
}

// MARK: - JSON Loading Service
class CardioRoutineService {
    static let shared = CardioRoutineService()
    private init() {}
    
    func loadBuiltInRoutines() -> [CardioRoutine] {
        guard let url = Bundle.main.url(forResource: "cardio_routines", withExtension: "json") else {
            print("Could not find cardio_routines.json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let routinesArray = json?["routines"] as? [[String: Any]] ?? []
            
            return routinesArray.compactMap { CardioRoutine.fromJSON($0) }
        } catch {
            print("Error loading cardio routines: \(error)")
            return []
        }
    }
}