import Foundation
import SwiftUI
import SwiftData

// MARK: - WeightEntry Model (Enhanced)
@Model
final class WeightEntry {
    var id: UUID
    var weight: Double // kg
    var date: Date
    var notes: String?
    var createdAt: Date
    
    // Enhanced Properties
    var bodyFat: Double? // Body fat percentage
    var muscleMass: Double? // Muscle mass in kg
    var mood: String? // How user felt
    var energyLevel: Int? // 1-10 scale
    
    // Relationships
    var user: User?
    
    init(weight: Double, date: Date, notes: String? = nil, bodyFat: Double? = nil, muscleMass: Double? = nil, mood: String? = nil, energyLevel: Int? = nil) {
        self.id = UUID()
        self.weight = weight
        self.date = date
        self.notes = notes
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
        self.mood = mood
        self.energyLevel = energyLevel
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Calculate BMI if user height available
    var bmi: Double? {
        guard let user = user, user.height > 0 else { return nil }
        let heightInMeters = user.height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    /// BMI Category
    var bmiCategory: String? {
        guard let bmi = bmi else { return nil }
        
        switch bmi {
        case ..<18.5: return "bmi_underweight".localized
        case 18.5..<25: return "bmi_normal".localized
        case 25..<30: return "bmi_overweight".localized
        case 30...: return "bmi_obese".localized
        default: return "bmi_unknown".localized
        }
    }
    
    /// Display date string
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    /// BMI color indicator
    var bmiColor: Color {
        guard let bmi = bmi else { return .gray }
        
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .yellow
        case 30...: return .red
        default: return .gray
        }
    }
}

// MARK: - BodyMeasurement Model (Enhanced)
@Model
final class BodyMeasurement {
    var id: UUID
    var type: String
    var value: Double // cm
    var date: Date
    var notes: String?
    var createdAt: Date
    
    // Enhanced Properties
    var leftValue: Double? // For paired measurements (left arm, left leg)
    var rightValue: Double? // For paired measurements
    var isSymmetrical: Bool // Whether left/right should be same
    
    // Relationships
    var user: User?
    
    init(type: String, value: Double, date: Date, notes: String? = nil, leftValue: Double? = nil, rightValue: Double? = nil) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.date = date
        self.notes = notes
        self.leftValue = leftValue
        self.rightValue = rightValue
        self.isSymmetrical = MeasurementType(rawValue: type)?.isSymmetrical ?? false
        self.createdAt = Date()
    }
    
    var typeEnum: MeasurementType {
        MeasurementType(rawValue: type) ?? .chest
    }
    
    // MARK: - Computed Properties
    
    /// Average value for paired measurements
    var averageValue: Double {
        if let left = leftValue, let right = rightValue {
            return (left + right) / 2
        }
        return value
    }
    
    /// Check if measurement is paired (has left/right)
    var isPaired: Bool {
        return leftValue != nil && rightValue != nil
    }
    
    /// Symmetry percentage for paired measurements
    var symmetryPercentage: Double? {
        guard let left = leftValue, let right = rightValue, left > 0 else { return nil }
        let ratio = min(left, right) / max(left, right)
        return ratio * 100
    }
    
    /// Display string for measurement
    var displayValue: String {
        if isPaired {
            return String(format: "L: %.1f cm, R: %.1f cm", leftValue ?? 0, rightValue ?? 0)
        } else {
            return String(format: "%.1f cm", value)
        }
    }
}

// MARK: - ProgressPhoto Model (Enhanced)
@Model
final class ProgressPhoto {
    var id: UUID
    var type: String
    var imageData: Data?
    var date: Date
    var notes: String?
    var createdAt: Date
    
    // Enhanced Properties
    var weight: Double? // Weight at time of photo
    var bodyFat: Double? // Body fat at time of photo
    var isVisible: Bool // User can hide photos
    var isFavorite: Bool
    var tags: [String]? // Custom tags
    
    // Relationships
    var user: User?
    
    init(type: String, imageData: Data?, date: Date, notes: String? = nil, weight: Double? = nil, bodyFat: Double? = nil, isVisible: Bool = true, isFavorite: Bool = false) {
        self.id = UUID()
        self.type = type
        self.imageData = imageData
        self.date = date
        self.notes = notes
        self.weight = weight
        self.bodyFat = bodyFat
        self.isVisible = isVisible
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }
    
    var typeEnum: PhotoType {
        PhotoType(rawValue: type) ?? .front
    }
    
    // MARK: - Computed Properties
    
    /// File size in MB
    var fileSizeMB: Double {
        guard let data = imageData else { return 0 }
        return Double(data.count) / (1024 * 1024)
    }
    
