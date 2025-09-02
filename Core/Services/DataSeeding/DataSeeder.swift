import SwiftData
import Foundation

// MARK: - Temporary placeholders (to be moved to separate files)
class ExerciseSeeder {
    @MainActor
    static func seedExercises(modelContext: ModelContext) async throws {
        Logger.info("Starting exercise seeding...")
        
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = try modelContext.fetchCount(descriptor)
        if existingCount > 0 {
            Logger.info("Exercises already seeded (\(existingCount) found), skipping")
            return
        }
        
        var totalSeeded = 0
        
        // Seed lift exercises
        do {
            let liftRows = try CSVParser.parseCSVFile("lift_exercises")
            totalSeeded += try await seedLiftExercises(rows: liftRows, modelContext: modelContext)
        } catch {
            Logger.error("Failed to parse lift_exercises.csv: \(error)")
            throw DataSeederError.parsingError("lift_exercises.csv: \(error.localizedDescription)")
        }
        
        
        // Save all exercises
        try modelContext.save()
        Logger.success("✅ Seeded \(totalSeeded) exercises")
    }
    
    @MainActor
    private static func seedLiftExercises(rows: [[String]], modelContext: ModelContext) async throws -> Int {
        guard rows.count > 1 else {
            throw DataSeederError.emptyFile("lift_exercises.csv")
        }
        
        // Expected: nameEN,nameTR,category,equipment,supportsWeight,supportsReps,supportsTime,supportsDistance
        let dataRows = Array(rows.dropFirst())
        var seededCount = 0
        
        for (index, row) in dataRows.enumerated() {
            guard row.count >= 8 else {
                Logger.warning("Skipping invalid lift exercise row \(index): insufficient columns")
                continue
            }
            
            // Create exercise with model-compatible constructor
            let exercise = Exercise(
                nameEN: row[0].trimmingCharacters(in: .whitespacesAndNewlines),
                nameTR: row[1].trimmingCharacters(in: .whitespacesAndNewlines),
                category: row[2].trimmingCharacters(in: .whitespacesAndNewlines),
                equipment: row[3].trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Set support flags from CSV
            exercise.supportsWeight = row[4].lowercased() == "true"
            exercise.supportsReps = row[5].lowercased() == "true"
            exercise.supportsTime = row[6].lowercased() == "true"
            exercise.supportsDistance = row[7].lowercased() == "true"
            
            modelContext.insert(exercise)
            seededCount += 1
            
            // Yield control periodically
            if seededCount % SeedingConfig.yieldInterval == 0 {
                await Task.yield()
            }
        }
        
        Logger.info("Seeded \(seededCount) lift exercises")
        return seededCount
    }
    
}

class CrossFitMovementSeeder {
    @MainActor
    static func seedCrossFitMovements(modelContext: ModelContext) async throws {
        Logger.info("Starting CrossFit movements seeding...")
        
        // Check if CrossFit movements already exist
        let descriptor = FetchDescriptor<CrossFitMovement>()
        let existingCount = try modelContext.fetchCount(descriptor)
        if existingCount > 0 {
            Logger.info("CrossFit movements already seeded (\(existingCount) found), skipping")
            return
        }
        
        // Parse metcon_exercises.csv
        let rows = try CSVParser.parseCSVFile("metcon_exercises")
        guard rows.count > 1 else {
            throw DataSeederError.emptyFile("metcon_exercises.csv")
        }
        
        // Expected: nameEN,nameTR,category,equipment,rxWeightMale,rxWeightFemale,supportsWeight,supportsReps,supportsTime,supportsDistance,wodSuitability,instructions,scalingNotes
        let dataRows = Array(rows.dropFirst())
        var seededCount = 0
        
        for (index, row) in dataRows.enumerated() {
            guard row.count >= 13 else {
                Logger.warning("Skipping invalid metcon exercise row \(index): insufficient columns")
                continue
            }
            
            // Create CrossFitMovement with all properties
            let movement = CrossFitMovement(
                nameEN: row[0].trimmingCharacters(in: .whitespacesAndNewlines),
                nameTR: row[1].trimmingCharacters(in: .whitespacesAndNewlines),
                category: row[2].trimmingCharacters(in: .whitespacesAndNewlines),
                equipment: row[3].trimmingCharacters(in: .whitespacesAndNewlines),
                rxWeightMale: row[4].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : row[4].trimmingCharacters(in: .whitespacesAndNewlines),
                rxWeightFemale: row[5].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : row[5].trimmingCharacters(in: .whitespacesAndNewlines),
                supportsWeight: row[6].lowercased() == "true",
                supportsReps: row[7].lowercased() == "true",
                supportsTime: row[8].lowercased() == "true",
                supportsDistance: row[9].lowercased() == "true",
                wodSuitability: Int(row[10].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10,
                instructions: row[11].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : row[11].trimmingCharacters(in: .whitespacesAndNewlines),
                scalingNotes: row[12].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : row[12].trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            modelContext.insert(movement)
            seededCount += 1
            
            // Yield control periodically
            if seededCount % SeedingConfig.yieldInterval == 0 {
                await Task.yield()
            }
        }
        
        try modelContext.save()
        Logger.success("✅ Seeded \(seededCount) CrossFit movements")
    }
}

class BenchmarkWODSeeder {
    @MainActor
    static func seedBenchmarkWODs(modelContext: ModelContext) async throws {
        Logger.info("Starting benchmark WODs seeding...")
        
        // Check if WODs already exist
        let descriptor = FetchDescriptor<WOD>(predicate: #Predicate<WOD> { $0.isCustom == false })
        let existingCount = try modelContext.fetchCount(descriptor)
        if existingCount > 0 {
            Logger.info("Benchmark WODs already seeded (\(existingCount) found), skipping")
            return
        }
        
        // Parse benchmark_wods.csv
        let rows = try CSVParser.parseCSVFile("benchmark_wods")
        guard rows.count > 1 else {
            throw DataSeederError.emptyFile("benchmark_wods.csv")
        }
        
        // Expected: name,nameEN,nameTR,type,category,description,descriptionTR,timeCap,rounds,movement1,rxMale1,rxFemale1,reps1,movement2,rxMale2,rxFemale2,reps2,movement3,rxMale3,rxFemale3,reps3,movement4,rxMale4,rxFemale4,reps4,repScheme
        let dataRows = Array(rows.dropFirst())
        var seededCount = 0
        
        for (index, row) in dataRows.enumerated() {
            guard row.count >= 8 else {
                Logger.warning("Skipping invalid WOD row \(index): insufficient columns (\(row.count))")
                continue
            }
            
            // Pad row to ensure we have at least 26 columns for safe indexing
            let paddedRow = row + Array(repeating: "", count: max(0, 26 - row.count))
            
            // Parse basic WOD info
            let name = paddedRow[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let typeString = paddedRow[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let category = paddedRow[4].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse optional fields
            let timeCap = Int(paddedRow[7].trimmingCharacters(in: .whitespacesAndNewlines)) 
            let rounds = Int(paddedRow[8].trimmingCharacters(in: .whitespacesAndNewlines))
            let repSchemeString = paddedRow[25].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse repScheme
            var repScheme: [Int] = []
            if !repSchemeString.isEmpty {
                repScheme = repSchemeString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            
            // Create WOD type
            let wodType: WODType = {
                switch typeString {
                case "for_time": return .forTime
                case "amrap": return .amrap
                case "emom": return .emom
                default: return .forTime
                }
            }()
            
            // Create WOD
            let wod = WOD(
                name: name,
                type: wodType,
                category: category,
                repScheme: repScheme,
                timeCap: timeCap,
                rounds: rounds,
                isCustom: false
            )
            
            modelContext.insert(wod)
            
            // Parse and create movements
            let movementColumns = [
                (9, 10, 11, 12),   // movement1, rxMale1, rxFemale1, reps1
                (13, 14, 15, 16),  // movement2, rxMale2, rxFemale2, reps2
                (17, 18, 19, 20),  // movement3, rxMale3, rxFemale3, reps3
                (21, 22, 23, 24)   // movement4, rxMale4, rxFemale4, reps4
            ]
            
            for (orderIndex, columns) in movementColumns.enumerated() {
                let (nameCol, rxMaleCol, rxFemaleCol, repsCol) = columns
                let movementName = paddedRow[nameCol].trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !movementName.isEmpty else { continue }
                
                let rxMale = paddedRow[rxMaleCol].trimmingCharacters(in: .whitespacesAndNewlines)
                let rxFemale = paddedRow[rxFemaleCol].trimmingCharacters(in: .whitespacesAndNewlines)
                let repsString = paddedRow[repsCol].trimmingCharacters(in: .whitespacesAndNewlines)
                
                let movement = WODMovement(
                    name: movementName,
                    rxWeightMale: rxMale.isEmpty ? nil : rxMale,
                    rxWeightFemale: rxFemale.isEmpty ? nil : rxFemale,
                    reps: Int(repsString),
                    orderIndex: orderIndex
                )
                
                movement.wod = wod
                wod.movements.append(movement)
                modelContext.insert(movement)
            }
            
            seededCount += 1
            
            // Yield control periodically
            if seededCount % SeedingConfig.yieldInterval == 0 {
                await Task.yield()
            }
        }
        
        try modelContext.save()
        Logger.success("✅ Seeded \(seededCount) benchmark WODs")
    }
}

class FoodSeeder {
    @MainActor
    static func seedFoods(modelContext: ModelContext) async throws {
        Logger.info("Starting foods seeding...")
        
        // Check if foods already exist
        let descriptor = FetchDescriptor<Food>()
        let existingCount = try modelContext.fetchCount(descriptor)
        if existingCount > 0 {
            Logger.info("Foods already seeded (\(existingCount) found), skipping")
            return
        }
        
        // Parse foods.csv
        let rows = try CSVParser.parseCSVFile("foods")
        guard rows.count > 1 else {
            throw DataSeederError.emptyFile("foods.csv")
        }
        
        // Expected: nameEN,nameTR,brand,calories,protein,carbs,fat,category,servingSizeGrams,servingName
        let dataRows = Array(rows.dropFirst())
        var seededCount = 0
        
        // OPTIMIZED: Process foods in smaller batches for faster UI feedback
        var batchCount = 0
        let batchSize = 25 // Smaller batches for faster initial response
        
        for (index, row) in dataRows.enumerated() {
            guard row.count >= 10 else {
                Logger.warning("Skipping invalid food row \(index): insufficient columns (\(row.count))")
                continue
            }
            
            // Parse basic food data
            let nameEN = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let nameTR = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let brand = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let calories = Double(row[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let protein = Double(row[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let carbs = Double(row[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let fat = Double(row[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let categoryString = row[7].trimmingCharacters(in: .whitespacesAndNewlines)
            let servingSizeString = row[8].trimmingCharacters(in: .whitespacesAndNewlines)
            let servingName = row[9].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse category
            let category: FoodCategory = {
                switch categoryString.lowercased() {
                case "meat": return .meat
                case "dairy": return .dairy
                case "vegetables", "vegetable": return .vegetables
                case "fruits", "fruit": return .fruits
                case "grains", "grain": return .grains
                case "nuts", "nut": return .nuts
                case "seafood": return .seafood
                case "beverages", "beverage": return .beverages
                case "snacks", "snack": return .snacks
                case "desserts", "sweet": return .desserts
                case "condiments", "condiment": return .condiments
                default: return .other
                }
            }()
            
            // Create Food
            let food = Food(
                nameEN: nameEN,
                nameTR: nameTR,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                category: category
            )
            
            // Set optional fields
            if !brand.isEmpty {
                food.brand = brand
            }
            
            if let servingSize = Double(servingSizeString), servingSize > 0 {
                food.servingSizeGrams = servingSize
            }
            
            if !servingName.isEmpty {
                food.servingName = servingName
            }
            
            // Set source as CSV
            food.source = .csv
            food.isVerified = true
            
            modelContext.insert(food)
            seededCount += 1
            batchCount += 1
            
            // PERFORMANCE: Save in smaller batches for faster UI updates
            if batchCount >= batchSize {
                try modelContext.save()
                batchCount = 0
                await Task.yield() // Allow UI to update
                Logger.info("Seeded \(seededCount) foods so far...")
            }
            
            // Yield control periodically for responsiveness
            if seededCount % SeedingConfig.yieldInterval == 0 {
                await Task.yield()
            }
        }
        
        // Save remaining items
        if batchCount > 0 {
            try modelContext.save()
        }
        
        Logger.success("✅ Seeded \(seededCount) foods")
    }
    
    @MainActor
    static func seedFoodAliasesIfNeeded(modelContext: ModelContext) async {
        // TODO: Implement - placeholder for now
        Logger.info("FoodAliases: Not implemented yet")
    }
}

class CardioSeeder {
    @MainActor
    static func seedCardioExercises(modelContext: ModelContext) async throws {
        Logger.info("Starting cardio workouts seeding...")
        
        // Check if cardio workouts already exist
        let descriptor = FetchDescriptor<CardioWorkout>()
        let existingCount = try modelContext.fetchCount(descriptor)
        if existingCount > 0 {
            Logger.info("Cardio workouts already seeded (\(existingCount) found), skipping")
            return
        }
        
        var totalSeeded = 0
        
        // Seed indoor cardio exercises
        do {
            let rows = try CSVParser.parseCSVFile("indoor_cardio")
            totalSeeded += try await seedCardioFromCSV(rows: rows, modelContext: modelContext, csvType: "indoor")
        } catch {
            Logger.warning("Failed to parse indoor_cardio.csv: \(error)")
        }
        
        // Seed outdoor cardio exercises
        do {
            let rows = try CSVParser.parseCSVFile("outdoor_cardio")
            totalSeeded += try await seedCardioFromCSV(rows: rows, modelContext: modelContext, csvType: "outdoor")
        } catch {
            Logger.warning("Failed to parse outdoor_cardio.csv: \(error)")
        }
        
        // Seed ergo cardio exercises
        do {
            let rows = try CSVParser.parseCSVFile("ergo_cardio")
            totalSeeded += try await seedCardioFromCSV(rows: rows, modelContext: modelContext, csvType: "ergo")
        } catch {
            Logger.warning("Failed to parse ergo_cardio.csv: \(error)")
        }
        
        if totalSeeded > 0 {
            try modelContext.save()
            Logger.success("✅ Seeded \(totalSeeded) cardio workouts")
        }
    }
    
    @MainActor
    private static func seedCardioFromCSV(rows: [[String]], modelContext: ModelContext, csvType: String) async throws -> Int {
        guard rows.count > 1 else {
            Logger.warning("Empty \(csvType)_cardio.csv file")
            return 0
        }
        
        // Expected: name,nameEN,nameTR,nameES,nameDE,equipment,exerciseType,met,descriptionTR,descriptionES,descriptionDE
        let dataRows = Array(rows.dropFirst())
        var seededCount = 0
        
        for (index, row) in dataRows.enumerated() {
            guard row.count >= 11 else {
                Logger.warning("Skipping invalid cardio row \(index): insufficient columns (\(row.count))")
                continue
            }
            
            let nameEN = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let nameTR = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let equipment = row[5].trimmingCharacters(in: .whitespacesAndNewlines)
            let exerciseType = row[6].trimmingCharacters(in: .whitespacesAndNewlines)
            let descriptionTR = row[8].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create CardioWorkout template
            let category: String = {
                switch csvType {
                case "outdoor": return "outdoor"
                case "ergo": return "ergometer"
                default: return "indoor"
                }
            }()
            
            let cardioWorkout = CardioWorkout(
                name: !nameTR.isEmpty ? nameTR : nameEN,
                nameEN: nameEN,
                nameTR: nameTR,
                type: exerciseType,
                category: category,
                description: !descriptionTR.isEmpty ? descriptionTR : "",
                descriptionTR: !descriptionTR.isEmpty ? descriptionTR : "",
                equipment: [equipment],
                isTemplate: true,
                isCustom: false
            )
            
            modelContext.insert(cardioWorkout)
            seededCount += 1
            
            // Yield control periodically
            if seededCount % SeedingConfig.yieldInterval == 0 {
                await Task.yield()
            }
        }
        
        Logger.info("Seeded \(seededCount) \(csvType) cardio workouts")
        return seededCount
    }
}

// MARK: - Placeholder classes for future implementation
class LiftProgramSeeder {
    @MainActor
    static func seedLiftPrograms(modelContext: ModelContext) async throws {
        // Check if lift programs already exist
        let descriptor = FetchDescriptor<LiftProgram>()
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
                nameDE: jsonProgram.metadata.name.de,
                nameES: jsonProgram.metadata.name.es,
                nameIT: jsonProgram.metadata.name.it,
                description: jsonProgram.metadata.description.en,
                descriptionEN: jsonProgram.metadata.description.en,
                descriptionTR: jsonProgram.metadata.description.tr,
                descriptionDE: jsonProgram.metadata.description.de,
                descriptionES: jsonProgram.metadata.description.es,
                descriptionIT: jsonProgram.metadata.description.it,
                weeks: jsonProgram.metadata.weeks,
                daysPerWeek: jsonProgram.metadata.daysPerWeek,
                level: jsonProgram.metadata.level,
                category: jsonProgram.metadata.category
            )
            
            // Create workouts from JSON
            for jsonWorkout in jsonProgram.workouts {
                let workout = LiftWorkout(
                    name: jsonWorkout.name.en,
                    nameEN: jsonWorkout.name.en,
                    nameTR: jsonWorkout.name.tr,
                    dayNumber: jsonWorkout.dayNumber,
                    estimatedDuration: jsonWorkout.estimatedDuration,
                    isTemplate: false,
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
                        exerciseId: exerciseID ?? UUID(),
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
    
    // MARK: - JSON Parsing Models for Lift Programs
    private struct JSONLiftProgram: Codable {
        let metadata: JSONProgramMetadata
        let progression: JSONProgression
        let workouts: [JSONWorkout]
        let schedule: JSONSchedule
    }
    
    private struct JSONProgramMetadata: Codable {
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
    
    private struct LocalizedString: Codable {
        let en: String
        let tr: String
        let de: String?
        let es: String?
        let it: String?
    }
    
    private struct JSONProgression: Codable {
        let type: String
        let increment: Double
        let unit: String
        let deloadThreshold: Int
        let deloadPercentage: Int
        let notes: LocalizedString
    }
    
    private struct JSONWorkout: Codable {
        let id: String
        let name: LocalizedString
        let dayNumber: Int
        let estimatedDuration: Int
        let exercises: [JSONExercise]
    }
    
    private struct JSONExercise: Codable {
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
    
    private struct JSONExerciseProgression: Codable {
        let type: String
        let increment: Double
    }
    
    private struct JSONSchedule: Codable {
        let pattern: String
        let restDays: Int
        let notes: LocalizedString
    }
}

class LiftRoutineSeeder {
    @MainActor
    static func seedLiftRoutines(modelContext: ModelContext) async throws {
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
            guard let fileURL = Bundle.main.url(forResource: "lift_routines", withExtension: "json") else {
                throw DataSeederError.fileNotFound("lift_routines.json")
            }
            
            let data = try Data(contentsOf: fileURL)
            let routineData = try JSONDecoder().decode(RoutineTemplateData.self, from: data)
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
    
    // MARK: - JSON Parsing Models for Routines
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
}

class DataNormalizer {
    @MainActor
    static func normalizeDataAfterSeeding(modelContext: ModelContext) async {
        // TODO: Implement - placeholder for now
        Logger.info("DataNormalizer: Not implemented yet")
    }
}

/**
 * Database seeding service that populates the app with initial data.
 * 
 * This service coordinates the initial database population with exercises, foods, benchmark WODs,
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
 */
class DataSeeder {
    
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
                
                // PRIORITY: Seed foods first for immediate nutrition functionality
                do {
                    await progressCallback?(.foods)
                    try await FoodSeeder.seedFoods(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed foods: \(error)")
                    await progressCallback?(.error("Failed to load foods: \(error.localizedDescription)"))
                    throw error
                }
                
                // Then seed exercises
                do {
                    await progressCallback?(.exercises)
                    try await ExerciseSeeder.seedExercises(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed exercises: \(error)")
                    await progressCallback?(.error("Failed to load exercises: \(error.localizedDescription)"))
                    throw error
                }
                
                // Secondary data seeding - sequential
                do {
                    await progressCallback?(.benchmarkWODs)
                    try await BenchmarkWODSeeder.seedBenchmarkWODs(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed benchmark WODs: \(error)")
                    // Continue with other seeding - not critical
                }
                
                do {
                    await progressCallback?(.crossFitMovements)
                    try await CrossFitMovementSeeder.seedCrossFitMovements(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed CrossFit movements: \(error)")
                    // Continue with other seeding - not critical for basic functionality
                }
                
                do {
                    await progressCallback?(.cardioExercises)
                    try await CardioSeeder.seedCardioExercises(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed cardio exercises: \(error)")
                    // Continue with other seeding - not critical for basic functionality
                }
                
                // JSON-based data seeding - sequential
                do {
                    await progressCallback?(.liftPrograms)
                    try await LiftProgramSeeder.seedLiftPrograms(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed lift programs: \(error)")
                    // Continue with other seeding - not implemented yet
                }
                
                do {
                    await progressCallback?(.routineTemplates)
                    try await LiftRoutineSeeder.seedLiftRoutines(modelContext: modelContext)
                    await Task.yield() // Keep UI responsive
                } catch {
                    Logger.error("Failed to seed lift routines: \(error)")
                    // Continue with other seeding - not implemented yet
                }
                
                // Normalization - after all data is seeded
                await progressCallback?(.normalization)
                await DataNormalizer.normalizeDataAfterSeeding(modelContext: modelContext)
                
                // Food aliases - depends on foods being seeded
                await progressCallback?(.foodAliases)
                await FoodSeeder.seedFoodAliasesIfNeeded(modelContext: modelContext)
                
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
            Logger.info("Database contains data, checking individual components...")
            
            // Even if database is not empty, check and seed missing components
            await seedMissingDataComponents(modelContext: modelContext, progressCallback: progressCallback)
            
            await progressCallback?(.completed)
            Logger.success("Database check completed")
        }
    }
    
    /// Seed missing data components individually
    @MainActor
    private static func seedMissingDataComponents(modelContext: ModelContext, progressCallback: ProgressCallback? = nil) async {
        // Check and seed CrossFit movements if missing
        let crossfitMovementCount = (try? modelContext.fetchCount(FetchDescriptor<CrossFitMovement>())) ?? 0
        if crossfitMovementCount == 0 {
            do {
                await progressCallback?(.crossFitMovements)
                try await CrossFitMovementSeeder.seedCrossFitMovements(modelContext: modelContext)
                Logger.success("Seeded missing CrossFit movements")
            } catch {
                Logger.error("Failed to seed missing CrossFit movements: \(error)")
            }
        }
        
        // Check and seed benchmark WODs if missing
        let benchmarkWODCount = (try? modelContext.fetchCount(FetchDescriptor<WOD>(predicate: #Predicate<WOD> { $0.isCustom == false }))) ?? 0
        if benchmarkWODCount == 0 {
            do {
                await progressCallback?(.benchmarkWODs)
                try await BenchmarkWODSeeder.seedBenchmarkWODs(modelContext: modelContext)
                Logger.success("Seeded missing benchmark WODs")
            } catch {
                Logger.error("Failed to seed missing benchmark WODs: \(error)")
            }
        }
        
        // Check and seed cardio exercises if missing  
        let cardioWorkoutCount = (try? modelContext.fetchCount(FetchDescriptor<CardioWorkout>())) ?? 0
        if cardioWorkoutCount == 0 {
            do {
                await progressCallback?(.cardioExercises)
                try await CardioSeeder.seedCardioExercises(modelContext: modelContext)
                Logger.success("Seeded missing cardio exercises")
            } catch {
                Logger.error("Failed to seed missing cardio exercises: \(error)")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Check if database is missing critical data
    @MainActor
    private static func isDatabaseEmpty(modelContext: ModelContext) async -> Bool {
        // Check all critical models
        let exerciseCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        let foodCount = (try? modelContext.fetchCount(FetchDescriptor<Food>())) ?? 0
        let crossfitMovementCount = (try? modelContext.fetchCount(FetchDescriptor<CrossFitMovement>())) ?? 0
        let benchmarkWODCount = (try? modelContext.fetchCount(FetchDescriptor<WOD>(predicate: #Predicate<WOD> { $0.isCustom == false }))) ?? 0
        
        // If any critical data is missing, we need seeding
        let isEmpty = exerciseCount == 0 || foodCount == 0 || crossfitMovementCount == 0 || benchmarkWODCount == 0
        
        Logger.info("Database status - Exercises: \(exerciseCount), Foods: \(foodCount), CrossFit Movements: \(crossfitMovementCount), Benchmark WODs: \(benchmarkWODCount)")
        
        return isEmpty
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