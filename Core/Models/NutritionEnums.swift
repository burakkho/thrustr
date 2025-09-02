import Foundation

enum FoodCategory: String, CaseIterable {
    // Temel kategoriler
    case meat = "meat"
    case dairy = "dairy"
    case grains = "grains"
    case vegetables = "vegetables"
    case fruits = "fruits"
    case nuts = "nuts"
    case beverages = "beverages"
    case snacks = "snacks"
    
    // Özel kategoriler
    case turkish = "turkish"
    case fastfood = "fastfood"
    case supplements = "supplements"
    case condiments = "condiments"
    case bakery = "bakery"
    case seafood = "seafood"
    case desserts = "desserts"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .meat: return NutritionKeys.Categories.meat.localized
        case .dairy: return NutritionKeys.Categories.dairy.localized
        case .grains: return NutritionKeys.Categories.grains.localized
        case .vegetables: return NutritionKeys.Categories.vegetables.localized
        case .fruits: return NutritionKeys.Categories.fruits.localized
        case .nuts: return NutritionKeys.Categories.nuts.localized
        case .beverages: return NutritionKeys.Categories.beverages.localized
        case .snacks: return NutritionKeys.Categories.snacks.localized
        case .turkish: return "Türk Yemekleri" // Keep Turkish-specific
        case .fastfood: return "Fast Food" // Keep universal
        case .supplements: return "Takviyeler" // Keep Turkish-specific
        case .condiments: return "Soslar & Baharatlar" // Keep Turkish-specific
        case .bakery: return "Fırın Ürünleri" // Keep Turkish-specific
        case .seafood: return "Deniz Ürünleri" // Keep Turkish-specific
        case .desserts: return "Tatlılar" // Keep Turkish-specific
        case .other: return NutritionKeys.Categories.other.localized
        }
    }
    
    var icon: String {
        switch self {
        case .meat: return "🥩"
        case .dairy: return "🥛"
        case .grains: return "🌾"
        case .vegetables: return "🥦"
        case .fruits: return "🍎"
        case .nuts: return "🥜"
        case .beverages: return "🥤"
        case .snacks: return "🍿"
        case .turkish: return "🇹🇷"
        case .fastfood: return "🍔"
        case .supplements: return "💊"
        case .condiments: return "🧂"
        case .bakery: return "🍞"
        case .seafood: return "🐟"
        case .desserts: return "🍰"
        case .other: return "🍽️"
        }
    }
}

// Food data source tracking for migration to OpenFoodFacts
enum FoodSource: String, CaseIterable {
    case manual = "manual"
    case openFoodFacts = "openFoodFacts"
    case csv = "csv"
}
