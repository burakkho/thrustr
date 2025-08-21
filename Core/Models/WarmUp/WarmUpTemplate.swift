import Foundation
import SwiftData

// MARK: - WarmUp Template Model
@Model
final class WarmUpTemplate {
    var id: UUID
    var name: String
    var nameEN: String
    var nameTR: String
    var templateDescription: String
    var category: String // "general", "upper", "lower", "dynamic", "recovery"
    var estimatedDuration: Int // in seconds
    var difficulty: String // "beginner", "intermediate", "advanced"
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Exercise IDs for this template (stored as JSON)
    var exerciseIds: [UUID]
    var exerciseInstructions: String? // JSON with exercise-specific instructions
    
    // Relationships
    var sessions: [WarmUpSession]
    
    init(
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        description: String = "",
        category: String = "general",
        estimatedDuration: Int = 300, // 5 minutes default
        difficulty: String = "beginner",
        exerciseIds: [UUID] = [],
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN ?? name
        self.nameTR = nameTR ?? name
        self.templateDescription = description
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.exerciseIds = exerciseIds
        self.exerciseInstructions = nil
        self.isCustom = isCustom
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sessions = []
    }
}

// MARK: - Computed Properties
extension WarmUpTemplate {
    var localizedName: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "tr": return nameTR.isEmpty ? nameEN : nameTR
        default: return nameEN.isEmpty ? name : nameEN
        }
    }
    
    var formattedDuration: String {
        let minutes = estimatedDuration / 60
        let seconds = estimatedDuration % 60
        
        if minutes > 0 && seconds > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(seconds)s"
        }
    }
    
    var categoryEnum: WarmUpCategory {
        WarmUpCategory(rawValue: category) ?? .general
    }
    
    var difficultyEnum: WarmUpDifficulty {
        WarmUpDifficulty(rawValue: difficulty) ?? .beginner
    }
    
    var totalExercises: Int {
        exerciseIds.count
    }
    
    var lastPerformed: Date? {
        sessions
            .filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
            .first?.startDate
    }
    
    var totalSessions: Int {
        sessions.filter { $0.isCompleted }.count
    }
}

// MARK: - Methods
extension WarmUpTemplate {
    func addExercise(exerciseId: UUID) {
        if !exerciseIds.contains(exerciseId) {
            exerciseIds.append(exerciseId)
            updatedAt = Date()
        }
    }
    
    func removeExercise(exerciseId: UUID) {
        exerciseIds.removeAll { $0 == exerciseId }
        updatedAt = Date()
    }
    
    func startSession(for user: User) -> WarmUpSession {
        let session = WarmUpSession(template: self, user: user)
        sessions.append(session)
        return session
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
    
    func duplicate() -> WarmUpTemplate {
        let copy = WarmUpTemplate(
            name: "\(name) (Copy)",
            nameEN: "\(nameEN) (Copy)",
            nameTR: "\(nameTR) (Kopya)",
            description: templateDescription,
            category: category,
            estimatedDuration: estimatedDuration,
            difficulty: difficulty,
            exerciseIds: exerciseIds,
            isCustom: true
        )
        return copy
    }
}

// MARK: - WarmUp Categories
enum WarmUpCategory: String, CaseIterable {
    case general = "general"
    case upper = "upper"
    case lower = "lower"
    case dynamic = "dynamic"
    case recovery = "recovery"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .dynamic: return "Dynamic"
        case .recovery: return "Recovery"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "figure.walk"
        case .upper: return "figure.arms.open"
        case .lower: return "figure.run"
        case .dynamic: return "bolt.fill"
        case .recovery: return "leaf.fill"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "blue"
        case .upper: return "orange"
        case .lower: return "green"
        case .dynamic: return "red"
        case .recovery: return "purple"
        }
    }
}

// MARK: - WarmUp Difficulty
enum WarmUpDifficulty: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}