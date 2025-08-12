import SwiftUI

extension FoodCategory {
    // MARK: - SF Symbol for category (standardized iconography)
    var systemIcon: String {
        switch self {
        case .meat: return "fish.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .grains: return "leaf.fill"
        case .vegetables: return "carrot.fill"
        case .fruits: return "apple.logo"
        case .nuts: return "oval.fill"
        case .beverages: return "drop.fill"
        case .snacks: return "popcorn.fill"
        case .turkish: return "fork.knife.circle.fill"
        case .fastfood: return "takeoutbag.and.cup.and.straw.fill"
        case .supplements: return "pills.fill"
        case .condiments: return "frying.pan.fill"
        case .bakery: return "birthday.cake"
        case .seafood: return "fish.fill"
        case .desserts: return "birthday.cake.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    // Backwards-compatible alias for design tokens
    var categoryColor: Color { color }

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
