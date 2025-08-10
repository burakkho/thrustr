import SwiftUI

// MARK: - Exercise Category Enum
enum ExerciseCategory: String, CaseIterable, Codable {
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case core = "core"
    case cardio = "cardio"
    case olympic = "olympic"
    case functional = "functional"
    case isolation = "isolation"
    case other = "other"

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Bacak"
        case .core: return "Core"
        case .cardio: return "Kardiyo"
        case .olympic: return "Olympic"
        case .functional: return "Fonksiyonel"
        case .isolation: return "İzolasyon"
        case .other: return "Diğer"
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
        case .other: return .secondary
        }
    }

    var description: String {
        switch self {
        case .push: return "Göğüs, omuz, triceps hareketleri"
        case .pull: return "Sırt, biceps hareketleri"
        case .legs: return "Bacak ve kalça hareketleri"
        case .core: return "Karın ve core hareketleri"
        case .cardio: return "Kardiyovasküler egzersizler"
        case .olympic: return "Olympic weightlifting hareketleri"
        case .functional: return "Fonksiyonel hareket kalıpları"
        case .isolation: return "İzolasyon ve yardımcı hareketler"
        case .other: return "Diğer egzersiz türleri"
        }
    }
}

// MARK: - Workout Part Type Enum
enum WorkoutPartType: String, CaseIterable, Codable {
    case strength = "strength"
    case conditioning = "conditioning"
    case accessory = "accessory"
    case warmup = "warmup"
    case functional = "functional"

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .conditioning: return "Conditioning"
        case .accessory: return "Accessory"
        case .warmup: return "Warm-up"
        case .functional: return "Functional"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell"
        case .conditioning: return "flame"
        case .accessory: return "plus.circle"
        case .warmup: return "thermometer.sun"
        case .functional: return "figure.strengthtraining.functional"
        }
    }

    var color: Color {
        switch self {
        case .strength: return .blue
        case .conditioning: return .red
        case .accessory: return .green
        case .warmup: return .orange
        case .functional: return .purple
        }
    }

    var description: String {
        switch self {
        case .strength: return "Ağırlık antrenmanı, set/rep tracking"
        case .conditioning: return "WOD, kardiyo, kondisyon antrenmanı"
        case .accessory: return "Yardımcı hareketler, izolasyon"
        case .warmup: return "Isınma hareketleri"
        case .functional: return "Fonksiyonel hareketler, crossfit"
        }
    }

    var suggestedExerciseCategories: [ExerciseCategory] {
        switch self {
        case .strength: return [.push, .pull, .legs, .olympic]
        case .conditioning: return [.cardio, .functional]
        case .accessory: return [.isolation, .core]
        case .warmup: return [.functional, .cardio]
        case .functional: return [.functional, .olympic, .cardio]
        }
    }
}

// MARK: - Exercise Equipment Types
enum ExerciseEquipment: String, CaseIterable {
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
        case .bodyweight: return "Vücut Ağırlığı"
        case .machine: return "Makine"
        case .cable: return "Kablo"
        case .band: return "Direnç Bandı"
        case .pullupBar: return "Barfiks Barı"
        case .bench: return "Bench"
        case .squat_rack: return "Squat Rack"
        case .platform: return "Platform"
        case .box: return "Box"
        case .ball: return "Medicine Ball"
        case .rope: return "Rope"
        case .sled: return "Sled"
        case .tire: return "Tire"
        case .other: return "Diğer"
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
enum WODFormat: String, CaseIterable {
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
        case .forTime: return "Belirlenen hareketleri mümkün olan en kısa sürede tamamla"
        case .amrap: return "Belirlenen sürede mümkün olduğunca çok tekrar/round yap"
        case .emom: return "Her dakikanın başında belirlenen hareketleri yap"
        case .tabata: return "20 saniye çalış, 10 saniye dinlen - 8 round"
        case .rounds: return "Belirlenen sayıda round tamamla"
        case .ladder: return "Tekrar sayısını artırarak veya azaltarak ilerle"
        case .chipper: return "Yüksek tekrarlı hareketleri sırayla bitir"
        case .custom: return "Özel format"
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
enum FitnessLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case elite = "elite"

    var displayName: String {
        switch self {
        case .beginner: return "Başlangıç"
        case .intermediate: return "Orta"
        case .advanced: return "İleri"
        case .elite: return "Elite"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "0-6 ay deneyim"
        case .intermediate: return "6 ay - 2 yıl deneyim"
        case .advanced: return "2+ yıl deneyim"
        case .elite: return "Profesyonel/Yarışmacı"
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
enum ActivityLevel: String, CaseIterable {
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
enum FitnessGoal: String, CaseIterable {
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
        case .recomp: return "Aynı anda yağ yak ve kas kazan"
        case .performance: return "Atletik performansı artır"
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
enum MealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case preworkout = "preworkout"
    case postworkout = "postworkout"

    var displayName: String {
        switch self {
        case .breakfast: return "Kahvaltı"
        case .lunch: return "Öğle"
        case .dinner: return "Akşam"
        case .snack: return "Atıştırma"
        case .preworkout: return "Antrenman Öncesi"
        case .postworkout: return "Antrenman Sonrası"
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
}
