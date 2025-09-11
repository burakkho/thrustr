import SwiftData
import Foundation

@Model
final class FoodAlias {
    var id: UUID = UUID()
    var term: String = ""
    var language: String = "en" // e.g., "tr", "en"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Relationship
    @Relationship var food: Food?

    init(term: String, language: String, food: Food? = nil) {
        self.id = UUID()
        self.term = term
        self.language = language
        self.createdAt = Date()
        self.updatedAt = Date()
        self.food = food
    }
}


