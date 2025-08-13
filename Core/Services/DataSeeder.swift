import SwiftData
import Foundation

@MainActor
class DataSeeder {
    
    // MARK: - Main Seed Function
    static func seedDatabaseIfNeeded(modelContext: ModelContext) {
        // Check counts independently to avoid duplicate seeding
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exerciseCount = (try? modelContext.fetchCount(exerciseDescriptor)) ?? 0

        var didSeed = false
        if exerciseCount == 0 {
            print("🌱 Seeding exercises…")
            seedExercises(modelContext: modelContext)
            didSeed = true
        } else {
            print("✅ Exercises already present: \(exerciseCount)")
        }

        // Foods
        let foodDescriptor = FetchDescriptor<Food>()
        let foodCount = (try? modelContext.fetchCount(foodDescriptor)) ?? 0
        if foodCount == 0 {
            print("🌱 Seeding foods…")
            seedFoods(modelContext: modelContext)
            didSeed = true
        } else {
            print("✅ Foods already present: \(foodCount)")
        }

        // Always run a normalization step to ensure critical categories are correct
        fixOlympicExerciseCategories(modelContext: modelContext)
        normalizeExerciseCategoriesToPartTypes(modelContext: modelContext)

        // Normalize food data (categories, missing TR names)
        normalizeFoodData(modelContext: modelContext)

        if didSeed {
            print("✅ Database seeding completed!")
        }

        // Always seed aliases for common foods (idempotent)
        seedFoodAliasesIfNeeded(modelContext: modelContext)
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

// MARK: - Data Repair & Normalization
extension DataSeeder {
    /// Ensures well-known Olympic weightlifting movements are categorized correctly as `olympic`.
    /// This is safe to run on every launch; it only updates records that are miscategorized.
    @MainActor
    static func fixOlympicExerciseCategories(modelContext: ModelContext) {
        let olympicExactNames: Set<String> = [
            "clean and jerk",
            "snatch",
            "power clean",
            "split jerk",
            "power snatch"
        ]

        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return }

        var updatedCount = 0
        for exercise in exercises {
            let nameENLower = exercise.nameEN.lowercased()
            let nameTRLower = exercise.nameTR.lowercased()

            let isOlympicByName = olympicExactNames.contains(nameENLower) ||
                                  olympicExactNames.contains(nameTRLower)

            if isOlympicByName && exercise.category != ExerciseCategory.olympic.rawValue {
                exercise.category = ExerciseCategory.olympic.rawValue
                updatedCount += 1
            }
        }

        if updatedCount > 0 {
            do {
                try modelContext.save()
                print("🔧 Normalized olympic categories for \(updatedCount) exercises.")
            } catch {
                print("❌ Failed to normalize olympic categories: \(error)")
            }
        } else {
            print("ℹ️ Olympic category normalization: no changes needed.")
        }
    }
}

// MARK: - Exercise Normalization to 4 Part Types
extension DataSeeder {
    @MainActor
    static func normalizeExerciseCategoriesToPartTypes(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return }

        var updated = 0
        for ex in exercises {
            let original = ExerciseCategory(rawValue: ex.category) ?? .other
            // If it's 'other', collapse to strength to better map to powerStrength flow
            if original == .other {
                ex.category = ExerciseCategory.strength.rawValue
                updated += 1
            }
        }

