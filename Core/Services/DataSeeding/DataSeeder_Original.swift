import SwiftData
import Foundation

/**
 * Database seeding service that populates the app with initial data from CSV and JSON files.
 * 
 * This service handles the initial database population with exercises, foods, benchmark WODs,
 * CrossFit movements, and workout programs. Designed for SwiftData compatibility with sequential
 * processing and comprehensive error handling.
 * 
 * Key features:
 * - Sequential seeding for SwiftData stability
 * - Batch processing with configurable batch sizes
 * - Individual error handling for each data type
 * - Progress tracking and logging
 * - Graceful fallback mechanisms
 * - SwiftUI integration with progress callbacks
 * 
 * Data sources:
 * - CSV files for exercises and food database
 * - JSON files for workout programs and templates
 * - Hardcoded benchmark WODs and CrossFit movements
 * 
 * Performance optimizations:
 * - Batch size: 10 items (reduced for stability)
 * - Yield interval: Every 10 operations
 * - Max retries: 3 attempts per operation
 */

// MARK: - Progress Tracking
enum SeedingProgress: CaseIterable, Identifiable, Equatable {
    case starting
    case exercises
    case foods
    case benchmarkWODs
    case crossFitMovements
    case cardioExercises
    case liftPrograms
    case routineTemplates
    case normalization
    case foodAliases
    case completed
    case error(String)
    
