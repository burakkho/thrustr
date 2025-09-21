import Foundation
import SwiftUI
import CoreLocation
import AVFoundation
import AudioToolbox
import HealthKit

@MainActor
@Observable
class CardioTimerViewModel {
    // MARK: - Core Services
    let timerViewModel = TimerViewModel()
    let locationManager = LocationManager.shared
    let bluetoothManager = BluetoothManager()
    
    // MARK: - HealthKit Integration
    private let healthStore = HKHealthStore()
    
    // Local data collection for iOS HealthKit
    private var heartRateReadings: [(Date, Double)] = []
    private var calorieReadings: [(Date, Double)] = []
    
    // MARK: - Audio Feedback
    private var audioPlayer: AVAudioPlayer?
    private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - Unit Settings
    private var unitSettings: UnitSettings { UnitSettings.shared }

    // MARK: - Screen Lock Management
    var isScreenLocked = false
    var lockSlideOffset: CGFloat = 0

    // MARK: - Volume Button Monitoring
    private var volumeButtonMonitor: Timer?
    private var lastVolumeLevel: Float = 0
    private var volumeButtonPressCount = 0
    private var volumeUnlockTimer: Timer?
    
    // MARK: - Cardio Properties
    let activityType: CardioActivityType
    let isOutdoor: Bool
    var user: User?
    
    // MARK: - Session Data
    var sessionStartTime: Date?
    var sessionPausedTime: TimeInterval = 0
    var totalPausedTime: TimeInterval = 0
    
    // MARK: - Metrics
    var currentPace: Double = 0 // min/km
    var averagePace: Double = 0 // min/km
    var currentCalories: Int = 0
    var splits: [SplitData] = []
    
    // Indoor-specific metrics
    var currentPerceivedEffort: Int = 5 // 1-10 RPE scale
    var manualDistance: Double = 0 // manually entered distance for indoor
    var manualSpeed: Double = 0 // manually entered speed for indoor
    
    // MARK: - UI State
    var showingBluetoothSheet = false
    var showingCompletionView = false
    var selectedHeartRateMethod: HeartRateMethod = .none
    
    // MARK: - Models
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
    
    enum HeartRateMethod {
        case none
        case bluetooth
        case appleWatch
        
        var displayName: String {
            switch self {
            case .none: return "Nabız Takibi Yok"
            case .bluetooth: return "Bluetooth Nabız Bandı"
            case .appleWatch: return "Apple Watch"
            }
        }
    }
    
    struct SplitData {
        let distance: Double // meters
        let time: TimeInterval
        let pace: Double // min/km
        let heartRate: Int?
    }
    
    // MARK: - Initialization
    init(activityType: CardioActivityType, isOutdoor: Bool, user: User? = nil) {
        self.activityType = activityType
        self.isOutdoor = isOutdoor
        self.user = user
        
        setupLocationTracking()
        setupHeartRateZones()
        setupAudioFeedback()
    }
    
    // MARK: - Setup
    private func setupLocationTracking() {
        if isOutdoor && !locationManager.isAuthorized {
            locationManager.requestAuthorization()
        }
    }
    
    private func setupHeartRateZones() {
        guard let user = user else { return }
        
        let maxHR = 220 - user.age
        let restingHR = 60 // Default resting heart rate
        
        bluetoothManager.updateHeartRateZonesKarvonen(max: maxHR, resting: restingHR)
    }
    
