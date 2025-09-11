import SwiftData
import Foundation

@Model
final class CrossFitMovement {
    var nameEN: String = ""
    var nameTR: String = ""
    var category: String = "" // Gymnastics, Olympic, Metabolic, Powerlifting, etc.
    var equipment: String = ""
    var rxWeightMale: String? // e.g., "43kg", "20kg", "BW"
    var rxWeightFemale: String? // e.g., "30kg", "15kg", "BW"
    var supportsWeight: Bool = false
    var supportsReps: Bool = false
    var supportsTime: Bool = false
    var supportsDistance: Bool = false
    var wodSuitability: Int = 10 // 1-10 scale for WOD appropriateness
    var instructions: String?
    var scalingNotes: String? // How to scale for different skill levels
    
    // Computed properties
    var displayName: String {
        // Use Turkish if available, fallback to English
        return nameTR.isEmpty ? nameEN : nameTR
    }
    
    var categoryEnum: CrossFitCategory {
        CrossFitCategory(rawValue: category) ?? .other
    }
    
    var equipmentEnum: CFEquipment {
        CFEquipment(rawValue: equipment) ?? .none
    }
    
    init(
        nameEN: String,
        nameTR: String = "",
        category: String,
        equipment: String,
        rxWeightMale: String? = nil,
        rxWeightFemale: String? = nil,
        supportsWeight: Bool = false,
        supportsReps: Bool = false,
        supportsTime: Bool = false,
        supportsDistance: Bool = false,
        wodSuitability: Int = 10,
        instructions: String? = nil,
        scalingNotes: String? = nil
    ) {
        self.nameEN = nameEN
        self.nameTR = nameTR
        self.category = category
        self.equipment = equipment
        self.rxWeightMale = rxWeightMale
        self.rxWeightFemale = rxWeightFemale
        self.supportsWeight = supportsWeight
        self.supportsReps = supportsReps
        self.supportsTime = supportsTime
        self.supportsDistance = supportsDistance
        self.wodSuitability = wodSuitability
        self.instructions = instructions
        self.scalingNotes = scalingNotes
    }
}

// MARK: - CrossFit Categories
enum CrossFitCategory: String, CaseIterable {
    case gymnastics = "Gymnastics"
    case olympic = "Olympic"
    case powerlifting = "Powerlifting"
    case metabolic = "Metabolic"
    case cardio = "Cardio"
    case functional = "Functional"
    case bodyweight = "Bodyweight"
    case plyometric = "Plyometric"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .gymnastics: return "figure.gymnastics"
        case .olympic: return "trophy.fill"
        case .powerlifting: return "dumbbell.fill"
        case .metabolic: return "flame.fill"
        case .cardio: return "heart.fill"
        case .functional: return "figure.strengthtraining.functional"
        case .bodyweight: return "figure.arms.open"
        case .plyometric: return "figure.jump"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .gymnastics: return "blue"
        case .olympic: return "yellow"
        case .powerlifting: return "red"
        case .metabolic: return "orange"
        case .cardio: return "pink"
        case .functional: return "green"
        case .bodyweight: return "purple"
        case .plyometric: return "indigo"
        case .other: return "gray"
        }
    }
}

// MARK: - CrossFit Equipment
enum CFEquipment: String, CaseIterable {
    case none = "None"
    case barbell = "Barbell"
    case dumbbell = "Dumbbell" 
    case dumbbells = "Dumbbells"
    case kettlebell = "Kettlebell"
    case pullUpBar = "Pull-up Bar"
    case rings = "Rings"
    case medicineBall = "Medicine Ball"
    case box = "Box"
    case jumpRope = "Jump Rope"
    case wall = "Wall"
    case rope = "Rope"
    case rower = "Concept2 Rower"
    case assaultBike = "Assault Bike"
    case sled = "Sled"
    case ghdMachine = "GHD Machine"
    case abMat = "AbMat"
    
    var icon: String {
        switch self {
        case .none: return "figure.walk"
        case .barbell: return "dumbbell.fill"
        case .dumbbell, .dumbbells: return "dumbbell"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .pullUpBar: return "rectangle.and.hand.point.up.left"
        case .rings: return "circle.dashed"
        case .medicineBall: return "basketball.fill"
        case .box: return "cube.box.fill"
        case .jumpRope: return "figure.jumprope"
        case .wall: return "square.grid.3x3"
        case .rope: return "cable.connector"
        case .rower: return "figure.rower"
        case .assaultBike: return "bicycle"
        case .sled: return "triangle.fill"
        case .ghdMachine: return "rectangle.on.rectangle"
        case .abMat: return "rectangle.fill"
        }
    }
}

// MARK: - Extensions
extension CrossFitMovement {
    // Get RX weight for specific gender
    func rxWeight(for gender: String?) -> String? {
        guard let gender = gender?.lowercased() else { return rxWeightMale }
        return gender == "female" ? rxWeightFemale : rxWeightMale
    }
    
    // Check if movement is suitable for WODs
    var isWODSuitable: Bool {
        return wodSuitability >= 7
    }
    
    // Get scaling suggestions
    var scalingSuggestions: [String] {
        var suggestions: [String] = []
        
        if let notes = scalingNotes, !notes.isEmpty {
            suggestions.append(notes)
        }
        
        // Add default scaling based on category
        switch categoryEnum {
        case .gymnastics:
            suggestions.append("Use assistance bands or reduce reps")
        case .olympic:
            suggestions.append("Reduce weight or use PVC pipe for form")
        case .powerlifting:
            suggestions.append("Scale weight to maintain proper form")
        case .metabolic, .cardio:
            suggestions.append("Reduce duration or intensity")
        default:
            break
        }
        
        return suggestions
    }
}

// MARK: - Static Data Helpers
extension CrossFitMovement {
    nonisolated(unsafe) static let sampleMovements: [CrossFitMovement] = [
        CrossFitMovement(
            nameEN: "Pull-ups",
            nameTR: "Barfiks",
            category: "Gymnastics",
            equipment: "Pull-up Bar",
            supportsReps: true,
            wodSuitability: 10,
            scalingNotes: "Assistance bands, jumping pull-ups, or ring rows"
        ),
        CrossFitMovement(
            nameEN: "Thrusters",
            nameTR: "Thruster",
            category: "Olympic",
            equipment: "Barbell",
            rxWeightMale: "43kg",
            rxWeightFemale: "30kg",
            supportsWeight: true,
            supportsReps: true,
            wodSuitability: 10,
            scalingNotes: "Use lighter weight or dumbbells"
        ),
        CrossFitMovement(
            nameEN: "Burpees",
            nameTR: "Burpee",
            category: "Bodyweight",
            equipment: "None",
            supportsReps: true,
            wodSuitability: 10,
            scalingNotes: "Step back/up instead of jumping, no push-up"
        )
    ]
}