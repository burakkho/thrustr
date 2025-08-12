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
        case .meat: return "Et & Tavuk"
        case .dairy: return "Süt Ürünleri"
        case .grains: return "Tahıllar"
        case .vegetables: return "Sebzeler"
        case .fruits: return "Meyveler"
        case .nuts: return "Kuruyemişler"
        case .beverages: return "İçecekler"
        case .snacks: return "Atıştırmalıklar"
        case .turkish: return "Türk Yemekleri"
        case .fastfood: return "Fast Food"
        case .supplements: return "Takviyeler"
        case .condiments: return "Soslar & Baharatlar"
        case .bakery: return "Fırın Ürünleri"
        case .seafood: return "Deniz Ürünleri"
        case .desserts: return "Tatlılar"
        case .other: return "Diğer"
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
