import SwiftData
import Foundation

@Model
final class Food {
    var id: UUID
    var nameEN: String
    var nameTR: String
    var brand: String?
    // Tracking source & barcode for OFF/manual/csv (defaults ensure migration safety)
    var sourceRaw: String = FoodSource.manual.rawValue
    var barcode: String? = nil
    // Remote image and metadata
    var imageUrlString: String? = nil
    var lastModified: Date? = nil
    var qualityScore: Int = 0
    
    // Besin değerleri (100g başına)
    var calories: Double    // kalori
    var protein: Double     // protein (g)
    var carbs: Double      // karbonhidrat (g)
    var fat: Double        // yağ (g)
    
    var category: String   // kategori
    var isActive: Bool     // aktif mi
    var isVerified: Bool   // Official vs user-added
    
    // Usage tracking
    var usageCount: Int = 0    // Kullanım sayısı
    var lastUsed: Date?        // Son kullanım tarihi
    var isFavorite: Bool = false  // Favori mi
    
    var createdAt: Date
    var updatedAt: Date
    
    init(nameEN: String, nameTR: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: FoodCategory = .other) {
        self.id = UUID()
        self.nameEN = nameEN
        self.nameTR = nameTR
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.category = category.rawValue
        self.isActive = true
        self.isVerified = true
        self.usageCount = 0
        self.lastUsed = nil
        self.isFavorite = false
        // Defaults are provided at declaration for safe migration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Computed Properties
extension Food {
    var source: FoodSource {
        get { FoodSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
    var imageURL: URL? {
        guard let imageUrlString, let url = URL(string: imageUrlString) else { return nil }
        return url
    }
    var categoryEnum: FoodCategory {
        FoodCategory(rawValue: category) ?? .other
    }
    
    var displayName: String {
        return nameTR.isEmpty ? nameEN : nameTR
    }
    
    var isRecentlyUsed: Bool {
        guard let lastUsed = lastUsed else { return false }
        return Date().timeIntervalSince(lastUsed) < 604800 // 1 hafta
    }
    
    var isPopular: Bool {
        return usageCount >= 3 // 3+ kullanım popüler sayılır
    }
    
    // Belirli gram için besin değerlerini hesapla
    func calculateNutrition(for grams: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let multiplier = grams / 100.0
        return (
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbs: carbs * multiplier,
            fat: fat * multiplier
        )
    }
}

// MARK: - Usage Tracking
extension Food {
    func recordUsage() {
        usageCount += 1
        lastUsed = Date()
        updatedAt = Date()
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
}
