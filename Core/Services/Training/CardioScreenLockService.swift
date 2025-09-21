import Foundation
import SwiftUI

/**
 * Screen lock management service for Cardio Live Tracking.
 *
 * Handles screen locking functionality during cardio workouts to prevent
 * accidental touches while maintaining access to essential workout metrics.
 * Provides slide-to-unlock and volume button unlock mechanisms.
 *
 * Features:
 * - Screen lock state management
 * - Slide-to-unlock gesture handling
 * - Volume button unlock detection
 * - Haptic feedback integration
 * - Security timeout management
 */
struct CardioScreenLockService: Sendable {

    // MARK: - Configuration

    /// Maximum slide offset for unlock (knob travel distance)
    static let maxSlideOffset: CGFloat = 250.0

    /// Minimum slide percentage required for unlock
    static let unlockThreshold: Double = 0.8

    /// Volume button press count required for unlock
    static let volumeUnlockPressCount: Int = 4

    /// Timeout for volume button unlock sequence (seconds)
    static let volumeUnlockTimeout: TimeInterval = 3.0

    /// Volume level change threshold for press detection
    static let volumeChangeThreshold: Float = 0.01

    // MARK: - Screen Lock Validation

    /**
     * Validates if slide gesture should trigger unlock.
     *
     * - Parameters:
     *   - slideOffset: Current slide offset value
     *   - maxOffset: Maximum allowed offset
     * - Returns: Boolean indicating if unlock should occur
     */
    static func shouldUnlockWithSlide(slideOffset: CGFloat, maxOffset: CGFloat) -> Bool {
        guard maxOffset > 0 else { return false }
        let progress = slideOffset / maxOffset
        return progress >= unlockThreshold
    }

    /**
     * Calculates slide progress percentage for UI feedback.
     *
     * - Parameters:
     *   - slideOffset: Current slide offset
     *   - maxOffset: Maximum allowed offset
     * - Returns: Progress percentage (0.0 to 1.0)
     */
    static func calculateSlideProgress(slideOffset: CGFloat, maxOffset: CGFloat) -> Double {
        guard maxOffset > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(slideOffset / maxOffset)))
    }

    /**
     * Constrains slide offset within valid bounds.
     *
     * - Parameters:
     *   - offset: Proposed offset value
     *   - maxOffset: Maximum allowed offset
     * - Returns: Constrained offset value
     */
    static func constrainSlideOffset(_ offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
        return max(0, min(maxOffset, offset))
    }

    // MARK: - Volume Button Unlock

    /**
     * Validates if volume button press count should trigger unlock.
     *
     * - Parameter pressCount: Current press count
     * - Returns: Boolean indicating if unlock should occur
     */
    static func shouldUnlockWithVolumeButtons(pressCount: Int) -> Bool {
        return pressCount >= volumeUnlockPressCount
    }

    /**
     * Detects significant volume level change indicating button press.
     *
     * - Parameters:
     *   - currentVolume: Current system volume level
     *   - previousVolume: Previous system volume level
     * - Returns: Boolean indicating if press was detected
     */
    static func detectVolumeButtonPress(currentVolume: Float, previousVolume: Float) -> Bool {
        return abs(currentVolume - previousVolume) > volumeChangeThreshold
    }

    // MARK: - Haptic Feedback

    /**
     * Triggers unlock success haptic feedback.
     */
    static func triggerUnlockSuccessHaptic() {
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }

    /**
     * Triggers slide attempt haptic feedback.
     */
    static func triggerSlideAttemptHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    /**
     * Triggers screen lock activation haptic feedback.
     */
    static func triggerLockActivationHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - Utility Methods

    /**
     * Formats slide-to-unlock text visibility based on progress.
     *
     * - Parameter progress: Slide progress (0.0 to 1.0)
     * - Returns: Text opacity value
     */
    static func calculateUnlockTextOpacity(progress: Double) -> Double {
        return progress > 0.8 ? 0 : (progress > 0.3 ? 0.3 : 0.8)
    }

    /**
     * Calculates knob shadow intensity based on slide progress.
     *
     * - Parameter progress: Slide progress (0.0 to 1.0)
     * - Returns: Shadow opacity value
     */
    static func calculateKnobShadowOpacity(progress: Double) -> Double {
        return 0.3 + (progress * 0.2) // 0.3 to 0.5
    }
}

// MARK: - Supporting Types

/**
 * Screen lock unlock method for analytics and logging.
 */
enum ScreenLockUnlockMethod: String, CaseIterable {
    case slideGesture = "slide_gesture"
    case volumeButtons = "volume_buttons"
    case manual = "manual"
}

/**
 * Screen lock state for comprehensive state management.
 */
struct ScreenLockState {
    var isLocked: Bool = false
    var slideOffset: CGFloat = 0
    var volumePressCount: Int = 0
    var lastVolumeLevel: Float = 0
    var unlockMethod: ScreenLockUnlockMethod?

    /**
     * Resets all state to default values.
     */
    mutating func reset() {
        isLocked = false
        slideOffset = 0
        volumePressCount = 0
        lastVolumeLevel = 0
        unlockMethod = nil
    }

    /**
     * Prepares state for new lock session.
     */
    mutating func prepareLock() {
        slideOffset = 0
        volumePressCount = 0
        unlockMethod = nil
        isLocked = true
    }
}