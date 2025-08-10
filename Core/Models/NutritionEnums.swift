import SwiftUI
import Foundation

enum FoodCategory: String, CaseIterable, Codable {
    case meat = "meat"
    case dairy = "dairy"
    case vegetables = "vegetables"
    case fruits = "fruits"
    case grains = "grains"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .meat: return "Et & Tavuk"
        case .dairy: return "Süt Ürünleri"
        case .vegetables: return "Sebzeler"
        case .fruits: return "Meyveler"
        case .grains: return "Tahıllar"
        case .other: return "Diğer"
        }
    }
    
    var icon: String {
        switch self {
        case .meat: return "fork.knife"
        case .dairy: return "cup.and.saucer"
        case .vegetables: return "carrot"
        case .fruits: return "apple"
        case .grains: return "leaf"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .meat: return .red
        case .dairy: return .blue
        case .vegetables: return .green
        case .fruits: return .pink
        case .grains: return .orange
        case .other: return .gray
        }
    }
}
