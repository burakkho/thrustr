import SwiftData
import Foundation

@MainActor
class DataSeeder {
    
    // MARK: - Main Seed Function
    static func seedDatabaseIfNeeded(modelContext: ModelContext) {
        // Check if already seeded
        let descriptor = FetchDescriptor<Exercise>()
        let exerciseCount = try? modelContext.fetchCount(descriptor)
        
        // If we have exercises, assume database is seeded
        if let count = exerciseCount, count > 0 {
            print("✅ Database already seeded with \(count) exercises")
            return
        }
        
        print("🌱 Starting database seed...")
        seedExercises(modelContext: modelContext)
        seedFoods(modelContext: modelContext)
        print("✅ Database seeding completed!")
    }
    
    // MARK: - Seed Exercises
    private static func seedExercises(modelContext: ModelContext) {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "csv"),
              let csvData = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ exercises.csv not found")
            return
        }
        
        let rows = csvData.components(separatedBy: .newlines)
        var successCount = 0
        
        for (index, row) in rows.enumerated() {
            // Skip header and empty rows
            if index == 0 || row.isEmpty { continue }
            
            let columns = parseCSVRow(row)
            if columns.count >= 9 {
                let exercise = Exercise(
                    nameEN: columns[0],
                    nameTR: columns[1],
                    category: columns[2],
                    equipment: columns[3]
                )
                
                exercise.supportsWeight = columns[4].lowercased() == "true"
                exercise.supportsReps = columns[5].lowercased() == "true"
                exercise.supportsTime = columns[6].lowercased() == "true"
                exercise.supportsDistance = columns[7].lowercased() == "true"
                exercise.instructions = columns[8].isEmpty ? nil : columns[8]
                
                modelContext.insert(exercise)
                successCount += 1
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Seeded \(successCount) exercises")
        } catch {
            print("❌ Error saving exercises: \(error)")
        }
    }
    
    // MARK: - Seed Foods
    private static func seedFoods(modelContext: ModelContext) {
        guard let url = Bundle.main.url(forResource: "foods", withExtension: "csv"),
              let csvData = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ foods.csv not found")
            return
        }
        
        let rows = csvData.components(separatedBy: .newlines)
        var successCount = 0
        
        for (index, row) in rows.enumerated() {
            // Skip header and empty rows
            if index == 0 || row.isEmpty { continue }
            
            let columns = parseCSVRow(row)
            if columns.count >= 8 {
                // Parse nutrition values safely
                let calories = Double(columns[3]) ?? 0
                let protein = Double(columns[4]) ?? 0
                let carbs = Double(columns[5]) ?? 0
                let fat = Double(columns[6]) ?? 0
                
                // Map category string to enum
                let categoryEnum = FoodCategory.fromString(columns[7])
                
                let food = Food(
                    nameEN: columns[0],
                    nameTR: columns[1],
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    category: categoryEnum
                )
                
                // Set brand if not empty
                if !columns[2].isEmpty {
                    food.brand = columns[2]
                }
                
                modelContext.insert(food)
                successCount += 1
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Seeded \(successCount) foods")
        } catch {
            print("❌ Error saving foods: \(error)")
        }
    }
    
    // MARK: - CSV Parser Helper
    private static func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        
        // Remove quotes from fields
        return result.map { field in
            field.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
    }
    
    // MARK: - Clear Database (for testing)
    static func clearDatabase(modelContext: ModelContext) {
        // Clear exercises
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        if let exercises = try? modelContext.fetch(exerciseDescriptor) {
            exercises.forEach { modelContext.delete($0) }
        }
        
        // Clear foods
        let foodDescriptor = FetchDescriptor<Food>()
        if let foods = try? modelContext.fetch(foodDescriptor) {
            foods.forEach { modelContext.delete($0) }
        }
        
        try? modelContext.save()
        print("🗑️ Database cleared")
    }
}

// MARK: - FoodCategory Helper
extension FoodCategory {
    static func fromString(_ string: String) -> FoodCategory {
        switch string.lowercased() {
        case "meat": return .meat
        case "dairy": return .dairy
        case "grains": return .grains
        case "vegetables": return .vegetables
        case "fruits": return .fruits
        case "nuts": return .nuts
        case "beverages": return .beverages
        case "snacks": return .snacks
        case "turkish": return .turkish
        case "fastfood": return .fastfood
        case "supplements": return .supplements
        case "condiments": return .condiments
        case "bakery": return .bakery
        case "seafood": return .seafood
        case "desserts": return .desserts
        default: return .other
        }
    }
}
