import SwiftUI

/**
 * Screen lock overlay component for Cardio Live Tracking.
 *
 * Provides a full-screen overlay with essential workout metrics and unlock mechanisms
 * when screen is locked during workout to prevent accidental touches.
 *
 * Features:
 * - Essential metrics display during lock
 * - Slide-to-unlock mechanism
 * - Volume button unlock hints
 * - Real-time workout data updates
 */
struct ScreenLockOverlay: View {
    @Environment(\.theme) private var theme

    // Lock state properties
    @Binding var isScreenLocked: Bool
    @Binding var lockSlideOffset: CGFloat

    // Workout data
    let formattedDuration: String
    let isTimerRunning: Bool
    let isOutdoor: Bool

    // ViewModels for metrics
    let viewModel: CardioTimerViewModel

    // Unlock callback
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent any accidental taps
                }

            VStack(spacing: theme.spacing.xl) {
                // Lock Icon and Status
                lockHeader

                Spacer()

                // Essential metrics display
                essentialMetrics

                Spacer()

                // Slide to unlock
                slideToUnlockView

                // Alternative unlock method hint
                unlockHints
            }
            .padding(theme.spacing.l)
        }
        .transition(.opacity)
    }

    // MARK: - Lock Header

    private var lockHeader: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            Text("training.screen_lock.screen_locked".localized)
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("training.screen_lock.accidental_press_protection".localized)
                .font(theme.typography.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Essential Metrics

    private var essentialMetrics: some View {
        VStack(spacing: theme.spacing.l) {
            // Timer Display
            TimerDisplay(
                formattedTime: formattedDuration,
                isRunning: isTimerRunning,
                size: .large
            )

            // Key metrics based on workout type
            HStack(spacing: theme.spacing.xl) {
                ForEach(getEssentialMetrics(), id: \.key) { metric in
                    VStack(spacing: 4) {
                        Text(metric.value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(metric.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    // MARK: - Slide to Unlock

    private var slideToUnlockView: some View {
        let sliderWidth: CGFloat = 300
        let knobSize: CGFloat = 50
        let maxOffset = sliderWidth - knobSize

        return ZStack {
            // Background track
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.2))
                .frame(height: 50)
                .overlay(
                    Text("training.screen_lock.slide_to_unlock".localized)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(
                            CardioScreenLockService.calculateUnlockTextOpacity(
                                progress: CardioScreenLockService.calculateSlideProgress(
                                    slideOffset: lockSlideOffset,
                                    maxOffset: maxOffset
                                )
                            )
                        ))
                )

            // Sliding knob
            HStack {
                RoundedRectangle(cornerRadius: 22.5)
                    .fill(
                        LinearGradient(
                            colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: knobSize, height: 45)
                    .overlay(
                        Image(systemName: "lock.open.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                    .offset(x: lockSlideOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                lockSlideOffset = CardioScreenLockService.constrainSlideOffset(
                                    value.translation.width,
                                    maxOffset: maxOffset
                                )
                            }
                            .onEnded { value in
                                if CardioScreenLockService.shouldUnlockWithSlide(
                                    slideOffset: lockSlideOffset,
                                    maxOffset: maxOffset
                                ) {
                                    // Unlock successful
                                    onUnlock()
                                    CardioScreenLockService.triggerUnlockSuccessHaptic()
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        lockSlideOffset = 0
                                    }
                                    CardioScreenLockService.triggerSlideAttemptHaptic()
                                }
                            }
                    )

                Spacer()
            }
        }
        .frame(width: sliderWidth)
    }

    // MARK: - Unlock Hints

    private var unlockHints: some View {
        VStack(spacing: theme.spacing.s) {
            Text("training.screen_lock.or".localized)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            Text("training.screen_lock.volume_buttons_hint".localized)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helper Methods

    /**
     * Gets essential metrics for lock screen display.
     */
    private func getEssentialMetrics() -> [EssentialMetric] {
        var metrics: [EssentialMetric] = []

        // Always show calories
        metrics.append(EssentialMetric(
            key: "calories",
            value: "\(viewModel.currentCalories)",
            subtitle: "kcal"
        ))

        // Distance for outdoor workouts
        if isOutdoor {
            metrics.append(EssentialMetric(
                key: "distance",
                value: viewModel.formattedDistance,
                subtitle: "Mesafe"
            ))
        }

        // Heart rate if connected
        if viewModel.bluetoothManager.isConnected {
            metrics.append(EssentialMetric(
                key: "heartRate",
                value: viewModel.formattedHeartRate,
                subtitle: "BPM"
            ))
        }

        return metrics
    }
}

// MARK: - Supporting Types

/**
 * Essential metric for lock screen display.
 */
struct EssentialMetric {
    let key: String
    let value: String
    let subtitle: String
}

// MARK: - Preview

#Preview {
    ScreenLockOverlay(
        isScreenLocked: .constant(true),
        lockSlideOffset: .constant(0),
        formattedDuration: "15:30",
        isTimerRunning: true,
        isOutdoor: true,
        viewModel: CardioTimerViewModel(
            activityType: .running,
            isOutdoor: true,
            user: User(
                name: "Test User",
                age: 30,
                gender: .male,
                height: 180,
                currentWeight: 75,
                fitnessGoal: .maintain,
                activityLevel: .moderate,
                selectedLanguage: "tr"
            )
        ),
        onUnlock: { }
    )
}