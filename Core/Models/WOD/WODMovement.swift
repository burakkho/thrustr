import Foundation
import SwiftData

@Model
final class WODMovement {
    var id: UUID
    var name: String
    var rxWeightMale: String? // "43kg" or "95lb"
    var rxWeightFemale: String? // "30kg" or "65lb"
    var scaledWeightMale: String? // "30kg" or "65lb"
    var scaledWeightFemale: String? // "20kg" or "45lb"
    var reps: Int? // Reps per round (if not using repScheme)
    var orderIndex: Int
    var notes: String?
    
    // User's selection for this workout
    var userWeight: Double? // Always stored in kg
    var isRX: Bool
    
    // Relationship
    var wod: WOD?
    
    init(
        name: String,
        rxWeightMale: String? = nil,
        rxWeightFemale: String? = nil,
        reps: Int? = nil,
        orderIndex: Int = 0,
        scaledWeightMale: String? = nil,
        scaledWeightFemale: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.rxWeightMale = rxWeightMale
        self.rxWeightFemale = rxWeightFemale
        self.scaledWeightMale = scaledWeightMale
        self.scaledWeightFemale = scaledWeightFemale
        self.reps = reps
        self.orderIndex = orderIndex
        self.notes = notes
        self.userWeight = nil
        self.isRX = false
    }
}

// MARK: - Computed Properties
extension WODMovement {
    // Get appropriate RX weight based on user gender
    func rxWeight(for gender: String?) -> String? {
        guard let gender = gender else { return rxWeightMale }
        return gender.lowercased() == "female" ? rxWeightFemale : rxWeightMale
    }
    
    // Get appropriate scaled weight based on user gender
    func scaledWeight(for gender: String?) -> String? {
        guard let gender = gender else { return scaledWeightMale }
        return gender.lowercased() == "female" ? scaledWeightFemale : scaledWeightMale
    }
    
    // Format movement display with reps
    var displayText: String {
        var text = name
        if let reps = reps, reps > 0 {
            text = "\(reps) \(name)"
        }
        return text
    }
    
    // Format with weight selection
    var fullDisplayText: String {
        var text = displayText
        
        if let userWeight = userWeight {
            let weightText = "\(Int(userWeight))kg"
            text += " @ \(weightText)"
            if isRX {
                text += " (RX)"
            }
        }
        
        return text
    }
}