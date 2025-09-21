import SwiftUI

// MARK: - Exercise Category Enum
enum ExerciseCategory: String, CaseIterable, Codable, Sendable {
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case core = "core"
    case cardio = "cardio"
    case olympic = "olympic"
    case functional = "functional"
    case isolation = "isolation"
    case strength = "strength"
    case flexibility = "flexibility"
    case plyometric = "plyometric"
    case other = "other"

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return TrainingKeys.Category.legs.localized
        case .core: return "Core"
        case .cardio: return TrainingKeys.Category.cardio.localized
        case .olympic: return "Olympic"
        case .functional: return TrainingKeys.Category.functional.localized
        case .isolation: return TrainingKeys.Exercise.isolation.localized
        case .strength: return "Strength"
        case .flexibility: return TrainingKeys.Category.flexibility.localized
        case .plyometric: return TrainingKeys.Category.plyometric.localized
        case .other: return TrainingKeys.Exercise.other.localized
        }
    }

    var icon: String {
        switch self {
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .legs: return "figure.walk"
        case .core: return "circle.grid.cross"
        case .cardio: return "heart"
        case .olympic: return "trophy"
        case .functional: return "figure.strengthtraining.functional"
        case .isolation: return "target"
        case .strength: return "dumbbell"
        case .flexibility: return "figure.cooldown"
        case .plyometric: return "figure.jumprope"
        case .other: return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .push: return .blue
        case .pull: return .green
        case .legs: return .purple
        case .core: return .orange
        case .cardio: return .red
        case .olympic: return .yellow
        case .functional: return .pink
        case .isolation: return .gray
        case .strength: return .blue
        case .flexibility: return .purple
        case .plyometric: return .red
        case .other: return .secondary
        }
    }

    var description: String {
        switch self {
        case .push: return TrainingKeys.Exercise.pushDescription.localized
        case .pull: return TrainingKeys.Exercise.pullDescription.localized
        case .legs: return TrainingKeys.Exercise.legsDescription.localized
        case .core: return TrainingKeys.Exercise.coreDescription.localized
        case .cardio: return TrainingKeys.Exercise.cardioDescription.localized
        case .olympic: return TrainingKeys.Exercise.olympicDescription.localized
        case .functional: return TrainingKeys.Exercise.functionalDescription.localized
        case .isolation: return TrainingKeys.Exercise.isolationDescription.localized
        case .strength: return TrainingKeys.Exercise.strengthDescription.localized
        case .flexibility: return TrainingKeys.Exercise.flexibilityDescription.localized
        case .plyometric: return TrainingKeys.Exercise.plyometricDescription.localized
        case .other: return TrainingKeys.Exercise.otherDescription.localized
        }
    }

    // Normalize arbitrary strings (from CSV) to a known category
    static func fromString(_ string: String) -> ExerciseCategory {
        switch string.lowercased() {
        case "push": return .push
        case "pull": return .pull
        case "legs", "leg": return .legs
        case "core": return .core
        case "cardio": return .cardio
        case "olympic": return .olympic
        case "functional": return .functional
        case "isolation": return .isolation
        case "strength": return .strength
        case "flexibility", "mobility": return .flexibility
        case "plyometric", "plyo": return .plyometric
        default: return .other
        }
    }
}

