import SwiftData
import Foundation

@MainActor
class DataSeeder {
    
    // MARK: - Main Seed Function
    static func seedDatabaseIfNeeded(modelContext: ModelContext) {
        // Check counts independently to avoid duplicate seeding
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let foodDescriptor = FetchDescriptor<Food>()
        let exerciseCount = (try? modelContext.fetchCount(exerciseDescriptor)) ?? 0
        let foodCount = (try? modelContext.fetchCount(foodDescriptor)) ?? 0

        var didSeed = false
        if exerciseCount == 0 {
            print("🌱 Seeding exercises…")
            seedExercises(modelContext: modelContext)
            didSeed = true
        } else {
            print("✅ Exercises already present: \(exerciseCount)")
        }

        if foodCount == 0 {
            print("🌱 Seeding foods…")
            seedFoods(modelContext: modelContext)
            didSeed = true
        } else {
            print("✅ Foods already present: \(foodCount)")
        }

        if didSeed {
            print("✅ Database seeding completed!")
        }
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

        // Quotas for curated set (total 120)
        let quotas: [ExerciseCategory: Int] = [
            .strength: 60,
            .core: 12,
            .functional: 10,
            .cardio: 8,
            .warmup: 6,
            .flexibility: 4,
            .olympic: 12,
            .plyometric: 8
        ]
        var used: [ExerciseCategory: Int] = [:]
        // Track best entry per exercise name to avoid dupes across equipment variants
        var keptByName: [String: (exercise: Exercise, rank: Int, category: ExerciseCategory)] = [:]

        // Equipment preference: lower rank is preferred
        let equipmentPreference: [String: Int] = [
            "barbell": 0,
            "dumbbell": 1,
            "machine": 2,
            "cable": 3,
            "kettlebell": 4,
            "bodyweight": 5,
            "rack": 6,
            "bench": 7,
            "box": 8,
            "ball": 9,
            "rope": 10,
            "bike": 11,
            "rower": 12,
            "treadmill": 13,
            "other": 99
        ]

        func equipmentRank(_ value: String) -> Int {
            equipmentPreference[value, default: 50]
        }

        // Helper closures
        func normalizeEquipment(_ raw: String) -> String {
            let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch v {
            case "barbell", "dumbbell", "kettlebell", "bodyweight", "machine", "cable", "band",
                 "bench", "rack", "box", "ball", "rope", "bike", "rower", "treadmill":
                return v
            case "none": return "bodyweight"
            case "mat", "foam_roller", "sandbag", "platform": return "other"
            default: return v.isEmpty ? "other" : v
            }
        }

        func canUse(category: ExerciseCategory) -> Bool {
            let cap = quotas[category] ?? 0
            let count = used[category] ?? 0
            return cap == 0 ? false : count < cap
        }

        func markUsed(_ category: ExerciseCategory) {
            used[category] = (used[category] ?? 0) + 1
        }

        // Iterate and pick curated unique rows until quotas filled or 100 reached
        for (index, row) in rows.enumerated() {
            if index == 0 || row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            let columns = parseCSVRow(row)
            if columns.count < 9 { continue }

            let nameEN = columns[0].trimmingCharacters(in: .whitespaces)
            let nameTR = columns[1].trimmingCharacters(in: .whitespaces)
            let category = ExerciseCategory.fromString(columns[2])
            let equipment = normalizeEquipment(columns[3])

            // Skip categories we don't curate for initial set
            if quotas[category] == nil { continue }

            // Prefer a single canonical entry per exercise name within the curated category quotas
            let nameKey = nameEN.lowercased()
            let newRank = equipmentRank(equipment)
            if let kept = keptByName[nameKey] {
                // Only consider replacement if same curated category and new equipment is preferred
                if kept.category == category && newRank < kept.rank {
                    // Update existing kept exercise with better equipment/flags/instructions
                    let existing = kept.exercise
                    existing.equipment = equipment
                    existing.supportsWeight = columns[4].lowercased() == "true"
                    existing.supportsReps = columns[5].lowercased() == "true"
                    existing.supportsTime = columns[6].lowercased() == "true"
                    existing.supportsDistance = columns[7].lowercased() == "true"
                    existing.instructions = columns[8].isEmpty ? nil : columns[8]
                    keptByName[nameKey] = (existing, newRank, category)
                }
                continue
            }

            if !canUse(category: category) { continue }

            let exercise = Exercise(
                nameEN: nameEN,
                nameTR: nameTR,
                category: category.rawValue,
                equipment: equipment
            )

            exercise.supportsWeight = columns[4].lowercased() == "true"
            exercise.supportsReps = columns[5].lowercased() == "true"
            exercise.supportsTime = columns[6].lowercased() == "true"
            exercise.supportsDistance = columns[7].lowercased() == "true"
            exercise.instructions = columns[8].isEmpty ? nil : columns[8]

            modelContext.insert(exercise)
            successCount += 1
            keptByName[nameKey] = (exercise, newRank, category)
            markUsed(category)

            if successCount >= 120 { break }
        }

        do {
            try modelContext.save()
            print("✅ Seeded curated exercises: total=\(successCount) | used=\(used)")
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
    static func clearExercisesOnly(modelContext: ModelContext) {
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        if let exercises = try? modelContext.fetch(exerciseDescriptor) {
            exercises.forEach { modelContext.delete($0) }
        }
        try? modelContext.save()
        print("🗑️ Exercises cleared (foods preserved)")
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