    /// Display date string
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    /// Check if photo has metadata
    var hasMetadata: Bool {
        return weight != nil || bodyFat != nil || !(notes?.isEmpty ?? true)
    }
}

// MARK: - Goal Model (Enhanced)
@Model
final class Goal {
    var id: UUID
    var title: String
    var goalDescription: String?
    var type: String
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var deadline: Date?
    var createdDate: Date
    var completedDate: Date?
    var isCompleted: Bool
    
    // Enhanced Properties
    var priority: Int // 1-5 scale
    var isActive: Bool
    var category: String // GoalCategory for grouping
    var reminderEnabled: Bool
    var milestones: [Double]? // Intermediate targets
    
    // Relationships
    var user: User?
    
    init(title: String, description: String? = nil, type: GoalType, targetValue: Double, currentValue: Double = 0, deadline: Date? = nil, priority: Int = 3, category: String = "general") {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.type = type.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = "goal_unit_\(type.rawValue)".localized
        self.deadline = deadline
        self.priority = priority
        self.category = category
        self.isActive = true
        self.reminderEnabled = true
        self.createdDate = Date()
        self.completedDate = nil
        self.isCompleted = false
    }
    
    var typeEnum: GoalType {
        GoalType(rawValue: type) ?? .weight
    }
    
    var description: String {
        goalDescription ?? ""
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        let progress = (currentValue / targetValue) * 100
        return min(max(progress, 0), 100)
    }
    
    var isExpired: Bool {
        guard let deadline = deadline else { return false }
        return Date() > deadline && !isCompleted
    }
    
    /// Remaining value to reach goal
    var remainingValue: Double {
        return max(targetValue - currentValue, 0)
    }
    
    /// Days remaining until deadline
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: deadline).day
        return days
    }
    
    /// Goal status text
    var statusText: String {
        if isCompleted { return "goal_status_completed".localized }
        if isExpired { return "goal_status_expired".localized }
        if let days = daysRemaining {
            if days > 0 { return "goal_status_days_remaining".localized(with: days) }
            if days == 0 { return "goal_status_ends_today".localized }
        }
        return "goal_status_active".localized
    }
    
    /// Priority emoji
    var priorityEmoji: String {
        switch priority {
        case 5: return "🔥"
        case 4: return "⭐"
        case 3: return "📌"
        case 2: return "💡"
        case 1: return "⚪"
        default: return "📌"
        }
    }
    
    /// Priority color
    var priorityColor: Color {
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .blue
        case 2: return .green
        case 1: return .gray
        default: return .blue
        }
    }
    
    // MARK: - Methods
    
    /// Update progress
    func updateProgress(_ newValue: Double) {
        currentValue = newValue
        
        // Check if goal is completed
        if currentValue >= targetValue && !isCompleted {
            markAsCompleted()
        }
    }
    
    /// Mark goal as completed
    func markAsCompleted() {
        isCompleted = true
        completedDate = Date()
        currentValue = targetValue
    }
    
    /// Reset goal
    func reset() {
        currentValue = 0
        isCompleted = false
        completedDate = nil
        isActive = true
    }
}

// MARK: - Supporting Enums

enum MeasurementCategory: String, CaseIterable {
    case torso = "torso"
    case arms = "arms"
    case legs = "legs"
    case head = "head"
    
    var displayName: String {
        return "measurement_category_\(self.rawValue)".localized
    }
    
    var icon: String {
        switch self {
        case .torso: return "person.crop.rectangle"
        case .arms: return "figure.strengthtraining.traditional"
        case .legs: return "figure.walk"
        case .head: return "person.crop.circle"
        }
    }
}

// MARK: - Measurement Type Enum (Enhanced)
enum MeasurementType: String, CaseIterable, Codable {
    case chest = "chest"
    case waist = "waist"
    case hips = "hips"
    case leftArm = "left_arm"
    case rightArm = "right_arm"
    case leftThigh = "left_thigh"
    case rightThigh = "right_thigh"
    case neck = "neck"
    case forearm = "forearm"
    case calf = "calf"
    case shoulders = "shoulders"
    
    var displayName: String {
        return "measurement_\(self.rawValue)".localized
    }
    
    var shortName: String {
        return displayName
    }
    
