import Foundation
import CoreLocation

@Observable
class CardioMetricsCalculator {
    // MARK: - Calculated Metrics
    private(set) var currentPace: Double = 0 // min/km
    private(set) var averagePace: Double = 0 // min/km
    private(set) var currentCalories: Int = 0
    private(set) var currentSpeed: Double = 0 // km/h
    private(set) var splits: [SplitData] = []
    
    // MARK: - Configuration
    private let activityType: CardioActivityType
    private let user: User?
    private var lastUpdateTime: Date = Date()
    private let updateThrottle: TimeInterval = 1.0 // 1 second throttling
    
    // MARK: - Internal State
    private var totalPausedTime: TimeInterval = 0
    private var sessionStartTime: Date?
    
    init(activityType: CardioActivityType, user: User?) {
        self.activityType = activityType
        self.user = user
    }
    
    // MARK: - Public Interface
    
    @MainActor
    func updateMetrics(
        isRunning: Bool,
        elapsedTime: TimeInterval,
        totalDistance: Double,
        currentLocationSpeed: Double,
        currentHeartRate: Int,
        totalPausedTime: TimeInterval
    ) {
        // Throttle updates to prevent UI blocking
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) >= updateThrottle else { return }
        lastUpdateTime = now
        
        guard isRunning else { return }
        
        // Update state
        self.totalPausedTime = totalPausedTime
        
        // Calculate in background
        Task.detached { [weak self] in
            await self?.performCalculations(
                elapsedTime: elapsedTime,
                totalDistance: totalDistance,
                currentLocationSpeed: currentLocationSpeed,
                currentHeartRate: currentHeartRate
            )
        }
    }
    
    // MARK: - Background Calculations
    
    private func performCalculations(
        elapsedTime: TimeInterval,
        totalDistance: Double,
        currentLocationSpeed: Double,
        currentHeartRate: Int
    ) async {
        let calculatedPace = calculatePace(elapsedTime: elapsedTime, totalDistance: totalDistance)
        let calculatedSpeed = currentLocationSpeed * 3.6 // m/s to km/h
        let calculatedCalories = calculateCalories(elapsedTime: elapsedTime, totalDistance: totalDistance, heartRate: currentHeartRate)
        
        // Check for splits (only if needed)
        let newSplits = checkForNewSplits(totalDistance: totalDistance, elapsedTime: elapsedTime, currentHeartRate: currentHeartRate)
        
        // Update UI on main thread
        await MainActor.run {
            self.currentPace = calculatedPace.current
            self.averagePace = calculatedPace.average
            self.currentSpeed = calculatedSpeed
            self.currentCalories = calculatedCalories
            
            if let newSplits = newSplits {
                self.splits.append(contentsOf: newSplits)
            }
        }
    }
    
    private func calculatePace(elapsedTime: TimeInterval, totalDistance: Double) -> (current: Double, average: Double) {
        guard totalDistance > 0 && elapsedTime > 0 else {
            return (0, 0)
        }
        
        let distanceKm = totalDistance / 1000.0
        let timeMinutes = elapsedTime / 60.0
        
        // Current pace (minutes per km)
        let currentPace = timeMinutes / distanceKm
        
        // Average pace (excluding paused time)
        let activeTimeMinutes = (elapsedTime - totalPausedTime) / 60.0
        let averagePace = activeTimeMinutes / distanceKm
        
        return (currentPace, averagePace)
    }
    
    private func calculateCalories(elapsedTime: TimeInterval, totalDistance: Double, heartRate: Int) -> Int {
        guard let user = user, elapsedTime > 0 else { return 0 }
        
        let durationHours = elapsedTime / 3600
        let weight = user.currentWeight
        
        // Heart rate based calculation (more accurate)
        if heartRate > 0 {
            let hr = Double(heartRate)
            let age = Double(user.age)
            let gender = user.genderEnum == .male ? 1.0 : 0.0
            
            // Heart rate formula: more accurate for real-time tracking
            let caloriesPerMinute = ((-55.0969 + (0.6309 * hr) + (0.1988 * weight) + (0.2017 * age)) / 4.184) * gender
            return max(1, Int(caloriesPerMinute * (elapsedTime / 60)))
        }
        
        // MET-based fallback calculation
        var metValue = activityType.metValue
        
        // Adjust MET based on actual speed if available
        if totalDistance > 0 && elapsedTime > 0 {
            let speedKmh = (totalDistance / 1000) / durationHours
            metValue = adjustedMETForSpeed(speedKmh: speedKmh, activityType: activityType)
        }
        
        let calculatedCalories = metValue * weight * durationHours
        return max(1, Int(calculatedCalories))
    }
    
    private func adjustedMETForSpeed(speedKmh: Double, activityType: CardioActivityType) -> Double {
        switch activityType {
        case .running:
            switch speedKmh {
            case 0..<8: return 8.0
            case 8..<12: return 10.0
            case 12..<16: return 12.0
            default: return 15.0
            }
        case .walking:
            switch speedKmh {
            case 0..<4: return 2.5
            case 4..<6: return 3.5
            default: return 4.5
            }
        case .cycling:
            switch speedKmh {
            case 0..<16: return 6.0
            case 16..<20: return 8.0
            case 20..<25: return 10.0
            default: return 12.0
            }
        }
    }
    
    private func checkForNewSplits(totalDistance: Double, elapsedTime: TimeInterval, currentHeartRate: Int) -> [SplitData]? {
        let kmCompleted = Int(totalDistance / 1000)
        
        guard kmCompleted > splits.count && kmCompleted > 0 else { return nil }
        
        let splitTime = elapsedTime - splits.reduce(0) { $0 + $1.time }
        let splitPace = splitTime / 60 // min/km
        
        let newSplit = SplitData(
            distance: 1000,
            time: splitTime,
            pace: splitPace,
            heartRate: currentHeartRate > 0 ? currentHeartRate : nil
        )
        
        Logger.info("New split detected - Km \(kmCompleted): \(formatPace(splitPace))")
        return [newSplit]
    }
    
    // MARK: - Formatting Helpers
    
    var formattedCurrentPace: String {
        guard currentPace > 0 && currentPace.isFinite else { return "--:--" }
        return formatPace(currentPace)
    }
    
    var formattedAveragePace: String {
        guard averagePace > 0 && averagePace.isFinite else { return "--:--" }
        return formatPace(averagePace)
    }
    
    var formattedSpeed: String {
        return String(format: "%.1f", currentSpeed)
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Reset & Cleanup
    
    func resetMetrics() {
        currentPace = 0
        averagePace = 0
        currentCalories = 0
        currentSpeed = 0
        splits.removeAll()
        sessionStartTime = nil
        totalPausedTime = 0
    }
    
    func setSessionStart(_ date: Date) {
        sessionStartTime = date
    }
}

// MARK: - Supporting Types

enum CardioActivityType: String, CaseIterable {
    case running = "run"
    case walking = "walk"
    case cycling = "bike"
    
    var displayName: String {
        switch self {
        case .running: return TrainingKeys.Cardio.running.localized
        case .walking: return TrainingKeys.Cardio.walking.localized
        case .cycling: return TrainingKeys.Cardio.cycling.localized
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        }
    }
    
    var metValue: Double {
        switch self {
        case .running: return 10.0
        case .walking: return 3.5
        case .cycling: return 8.0
        }
    }
}

struct SplitData {
    let distance: Double // meters
    let time: TimeInterval
    let pace: Double // min/km
    let heartRate: Int?
}