import Foundation
import CoreLocation
import SwiftUI

@Observable
class LocationManager: NSObject {
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateTimer: Timer?
    
    // Published properties
    var isAuthorized = false
    var isTracking = false
    var currentLocation: CLLocation?
    var currentSpeed: Double = 0 // m/s
    var currentAltitude: Double = 0 // meters
    var totalDistance: Double = 0 // meters
    var averageSpeed: Double = 0 // m/s
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var locationAccuracy: LocationAccuracy = .good
    
    // Private tracking properties
    private var lastLocation: CLLocation?
    private var speedReadings: [Double] = []
    private var lastRecordTime: Date?
    private var minimumRecordInterval: TimeInterval = 5 // seconds
    
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
            // Only request if not determined
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
        guard CLLocationManager.locationServicesEnabled() else {
            Logger.error("Location services are disabled")
            return
        }
        
        guard isAuthorized else {
            Logger.warning("Location not authorized, cannot start tracking")
            return
        }
        
        resetTracking()
        isTracking = true
        
        // Start location updates on background thread to avoid UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        
        // Start timer for dynamic recording
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRecordingInterval()
        }
        
        Logger.info("Started GPS tracking")
    }
    
    func stopTracking() {
        isTracking = false
        
        // Stop location updates on background thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.locationManager.stopUpdatingLocation()
        }
        
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        Logger.info("Stopped GPS tracking - Total distance: \(formatDistance(totalDistance))")
    }
    
    func pauseTracking() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.locationManager.stopUpdatingLocation()
        }
        locationUpdateTimer?.invalidate()
    }
    
    func resumeTracking() {
        guard isAuthorized else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRecordingInterval()
        }
    }
    
    func resetTracking() {
        totalDistance = 0
        averageSpeed = 0
        currentSpeed = 0
        currentAltitude = 0
        routeCoordinates.removeAll()
        speedReadings.removeAll()
        lastLocation = nil
        lastRecordTime = nil
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
    private func updateRecordingInterval() {
        // Dynamic recording based on speed
        let speedKmh = currentSpeed * 3.6
        
        if speedKmh < 1 {
            // Stationary - don't record
            minimumRecordInterval = 30
        } else if speedKmh < 7 {
            // Walking speed - every 10 seconds
            minimumRecordInterval = 10
        } else if speedKmh < 20 {
            // Running speed - every 5 seconds
            minimumRecordInterval = 5
        } else {
            // Cycling speed - every 3 seconds
            minimumRecordInterval = 3
        }
    }
    
    private func shouldRecordLocation() -> Bool {
        guard let lastTime = lastRecordTime else {
            return true
        }
        
        let timeSinceLastRecord = Date().timeIntervalSince(lastTime)
        
        // Record if enough time has passed or direction changed significantly
        if timeSinceLastRecord >= minimumRecordInterval {
            return true
        }
        
        // Check for significant direction change
        if let last = lastLocation, let current = currentLocation {
            let bearing = calculateBearing(from: last.coordinate, to: current.coordinate)
            if abs(bearing) > 30 {
                return true
            }
        }
        
        return false
    }
    
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
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self?.isAuthorized = true
                Logger.info("Location authorization granted")
            case .denied, .restricted:
                self?.isAuthorized = false
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        currentSpeed = max(0, location.speed)
        currentAltitude = location.altitude
        
        // Update accuracy
        updateLocationAccuracy(location)
        
        // Calculate distance
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            
            // Filter out GPS jitter
            if distance > 1 && distance < 100 && location.horizontalAccuracy <= 20 {
                totalDistance += distance
            }
        }
        
        // Update average speed
        speedReadings.append(currentSpeed)
        if speedReadings.count > 10 {
            speedReadings.removeFirst()
        }
        averageSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
        
        // Record route point if needed
        if shouldRecordLocation() {
            routeCoordinates.append(location.coordinate)
            lastRecordTime = Date()
        }
        
        lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.error("Location manager failed: \(error.localizedDescription)")
        locationAccuracy = .noSignal
    }
}