    // MARK: - Equatable Implementation
    static func == (lhs: SeedingProgress, rhs: SeedingProgress) -> Bool {
        switch (lhs, rhs) {
        case (.starting, .starting),
             (.exercises, .exercises),
             (.foods, .foods),
             (.benchmarkWODs, .benchmarkWODs),
             (.crossFitMovements, .crossFitMovements),
             (.cardioExercises, .cardioExercises),
             (.liftPrograms, .liftPrograms),
             (.routineTemplates, .routineTemplates),
             (.normalization, .normalization),
             (.foodAliases, .foodAliases),
             (.completed, .completed):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var id: String {
        switch self {
        case .starting: return "starting"
        case .exercises: return "exercises"
        case .foods: return "foods"
        case .benchmarkWODs: return "benchmarkWODs"
        case .crossFitMovements: return "crossFitMovements"
        case .cardioExercises: return "cardioExercises"
        case .liftPrograms: return "liftPrograms"
        case .routineTemplates: return "routineTemplates"
        case .normalization: return "normalization"
        case .foodAliases: return "foodAliases"
        case .completed: return "completed"
        case .error(let message): return "error_\(message.hashValue)"
        }
    }
    
    var title: String {
        switch self {
        case .starting: return "Preparing database..."
        case .exercises: return "Loading exercises..."
        case .foods: return "Loading foods..."
        case .benchmarkWODs: return "Loading benchmark WODs..."
        case .crossFitMovements: return "Loading CrossFit movements..."
        case .cardioExercises: return "Loading cardio exercises..."
        case .liftPrograms: return "Loading lift programs..."
        case .routineTemplates: return "Loading routine templates..."
        case .normalization: return "Optimizing data..."
        case .foodAliases: return "Setting up food aliases..."
        case .completed: return "Database ready!"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var progressValue: Double {
        switch self {
        case .starting: return 0.0
        case .exercises: return 0.1
        case .foods: return 0.3
        case .benchmarkWODs: return 0.4
        case .crossFitMovements: return 0.5
        case .cardioExercises: return 0.6
        case .liftPrograms: return 0.7
        case .routineTemplates: return 0.8
        case .normalization: return 0.9
        case .foodAliases: return 0.95
        case .completed: return 1.0
        case .error(_): return 0.0
        }
    }
    
    static var allCases: [SeedingProgress] {
        return [.starting, .exercises, .foods, .benchmarkWODs, .crossFitMovements, 
                .cardioExercises, .liftPrograms, .routineTemplates, .normalization, 
                .foodAliases, .completed]
    }
}

// MARK: - Progress Callback
typealias ProgressCallback = @MainActor (SeedingProgress) async -> Void

class DataSeeder {
    
    // MARK: - Configuration
    private struct SeedingConfig {
        static let batchSize = 50      // Performance optimization - increased from 10 to 50
        static let maxRetries = 3
        static let yieldInterval = 25  // Performance optimization - less frequent yielding
    }
    
    // MARK: - Main Seed Function
    @MainActor
    static func seedDatabaseIfNeeded(modelContext: ModelContext, progressCallback: ProgressCallback? = nil) async {
        let isEmpty = await isDatabaseEmpty(modelContext: modelContext)
        
        if isEmpty {
            await progressCallback?(.starting)
            Logger.info("Database is empty, starting optimized seeding...")
            
            do {
                // Sequential seeding for SwiftData compatibility
                Logger.info("Starting sequential database seeding...")
                
                // Core data seeding - sequential with individual error handling
                do {
                    await progressCallback?(.exercises)
                    try await seedExercises(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed exercises: \(error)")
                    await progressCallback?(.error("Failed to load exercises: \(error.localizedDescription)"))
                    throw error
                }
                
                do {
                    await progressCallback?(.foods)
                    try await seedFoods(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed foods: \(error)")
                    await progressCallback?(.error("Failed to load foods: \(error.localizedDescription)"))
                    throw error
                }
                
                // Secondary data seeding - sequential
                await progressCallback?(.benchmarkWODs)
                try await seedBenchmarkWODsIfNeeded(modelContext: modelContext)
                
                await progressCallback?(.crossFitMovements)
                try await seedCrossFitMovementsFromCSVIfNeeded(modelContext: modelContext)
                
                await progressCallback?(.cardioExercises)
                try await seedCardioExercisesIfNeeded(modelContext: modelContext)
                
                // JSON-based data seeding - sequential
                await progressCallback?(.liftPrograms)
                try await seedLiftProgramsFromJSONIfNeeded(modelContext: modelContext)
                
                await progressCallback?(.routineTemplates)
                try await seedRoutineTemplatesIfNeeded(modelContext: modelContext)
                
                // Normalization - after all data is seeded
                await progressCallback?(.normalization)
                await normalizeDataAfterSeeding(modelContext: modelContext)
                
                // Food aliases - depends on foods being seeded
                await progressCallback?(.foodAliases)
                await seedFoodAliasesIfNeeded(modelContext: modelContext)
                
                await progressCallback?(.completed)
                Logger.success("Optimized database seeding completed!")
                
            } catch {
                Logger.error("Database seeding failed: \(error)")
                await progressCallback?(.error("Database seeding failed: \(error.localizedDescription)"))
                // Fallback to basic seeding with minimal test data
                Logger.info("Attempting fallback seeding...")
                await fallbackSeeding(modelContext: modelContext, progressCallback: progressCallback)
            }
        } else {
            await progressCallback?(.completed)
            Logger.success("Database already contains data, skipping seeding")
        }
    }
    
    // MARK: - Optimized Helper Functions
    
    /// Optimized: Single check for database emptiness
    @MainActor
    private static func isDatabaseEmpty(modelContext: ModelContext) async -> Bool {
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exerciseCount = (try? modelContext.fetchCount(exerciseDescriptor)) ?? 0
        return exerciseCount == 0
    }
    
    /// Fallback seeding for critical failures
    @MainActor
    private static func fallbackSeeding(modelContext: ModelContext, progressCallback: ProgressCallback? = nil) async {
        await progressCallback?(.error("Using fallback mode with minimal data"))
        Logger.warning("🚨 Using fallback seeding with minimal test data...")
        
        do {
            await progressCallback?(.exercises)
            // Create absolutely minimal test exercises
            let testExercises = [
                ("Squat", "Squat", "legs", "bodyweight"),
                ("Push Up", "Push Up", "push", "bodyweight"),
                ("Plank", "Plank", "core", "bodyweight")
            ]
            
            for (nameEN, nameTR, category, equipment) in testExercises {
                let exercise = Exercise(
                    nameEN: nameEN,
                    nameTR: nameTR,
                    category: category,
                    equipment: equipment
                )
                modelContext.insert(exercise)
            }
            
            // Try to save the minimal data
            try modelContext.save()
            await progressCallback?(.completed)
            Logger.success("✅ Fallback seeding completed with \(testExercises.count) basic exercises")
        } catch {
            await progressCallback?(.error("Critical failure: \(error.localizedDescription)"))
            Logger.error("❌ Even fallback seeding failed: \(error)")
            // At this point, the app will have an empty database
            // but it should still function
        }
    }
    
    /// Optimized: Combined normalization after seeding
    @MainActor
    private static func normalizeDataAfterSeeding(modelContext: ModelContext) async {
        await Task.yield() // Keep UI responsive
        
        // Run all normalizations together
        
        await normalizeExerciseCategoriesToPartTypes(modelContext: modelContext)
        await Task.yield()
        
        await normalizeFoodData(modelContext: modelContext)
        await Task.yield()
        
        Logger.info("Data normalization completed")
    }
    
    // MARK: - Standardized CSV Parser
    private struct CSVParser {
        static func parseCSVRow(_ row: String) -> [String] {
            // Very simple and safe CSV parsing
            let fields = row.components(separatedBy: ",")
            return fields.map { field in
                let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove quotes safely
                if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count > 1 {
                    return String(trimmed.dropFirst().dropLast())
                }
                return trimmed
            }
        }
        
        static func parseCSVFile(_ filename: String) throws -> [[String]] {
            // Support both root Resources and subfolder paths
            var url: URL?
            
            // First try with subfolder path (e.g., "Training/Cardio/outdoor_cardio")
            if filename.contains("/") {
                let components = filename.components(separatedBy: "/")
                let fileName = components.last ?? filename
                let subpath = components.dropLast().joined(separator: "/")
                url = Bundle.main.url(forResource: fileName, withExtension: "csv", subdirectory: subpath)
            }
            
            // If not found or no subfolder, try root Resources
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "csv")
            }
            
            guard let fileURL = url else {
                Logger.error("CSV file not found in bundle: \(filename).csv")
                throw DataSeederError.fileNotFound(filename)
            }
            
            let csvData: String
            do {
                csvData = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                throw DataSeederError.parsingError("Failed to read CSV file: \(error)")
            }
            
            // Split by newlines and clean up
            let rows = csvData.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            guard rows.count > 1 else {
                throw DataSeederError.emptyFile(filename)
            }
            
            var parsedRows: [[String]] = []
            
            for (index, row) in rows.enumerated() {
                let parsedRow = parseCSVRow(row)
                
                // Skip completely empty rows
                if parsedRow.allSatisfy({ $0.isEmpty }) {
                    Logger.warning("Skipping empty row at index \(index) in \(filename)")
                    continue
                }
                
                parsedRows.append(parsedRow)
            }
            
            Logger.info("Successfully parsed \(parsedRows.count) rows from \(filename)")
            return parsedRows
        }
        
        static func parseJSONFile<T: Codable>(_ filename: String, as type: T.Type) throws -> T {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                throw DataSeederError.fileNotFound(filename)
            }
            
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw DataSeederError.parsingError("Failed to read JSON file: \(error)")
            }
            
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw DataSeederError.parsingError("Failed to decode JSON: \(error)")
            }
        }
    }
    
    // MARK: - Exercise ID Resolution
    private struct ExerciseResolver {
        private var exerciseCache: [String: UUID] = [:]
        
        mutating func resolveExerciseID(name: String, modelContext: ModelContext) -> UUID? {
            // Check cache first
            if let cachedID = exerciseCache[name] {
                return cachedID
            }
            
            // Search in database
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate<Exercise> { 
                    $0.nameEN.localizedStandardContains(name) || 
                    $0.nameTR.localizedStandardContains(name)
                }
            )
            
            if let exercise = try? modelContext.fetch(descriptor).first {
                exerciseCache[name] = exercise.id
                return exercise.id
            }
            
            return nil
        }
        
        mutating func resolveExerciseIDs(names: [String], modelContext: ModelContext) -> [UUID] {
            return names.compactMap { resolveExerciseID(name: $0, modelContext: modelContext) }
        }
    }
    
    
    // MARK: - Seed Exercises with Improved Error Handling  
    @MainActor
    private static func seedExercises(modelContext: ModelContext) async throws {
        // Load lift_exercises.csv
        let resourceName = "lift_exercises"
        
        do {
            // Load basic exercises (lift, strength, etc.)
            let basicRows = try CSVParser.parseCSVFile(resourceName)
            Logger.info("Loaded \(basicRows.count) basic exercise rows")
            
            let rows = basicRows
            var successCount = 0
            var processedCount = 0
            
            // Check if we should import all or curated set
            let importAll: Bool = {
                #if DEBUG
                return UserDefaults.standard.object(forKey: "seed.importAll") as? Bool ?? true
                #else
                return UserDefaults.standard.object(forKey: "seed.importAll") as? Bool ?? false
                #endif
            }()
            
            if importAll {
                // Import all exercises
                for (index, columns) in rows.enumerated() {
                    if index == 0 { continue } // Skip header
                    if columns.count < 8 { continue }
                    
                    do {
                        let exercise = try createExerciseFromCSV(columns: columns)
                        modelContext.insert(exercise)
                        successCount += 1
                        processedCount += 1
                        
                        // Save in batches
                        if processedCount % SeedingConfig.batchSize == 0 {
                            try modelContext.save()
                            Logger.info("Batch saved: \(processedCount) exercises")
                            await Task.yield()
                        }
                    } catch {
                        Logger.error("❌ Failed to create exercise at row \(index): \(error), columns: \(columns)")
                        continue
                    }
                }
            } else {
                // Import curated set
                successCount = try await seedCuratedExercises(rows: rows, modelContext: modelContext)
            }
            
            // Save remaining exercises
            try modelContext.save()
            Logger.success("Seeded exercises: total=\(successCount)")
            
        } catch {
            Logger.error("Failed to seed exercises: \(error)")
            throw error
        }
    }
    
