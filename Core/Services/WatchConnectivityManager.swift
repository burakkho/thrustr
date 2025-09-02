import Foundation
import WatchConnectivity
import SwiftUI

@Observable
class WatchConnectivityManager: NSObject {
    // MARK: - Shared Instance
    static let shared = WatchConnectivityManager()
    // MARK: - Properties
    var isSupported = false
    var isWatchAppInstalled = false
    var isReachable = false
    var isPaired = false
    var watchState: WCSessionActivationState = .notActivated
    
    // Watch Data
    var watchHeartRate: Int = 0
    var watchSteps: Int = 0
    var watchCalories: Int = 0
    var lastWatchUpdate: Date?
    
    // Communication
    private var session: WCSession?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            isSupported = true
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            
            Logger.info("Watch Connectivity setup initiated")
        } else {
            Logger.warning("Watch Connectivity not supported on this device")
            isSupported = false
        }
    }
    
    // MARK: - Communication Methods
    func sendWorkoutStartMessage(activityType: String, isOutdoor: Bool) {
        guard let session = session, session.isReachable else {
            Logger.warning("Watch not reachable - cannot send workout start")
            return
        }
        
        let message: [String: Any] = [
            "command": "startWorkout",
            "activityType": activityType,
            "isOutdoor": isOutdoor,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { response in
            Logger.success("Watch workout start confirmed: \(response)")
        }, errorHandler: { error in
            Logger.error("Failed to send workout start to watch: \(error)")
        })
    }
    
    func sendWorkoutStopMessage() {
        guard let session = session, session.isReachable else {
            Logger.warning("Watch not reachable - cannot send workout stop")
            return
        }
        
        let message: [String: Any] = [
            "command": "stopWorkout",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { response in
            Logger.success("Watch workout stop confirmed: \(response)")
        }, errorHandler: { error in
            Logger.error("Failed to send workout stop to watch: \(error)")
        })
    }
    
    func requestWatchData() {
        guard let session = session, session.isReachable else {
            Logger.warning("Watch not reachable - cannot request data")
            return
        }
        
        let message: [String: Any] = [
            "command": "requestData",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { [weak self] response in
            self?.processWatchDataResponse(response)
        }, errorHandler: { error in
            Logger.error("Failed to request watch data: \(error)")
        })
    }
    
    private func processWatchDataResponse(_ response: [String: Any]) {
        if let heartRate = response["heartRate"] as? Int {
            watchHeartRate = heartRate
        }
        
        if let steps = response["steps"] as? Int {
            watchSteps = steps
        }
        
        if let calories = response["calories"] as? Int {
            watchCalories = calories
        }
        
        lastWatchUpdate = Date()
        
        Logger.info("Watch data updated - HR: \(watchHeartRate), Steps: \(watchSteps), Calories: \(watchCalories)")
    }
    
    // MARK: - Health Data Sync
    func syncHealthData(steps: Int, heartRate: Int, calories: Int) {
        guard let session = session else { return }
        
        let healthData: [String: Any] = [
            "steps": steps,
            "heartRate": heartRate,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(healthData)
            Logger.info("Health data synced to watch")
        } catch {
            Logger.error("Failed to sync health data to watch: \(error)")
        }
    }
    
    // MARK: - Status Methods
    var statusDescription: String {
        if !isSupported {
            return "Watch Connectivity desteklenmiyor"
        } else if !isPaired {
            return "Apple Watch eşleştirilmemiş"
        } else if !isWatchAppInstalled {
            return "Watch uygulaması yüklü değil"
        } else if !isReachable {
            return "Apple Watch ulaşılabilir değil"
        } else {
            return "Apple Watch bağlı"
        }
    }
    
    var isFullyConnected: Bool {
        return isSupported && isPaired && isWatchAppInstalled && isReachable
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.watchState = activationState
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
            
            if let error = error {
                Logger.error("Watch session activation failed: \(error)")
            } else {
                Logger.success("Watch session activated - State: \(activationState.rawValue), Paired: \(session.isPaired), Installed: \(session.isWatchAppInstalled)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.info("Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        Logger.info("Watch session deactivated")
        // Reactivate the session for iOS
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            Logger.info("Watch reachability changed: \(session.isReachable)")
        }
    }
    
    // MARK: - Message Handling
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
            
            // Send acknowledgment
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
        }
    }
    
    private func handleWatchMessage(_ message: [String: Any]) {
        guard let command = message["command"] as? String else {
            Logger.warning("Received watch message without command")
            return
        }
        
        switch command {
        case "healthUpdate":
            if let heartRate = message["heartRate"] as? Int {
                watchHeartRate = heartRate
            }
            if let steps = message["steps"] as? Int {
                watchSteps = steps  
            }
            if let calories = message["calories"] as? Int {
                watchCalories = calories
            }
            lastWatchUpdate = Date()
            
        case "workoutStatus":
            Logger.info("Received workout status from watch: \(message)")
            
        default:
            Logger.info("Unknown watch command: \(command)")
        }
    }
    
    // MARK: - Application Context
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            Logger.info("Received application context from watch: \(applicationContext)")
            self.processWatchDataResponse(applicationContext)
        }
    }
}