import Foundation
import CoreMotion
import HealthKit
import SwiftUI
import Combine

@MainActor
@Observable
class StepCounterManager: NSObject {
    // MARK: - Shared Instance
    static let shared = StepCounterManager()
    
    // MARK: - Core Motion
    private let pedometer = CMPedometer()
    private let motionActivityManager = CMMotionActivityManager()
    
    // MARK: - Published Properties
    var isAvailable = false
    var isAuthorized = false
    var isActive = false
    private var isRequestingPermissions = false
    
    // Session Data - reactive SwiftUI updates with @Observable
    var sessionSteps: Int = 0
    var sessionDistance: Double = 0 // meters
    var sessionFloorsAscended: Int = 0
    var sessionFloorsDescended: Int = 0
    var sessionPace: Double = 0 // steps/min
    var sessionCadence: Double = 0 // steps/min
    
    // Current Activity
    var currentActivity: String = "unknown"
    var confidence: CMMotionActivityConfidence = .low
    
    // Real-time metrics - reactive SwiftUI updates with @Observable
    var stepsHistory: [(Date, Int)] = []
    var lastStepUpdate: Date = Date()
    
    // MARK: - Session Management
    private var sessionStartDate: Date?
    private var isSessionActive = false
    
    // MARK: - Initialization
    private override init() {
        super.init()
        checkAvailability()
        Logger.info("StepCounterManager: Singleton instance initialized")
    }
    
    // MARK: - Availability & Authorization
    private func checkAvailability() {
        isAvailable = CMPedometer.isStepCountingAvailable() && 
                     CMPedometer.isDistanceAvailable() &&
                     CMMotionActivityManager.isActivityAvailable()
        
        Logger.info("StepCounterManager availability: steps=\(CMPedometer.isStepCountingAvailable()), distance=\(CMPedometer.isDistanceAvailable()), activity=\(CMMotionActivityManager.isActivityAvailable())")
    }
    