    private static func createExerciseFromCSV(columns: [String]) throws -> Exercise {
        guard columns.count >= 8 else {
            throw DataSeederError.invalidDataFormat("Exercise requires at least 8 columns")
        }
        
        let nameEN = columns[0].trimmingCharacters(in: .whitespaces)
        let nameTR = columns[1].trimmingCharacters(in: .whitespaces)
        let categoryString = columns[2].trimmingCharacters(in: .whitespaces)
        let equipment = columns[3].trimmingCharacters(in: .whitespaces)
        
        guard !nameEN.isEmpty else {
            throw DataSeederError.invalidDataFormat("Exercise name cannot be empty")
        }
        
        // Create exercise with basic info first
        let exercise = Exercise(
            nameEN: nameEN,
            nameTR: nameTR.isEmpty ? nameEN : nameTR,
            category: categoryString,
            equipment: equipment
        )
        
        // Parse boolean values safely and update properties
        if columns.count > 4 {
            exercise.supportsWeight = columns[4].lowercased() == "true"
        }
        if columns.count > 5 {
            exercise.supportsReps = columns[5].lowercased() == "true"
        }
        if columns.count > 6 {
            exercise.supportsTime = columns[6].lowercased() == "true"
        }
        if columns.count > 7 {
            exercise.supportsDistance = columns[7].lowercased() == "true"
        }
        
        return exercise
    }
    
    private static func seedCuratedExercises(rows: [[String]], modelContext: ModelContext) async throws -> Int {
        // Quotas for curated set (total ~120)
        let quotas: [ExerciseCategory: Int] = [
            .strength: 60,
            .core: 12,
            .functional: 10,
            .cardio: 8,
            .flexibility: 4,
            .olympic: 12,
            .plyometric: 8
        ]
        
        var used: [ExerciseCategory: Int] = [:]
        var keptByName: [String: (exercise: Exercise, rank: Int, category: ExerciseCategory)] = [:]
        var successCount = 0
        
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
        
        func quotaBucket(for category: ExerciseCategory) -> ExerciseCategory {
            switch category {
            case .push, .pull, .legs, .isolation:
                return .strength
            default:
                return category
            }
        }
        
        // Process rows
        for (index, columns) in rows.enumerated() {
            if index == 0 { continue } // Skip header
            if columns.count < 8 { continue }
            
            do {
                let nameEN = columns[0].trimmingCharacters(in: .whitespaces)
                let categoryString = columns[2].trimmingCharacters(in: .whitespaces)
                let category = ExerciseCategory.fromString(categoryString)
                let bucket = quotaBucket(for: category)
                let equipment = normalizeEquipment(columns[3])
                
                // Skip categories we don't curate for initial set
                if quotas[bucket] == nil { continue }
                
                // Prefer a single canonical entry per exercise name
                let nameKey = nameEN.lowercased()
                let newRank = equipmentRank(equipment)
                
                if let kept = keptByName[nameKey] {
                    // Only consider replacement if same curated category and new equipment is preferred
                    if kept.category == bucket && newRank < kept.rank {
                        let existing = kept.exercise
                        existing.equipment = equipment
                        existing.supportsWeight = columns[4].lowercased() == "true"
                        existing.supportsReps = columns[5].lowercased() == "true"
                        existing.supportsTime = columns[6].lowercased() == "true"
                        existing.supportsDistance = columns[7].lowercased() == "true"
                        keptByName[nameKey] = (existing, newRank, bucket)
                    }
                    continue
                }
                
                if !canUse(category: bucket) { continue }
                
                let exercise = try createExerciseFromCSV(columns: columns)
                modelContext.insert(exercise)
                successCount += 1
                keptByName[nameKey] = (exercise, newRank, bucket)
                markUsed(bucket)
                
                if successCount >= 120 { break }
                
                // Yield periodically
                if successCount % SeedingConfig.yieldInterval == 0 {
                    await Task.yield()
                }
                
            } catch {
                Logger.warning("Failed to process exercise at row \(index): \(error)")
                continue
            }
        }
        
        return successCount
    }
    
    
    // MARK: - Seed Foods with Improved Error Handling
    @MainActor
    private static func seedFoods(modelContext: ModelContext) async throws {
        // Load foods.csv
        guard let url = Bundle.main.url(forResource: "foods", withExtension: "csv"),
              let csvData = try? String(contentsOf: url, encoding: .utf8) else {
            throw DataSeederError.fileNotFound("foods.csv")
        }
        
        let rows = csvData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var successCount = 0
        
        for (index, row) in rows.enumerated() {
            // Yield every 50 foods
            if index % 50 == 0 {
                await Task.yield()
            }
            
            // Skip header and empty rows
            if index == 0 || row.isEmpty { continue }
            
            do {
                let columns = CSVParser.parseCSVRow(row)
                if columns.count >= 8 {
                    let food = try createFoodFromCSV(columns: columns)
                    modelContext.insert(food)
                    successCount += 1
                }
            } catch {
                Logger.warning("Failed to create food at row \(index): \(error)")
                continue
            }
        }
        
        do {
            try modelContext.save()
            Logger.success("Seeded \(successCount) foods")
        } catch {
            Logger.error("Error saving foods: \(error)")
            throw error
        }
    }
    
