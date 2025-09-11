import Foundation
import SwiftData

// MARK: - Equipment Item Model
@Model
final class EquipmentItem {
    var id: UUID = UUID()
    var name: String = ""
    var orderIndex: Int = 0
    
    // Relationships
    var cardioWorkout: CardioWorkout?
    
    init(name: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
    }
}

// MARK: - Equipment Types
enum EquipmentType: String, CaseIterable {
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
        case .outdoor: return "leaf.fill"
        case .treadmill: return "figure.run"
        case .rowErg: return "figure.rowing"
        case .bikeErg: return "figure.cycling"
        case .skiErg: return "figure.skiing.downhill"
        }
    }
}