    func requestPermissions() async -> Bool {
        // Prevent multiple simultaneous requests
        guard !isRequestingPermissions else {
            Logger.warning("StepCounter: Permission request already in progress, waiting...")
            return isAuthorized
        }
        
        // If already authorized, don't request again
        if isAuthorized {
            Logger.info("StepCounter: Already authorized, skipping permission request")
            return true
        }
        
        Logger.info("StepCounter: Requesting permissions...")
        isRequestingPermissions = true
        defer { isRequestingPermissions = false }
        
        guard isAvailable else {
            Logger.warning("StepCounter: CoreMotion services not available - StepCounting: \(CMPedometer.isStepCountingAvailable()), Distance: \(CMPedometer.isDistanceAvailable()), Activity: \(CMMotionActivityManager.isActivityAvailable())")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            // Request motion activity permission first
            motionActivityManager.queryActivityStarting(from: Date().addingTimeInterval(-60), 
                                                       to: Date(), 
                                                       to: .main) { [weak self] (activities, error) in
                if let error = error {
                    Logger.error("StepCounter: Motion activity permission denied: \(error.localizedDescription)")
                    self?.isAuthorized = false
                    continuation.resume(returning: false)
                } else {
                    Logger.success("StepCounter: Motion & Fitness permissions granted successfully")
                    self?.isAuthorized = true
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        Logger.info("StepCounter: startSession called - authorized: \(isAuthorized), available: \(isAvailable), active: \(isSessionActive)")
        
        guard isAuthorized && isAvailable && !isSessionActive else {
            Logger.warning("Cannot start step counter session - authorized: \(isAuthorized), available: \(isAvailable), alreadyActive: \(isSessionActive)")
            return
        }
        
        sessionStartDate = Date()
        isSessionActive = true
        isActive = true
        
        // Reset session data
        sessionSteps = 0
        sessionDistance = 0
        sessionFloorsAscended = 0
        sessionFloorsDescended = 0
        sessionPace = 0
        sessionCadence = 0
        stepsHistory.removeAll()
        
        startPedometerUpdates()
        startActivityUpdates()
        
        Logger.success("Step counter session started successfully at \(Date())")
    }
    
    func stopSession() {
        guard isSessionActive else { return }
        
        isSessionActive = false
        isActive = false
        
        pedometer.stopUpdates()
        motionActivityManager.stopActivityUpdates()
        
        Logger.info("Step counter session stopped - Final steps: \(sessionSteps)")
    }
    
    func pauseSession() {
        guard isSessionActive else { return }
        
        isActive = false
        pedometer.stopUpdates()
        motionActivityManager.stopActivityUpdates()
        
        Logger.info("Step counter session paused")
    }
    
    func resumeSession() {
        guard isSessionActive && !isActive else { return }
        
        isActive = true
        startPedometerUpdates()
        startActivityUpdates()
        
        Logger.info("Step counter session resumed")
    }
    
    // MARK: - CoreMotion Updates
    private func startPedometerUpdates() {
        guard let startDate = sessionStartDate else {
            Logger.error("StepCounter: Cannot start pedometer - no session start date")
            return
        }
        
        Logger.info("StepCounter: Starting pedometer updates from \(startDate)")
        
        // Start real-time pedometer updates
        pedometer.startUpdates(from: startDate) { [weak self] (pedometerData, error) in
            guard let self = self else { return }
            
            if let error = error {
                Logger.error("StepCounter: Pedometer update error: \(error.localizedDescription)")
                return
            }
            
            guard let data = pedometerData else {
                Logger.warning("StepCounter: Received nil pedometer data")
                return
            }
            
            Logger.info("StepCounter: Received pedometer data - Steps: \(data.numberOfSteps)")
            
            DispatchQueue.main.async {
                self.updateSessionData(with: data)
            }
        }
        
        Logger.success("StepCounter: Pedometer updates started successfully")
    }
    
    private func updateSessionData(with data: CMPedometerData) {
        let previousSteps = sessionSteps
        
        // @Observable automatically handles UI updates
        let newSteps = data.numberOfSteps.intValue
        let newDistance = data.distance?.doubleValue ?? 0
        
        sessionSteps = newSteps
        sessionDistance = newDistance
        sessionFloorsAscended = data.floorsAscended?.intValue ?? 0
        sessionFloorsDescended = data.floorsDescended?.intValue ?? 0
        
        // Calculate pace and cadence
        if let startDate = sessionStartDate {
            let elapsed = Date().timeIntervalSince(startDate)
            if elapsed > 0 {
                sessionPace = Double(sessionSteps) / (elapsed / 60) // steps/min
                sessionCadence = sessionPace // Same as pace for steps/min
            }
        }
        
        // Update history
        stepsHistory.append((Date(), sessionSteps))
        
        // Keep only last 5 minutes of history
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        stepsHistory = stepsHistory.filter { $0.0 > fiveMinutesAgo }
        
        lastStepUpdate = Date()
        
        // Detailed logging and explicit UI update notification
        if sessionSteps != previousSteps {
            Logger.success("StepCounter: Steps updated from \(previousSteps) to \(sessionSteps), Distance: \(Int(sessionDistance))m, Pace: \(String(format: "%.1f", sessionPace)) steps/min")
            
            // Force update timestamp to trigger any dependent computations
            lastStepUpdate = Date()
        } else {
            Logger.info("StepCounter: Data received but steps unchanged: \(sessionSteps)")
        }
    }
    
    private func startActivityUpdates() {
        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            self.confidence = activity.confidence
            
            if activity.running {
                self.currentActivity = "running"
            } else if activity.walking {
                self.currentActivity = "walking"
            } else if activity.cycling {
                self.currentActivity = "cycling"
            } else if activity.automotive {
                self.currentActivity = "automotive"
            } else if activity.stationary {
                self.currentActivity = "stationary"
            } else {
                self.currentActivity = "unknown"
            }
        }
    }
    
    // MARK: - Metrics Calculation
    func getAverageStepsPerMinute() -> Double {
        guard !stepsHistory.isEmpty else { return 0 }
        
        let totalSteps = stepsHistory.map { $0.1 }.max() ?? 0
        let startTime = stepsHistory.first?.0 ?? Date()
        let elapsed = Date().timeIntervalSince(startTime)
        
        return elapsed > 0 ? Double(totalSteps) / (elapsed / 60) : 0
    }
    
    func getEstimatedCaloriesBurned(for user: User) -> Int {
        // Basic calorie estimation based on steps and user data
        let weightInKg = user.currentWeight
        let caloriesPerStep = weightInKg * 0.04 / 1000 // Rough estimation
        
        return Int(Double(sessionSteps) * caloriesPerStep)
    }
    
    func getStepLength(for user: User) -> Double {
        // Estimate step length from distance and steps
        guard sessionSteps > 0 else { return 0 }
        return sessionDistance / Double(sessionSteps) * 100 // in cm
    }
    
    // MARK: - Data Source Methods
    func resetSession() {
        sessionSteps = 0
        sessionDistance = 0
        sessionFloorsAscended = 0
        sessionFloorsDescended = 0
        sessionPace = 0
        sessionCadence = 0
        stepsHistory.removeAll()
        sessionStartDate = Date()
    }
}

// MARK: - Data Source Priority
extension StepCounterManager {
    enum DataSource {
        case phone
        case appleWatch
        case combined
        
        var displayName: String {
            switch self {
            case .phone: return "iPhone"
            case .appleWatch: return "Apple Watch"
            case .combined: return "iPhone + Watch"
            }
        }
    }
}