    private static func createFoodFromCSV(columns: [String]) throws -> Food {
        guard columns.count >= 8 else {
            throw DataSeederError.invalidDataFormat("Food requires at least 8 columns")
        }
        
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
        
        // Optional serving columns
        if columns.count >= 9 {
            let s = columns[8].trimmingCharacters(in: .whitespaces)
            if let g = Double(s), g > 0 { food.servingSizeGrams = g }
        }
        if columns.count >= 10 {
            let label = columns[9].trimmingCharacters(in: .whitespaces)
            if !label.isEmpty { food.servingName = label }
        }
        
        return food
    }
    
    // MARK: - Clear Database (for testing)
    static func clearExercisesOnly(modelContext: ModelContext) {
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        if let exercises = try? modelContext.fetch(exerciseDescriptor) {
            exercises.forEach { modelContext.delete($0) }
        }
        try? modelContext.save()
        Logger.info("Exercises cleared (foods preserved)")
    }
}

// MARK: - DataSeederError
enum DataSeederError: Error, LocalizedError {
    case fileNotFound(String)
    case emptyFile(String)
    case invalidDataFormat(String)
    case parsingError(String)
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "File not found: \(filename)"
        case .emptyFile(let filename):
            return "File is empty: \(filename)"
        case .invalidDataFormat(let message):
            return "Invalid data format: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}


// MARK: - Exercise Normalization to 4 Part Types
extension DataSeeder {
    @MainActor
    static func normalizeExerciseCategoriesToPartTypes(modelContext: ModelContext) async {
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

        if updated > 0 { 
            do {
                try modelContext.save()
                Logger.info("Normalized exercise categories (other→strength): updated=\(updated)")
            } catch {
                Logger.error("Failed to save normalized exercise categories: \(error)")
            }
        } else { 
            Logger.info("Exercise category normalization: no changes needed.") 
        }
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
    static func seedFoodAliasesIfNeeded(modelContext: ModelContext) async {
        // Prevent over-seeding by checking any existing alias
        let aliasDescriptor = FetchDescriptor<FoodAlias>()
        let aliasCount = (try? modelContext.fetchCount(aliasDescriptor)) ?? 0
        if aliasCount > 0 { return }

        // Minimal alias map: term (language) -> English canonical search key
        let aliasMap: [String: (language: String, searchKeys: [String])] = [
            // Turkish aliases
            "tavuk göğsü": (language: "tr", searchKeys: ["chicken breast"]),
            "tavuk": (language: "tr", searchKeys: ["chicken"]),
            "pirinç": (language: "tr", searchKeys: ["rice"]),
            "esmer pirinç": (language: "tr", searchKeys: ["brown rice"]),
            "bulgur": (language: "tr", searchKeys: ["bulgur"]),
            "yulaf": (language: "tr", searchKeys: ["oat", "oats"]),
            "ekmek": (language: "tr", searchKeys: ["bread"]),
            "makarna": (language: "tr", searchKeys: ["pasta", "spaghetti"]),
            "ton balığı": (language: "tr", searchKeys: ["tuna"]),
            "somon": (language: "tr", searchKeys: ["salmon"]),
            "yoğurt": (language: "tr", searchKeys: ["yogurt", "yoghurt"]),
            "süt": (language: "tr", searchKeys: ["milk"]),
            "peynir": (language: "tr", searchKeys: ["cheese"]),
            "badem": (language: "tr", searchKeys: ["almond"]),
            "fındık": (language: "tr", searchKeys: ["hazelnut"]),
            "ceviz": (language: "tr", searchKeys: ["walnut"]),
            "muz": (language: "tr", searchKeys: ["banana"]),
            "çilek": (language: "tr", searchKeys: ["strawberry"]),
            "domates": (language: "tr", searchKeys: ["tomato"]),
            "elma": (language: "tr", searchKeys: ["apple"]),
            
            // Spanish aliases
            "pechuga de pollo": (language: "es", searchKeys: ["chicken breast"]),
            "pollo": (language: "es", searchKeys: ["chicken"]),
            "arroz": (language: "es", searchKeys: ["rice"]),
            "arroz integral": (language: "es", searchKeys: ["brown rice"]),
            "avena": (language: "es", searchKeys: ["oat", "oats"]),
            "pan": (language: "es", searchKeys: ["bread"]),
            "pasta": (language: "es", searchKeys: ["pasta", "spaghetti"]),
            "atún": (language: "es", searchKeys: ["tuna"]),
            "salmón": (language: "es", searchKeys: ["salmon"]),
            "yogur": (language: "es", searchKeys: ["yogurt", "yoghurt"]),
            "leche": (language: "es", searchKeys: ["milk"]),
            "queso": (language: "es", searchKeys: ["cheese"]),
            "almendra": (language: "es", searchKeys: ["almond"]),
            "avellana": (language: "es", searchKeys: ["hazelnut"]),
            "nuez": (language: "es", searchKeys: ["walnut"]),
            "plátano": (language: "es", searchKeys: ["banana"]),
            "fresa": (language: "es", searchKeys: ["strawberry"]),
            "tomate": (language: "es", searchKeys: ["tomato"]),
            "manzana": (language: "es", searchKeys: ["apple"]),
        ]

        // Build index of foods by normalized EN name for fast linking
        let foodDescriptor = FetchDescriptor<Food>()
        guard let foods = try? modelContext.fetch(foodDescriptor) else { return }
        let idx: [String: [Food]] = Dictionary(grouping: foods, by: { $0.nameEN.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })

        var created = 0
        for (term, aliasInfo) in aliasMap {
            for key in aliasInfo.searchKeys {
                let enKey = key.lowercased()
                guard let targets = idx[enKey] else { continue }
                for food in targets.prefix(10) { // limit excessive linking
                    let alias = FoodAlias(term: term, language: aliasInfo.language, food: food)
                    modelContext.insert(alias)
                    created += 1
                }
            }
        }

        do {
            try modelContext.save()
            Logger.success("Seeded Food Aliases: created=\(created)")
        } catch {
            Logger.error("Failed to save food aliases: \(error)")
        }
    }
}

// MARK: - Food Normalization
extension DataSeeder {
    @MainActor
    static func normalizeFoodData(modelContext: ModelContext) async {
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
            do {
                try modelContext.save()
                Logger.info("Normalized food data: updated=\(updated)")
            } catch {
                Logger.error("Failed to save normalized food data: \(error)")
            }
        } else {
            Logger.info("Food normalization: no changes needed.")
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
    
    // MARK: - Seed Benchmark WODs
    @MainActor
    private static func seedBenchmarkWODsIfNeeded(modelContext: ModelContext) async throws {
        // Check if benchmark WODs already exist
        let descriptor = FetchDescriptor<WOD>(predicate: #Predicate<WOD> { !$0.isCustom })
        let existingWODs = (try? modelContext.fetch(descriptor)) ?? []
        
        // Force re-seed if existing WODs have incorrect categories
        let needsReseed = existingWODs.contains { wod in
            wod.category == "The Girls" || wod.category == "Hero WODs"
        }
        
        if !existingWODs.isEmpty && !needsReseed {
            Logger.success("Benchmark WODs already present: \(existingWODs.count)")
            return
        }
        
        // Delete existing benchmark WODs if they need re-seeding
        if needsReseed {
            Logger.info("Re-seeding benchmark WODs due to category mismatch...")
            for wod in existingWODs {
                modelContext.delete(wod)
            }
        }
        
        Logger.info("Seeding benchmark WODs from CSV...")
        await Task.yield() // Keep UI responsive
        try await seedBenchmarkWODsFromCSV(modelContext: modelContext)
    }
    
    @MainActor
    private static func seedBenchmarkWODsFromCSV(modelContext: ModelContext) async throws {
        do {
            let rows = try CSVParser.parseCSVFile("benchmark_wods")
            guard rows.count > 1 else { return } // Skip empty file
            
            let headers = rows[0]
            var created = 0
            
            for (index, values) in rows.enumerated() {
                if index == 0 { continue } // Skip header
                guard values.count >= headers.count else { continue }
                
                // Create dictionary from headers and values
                let row = Dictionary(uniqueKeysWithValues: zip(headers, values))
                
                // Extract basic WOD info
                guard let name = row["name"], !name.isEmpty,
                      let type = row["type"], !type.isEmpty,
                      let categoryStr = row["category"] else { continue }
                
                // Convert type
                let wodType = WODType(rawValue: type) ?? .custom
                
                // Create WOD
                let wod = WOD(
                    name: name,
                    type: wodType,
                    category: categoryStr,
                    repScheme: parseRepScheme(row["repScheme"]),
                    timeCap: parseTimeCap(row["timeCap"]),
                    isCustom: false
                )
                
                // Add movements
                addMovementsFromCSV(to: wod, from: row)
                
                modelContext.insert(wod)
                created += 1
                
                // Yield periodically
                if created % SeedingConfig.yieldInterval == 0 {
                    await Task.yield()
                }
            }
            
            try modelContext.save()
            Logger.success("Created \(created) benchmark WODs")
            
        } catch {
            Logger.error("Failed to seed benchmark WODs: \(error)")
            throw error
        }
    }
    
    private static func parseRepScheme(_ repSchemeStr: String?) -> [Int] {
        guard let repSchemeStr = repSchemeStr, !repSchemeStr.isEmpty else { return [] }
        return repSchemeStr.components(separatedBy: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
    
    private static func parseTimeCap(_ timeCapStr: String?) -> Int? {
        guard let timeCapStr = timeCapStr, !timeCapStr.isEmpty else { return nil }
        return Int(timeCapStr)
    }
    
    private static func addMovementsFromCSV(to wod: WOD, from row: [String: String]) {
        for i in 1...4 { // Support up to 4 movements
            guard let movementName = row["movement\(i)"], !movementName.isEmpty else { continue }
            
            let movement = WODMovement(
                name: movementName,
                rxWeightMale: row["rxMale\(i)"],
                rxWeightFemale: row["rxFemale\(i)"],
                reps: Int(row["reps\(i)"] ?? ""),
                orderIndex: i - 1
            )
            
            movement.wod = wod
            wod.movements.append(movement)
        }
    }
    
    // MARK: - Seed CrossFit Movements from CSV
    @MainActor
    private static func seedCrossFitMovementsFromCSVIfNeeded(modelContext: ModelContext) async throws {
        // Check if CrossFit movements already exist
        let descriptor = FetchDescriptor<CrossFitMovement>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if existingCount > 0 {
            Logger.success("CrossFit movements already present: \(existingCount)")
            return
        }
        
        Logger.info("Seeding CrossFit movements from CSV...")
        try await seedCrossFitMovementsFromCSV(modelContext: modelContext)
    }
    
    @MainActor
    private static func seedCrossFitMovementsFromCSV(modelContext: ModelContext) async throws {
        do {
            let rows = try CSVParser.parseCSVFile("metcon_exercises")
            guard rows.count > 1 else { return } // Skip empty file
            
            let headers = rows[0]
            var created = 0
            
            for (index, values) in rows.enumerated() {
                if index == 0 { continue } // Skip header
                guard values.count >= headers.count else { continue }
                
                // Create dictionary from headers and values
                let row = Dictionary(uniqueKeysWithValues: zip(headers, values))
                
                // Extract movement info
                guard let nameEN = row["nameEN"], !nameEN.isEmpty,
                      let category = row["category"], !category.isEmpty,
                      let equipment = row["equipment"] else { continue }
                
                let movement = CrossFitMovement(
                    nameEN: nameEN,
                    nameTR: row["nameTR"] ?? nameEN,
                    category: category,
                    equipment: equipment,
                    rxWeightMale: parseEmptyString(row["rxWeightMale"]),
                    rxWeightFemale: parseEmptyString(row["rxWeightFemale"]),
                    supportsWeight: parseBool(row["supportsWeight"]),
                    supportsReps: parseBool(row["supportsReps"]),
                    supportsTime: parseBool(row["supportsTime"]),
                    supportsDistance: parseBool(row["supportsDistance"]),
                    wodSuitability: parseInt(row["wodSuitability"]) ?? 10,
                    instructions: parseEmptyString(row["instructions"]),
                    scalingNotes: parseEmptyString(row["scalingNotes"])
                )
                
                modelContext.insert(movement)
                created += 1
                
                // Yield periodically
                if created % SeedingConfig.yieldInterval == 0 {
                    await Task.yield()
                }
            }
            
            try modelContext.save()
            Logger.success("Created \(created) CrossFit movements")
            
        } catch {
            Logger.error("Failed to seed CrossFit movements: \(error)")
            throw error
        }
    }
    
    private static func parseEmptyString(_ str: String?) -> String? {
        guard let str = str, !str.isEmpty else { return nil }
        return str
    }
    
    private static func parseBool(_ str: String?) -> Bool {
        return str?.lowercased() == "true"
    }
    
    private static func parseInt(_ str: String?) -> Int? {
        guard let str = str, !str.isEmpty else { return nil }
        return Int(str)
    }
    
    
    // MARK: - Seed Cardio Exercises
    @MainActor
    private static func seedCardioExercisesIfNeeded(modelContext: ModelContext) async throws {
        // Check if cardio workouts already exist
        let descriptor = FetchDescriptor<CardioWorkout>(predicate: #Predicate<CardioWorkout> { !$0.isCustom })
        let existingCardios = (try? modelContext.fetch(descriptor)) ?? []
        
        if !existingCardios.isEmpty {
            Logger.success("Cardio exercises already present: \(existingCardios.count)")
            return
        }
        
        Logger.info("Seeding cardio exercises from CSV...")
        try await seedCardiosFromCSV(modelContext: modelContext)
    }
    
    @MainActor
    private static func seedCardiosFromCSV(modelContext: ModelContext) async throws {
        // Seed from 3 separate CSV files
        let cardioFiles = [
            ("outdoor_cardio", "outdoor"),
            ("indoor_cardio", "indoor"),
            ("ergo_cardio", "ergometer")
        ]
        
        var totalCreated = 0
        
        for (fileName, location) in cardioFiles {
            do {
                let rows = try CSVParser.parseCSVFile(fileName)
                guard rows.count > 1 else { continue }
                
                let headers = rows[0]
                
                for (index, values) in rows.enumerated() {
                    if index == 0 { continue } // Skip header
                    guard values.count >= headers.count else { continue }
                    
                    let row = Dictionary(uniqueKeysWithValues: zip(headers, values))
                    
                    // Extract cardio workout info
                    guard let name = row["name"], !name.isEmpty else { continue }
                    
                    // Parse equipment - it's a single value in new CSVs
                    let equipmentValue = row["equipment"] ?? ""
                    let equipment = [equipmentValue] // Convert to array for compatibility
                    
                    let workout = CardioWorkout(
                        name: name,
                        nameEN: row["nameEN"] ?? name,
                        nameTR: row["nameTR"] ?? name,
                        nameES: row["nameES"] ?? name,
                        nameDE: row["nameDE"] ?? name,
                        type: "exercise", // All are exercise types now
                        category: location, // Use location as category (outdoor/indoor/ergometer)
                        description: "",
                        descriptionTR: row["descriptionTR"] ?? "",
                        descriptionES: row["descriptionES"] ?? "",
                        descriptionDE: row["descriptionDE"] ?? "",
                        targetDistance: nil, // No predetermined targets
                        targetTime: nil, // No predetermined targets
                        estimatedCalories: nil, // Will be calculated per session
                        difficulty: "any", // Exercise types work for any level
                        equipment: equipment,
                        isTemplate: true,
                        isCustom: false
                    )
                
                // Add default exercise for this exercise type
                if let exerciseType = row["exerciseType"], !exerciseType.isEmpty {
                    let exercise = CardioExercise(
                        name: name,
                        exerciseType: exerciseType,
                        targetDistance: nil, // User will set per session
                        targetTime: nil, // User will set per session
                        equipment: equipment.first ?? "outdoor"
                    )
                    workout.addExercise(exercise)
                }
                
                modelContext.insert(workout)
                totalCreated += 1
                
                // Yield periodically
                if totalCreated % SeedingConfig.yieldInterval == 0 {
                    await Task.yield()
                }
                }
            } catch {
                Logger.error("Failed to seed \(fileName): \(error)")
                // Continue with next file
            }
        }
        
        try modelContext.save()
        Logger.success("Created \(totalCreated) cardio workouts from CSV files")
        
        // Debug: Verify created workouts by location
        let outdoorWorkouts = (try? modelContext.fetch(FetchDescriptor<CardioWorkout>(
            predicate: #Predicate<CardioWorkout> { $0.category == "outdoor" && !$0.isCustom }
        ))) ?? []
        let indoorWorkouts = (try? modelContext.fetch(FetchDescriptor<CardioWorkout>(
            predicate: #Predicate<CardioWorkout> { $0.category == "indoor" && !$0.isCustom }
        ))) ?? []
        let ergometerWorkouts = (try? modelContext.fetch(FetchDescriptor<CardioWorkout>(
            predicate: #Predicate<CardioWorkout> { $0.category == "ergometer" && !$0.isCustom }
        ))) ?? []
        
        Logger.info("Debug - Outdoor workouts: \(outdoorWorkouts.count)")
        Logger.info("Debug - Indoor workouts: \(indoorWorkouts.count)")
        Logger.info("Debug - Ergometer workouts: \(ergometerWorkouts.count)")
        
        for workout in outdoorWorkouts.prefix(2) {
            Logger.info("Debug - Outdoor workout: \(workout.name), category: \(workout.category), location: \(workout.location)")
        }
    }
    
    // MARK: - Helper Methods
    private static func parseEquipmentArray(_ equipmentString: String) -> [String] {
        // Parse JSON-like array string: ["outdoor", "treadmill"]
        let cleaned = equipmentString
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        if cleaned.isEmpty {
            return ["outdoor"] // Default equipment
        }
        
        return cleaned.components(separatedBy: ",").filter { !$0.isEmpty }
    }
}

// MARK: - JSON-Based Programs
extension DataSeeder {
    
    
    // MARK: - JSON Parsing Models for Lift Programs
    struct JSONLiftProgram: Codable {
        let metadata: JSONProgramMetadata
        let progression: JSONProgression
        let workouts: [JSONWorkout]
        let schedule: JSONSchedule
    }
    
    struct JSONProgramMetadata: Codable {
        let id: String
        let name: LocalizedString
        let description: LocalizedString
        let weeks: Int
        let daysPerWeek: Int
        let level: String
        let category: String
        let isCustom: Bool
        let author: String?
        let version: String
    }
    
    struct LocalizedString: Codable {
        let en: String
        let tr: String
    }
    
    struct JSONProgression: Codable {
        let type: String
        let increment: Double
        let unit: String
        let deloadThreshold: Int
        let deloadPercentage: Int
        let notes: LocalizedString
    }
    
    struct JSONWorkout: Codable {
        let id: String
        let name: LocalizedString
        let dayNumber: Int
        let estimatedDuration: Int
        let exercises: [JSONExercise]
    }
    
    struct JSONExercise: Codable {
        let id: String
        let exerciseName: String
        let exerciseNameTR: String
        let orderIndex: Int
        let targetSets: Int
        let targetReps: Int
        let targetWeight: Double?
        let restTime: Int
        let isWarmup: Bool
        let notes: LocalizedString
        let progression: JSONExerciseProgression
    }
    
    struct JSONExerciseProgression: Codable {
        let type: String
        let increment: Double
    }
    
    struct JSONSchedule: Codable {
        let pattern: String
        let restDays: Int
        let notes: LocalizedString
    }
    
    // MARK: - JSON Loading Functions
    @MainActor
    static func seedLiftProgramsFromJSONIfNeeded(modelContext: ModelContext) async throws {
        // Check if lift programs already exist
        let descriptor = FetchDescriptor<LiftProgram>(predicate: #Predicate<LiftProgram> { !$0.isCustom })
        let existingPrograms = (try? modelContext.fetch(descriptor)) ?? []
        
        if !existingPrograms.isEmpty {
            Logger.success("Lift programs already seeded: \(existingPrograms.count)")
            return
        }
        
        Logger.info("Loading lift programs from JSON files...")
        try await loadLiftProgramsFromJSON(modelContext: modelContext)
    }
    
    @MainActor
    private static func loadLiftProgramsFromJSON(modelContext: ModelContext) async throws {
        // Try different ways to find the LiftPrograms folder
        var programsURL: URL?
        
        Logger.info("Searching for LiftPrograms folder...")
        
        // First try: Look for specific JSON file to find the folder
        if let jsonURL = Bundle.main.url(forResource: "stronglifts5x5", withExtension: "json") {
            let parentURL = jsonURL.deletingLastPathComponent()
            Logger.info("Found stronglifts5x5.json at: \(jsonURL.path)")
            Logger.info("Parent directory: \(parentURL.path), name: \(parentURL.lastPathComponent)")
            programsURL = parentURL
        }
        
        // Second try: Use subdirectory parameter for new structure
        if programsURL == nil {
            if let url = Bundle.main.url(forResource: "", withExtension: nil, subdirectory: "Training/Programs/LiftPrograms") {
                Logger.info("Found LiftPrograms via subdirectory: \(url.path)")
                programsURL = url
            }
        }
        
        // Third try: Legacy subdirectory
        if programsURL == nil {
            if let url = Bundle.main.url(forResource: "", withExtension: nil, subdirectory: "LiftPrograms") {
                Logger.info("Found LiftPrograms via legacy path: \(url.path)")
                programsURL = url
            }
        }
        
        guard let finalURL = programsURL, 
              FileManager.default.fileExists(atPath: finalURL.path) else {
            throw DataSeederError.fileNotFound("LiftPrograms folder (checked Training/Programs/LiftPrograms and legacy locations)")
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: finalURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" }
            
            var loadedCount = 0
            var exerciseResolver = ExerciseResolver()
            
            for fileURL in fileURLs {
                if let program = try await loadSingleProgramFromJSON(
                    fileURL: fileURL, 
                    modelContext: modelContext,
                    exerciseResolver: &exerciseResolver
                ) {
                    modelContext.insert(program)
                    loadedCount += 1
                    Logger.info("Loaded program: \(program.localizedName)")
                }
            }
            
            try modelContext.save()
            Logger.success("Successfully loaded \(loadedCount) lift programs from JSON")
            
        } catch {
            Logger.error("Failed to load lift programs from JSON: \(error)")
            throw error
        }
    }
    
    @MainActor
    private static func loadSingleProgramFromJSON(
        fileURL: URL, 
        modelContext: ModelContext,
        exerciseResolver: inout ExerciseResolver
    ) async throws -> LiftProgram? {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonProgram = try JSONDecoder().decode(JSONLiftProgram.self, from: data)
            
            // Create LiftProgram from JSON
            let program = LiftProgram(
                name: jsonProgram.metadata.name.en,
                nameEN: jsonProgram.metadata.name.en,
                nameTR: jsonProgram.metadata.name.tr,
                description: jsonProgram.metadata.description.en,
                descriptionEN: jsonProgram.metadata.description.en,
                descriptionTR: jsonProgram.metadata.description.tr,
                weeks: jsonProgram.metadata.weeks,
                daysPerWeek: jsonProgram.metadata.daysPerWeek,
                level: jsonProgram.metadata.level,
                category: jsonProgram.metadata.category,
                isCustom: jsonProgram.metadata.isCustom
            )
            
            // Create workouts from JSON
            for jsonWorkout in jsonProgram.workouts {
                let workout = LiftWorkout(
                    name: jsonWorkout.name.en,
                    nameEN: jsonWorkout.name.en,
                    nameTR: jsonWorkout.name.tr,
                    dayNumber: jsonWorkout.dayNumber,
                    estimatedDuration: jsonWorkout.estimatedDuration,
                    isTemplate: false, // Program workout'ları template değil
                    isCustom: false
                )
                
                // Create exercises from JSON with proper ID resolution
                for jsonExercise in jsonWorkout.exercises {
                    // Try to resolve the exercise ID from the database
                    let exerciseID = exerciseResolver.resolveExerciseID(
                        name: jsonExercise.exerciseName, 
                        modelContext: modelContext
                    )
                    
                    let exercise = LiftExercise(
                        exerciseId: exerciseID ?? UUID(), // Fallback to UUID if not found
                        exerciseName: jsonExercise.exerciseName,
                        orderIndex: jsonExercise.orderIndex,
                        targetSets: jsonExercise.targetSets,
                        targetReps: jsonExercise.targetReps,
                        targetWeight: jsonExercise.targetWeight,
                        restTime: jsonExercise.restTime,
                        isWarmup: jsonExercise.isWarmup
                    )
                    
                    workout.addExercise(exercise)
                }
                
                program.addWorkout(workout)
            }
            
            return program
            
        } catch {
            Logger.warning("Skipping JSON file \(fileURL.lastPathComponent) - invalid format: \(error)")
            return nil
        }
    }
    
    // MARK: - Routine Template Seeding
    @MainActor
    static func seedRoutineTemplatesIfNeeded(modelContext: ModelContext) async throws {
        // Check if routine templates already exist
        let descriptor = FetchDescriptor<LiftWorkout>(
            predicate: #Predicate<LiftWorkout> { $0.isTemplate && !$0.isCustom }
        )
        let existingTemplates = (try? modelContext.fetch(descriptor)) ?? []
        
        if !existingTemplates.isEmpty {
            Logger.success("Routine templates already present: \(existingTemplates.count)")
            return
        }
        
        Logger.info("Loading routine templates from JSON...")
        try await loadRoutineTemplatesFromJSON(modelContext: modelContext)
    }
    
    @MainActor
    private static func loadRoutineTemplatesFromJSON(modelContext: ModelContext) async throws {
        do {
            let routineData = try CSVParser.parseJSONFile("lift_routines", as: RoutineTemplateData.self)
            var createdCount = 0
            var exerciseResolver = ExerciseResolver()
            
            for template in routineData.templates {
                if let workout = try await createWorkoutFromTemplate(
                    template, 
                    modelContext: modelContext,
                    exerciseResolver: &exerciseResolver
                ) {
                    modelContext.insert(workout)
                    createdCount += 1
                }
            }
            
            try modelContext.save()
            Logger.success("Created \(createdCount) routine templates")
            
        } catch {
            Logger.error("Failed to parse routine templates JSON: \(error)")
            throw error
        }
    }
    
    @MainActor
    private static func createWorkoutFromTemplate(
        _ template: RoutineTemplate, 
        modelContext: ModelContext,
        exerciseResolver: inout ExerciseResolver
    ) async throws -> LiftWorkout? {
        let workout = LiftWorkout(
            name: template.name,
            nameEN: template.nameEN,
            nameTR: template.nameTR,
            estimatedDuration: template.estimatedDuration,
            isTemplate: true,
            isCustom: false
        )
        
        // Get all available exercises from database
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let availableExercises = (try? modelContext.fetch(exerciseDescriptor)) ?? []
        
        // Handle duplicate exercise names by taking the first occurrence
        let exerciseGroups = Dictionary(grouping: availableExercises, by: { $0.nameEN })
        let exerciseDict = exerciseGroups.compactMapValues { exercises in
            // If there are duplicates, take the first one
            exercises.first
        }
        
        for (index, exerciseName) in template.exercises.enumerated() {
            // Try to find the exercise in the database
            if let exercise = exerciseDict[exerciseName] {
                let liftExercise = LiftExercise(
                    exerciseId: exercise.id,
                    exerciseName: exercise.nameEN,
                    orderIndex: index
                )
                workout.addExercise(liftExercise)
            } else {
                // If not found, try to resolve by name
                if let exerciseID = exerciseResolver.resolveExerciseID(
                    name: exerciseName, 
                    modelContext: modelContext
                ) {
                    let liftExercise = LiftExercise(
                        exerciseId: exerciseID,
                        exerciseName: exerciseName,
                        orderIndex: index
                    )
                    workout.addExercise(liftExercise)
                } else {
                    Logger.warning("Exercise '\(exerciseName)' not found in database for template '\(template.name)'")
                    continue
                }
            }
        }
        
        return workout.exercises.isEmpty ? nil : workout
    }
    
}

// MARK: - Routine Template JSON Models
private struct RoutineTemplateData: Codable {
    let templates: [RoutineTemplate]
}

private struct RoutineTemplate: Codable {
    let id: String
    let name: String
    let nameEN: String
    let nameTR: String
    let nameES: String?
    let nameDE: String?
    let category: String
    let estimatedDuration: Int
    let isTemplate: Bool
    let isCustom: Bool
    let exercises: [String]
}