        if updated > 0 { try? modelContext.save(); print("🔧 Normalized exercise categories (other→strength): updated=\(updated)") }
        else { print("ℹ️ Exercise category normalization: no changes needed.") }
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

// MARK: - Food Aliases Seed
extension DataSeeder {
    @MainActor
    static func seedFoodAliasesIfNeeded(modelContext: ModelContext) {
        // Prevent over-seeding by checking any existing alias
        let aliasDescriptor = FetchDescriptor<FoodAlias>()
        let aliasCount = (try? modelContext.fetchCount(aliasDescriptor)) ?? 0
        if aliasCount > 0 { return }

        // Minimal alias map: term (TR) -> English canonical search key
        let aliasMap: [String: [String]] = [
            "tavuk göğsü": ["chicken breast"],
            "tavuk": ["chicken"],
            "pirinç": ["rice"],
            "esmer pirinç": ["brown rice"],
            "bulgur": ["bulgur"],
            "yulaf": ["oat", "oats"],
            "ekmek": ["bread"],
            "makarna": ["pasta", "spaghetti"],
            "ton balığı": ["tuna"],
            "somon": ["salmon"],
            "yoğurt": ["yogurt", "yoghurt"],
            "süt": ["milk"],
            "peynir": ["cheese"],
            "badem": ["almond"],
            "fındık": ["hazelnut"],
            "ceviz": ["walnut"],
            "muz": ["banana"],
            "çilek": ["strawberry"],
            "domates": ["tomato"],
            "elma": ["apple"],
        ]

        // Build index of foods by normalized EN name for fast linking
        let foodDescriptor = FetchDescriptor<Food>()
        guard let foods = try? modelContext.fetch(foodDescriptor) else { return }
        let idx: [String: [Food]] = Dictionary(grouping: foods, by: { $0.nameEN.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })

        var created = 0
        for (trTerm, enKeys) in aliasMap {
            for key in enKeys {
                let enKey = key.lowercased()
                guard let targets = idx[enKey] else { continue }
                for food in targets.prefix(10) { // limit excessive linking
                    let alias = FoodAlias(term: trTerm, language: "tr", food: food)
                    modelContext.insert(alias)
                    created += 1
                }
            }
        }

        try? modelContext.save()
        print("✅ Seeded Food Aliases: created=\(created)")
    }
}

// MARK: - Food Normalization
extension DataSeeder {
    @MainActor
    static func normalizeFoodData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Food>()
        guard let foods = try? modelContext.fetch(descriptor) else { return }

        var updated = 0
        for food in foods {
            // Ensure nameTR present
            if food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                food.nameTR = food.nameEN
                updated += 1
            }

            // Category normalization: only adjust when clearly miscategorized
            if let better = classifyCategory(for: food) {
                let current = food.categoryEnum
                if current == .other || current == .beverages || current == .desserts || current == .condiments {
                    if better != current {
                        food.category = better.rawValue
                        updated += 1
                    }
                }
            }
        }

        if updated > 0 {
            try? modelContext.save()
            print("🔧 Normalized food data: updated=\(updated)")
        } else {
            print("ℹ️ Food normalization: no changes needed.")
        }
    }

    private static func classifyCategory(for food: Food) -> FoodCategory? {
        let text = (food.nameTR + " " + food.nameEN + " " + (food.brand ?? "")).lowercased()
        func matches(_ pattern: String) -> Bool {
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }

        // Dairy
        if matches("yo[gğ]urt|s[uü]t|kefir|peynir|quark|labne|kaymak|cream|yogurt|milk|cheese") { return .dairy }
        // Grains & bakery
        if matches("pirin[cç]|bulgur|yulaf|spag|makarna|şehriye|vermicelli|pasta|noodle|ekmek|lavaş|bazlama|simit|pilav|granola") { return .grains }
        // Legumes / vegetables mapping
        if matches("nohut|mercime[kg]|fasulye|barbunya|bezelye") { return .vegetables }
        // Meat
        if matches("tavuk|hindi|dana|s[ıi][ğg][ıi]r|k[öo]fte|et |kıyma|kebap|sucuk|past[ıi]rma|salam|sosis|jambon|beef|chicken|turkey") { return .meat }
        // Seafood
        if matches("ton bal[ıi][gğ][ıi]|somon|levrek|hamsi|uskumru|bal[ıi]k|tuna|salmon|sardalya|anchovy") { return .seafood }
        // Nuts
        if matches("badem|f[ıi]nd[ıi]k|ceviz|f[ıi]st[ıi]k|antep|fıstığı|peanut|almond|hazelnut|walnut|pistachio") { return .nuts }
        // Fruits
        if matches("muz|[çc]ile[kg]|portakal|elma|armut|[üu]z[üu]m|nar|k[ıi]raz|kay[ıi]s[ıi]|[şs]eftali|mandalina|limon|avokado|ananas|kavun|karpuz|incir|erik|greyfurt|berry|banana|apple|orange|strawberry") { return .fruits }
        // Snacks
        if matches("cips|kraker|bisk[iı]vi|[çc]ikolata|gofret|[çc]erez|lokum|wafer|cookie|cracker|chips|snack|bar") { return .snacks }
        // Beverages
        if matches("su[yıi]|gazoz|soda|ayran|kahve|kola|[çc]ay|meyve suyu|smoothie|nektar|i[cç]ecek|icecek|kakao|milkshake|cola|tea|coffee|soda|water|juice") { return .beverages }
        // Condiments
        if matches("zeytinya[gğ][ıi]|ya[gğ][ıi]|ket[çc]ap|mayonez|sal[cç]a|sirke|sos|hardal|vinegar|olive oil|oil") { return .condiments }
        return nil
    }
}
