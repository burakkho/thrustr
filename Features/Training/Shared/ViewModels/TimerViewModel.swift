import SwiftUI
import Foundation

@Observable
class TimerViewModel {
    // MARK: - Published Properties
    var elapsedTime: TimeInterval = 0
    var formattedTime: String = "00:00.0"
    var isRunning = false
    var isPaused = false
    var isCompleted = false
    var timerState: TimerState = .stopped
    
    // Countdown properties
    var isCountdown = false
    var countdownValue = 3
    var showingCountdown = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var countdownStartTime: Date?
    
    // MARK: - Enums
    enum TimerState: Int {
        case stopped = 0, countdown = 1, running = 2, paused = 3, completed = 4
    }
    
    // MARK: - Public Methods
    
    func startCountdown() {
        guard timerState == .stopped else { return }
        
        timerState = .countdown
        isCountdown = true
        showingCountdown = true
        countdownValue = 3
        countdownStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    func startTimer() {
        guard timerState == .stopped else { return }
        
        DispatchQueue.main.async {
            HapticManager.shared.impact(.medium)
        }
        
        timerState = .running
        isRunning = true
        isPaused = false
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMainTimer()
        }
    }
    
    func pauseTimer() {
        guard timerState == .running else { return }
        
        DispatchQueue.main.async {
            HapticManager.shared.impact(.light)
        }
        
        timer?.invalidate()
        timer = nil
        timerState = .paused
        isPaused = true
        pausedTime = elapsedTime
    }
    
    func resumeTimer() {
        guard timerState == .paused else { return }
        
        startTime = Date().addingTimeInterval(-pausedTime)
        timerState = .running
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMainTimer()
        }
    }
    
    func stopTimer() {
        DispatchQueue.main.async {
            HapticManager.shared.notification(.success)
        }
        
        timer?.invalidate()
        timer = nil
        timerState = .completed
        isRunning = false
        isPaused = false
        isCompleted = true
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .stopped
        isRunning = false
        isPaused = false
        isCompleted = false
        elapsedTime = 0
        formattedTime = "00:00"
        isCountdown = false
        showingCountdown = false
        countdownValue = 3
        startTime = nil
        pausedTime = 0
        countdownStartTime = nil
    }
    
    // MARK: - Private Methods
    
    private func updateCountdown() {
        countdownValue -= 1
        
        if countdownValue > 0 {
            // Continue countdown
            return
        } else {
            // Countdown finished, start main timer
            timer?.invalidate()
            timer = nil
            
            isCountdown = false
            showingCountdown = false
            timerState = .running
            isRunning = true
            
            startTime = Date()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateMainTimer()
            }
        }
    }
    
    private func updateMainTimer() {
        guard let startTime = startTime else { return }
        
        elapsedTime = Date().timeIntervalSince(startTime)
        formattedTime = formatTime(elapsedTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Cleanup
    
    deinit {
        timer?.invalidate()
    }
}
