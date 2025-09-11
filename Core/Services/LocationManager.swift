import Foundation
import CoreLocation
import SwiftUI

// MARK: - Location Tracking Actor (Background Processing)
actor LocationTracker {
    private var totalDistance: Double = 0
    private var averageSpeed: Double = 0
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var lastLocation: CLLocation?
    private var speedReadings: [Double] = []
    private var lastRecordTime: Date?
    private let minimumRecordInterval: TimeInterval = 5
    
    func updateLocation(_ location: CLLocation) async -> LocationUpdate {
        let currentTime = Date()
        
        // Calculate distance if we have a previous location
        var distanceIncrement: Double = 0
        if let lastLoc = lastLocation {
            distanceIncrement = location.distance(from: lastLoc)
            totalDistance += distanceIncrement
        }
        
        // Update speed readings
        speedReadings.append(location.speed >= 0 ? location.speed : 0)
        if speedReadings.count > 20 { // Keep last 20 readings
            speedReadings.removeFirst()
        }
        
        // Calculate average speed
        let validSpeeds = speedReadings.filter { $0 > 0 }
        averageSpeed = validSpeeds.isEmpty ? 0 : validSpeeds.reduce(0, +) / Double(validSpeeds.count)
        
        // Record coordinate if enough time has passed
        var shouldRecordCoordinate = false
        if let lastTime = lastRecordTime {
            shouldRecordCoordinate = currentTime.timeIntervalSince(lastTime) >= minimumRecordInterval
        } else {
            shouldRecordCoordinate = true
        }
        
        if shouldRecordCoordinate {
            routeCoordinates.append(location.coordinate)
            lastRecordTime = currentTime
        }
        
        lastLocation = location
        
        return LocationUpdate(
            totalDistance: totalDistance,
            averageSpeed: averageSpeed,
            currentSpeed: location.speed >= 0 ? location.speed : 0,
            routeCoordinates: routeCoordinates
        )
    }
    
    func resetTracking() async {
        totalDistance = 0
        averageSpeed = 0
        routeCoordinates = []
        lastLocation = nil
        speedReadings = []
        lastRecordTime = nil
    }
    
    func getCurrentStats() async -> LocationStats {
        return LocationStats(
            totalDistance: totalDistance,
            averageSpeed: averageSpeed,
            routeCoordinates: routeCoordinates
        )
    }
    
    func getLastRecordTime() async -> Date? {
        return lastRecordTime
    }
    
    func getMinimumRecordInterval() async -> TimeInterval {
        return minimumRecordInterval
    }
}

// MARK: - Location Data Types
struct LocationUpdate: Sendable {
    let totalDistance: Double
    let averageSpeed: Double
    let currentSpeed: Double
    let routeCoordinates: [CLLocationCoordinate2D]
}

struct LocationStats: Sendable {
    let totalDistance: Double
    let averageSpeed: Double
    let routeCoordinates: [CLLocationCoordinate2D]
}

// MARK: - Location Manager (UI Interface)
@MainActor
@Observable
class LocationManager: NSObject {
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let tracker = LocationTracker()
    private var locationUpdateTimer: Timer?
    
    // UI-bound properties
    var isAuthorized = false
    var isTracking = false
    var currentLocation: CLLocation?
    var currentSpeed: Double = 0 // m/s
    var currentAltitude: Double = 0 // meters
    var totalDistance: Double = 0 // meters
    var averageSpeed: Double = 0 // m/s
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var locationAccuracy: LocationAccuracy = .good
    