    var icon: String {
        switch self {
        case .chest: return "heart.fill"
        case .waist: return "oval.fill"
        case .hips: return "circle.fill"
        case .leftArm, .rightArm: return "figure.strengthtraining.traditional"
        case .leftThigh, .rightThigh: return "figure.walk"
        case .neck: return "person.crop.circle"
        case .forearm: return "figure.flexibility"
        case .calf: return "figure.run"
        case .shoulders: return "figure.strengthtraining.functional"
        }
    }
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .waist: return .orange
        case .hips: return .pink
        case .leftArm: return .blue
        case .rightArm: return .cyan
        case .leftThigh: return .green
        case .rightThigh: return .mint
        case .neck: return .purple
        case .forearm: return .indigo
        case .calf: return .brown
        case .shoulders: return .yellow
        }
    }
    
    /// Whether this measurement type should have left/right values
    var isSymmetrical: Bool {
        switch self {
        case .leftArm, .rightArm, .leftThigh, .rightThigh, .forearm, .calf:
            return true
        default:
            return false
        }
    }
    
    /// Measurement category for grouping
    var category: MeasurementCategory {
        switch self {
        case .chest, .waist, .hips, .shoulders:
            return .torso
        case .leftArm, .rightArm, .forearm:
            return .arms
        case .leftThigh, .rightThigh, .calf:
            return .legs
        case .neck:
            return .head
        }
    }
}

// MARK: - Photo Type Enum (Enhanced)
enum PhotoType: String, CaseIterable, Codable {
    case front = "front"
    case side = "side"
    case back = "back"
    case closeUp = "close_up"
    
    var displayName: String {
        return "photo_type_\(self.rawValue)".localized
    }
    
    var instruction: String {
        return "photo_instruction_\(self.rawValue)".localized
    }
    
    var icon: String {
        switch self {
        case .front: return "person.fill"
        case .side: return "person.and.arrow.left.and.arrow.right"
        case .back: return "person.badge.minus"
        case .closeUp: return "photo.on.rectangle"
        }
    }
    
    var color: Color {
        switch self {
        case .front: return .blue
        case .side: return .green
        case .back: return .orange
        case .closeUp: return .purple
        }
    }
}

// MARK: - Goal Type Enum (Enhanced)
enum GoalType: String, CaseIterable, Codable {
    case weight = "weight"
    case bodyFat = "body_fat"
    case muscle = "muscle"
    case strength = "strength"
    case endurance = "endurance"
    case flexibility = "flexibility"
    
    var displayName: String {
        return "goal_type_\(self.rawValue)".localized
    }
    
    var unit: String {
        return "goal_unit_\(self.rawValue)".localized
    }
    
    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .bodyFat: return "percent"
        case .muscle: return "figure.strengthtraining.traditional"
        case .strength: return "dumbbell"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        }
    }
    
    var color: Color {
        switch self {
        case .weight: return .blue
        case .bodyFat: return .orange
        case .muscle: return .red
        case .strength: return .purple
        case .endurance: return .green
        case .flexibility: return .cyan
        }
    }
}

// MARK: - Model Extensions for Queries

extension WeightEntry {
    /// Predicate for recent weight entries
    static func recentEntriesPredicate(days: Int) -> Predicate<WeightEntry> {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return #Predicate { entry in
            entry.date >= startDate
        }
    }
}

extension BodyMeasurement {
    /// Predicate for measurements by type
    static func typePredicate(_ type: MeasurementType) -> Predicate<BodyMeasurement> {
        return #Predicate { measurement in
            measurement.type == type.rawValue
        }
    }
    
    /// Predicate for recent measurements
    static func recentMeasurementsPredicate(days: Int) -> Predicate<BodyMeasurement> {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return #Predicate { measurement in
            measurement.date >= startDate
        }
    }
}

extension ProgressPhoto {
    /// Predicate for visible photos
    static var visiblePhotosPredicate: Predicate<ProgressPhoto> {
        return #Predicate { photo in
            photo.isVisible == true
        }
    }
    
    /// Predicate for photos by type
    static func typePredicate(_ type: PhotoType) -> Predicate<ProgressPhoto> {
        return #Predicate { photo in
            photo.type == type.rawValue && photo.isVisible == true
        }
    }
    
    /// Predicate for favorite photos
    static var favoritePhotosPredicate: Predicate<ProgressPhoto> {
        return #Predicate { photo in
            photo.isFavorite == true && photo.isVisible == true
        }
    }
}

extension Goal {
    /// Predicate for active goals
    static var activeGoalsPredicate: Predicate<Goal> {
        return #Predicate { goal in
            goal.isActive == true && goal.isCompleted == false
        }
    }
    
    /// Predicate for completed goals
    static var completedGoalsPredicate: Predicate<Goal> {
        return #Predicate { goal in
            goal.isCompleted == true
        }
    }
    
    /// Predicate for goals by type
    static func typePredicate(_ type: GoalType) -> Predicate<Goal> {
        return #Predicate { goal in
            goal.type == type.rawValue
        }
    }
    
    /// Predicate for high priority goals
    static var highPriorityGoalsPredicate: Predicate<Goal> {
        return #Predicate { goal in
            goal.priority >= 4 && goal.isActive == true && goal.isCompleted == false
        }
    }
}
