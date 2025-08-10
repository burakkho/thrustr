import SwiftUI

extension FoodCategory {
    // icon VAR BUNU SİL, systemIcon kalsın
    
    // MARK: - Color (SADECE BU KALSIN)
    var color: Color {
        switch self {
        case .meat: return .red
        case .dairy: return .blue
        case .grains: return .brown
        case .vegetables: return .green
        case .fruits: return .orange
        case .nuts: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .beverages: return .cyan
        case .snacks: return .purple
        case .turkish: return Color(red: 0.8, green: 0.1, blue: 0.1)
        case .fastfood: return .pink
        case .supplements: return .indigo
        case .condiments: return .yellow
        case .bakery: return Color(red: 0.9, green: 0.6, blue: 0.3)
        case .seafood: return .teal
        case .desserts: return Color(red: 1.0, green: 0.4, blue: 0.6)
        case .other: return .gray
        }
    }
}
