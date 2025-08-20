import Foundation

// MARK: - Exercise Extensions
extension Exercise {
    
    /// Returns localized exercise name based on current language
    var localizedName: String {
        // Use LanguageManager to determine current language
        // For now, default to English to avoid dependency issues
        // TODO: Implement proper localization with LanguageManager
        return nameEN.isEmpty ? nameTR : nameEN
    }
    
    /// Returns exercise name in user's preferred language
    func getName(language: String = "en") -> String {
        switch language.lowercased() {
        case "tr", "turkish":
            return nameTR.isEmpty ? nameEN : nameTR
        default:
            return nameEN.isEmpty ? nameTR : nameEN
        }
    }
    
    /// Returns formatted category display name
    var categoryDisplay: String {
        switch category.lowercased() {
        case "push":
            return "Push"
        case "pull":
            return "Pull"
        case "legs":
            return "Legs"
        case "core":
            return "Core"
        case "strength":
            return "Strength"
        case "isolation":
            return "Isolation"
        case "olympic":
            return "Olympic"
        case "functional":
            return "Functional"
        case "plyometric":
            return "Plyometric"
        default:
            return category.capitalized
        }
    }
    
    /// Returns formatted equipment display name
    var equipmentDisplay: String {
        switch equipment.lowercased() {
        case "barbell":
            return "Barbell"
        case "dumbbell":
            return "Dumbbell"
        case "cable":
            return "Cable"
        case "machine":
            return "Machine"
        case "bodyweight":
            return "Bodyweight"
        case "kettlebell":
            return "Kettlebell"
        case "pullup_bar":
            return "Pull-up Bar"
        case "other":
            return "Other"
        default:
            return equipment.capitalized
        }
    }
    
    /// Returns category and equipment combined for display
    var categoryEquipmentDisplay: String {
        return "\(categoryDisplay) • \(equipmentDisplay)"
    }
    
    /// Returns whether exercise supports weight tracking
    var canTrackWeight: Bool {
        return supportsWeight
    }
    
    /// Returns whether exercise supports rep tracking  
    var canTrackReps: Bool {
        return supportsReps
    }
    
    /// Returns whether exercise supports time tracking
    var canTrackTime: Bool {
        return supportsTime
    }
    
    /// Returns whether exercise supports distance tracking
    var canTrackDistance: Bool {
        return supportsDistance
    }
}