// MARK: - Exercise Equipment Types
enum ExerciseEquipment: String, CaseIterable, Sendable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case kettlebell = "kettlebell"
    case bodyweight = "bodyweight"
    case machine = "machine"
    case cable = "cable"
    case band = "resistance_band"
    case pullupBar = "pullup_bar"
    case bench = "bench"
    case squat_rack = "squat_rack"
    case platform = "platform"
    case box = "box"
    case ball = "medicine_ball"
    case rope = "rope"
    case sled = "sled"
    case tire = "tire"
    case other = "other"

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .kettlebell: return "Kettlebell"
        case .bodyweight: return TrainingKeys.Exercise.bodyweight.localized
        case .machine: return "Makine"
        case .cable: return "Kablo"
        case .band: return TrainingKeys.Exercise.band.localized
        case .pullupBar: return TrainingKeys.Exercise.pullupBar.localized
        case .bench: return "Bench"
        case .squat_rack: return "Squat Rack"
        case .platform: return "Platform"
        case .box: return "Box"
        case .ball: return "Medicine Ball"
        case .rope: return "Rope"
        case .sled: return "Sled"
        case .tire: return "Tire"
        case .other: return TrainingKeys.Exercise.otherEquipment.localized
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "minus.rectangle"
        case .dumbbell: return "dumbbell"
        case .kettlebell: return "triangle"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .machine: return "gear"
        case .cable: return "cable.connector"
        case .band: return "oval"
        case .pullupBar: return "minus"
        case .bench: return "rectangle"
        case .squat_rack: return "square.stack.3d.up"
        case .platform: return "rectangle.stack"
        case .box: return "cube"
        case .ball: return "circle"
        case .rope: return "link"
        case .sled: return "triangle.fill"
        case .tire: return "circle.dotted"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - WOD Format Types
enum WODFormat: String, CaseIterable, Sendable {
    case forTime = "for_time"
    case amrap = "amrap"
    case emom = "emom"
    case tabata = "tabata"
    case rounds = "rounds"
    case ladder = "ladder"
    case chipper = "chipper"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .forTime: return "For Time"
        case .amrap: return "AMRAP"
        case .emom: return "EMOM"
        case .tabata: return "Tabata"
        case .rounds: return "Rounds"
        case .ladder: return "Ladder"
        case .chipper: return "Chipper"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .forTime: return TrainingKeys.Exercise.forTimeDescription.localized
        case .amrap: return TrainingKeys.Exercise.amrapDescription.localized
        case .emom: return TrainingKeys.Exercise.emomDescription.localized
        case .tabata: return TrainingKeys.Exercise.tabataDescription.localized
        case .rounds: return TrainingKeys.Exercise.roundsDescription.localized
        case .ladder: return TrainingKeys.Exercise.ladderDescription.localized
        case .chipper: return TrainingKeys.Exercise.chipperDescription.localized
        case .custom: return TrainingKeys.Exercise.customDescription.localized
        }
    }

    var icon: String {
        switch self {
        case .forTime: return "stopwatch"
        case .amrap: return "infinity"
        case .emom: return "clock"
        case .tabata: return "timer"
        case .rounds: return "arrow.clockwise"
        case .ladder: return "chart.line.uptrend.xyaxis"
        case .chipper: return "list.bullet"
        case .custom: return "gear"
        }
    }

    var color: Color {
        switch self {
        case .forTime: return .red
        case .amrap: return .blue
        case .emom: return .orange
        case .tabata: return .purple
        case .rounds: return .green
        case .ladder: return .yellow
        case .chipper: return .pink
        case .custom: return .gray
        }
    }

    var requiresTimeCap: Bool {
        switch self {
        case .amrap, .emom, .tabata: return true
        case .forTime, .rounds, .ladder, .chipper, .custom: return false
        }
    }

    var allowsRounds: Bool {
        switch self {
        case .rounds, .amrap, .emom, .tabata: return true
        case .forTime, .ladder, .chipper, .custom: return false
        }
    }
}

// MARK: - Fitness Level
enum FitnessLevel: String, CaseIterable, Sendable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case elite = "elite"

    var displayName: String {
        switch self {
        case .beginner: return TrainingKeys.Exercise.beginner.localized
        case .intermediate: return "Orta"
        case .advanced: return TrainingKeys.Exercise.advanced.localized
        case .elite: return "Elite"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "0-6 ay deneyim"
        case .intermediate: return TrainingKeys.Exercise.intermediateExperience.localized
        case .advanced: return TrainingKeys.Exercise.advancedExperience.localized
        case .elite: return TrainingKeys.Exercise.eliteExperience.localized
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .elite: return .purple
        }
    }
}

