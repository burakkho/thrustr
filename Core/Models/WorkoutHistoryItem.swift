import Foundation
import HealthKit

struct WorkoutHistoryItem: Identifiable, Hashable {
    let id: UUID
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double? // in kilocalories
    let totalDistance: Double? // in meters
    let source: String // App that created the workout
    let isFromHealthKit: Bool
    
    // Computed properties
    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    var activityDisplayName: String {
        switch activityType {
        case .running:
            return "Koşu"
        case .cycling:
            return "Bisiklet"
        case .swimming:
            return "Yüzme"
        case .walking:
            return "Yürüyüş"
        case .traditionalStrengthTraining:
            return "Güç Antrenmanı"
        case .crossTraining:
            return "CrossTraining/WOD"
        case .rowing:
            return "Kürek"
        case .elliptical:
            return "Eliptik"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining:
            return "Fonksiyonel Antrenman"
        case .coreTraining:
            return "Core Antrenmanı"
        case .flexibility:
            return "Esneklik"
        case .highIntensityIntervalTraining:
            return "HIIT"
        case .jumpRope:
            return "İp Atlama"
        case .stairs:
            return "Merdiven"
        case .kickboxing:
            return "Kickboks"
        case .pilates:
            return "Pilates"
        case .dance:
            return "Dans"
        case .taiChi:
            return "Tai Chi"
        case .barre:
            return "Barre"
        case .wrestling:
            return "Güreş"
        case .boxing:
            return "Boks"
        case .martialArts:
            return "Dövüş Sanatları"
        default:
            return "Diğer"
        }
    }
    
    var activityIcon: String {
        switch activityType {
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .walking:
            return "figure.walk"
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "dumbbell.fill"
        case .crossTraining:
            return "figure.strengthtraining.traditional"
        case .rowing:
            return "oar.2.crossed"
        case .elliptical:
            return "figure.elliptical"
        case .yoga:
            return "figure.yoga"
        case .coreTraining:
            return "figure.core.training"
        case .flexibility:
            return "figure.flexibility"
        case .highIntensityIntervalTraining:
            return "bolt.fill"
        case .jumpRope:
            return "figure.jumprope"
        case .stairs:
            return "figure.stairs"
        case .kickboxing, .boxing:
            return "figure.boxing"
        case .pilates:
            return "figure.pilates"
        case .dance:
            return "figure.dance"
        case .taiChi:
            return "figure.taichi"
        case .barre:
            return "figure.barre"
        case .wrestling:
            return "figure.wrestling"
        case .martialArts:
            return "figure.martial.arts"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var caloriesFormatted: String? {
        guard let calories = totalEnergyBurned else { return nil }
        return "\(Int(calories)) kcal"
    }
    
    var distanceFormatted: String? {
        guard let distance = totalDistance, distance > 0 else { return nil }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return "\(Int(distance)) m"
        }
    }
}

// MARK: - HealthKit Extensions
extension WorkoutHistoryItem {
    init(from workout: HKWorkout) {
        self.id = UUID()
        self.activityType = workout.workoutActivityType
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.duration = workout.duration
        self.totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        self.totalDistance = workout.totalDistance?.doubleValue(for: .meter())
        self.source = workout.sourceRevision.source.name
        self.isFromHealthKit = true
    }
}

// MARK: - Mock Data for Development
extension WorkoutHistoryItem {
    static let mockWorkouts: [WorkoutHistoryItem] = [
        WorkoutHistoryItem(
            id: UUID(),
            activityType: .running,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(-84600),
            duration: 1800,
            totalEnergyBurned: 450,
            totalDistance: 5000,
            source: "Thrustr",
            isFromHealthKit: false
        ),
        WorkoutHistoryItem(
            id: UUID(),
            activityType: .traditionalStrengthTraining,
            startDate: Date().addingTimeInterval(-172800),
            endDate: Date().addingTimeInterval(-169200),
            duration: 3600,
            totalEnergyBurned: 320,
            totalDistance: nil,
            source: "Apple Fitness+",
            isFromHealthKit: true
        ),
        WorkoutHistoryItem(
            id: UUID(),
            activityType: .cycling,
            startDate: Date().addingTimeInterval(-259200),
            endDate: Date().addingTimeInterval(-255600),
            duration: 3600,
            totalEnergyBurned: 680,
            totalDistance: 25000,
            source: "Strava",
            isFromHealthKit: true
        )
    ]
}