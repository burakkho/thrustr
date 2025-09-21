import Foundation
import AVFoundation
import SwiftUI

/**
 * Volume button monitoring service for workout screen unlock functionality.
 *
 * Handles volume button detection during cardio workouts to enable screen unlock
 * when users are unable to use touch gestures. Provides timer-based monitoring
 * with proper cleanup and background operation support.
 *
 * Features:
 * - Volume level change detection
 * - Press counting with timeout management
 * - Background monitoring setup/cleanup
 * - Unlock callback integration
 * - Memory leak prevention
 */
@Observable
class CardioVolumeButtonService {

    // MARK: - Observable Properties

    /// Current volume button press count
    var pressCount: Int = 0

    /// Last recorded system volume level
    var lastVolumeLevel: Float = 0

    /// Whether monitoring is currently active
    var isMonitoring: Bool = false

    // MARK: - Private Properties

    /// Timer for volume button monitoring
    private var monitoringTimer: Timer?

    /// Timer for press count timeout
    private var timeoutTimer: Timer?

    /// Unlock callback to notify when unlock should occur
    private var unlockCallback: (() -> Void)?

    // MARK: - Configuration

    /// Monitoring interval for volume changes (seconds)
    private let monitoringInterval: TimeInterval = 0.1

    /// Press count timeout duration (seconds)
    private let pressCountTimeout: TimeInterval = CardioScreenLockService.volumeUnlockTimeout

    /// Required press count for unlock
    private let requiredPressCount: Int = CardioScreenLockService.volumeUnlockPressCount

    /// Volume change threshold for press detection
    private let volumeChangeThreshold: Float = CardioScreenLockService.volumeChangeThreshold

    // MARK: - Public Methods

    /**
     * Starts volume button monitoring with unlock callback.
     *
     * - Parameter onUnlock: Callback to execute when unlock conditions are met
     */
    func startMonitoring(onUnlock: @escaping () -> Void) {
        guard !isMonitoring else { return }

        unlockCallback = onUnlock
        setupInitialVolumeLevel()
        startMonitoringTimer()
        isMonitoring = true

        Logger.info("Volume button monitoring started for screen unlock")
    }

    /**
     * Stops volume button monitoring and cleans up resources.
     */
    func stopMonitoring() {
        guard isMonitoring else { return }

        cleanupTimers()
        resetState()
        isMonitoring = false

        Logger.info("Volume button monitoring stopped")
    }

    /**
     * Resets press count and timeout timer.
     */
    func resetPressCount() {
        pressCount = 0
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    /**
     * Forces an unlock trigger (for testing or manual unlock).
     */
    func triggerUnlock() {
        unlockCallback?()
        resetPressCount()
        Logger.info("Manual volume button unlock triggered")
    }

    // MARK: - Private Methods

    /**
     * Sets up initial system volume level for comparison.
     */
    private func setupInitialVolumeLevel() {
        let audioSession = AVAudioSession.sharedInstance()
        lastVolumeLevel = audioSession.outputVolume
    }

    /**
     * Starts the volume monitoring timer.
     */
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkVolumeChange()
            }
        }
    }

    /**
     * Checks for volume level changes and processes button presses.
     */
    @MainActor
    private func checkVolumeChange() {
        let audioSession = AVAudioSession.sharedInstance()
        let currentVolume = audioSession.outputVolume

        // Detect volume button press using service validation
        if CardioScreenLockService.detectVolumeButtonPress(
            currentVolume: currentVolume,
            previousVolume: lastVolumeLevel
        ) {
            processVolumeButtonPress()
            lastVolumeLevel = currentVolume
        }
    }

    /**
     * Processes a detected volume button press.
     */
    @MainActor
    private func processVolumeButtonPress() {
        pressCount += 1

        // Start timeout timer on first press
        if pressCount == 1 {
            startTimeoutTimer()
        }

        // Check if unlock conditions are met
        if CardioScreenLockService.shouldUnlockWithVolumeButtons(pressCount: pressCount) {
            executeUnlock()
        }

        Logger.debug("Volume button press detected. Count: \(pressCount)")
    }

    /**
     * Starts the press count timeout timer.
     */
    private func startTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: pressCountTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handlePressCountTimeout()
            }
        }
    }

    /**
     * Handles press count timeout by resetting count.
     */
    @MainActor
    private func handlePressCountTimeout() {
        Logger.debug("Volume button press count timeout - resetting")
        resetPressCount()
    }

    /**
     * Executes unlock callback and triggers success haptic feedback.
     */
    private func executeUnlock() {
        // Trigger unlock
        unlockCallback?()

        // Success haptic feedback
        CardioScreenLockService.triggerUnlockSuccessHaptic()

        // Reset press count
        resetPressCount()

        Logger.info("Screen unlocked via volume button combination")
    }

    /**
     * Cleans up all timers to prevent memory leaks.
     */
    private func cleanupTimers() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil

        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    /**
     * Resets all internal state to default values.
     */
    private func resetState() {
        pressCount = 0
        lastVolumeLevel = 0
        unlockCallback = nil
    }

    // MARK: - Deinitializer

    deinit {
        stopMonitoring()
    }
}

// MARK: - Supporting Types

/**
 * Volume button monitoring state for debugging and analytics.
 */
struct VolumeButtonState {
    let isMonitoring: Bool
    let pressCount: Int
    let lastVolumeLevel: Float
    let timeSinceLastPress: TimeInterval?

    init(service: CardioVolumeButtonService) {
        self.isMonitoring = service.isMonitoring
        self.pressCount = service.pressCount
        self.lastVolumeLevel = service.lastVolumeLevel
        self.timeSinceLastPress = nil // Could be enhanced with timestamp tracking
    }
}

/**
 * Volume monitoring configuration for customization.
 */
struct VolumeMonitoringConfig {
    let monitoringInterval: TimeInterval
    let pressCountTimeout: TimeInterval
    let requiredPressCount: Int
    let volumeChangeThreshold: Float

    static let `default` = VolumeMonitoringConfig(
        monitoringInterval: 0.1,
        pressCountTimeout: CardioScreenLockService.volumeUnlockTimeout,
        requiredPressCount: CardioScreenLockService.volumeUnlockPressCount,
        volumeChangeThreshold: CardioScreenLockService.volumeChangeThreshold
    )
}