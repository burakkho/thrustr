import Foundation

// MARK: - Gender Enum
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    
    var displayName: String {
        switch self {
        case .male: return "gender.male".localized
        case .female: return "gender.female".localized
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
}