// MARK: - Activity Level - UPDATED FOR LOCALIZATION
enum ActivityLevel: String, CaseIterable, Sendable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "very_active"

    var displayName: String {
        switch self {
        case .sedentary: return "onboarding.activity.sedentary".localized
        case .light: return "onboarding.activity.light".localized
        case .moderate: return "onboarding.activity.moderate".localized
        case .active: return "onboarding.activity.active".localized
        case .veryActive: return "onboarding.activity.veryActive".localized
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "onboarding.activity.sedentary.desc".localized
        case .light: return "onboarding.activity.light.desc".localized
        case .moderate: return "onboarding.activity.moderate.desc".localized
        case .active: return "onboarding.activity.active.desc".localized
        case .veryActive: return "onboarding.activity.veryActive.desc".localized
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

// MARK: - Fitness Goal - UPDATED FOR LOCALIZATION
enum FitnessGoal: String, CaseIterable, Sendable {
    case cut = "cut"
    case bulk = "bulk"
    case maintain = "maintain"
    case recomp = "recomp"
    case performance = "performance"

    var displayName: String {
        switch self {
        case .cut: return "onboarding.goals.cut.title".localized
        case .bulk: return "onboarding.goals.bulk.title".localized
        case .maintain: return "onboarding.goals.maintain.title".localized
        case .recomp: return "Recomposition"
        case .performance: return "Performans"
        }
    }

    var description: String {
        switch self {
        case .cut: return "onboarding.goals.cut.subtitle".localized
        case .bulk: return "onboarding.goals.bulk.subtitle".localized
        case .maintain: return "onboarding.goals.maintain.subtitle".localized
        case .recomp: return TrainingKeys.Exercise.recompDescription.localized
        case .performance: return TrainingKeys.Exercise.performanceDescription.localized
        }
    }

    var calorieAdjustment: Double {
        switch self {
        case .cut: return 0.8 // 20% deficit
        case .bulk: return 1.15 // 15% surplus
        case .maintain: return 1.0 // maintenance
        case .recomp: return 0.9 // 10% deficit
        case .performance: return 1.1 // 10% surplus
        }
    }
    
    // MISSING PROPERTY ADDED:
    var calorieMultiplier: Double {
        return calorieAdjustment
    }

    var proteinMultiplier: Double {
        switch self {
        case .cut: return 2.5
        case .bulk: return 2.0
        case .maintain: return 1.8
        case .recomp: return 2.3
        case .performance: return 2.2
        }
    }

    var icon: String {
        switch self {
        case .cut: return "flame"
        case .bulk: return "arrow.up.circle"
        case .maintain: return "equal.circle"
        case .recomp: return "arrow.triangle.2.circlepath"
        case .performance: return "bolt"
        }
    }

    var color: Color {
        switch self {
        case .cut: return .red
        case .bulk: return .blue
        case .maintain: return .green
        case .recomp: return .purple
        case .performance: return .orange
        }
    }
}

// MARK: - Meal Types
enum MealType: String, CaseIterable, Sendable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case preworkout = "preworkout"
    case postworkout = "postworkout"

    var displayName: String {
        switch self {
        case .breakfast: return TrainingKeys.Exercise.breakfast.localized
        case .lunch: return TrainingKeys.Exercise.lunch.localized
        case .dinner: return TrainingKeys.Exercise.dinner.localized
        case .snack: return TrainingKeys.Exercise.snack.localized
        case .preworkout: return TrainingKeys.Exercise.preworkout.localized
        case .postworkout: return TrainingKeys.Exercise.postworkout.localized
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        case .preworkout: return "bolt.fill"
        case .postworkout: return "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        case .preworkout: return .blue
        case .postworkout: return .red
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: return 1
        case .preworkout: return 2
        case .lunch: return 3
        case .snack: return 4
        case .postworkout: return 5
        case .dinner: return 6
        }
    }

    var healthKitValue: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .preworkout: return "Pre-Workout"
        case .postworkout: return "Post-Workout"
        }
    }
}