    // MARK: - Enums
    enum LocationAccuracy {
        case excellent, good, poor, noSignal
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .yellow
            case .poor: return .orange
            case .noSignal: return .red
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "GPS: Mükemmel"
            case .good: return "GPS: İyi"
            case .poor: return "GPS: Zayıf"
            case .noSignal: return "GPS: Sinyal Yok"
            }
        }
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 5 // meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    // MARK: - Public Methods
    func requestAuthorization() {
        // Guard against multiple authorization requests
        guard !isAuthorized else {
            Logger.debug("Location already authorized, skipping request")
            return
        }
        
        let currentStatus = locationManager.authorizationStatus
        Logger.debug("Current authorization status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            // Request authorization - will trigger delegate callback
            Logger.info("Requesting location authorization")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            Logger.info("Location already authorized")
        case .denied, .restricted:
            isAuthorized = false
            Logger.warning("Location authorization denied")
        @unknown default:
            break
        }
    }
    
    func startTracking() {
        // Check authorization status first without calling locationServicesEnabled on main thread
        guard isAuthorized else {
            Logger.warning("Location not authorized, cannot start tracking")
            return
        }
        
        Task {
            await resetTracking()
        }
        isTracking = true
        
        // Start location updates on main actor
        Task { @MainActor [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        
        // Dynamic recording is now handled by the actor
        
        Logger.info("Started GPS tracking")
    }
    
    func stopTracking() {
        isTracking = false
        
        // Stop location updates on main actor
        Task { @MainActor [weak self] in
            self?.locationManager.stopUpdatingLocation()
        }
        
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        Logger.info("Stopped GPS tracking - Total distance: \(formatDistance(totalDistance))")
    }
    
    func pauseTracking() {
        Task { @MainActor [weak self] in
            self?.locationManager.stopUpdatingLocation()
        }
        locationUpdateTimer?.invalidate()
    }
    
    func resumeTracking() {
        guard isAuthorized else { return }
        
        Task { @MainActor [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        
        // Timer for recording interval tracking
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Update recording interval handled by the tracker actor
            // No need for manual interval tracking here
        }
    }
    
    func resetTracking() async {
        // Reset UI properties
        totalDistance = 0
        averageSpeed = 0
        currentSpeed = 0
        currentAltitude = 0
        routeCoordinates.removeAll()
        
        // Reset actor state
        await tracker.resetTracking()
    }
    
    // MARK: - Route Data
    func getRouteData() -> Data? {
        let routePoints = routeCoordinates.map { coordinate in
            ["lat": coordinate.latitude, "lng": coordinate.longitude]
        }
        
        return try? JSONSerialization.data(withJSONObject: routePoints)
    }
    
    func getElevationGain() -> Double {
        var elevationGain: Double = 0
        var lastAltitude: Double?
        
        for _ in routeCoordinates {
            if let altitude = lastAltitude {
                let diff = currentAltitude - altitude
                if diff > 0 {
                    elevationGain += diff
                }
            }
            lastAltitude = currentAltitude
        }
        
        return elevationGain
    }
    
    // MARK: - Private Methods
    // Recording interval and location recording logic is now handled by the LocationTracker actor
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        var bearing = atan2(x, y)
        bearing = bearing * 180 / .pi
        
        return bearing
    }
    
    private func updateLocationAccuracy(_ location: CLLocation) {
        let accuracy = location.horizontalAccuracy
        
        if accuracy < 0 {
            locationAccuracy = .noSignal
        } else if accuracy <= 5 {
            locationAccuracy = .excellent
        } else if accuracy <= 10 {
            locationAccuracy = .good
        } else {
            locationAccuracy = .poor
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch self.locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                Logger.info("Location authorization granted")
            case .denied, .restricted:
                self.isAuthorized = false
                Logger.warning("Location authorization denied")
            case .notDetermined:
                // Don't recursively call requestAuthorization from delegate
                // The initial call should handle this case
                Logger.info("Location authorization still not determined")
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            // Update UI properties
            self.currentLocation = location
            self.currentSpeed = max(0, location.speed)
            self.currentAltitude = location.altitude
            
            // Update accuracy
            self.updateLocationAccuracy(location)
            
            // Process location data in background actor
            let locationUpdate = await self.tracker.updateLocation(location)
            
            // Update UI with processed data
            self.totalDistance = locationUpdate.totalDistance
            self.averageSpeed = locationUpdate.averageSpeed
            self.routeCoordinates = locationUpdate.routeCoordinates
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.error("Location manager failed: \(error.localizedDescription)")
        Task { @MainActor in
            self.locationAccuracy = .noSignal
        }
    }
}