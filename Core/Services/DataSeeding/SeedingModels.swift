import SwiftUI
import SwiftData
import Foundation

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

// MARK: - Seeding Configuration
struct SeedingConfig {
    static let batchSize = 50
    static let maxRetries = 3
    static let yieldInterval = 25
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
    let de: String?
    let es: String?
    let it: String?
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

// MARK: - Routine Template JSON Models
struct RoutineTemplateData: Codable {
    let templates: [RoutineTemplate]
}

struct RoutineTemplate: Codable {
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

// MARK: - Exercise Resolver
struct ExerciseResolver {
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