    private func setupAudioFeedback() {
        do {
            // Configure audio session to mix with other audio (music)
            // This allows workout sounds to play over music without interrupting it
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio, // Optimized for short audio cues
                options: [.mixWithOthers, .duckOthers] // Mix with music, duck volume briefly
            )
            
            // Prepare haptic generator
            hapticGenerator.prepare()
            
            Logger.info("Audio feedback configured - will mix with user's music")
        } catch {
            Logger.error("Failed to setup audio feedback: \(error)")
        }
    }
    
    // MARK: - Audio Feedback Methods
    
    private func playAudioFeedback(for type: AudioFeedbackType) {
        // Check if audio feedback is enabled in user settings
        guard shouldPlayAudioFeedback() else {
            // Always provide haptic feedback as fallback
            hapticGenerator.impactOccurred()
            return
        }
        
        // Use system sounds for better integration
        switch type {
        case .splitComplete:
            // Short, pleasant beep for splits
            AudioServicesPlaySystemSound(1309) // Tock sound
        case .lapComplete:
            // Double beep for laps
            AudioServicesPlaySystemSound(1309)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AudioServicesPlaySystemSound(1309)
            }
        case .milestone:
            // Achievement sound
            AudioServicesPlaySystemSound(1322) // Anticipate sound
        case .warning:
            // Subtle alert
            AudioServicesPlaySystemSound(1306) // Telegraph sound
        }
        
        // Always provide haptic feedback
        hapticGenerator.impactOccurred()
    }
    
    private func shouldPlayAudioFeedback() -> Bool {
        // Audio feedback enabled by default - configurable via settings
        // For now, always provide feedback (will mix with music)
        return true
    }
    
    
    enum AudioFeedbackType {
        case splitComplete
        case lapComplete
        case milestone
        case warning
    }
    
    // MARK: - Timer Control
    func startSession() {
        sessionStartTime = Date()
        
        // Start HealthKit workout session
        Task {
            await startHealthKitTracking()
        }
        
        // Start timer with countdown
        timerViewModel.startCountdown()
        
        // Start GPS tracking if outdoor
        if isOutdoor {
            locationManager.startTracking()
        }
        
        Logger.info("Started cardio session: \(activityType.displayName), Outdoor: \(isOutdoor)")
    }
    
    func pauseSession() {
        timerViewModel.pauseTimer()
        sessionPausedTime = Date().timeIntervalSinceNow
        
        if isOutdoor {
            locationManager.pauseTracking()
        }
        
        Logger.info("Paused cardio session")
    }
    
    func resumeSession() {
        timerViewModel.resumeTimer()
        totalPausedTime += abs(sessionPausedTime)
        sessionPausedTime = 0
        
        if isOutdoor {
            locationManager.resumeTracking()
        }
        
        Logger.info("Resumed cardio session")
    }
    
    func stopSession() {
        timerViewModel.stopTimer()
        
        // Finish HealthKit workout
        Task {
            await saveHealthKitWorkout()
        }
        
        if isOutdoor {
            locationManager.stopTracking()
        }
        
        if bluetoothManager.isConnected {
            bluetoothManager.disconnect()
        }
        
        showingCompletionView = true
        
        Logger.info("Stopped cardio session - Duration: \(formattedDuration), Distance: \(formattedDistance)")
    }
    
    // MARK: - Metrics Calculation
    func updateMetrics() {
        // Only update if timer is running
        guard timerViewModel.isRunning else { return }
        
        // Update pace - Fix the calculation logic
        if isOutdoor && locationManager.totalDistance > 0 && timerViewModel.elapsedTime > 0 {
            let distanceKm = locationManager.totalDistance / 1000.0
            let timeMinutes = timerViewModel.elapsedTime / 60.0
            
            // Calculate current pace (minutes per km)
            currentPace = timeMinutes / distanceKm
            
            // Calculate average pace (excluding paused time)
            let activeTimeMinutes = (timerViewModel.elapsedTime - totalPausedTime) / 60.0
            averagePace = activeTimeMinutes / distanceKm
        } else {
            // For indoor or when no distance data
            currentPace = 0
            averagePace = 0
        }
        
        // Update calories - this now works without heart rate monitor
        currentCalories = calculateCalories()
        
        // Check for split (every km)
        checkForSplit()
        
        // Write real-time data to HealthKit
        Task {
            await collectHealthKitData()
        }
        
        // Force UI update by updating a computed property dependency
        Logger.debug("Updated metrics - Distance: \(locationManager.totalDistance)m, Pace: \(currentPace), Calories: \(currentCalories)")
    }
    
    private func calculateCalories() -> Int {
        guard let user = user else { return 0 }
        
        let durationHours = timerViewModel.elapsedTime / 3600
        let weight = user.currentWeight
        
        // Include heart rate if available for more accurate calculation
        if bluetoothManager.currentHeartRate > 0 {
            let hr = Double(bluetoothManager.currentHeartRate)
            let age = Double(user.age)
            let gender = user.genderEnum == .male ? 1.0 : 0.0
            
            // Using heart rate based formula
            let caloriesPerMinute = ((-55.0969 + (0.6309 * hr) + (0.1988 * weight) + (0.2017 * age)) / 4.184) * gender
            return Int(caloriesPerMinute * (timerViewModel.elapsedTime / 60))
        }
        
        // Fallback: MET-based calculation (works without heart rate monitor)
        var adjustedMET = activityType.metValue
        
        // Adjust MET based on GPS speed if available
        if isOutdoor && locationManager.currentSpeed > 0 {
            let speedKmh = locationManager.currentSpeed * 3.6
            
            switch activityType {
            case .running:
                adjustedMET = speedKmh < 8 ? 8.0 : (speedKmh < 12 ? 10.0 : 12.0)
            case .walking:
                adjustedMET = speedKmh < 4 ? 2.5 : (speedKmh < 6 ? 3.5 : 4.5)
            case .cycling:
                adjustedMET = speedKmh < 16 ? 6.0 : (speedKmh < 20 ? 8.0 : 10.0)
            }
        }
        
        // MET formula: Calories = MET × weight (kg) × time (hours)
        let calculatedCalories = adjustedMET * weight * durationHours
        
        // Ensure we return at least 1 calorie if there's activity
        return max(1, Int(calculatedCalories))
    }
    
    private func checkForSplit() {
        let splitDistance = UnitsConverter.getSplitDistance(system: unitSettings.unitSystem)
        let splitsCompleted = UnitsConverter.calculateSplitNumber(totalMeters: locationManager.totalDistance, system: unitSettings.unitSystem)
        
        if splitsCompleted > splits.count && splitsCompleted > 0 {
            let splitTime = timerViewModel.elapsedTime - splits.reduce(0) { $0 + $1.time }
            let splitPace = splitTime / 60 // min per unit distance
            
            let split = SplitData(
                distance: splitDistance,
                time: splitTime,
                pace: splitPace,
                heartRate: bluetoothManager.currentHeartRate > 0 ? bluetoothManager.currentHeartRate : nil
            )
            
            splits.append(split)
            
            // Audio feedback for split completion
            playAudioFeedback(for: .splitComplete)
            let splitLabel = UnitsFormatter.formatSplitDistance(splitNumber: splitsCompleted, system: unitSettings.unitSystem)
            Logger.info("\(splitLabel): \(formatPace(splitPace))")
        }
    }
    
    // MARK: - Heart Rate Methods
    func connectHeartRateDevice() {
        showingBluetoothSheet = true
        bluetoothManager.startScanning()
    }
    
    func selectHeartRateDevice(_ device: BluetoothManager.BluetoothDevice) {
        bluetoothManager.connect(to: device)
        selectedHeartRateMethod = .bluetooth
        showingBluetoothSheet = false
    }
    
    // MARK: - Computed Properties
    var formattedDuration: String {
        return timerViewModel.formattedTime
    }
    
    var formattedDistance: String {
        let distance = isOutdoor ? locationManager.totalDistance : 0
        return UnitsFormatter.formatDistance(meters: distance, system: unitSettings.unitSystem)
    }
    
    var formattedPace: String {
        guard currentPace > 0 && currentPace.isFinite else { return "--:--" }
        return formatPace(currentPace)
    }
    
    var formattedSpeed: String {
        let speed = isOutdoor ? locationManager.currentSpeed * 3.6 : 0
        return UnitsFormatter.formatSpeed(kmh: speed, system: unitSettings.unitSystem)
    }
    
    var formattedHeartRate: String {
        let hr = bluetoothManager.currentHeartRate
        return hr > 0 ? "\(hr)" : "--"
    }
    
    var heartRateZone: String {
        return bluetoothManager.currentZone.rawValue
    }
    
    var heartRateZoneColor: Color {
        return bluetoothManager.currentZone.color
    }
    
    var gpsAccuracy: String {
        return locationManager.locationAccuracy.description
    }
    
    var gpsAccuracyColor: Color {
        return locationManager.locationAccuracy.color
    }
    
    var perceivedEffortLevel: String {
        return "\(currentPerceivedEffort)"
    }
    
    var formattedManualDistance: String {
        return UnitsFormatter.formatDistance(meters: manualDistance, system: unitSettings.unitSystem)
    }
    
    // MARK: - Helper Methods
    private func formatPace(_ pace: Double) -> String {
        return UnitsFormatter.formatDetailedPace(minPerKm: pace, system: unitSettings.unitSystem)
    }

    /// Format split time in MM:SS format
    func formatSplitTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format pace for display with proper unit system
    func formatPaceForDisplay(_ pace: Double) -> String {
        return UnitsFormatter.formatDetailedPace(minPerKm: pace, system: unitSettings.unitSystem)
    }
    
    // MARK: - Session Completion
    func createCardioSession() -> CardioSession {
        let session = CardioSession(workout: nil, user: user)
        
        session.totalDuration = Int(timerViewModel.elapsedTime)
        session.totalDistance = locationManager.totalDistance
        session.totalCaloriesBurned = currentCalories
        
        if bluetoothManager.currentHeartRate > 0 {
            session.averageHeartRate = bluetoothManager.getAverageHeartRate()
            session.maxHeartRate = bluetoothManager.getMaxHeartRate()
        }
        
        if isOutdoor {
            session.routeData = locationManager.getRouteData()
            session.elevationGain = locationManager.getElevationGain()
            session.averageSpeed = locationManager.averageSpeed * 3.6 // Convert to km/h
        }
        
        return session
    }
    
    // MARK: - HealthKit Integration Methods (iOS Pattern)
    @MainActor
    private func startHealthKitTracking() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.warning("HealthKit not available on this device")
            return
        }
        
        // Clear previous data
        heartRateReadings.removeAll()
        calorieReadings.removeAll()
        
        Logger.info("HealthKit tracking started - collecting data locally")
    }
    
    @MainActor
    private func mapActivityTypeToHealthKit() -> HKWorkoutActivityType {
        switch activityType {
        case .running:
            return .running
        case .walking:
            return .walking
        case .cycling:
            return .cycling
        }
    }
    
    @MainActor
    private func collectHealthKitData() async {
        let now = Date()
        
        // Collect heart rate data
        if bluetoothManager.currentHeartRate > 0 {
            heartRateReadings.append((now, Double(bluetoothManager.currentHeartRate)))
        }
        
        // Collect calorie data
        if currentCalories > 0 {
            calorieReadings.append((now, Double(currentCalories)))
        }
    }
    
    @MainActor
    private func saveHealthKitWorkout() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let startTime = sessionStartTime else {
            return
        }
        
        do {
            let endTime = Date()
            var samples: [HKSample] = []
            
            // Create workout using HKWorkoutBuilder (iOS 17+)
            let workout = try await createWorkout(
                activityType: mapActivityTypeToHealthKit(),
                start: startTime,
                end: endTime,
                duration: endTime.timeIntervalSince(startTime) - totalPausedTime,
                totalEnergyBurned: currentCalories > 0 ? HKQuantity(unit: .kilocalorie(), doubleValue: Double(currentCalories)) : nil,
                totalDistance: isOutdoor ? HKQuantity(unit: .meter(), doubleValue: locationManager.totalDistance) : nil,
                isIndoor: !isOutdoor
            )
            samples.append(workout)
            
            // Add heart rate samples
            for (timestamp, heartRate) in heartRateReadings {
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: heartRate)
                let heartRateSample = HKQuantitySample(
                    type: heartRateType,
                    quantity: heartRateQuantity,
                    start: timestamp,
                    end: timestamp
                )
                samples.append(heartRateSample)
            }
            
            // Add route if outdoor and we have coordinates
            if isOutdoor && !locationManager.routeCoordinates.isEmpty {
                let locations = locationManager.routeCoordinates.map { coordinate in
                    CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                }
                
                let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
                try await routeBuilder.insertRouteData(locations)
                let route = try await routeBuilder.finishRoute(with: workout, metadata: nil)
                samples.append(route)
            }
            
            // Save all samples to HealthKit
            try await healthStore.save(samples)
            
            Logger.info("HealthKit workout saved successfully with \(samples.count) samples")
        } catch {
            Logger.error("Failed to save HealthKit workout: \(error)")
        }
        
        // Clean up local data
        heartRateReadings.removeAll()
        calorieReadings.removeAll()
    }
    
    // MARK: - HealthKit Workout Creation
    
    /// Creates a workout using HKWorkoutBuilder (iOS 17+ only)
    private func createWorkout(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        isIndoor: Bool
    ) async throws -> HKWorkout {
        
        let metadata: [String: Any] = [
            HKMetadataKeyIndoorWorkout: isIndoor
        ]
        
        return try await createWorkoutWithBuilder(
            activityType: activityType,
            start: start,
            end: end,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: metadata
        )
    }
    
    /// Modern workout creation using HKWorkoutBuilder (iOS 17+ only)
    private func createWorkoutWithBuilder(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]
    ) async throws -> HKWorkout {
        
        let healthStore = HKHealthStore()
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = metadata[HKMetadataKeyIndoorWorkout] as? Bool == true ? .indoor : .outdoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        return try await withCheckedThrowingContinuation { continuation in
            builder.beginCollection(withStart: start) { success, error in
                if let error = error {
                    print("⚠️ HKWorkoutBuilder failed to begin collection: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                // Add energy burned if available
                if let energyBurned = totalEnergyBurned {
                    let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                    let energySample = HKQuantitySample(
                        type: energyType,
                        quantity: energyBurned,
                        start: start,
                        end: end
                    )
                    builder.add([energySample]) { success, error in
                        if let error = error {
                            print("⚠️ Failed to add energy sample: \(error)")
                        }
                    }
                }
                
                // Add distance if available
                if let distance = totalDistance {
                    let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
                    let distanceSample = HKQuantitySample(
                        type: distanceType,
                        quantity: distance,
                        start: start,
                        end: end
                    )
                    builder.add([distanceSample]) { success, error in
                        if let error = error {
                            print("⚠️ Failed to add distance sample: \(error)")
                        }
                    }
                }
                
                builder.endCollection(withEnd: end) { success, error in
                    if let error = error {
                        print("⚠️ HKWorkoutBuilder failed to end collection: \(error)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    builder.finishWorkout { workout, error in
                        if let error = error {
                            print("⚠️ HKWorkoutBuilder failed to finish workout: \(error)")
                            continuation.resume(throwing: error)
                        } else if let workout = workout {
                            continuation.resume(returning: workout)
                        } else {
                            print("⚠️ HKWorkoutBuilder returned no workout")
                            let noWorkoutError = NSError(domain: "HKWorkoutBuilder", code: -1, userInfo: [NSLocalizedDescriptionKey: "No workout returned from builder"])
                            continuation.resume(throwing: noWorkoutError)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Volume Button Monitoring & Screen Lock

    /**
     * Sets up volume button monitoring for screen unlock functionality
     */
    func setupVolumeButtonMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        lastVolumeLevel = audioSession.outputVolume

        volumeButtonMonitor = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let currentVolume = audioSession.outputVolume

            // Detect volume button press (both up and down)
            Task { @MainActor in
                if abs(currentVolume - self.lastVolumeLevel) > 0.01 {
                    self.volumeButtonPressed()
                    self.lastVolumeLevel = currentVolume
                }
            }
        }
    }

    /**
     * Cleans up volume button monitoring timers
     */
    func cleanupVolumeButtonMonitoring() {
        volumeButtonMonitor?.invalidate()
        volumeButtonMonitor = nil
        volumeUnlockTimer?.invalidate()
        volumeUnlockTimer = nil
    }

    /**
     * Handles volume button press for screen unlock
     */
    private func volumeButtonPressed() {
        guard isScreenLocked else { return }

        volumeButtonPressCount += 1

        // If this is the first press, start the timer
        if volumeButtonPressCount == 1 {
            volumeUnlockTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task { @MainActor in
                    // Reset count after 3 seconds
                    self.volumeButtonPressCount = 0
                }
            }
        }

        // Check if we have enough presses to unlock (both volume up and down within 3 seconds)
        if volumeButtonPressCount >= 4 { // Multiple quick presses simulate up+down combo
            unlockScreen()
        }
    }

    /**
     * Unlocks the screen with animation and haptic feedback
     */
    func unlockScreen() {
        withAnimation(.easeOut(duration: 0.3)) {
            isScreenLocked = false
            lockSlideOffset = 0
        }

        // Success haptic feedback
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)

        // Reset counter
        volumeButtonPressCount = 0
        volumeUnlockTimer?.invalidate()
        volumeUnlockTimer = nil

        Logger.info("Screen unlocked via volume button combination")
    }

    /**
     * Locks the screen programmatically
     */
    func lockScreen() {
        withAnimation(.easeOut(duration: 0.3)) {
            isScreenLocked = true
            lockSlideOffset = 0
        }
    }

}