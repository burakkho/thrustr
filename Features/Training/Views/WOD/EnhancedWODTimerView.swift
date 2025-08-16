import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct EnhancedWODTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    let wod: WOD
    let movements: [WODMovement]
    let isRX: Bool
    
    // Timer states
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var isCompleted = false
    
    // AMRAP/Round tracking
    @State private var completedRounds = 0
    @State private var currentMovementIndex = 0
    @State private var currentRepIndex = 0
    @State private var movementSplits: [TimeInterval] = []
    @State private var roundSplits: [TimeInterval] = []
    
    // UI States
    @State private var showingResultEntry = false
    @State private var showingCountdown = false
    @State private var countdownValue = 3
    @State private var splitMode = false
    
    // Sound effects
    @State private var audioPlayer: AVAudioPlayer?
    
    private var currentUser: User? {
        user.first
    }
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
    
    private var formattedSplitTime: String {
        let lastSplit = roundSplits.last ?? 0
        let currentSplit = elapsedTime - lastSplit
        let minutes = Int(currentSplit) / 60
        let seconds = Int(currentSplit) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var currentMovement: WODMovement? {
        guard currentMovementIndex < movements.count else { return nil }
        return movements[currentMovementIndex]
    }
    
    private var progressPercentage: Double {
        guard wod.wodType == .forTime, !wod.repScheme.isEmpty else { return 0 }
        
        let totalReps = wod.repScheme.reduce(0, +) * movements.count
        let completedReps = calculateCompletedReps()
        
        return min(Double(completedReps) / Double(totalReps), 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        theme.colors.accent.opacity(0.1),
                        theme.colors.backgroundPrimary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Button("Cancel") {
                            timer?.invalidate()
                            UIApplication.shared.isIdleTimerDisabled = false
                            dismiss()
                        }
                        .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer()
                        
                        Text(wod.name)
                            .font(theme.typography.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if isRX {
                            Text("RX")
                                .font(theme.typography.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, theme.spacing.s)
                                .padding(.vertical, 2)
                                .background(theme.colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(theme.radius.s)
                        }
                    }
                    .padding()
                    
                    // Main Timer Display
                    VStack(spacing: theme.spacing.m) {
                        // Progress Ring for For Time WODs
                        if wod.wodType == .forTime {
                            ZStack {
                                Circle()
                                    .stroke(theme.colors.backgroundSecondary, lineWidth: 20)
                                    .frame(width: 250, height: 250)
                                
                                Circle()
                                    .trim(from: 0, to: progressPercentage)
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.colors.accent, theme.colors.success],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                    )
                                    .frame(width: 250, height: 250)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.5), value: progressPercentage)
                                
                                VStack(spacing: 8) {
                                    Text(formattedTime)
                                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                                        .foregroundColor(isRunning ? theme.colors.accent : theme.colors.textPrimary)
                                    
                                    if splitMode && isRunning {
                                        Text("Split: \(formattedSplitTime)")
                                            .font(theme.typography.body)
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                }
                            }
                        } else {
                            // Standard timer display for AMRAP/EMOM
                            VStack(spacing: 8) {
                                Text(formattedTime)
                                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                                    .foregroundColor(isRunning ? theme.colors.accent : theme.colors.textPrimary)
                                
                                if wod.wodType == .amrap {
                                    HStack(spacing: theme.spacing.xl) {
                                        VStack {
                                            Text("Rounds")
                                                .font(theme.typography.caption)
                                                .foregroundColor(theme.colors.textSecondary)
                                            Text("\(completedRounds)")
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(theme.colors.success)
                                        }
                                        
                                        VStack {
                                            Text("Movement")
                                                .font(theme.typography.caption)
                                                .foregroundColor(theme.colors.textSecondary)
                                            Text("\(currentMovementIndex + 1)/\(movements.count)")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(theme.colors.accent)
                                        }
                                    }
                                    .padding(.top, theme.spacing.m)
                                }
                            }
                        }
                    }
                    .padding(.vertical, theme.spacing.xl)
                    
                    // Movement Display
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: theme.spacing.m) {
                                ForEach(Array(movements.enumerated()), id: \.element.id) { index, movement in
                                    MovementTimerCard(
                                        movement: movement,
                                        index: index,
                                        isCurrent: currentMovementIndex == index,
                                        isCompleted: index < currentMovementIndex || (wod.wodType == .amrap && completedRounds > 0),
                                        repScheme: wod.repScheme,
                                        currentRepIndex: currentRepIndex
                                    )
                                    .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: currentMovementIndex) { _, newValue in
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    
                    // Control Panel
                    VStack(spacing: theme.spacing.m) {
                        // Split/Round buttons for active timer
                        if isRunning && !isPaused {
                            HStack(spacing: theme.spacing.m) {
                                if wod.wodType == .forTime {
                                    Button(action: recordSplit) {
                                        HStack {
                                            Image(systemName: "timer")
                                            Text("Split")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(theme.colors.accent.opacity(0.2))
                                        .foregroundColor(theme.colors.accent)
                                        .cornerRadius(theme.radius.m)
                                    }
                                    
                                    Button(action: nextMovement) {
                                        HStack {
                                            Image(systemName: "arrow.right.circle")
                                            Text("Next")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(theme.colors.success.opacity(0.2))
                                        .foregroundColor(theme.colors.success)
                                        .cornerRadius(theme.radius.m)
                                    }
                                } else if wod.wodType == .amrap {
                                    Button(action: completeRound) {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                            Text("Complete Round (+1)")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(theme.colors.success)
                                        .foregroundColor(.white)
                                        .cornerRadius(theme.radius.m)
                                    }
                                }
                            }
                        }
                        
                        // Main control buttons
                        HStack(spacing: theme.spacing.m) {
                            if !isRunning && !isCompleted {
                                Button(action: startCountdown) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Start")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.colors.success)
                                    .foregroundColor(.white)
                                    .cornerRadius(theme.radius.m)
                                }
                            } else if isRunning {
                                Button(action: togglePause) {
                                    HStack {
                                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                        Text(isPaused ? "Resume" : "Pause")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.colors.warning)
                                    .foregroundColor(.white)
                                    .cornerRadius(theme.radius.m)
                                }
                                
                                Button(action: stopTimer) {
                                    HStack {
                                        Image(systemName: "stop.fill")
                                        Text("Finish")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.colors.error)
                                    .foregroundColor(.white)
                                    .cornerRadius(theme.radius.m)
                                }
                            } else if isCompleted {
                                Button(action: saveResult) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save Result")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.colors.success)
                                    .foregroundColor(.white)
                                    .cornerRadius(theme.radius.m)
                                }
                            }
                        }
                        
                        // Split times display
                        if !roundSplits.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.m) {
                                    ForEach(Array(roundSplits.enumerated()), id: \.offset) { index, split in
                                        VStack {
                                            Text("R\(index + 1)")
                                                .font(theme.typography.caption)
                                                .foregroundColor(theme.colors.textSecondary)
                                            Text(formatTime(split))
                                                .font(theme.typography.caption2)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, theme.spacing.s)
                                        .padding(.vertical, 4)
                                        .background(theme.colors.backgroundSecondary)
                                        .cornerRadius(theme.radius.s)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                setupAudio()
            }
            .onDisappear {
                timer?.invalidate()
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .overlay(
                CountdownOverlay(isShowing: $showingCountdown, value: $countdownValue)
            )
            .sheet(isPresented: $showingResultEntry) {
                EnhancedResultEntryView(
                    wod: wod,
                    isRX: isRX,
                    elapsedTime: elapsedTime,
                    rounds: completedRounds,
                    splits: roundSplits,
                    onSave: { result in
                        saveWODResult(result)
                    }
                )
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func startCountdown() {
        showingCountdown = true
        countdownValue = 3
        playSound("countdown")
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { countdownTimer in
            countdownValue -= 1
            if countdownValue > 0 {
                playSound("countdown")
            } else {
                countdownTimer.invalidate()
                showingCountdown = false
                startTimer()
                playSound("start")
            }
        }
    }
    
    private func startTimer() {
        isRunning = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            
            // Check time cap
            if let timeCap = wod.timeCap, elapsedTime >= Double(timeCap) {
                stopTimer()
                playSound("finish")
            }
        }
    }
    
    private func togglePause() {
        if isPaused {
            startTimer()
        } else {
            timer?.invalidate()
            isPaused = true
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        isRunning = false
        isCompleted = true
        playSound("finish")
        showingResultEntry = true
    }
    
    private func recordSplit() {
        movementSplits.append(elapsedTime)
        HapticManager.shared.impact(.medium)
    }
    
    private func nextMovement() {
        if currentMovementIndex < movements.count - 1 {
            currentMovementIndex += 1
            HapticManager.shared.impact(.light)
        } else {
            // End of round for For Time
            if wod.wodType == .forTime {
                if currentRepIndex < wod.repScheme.count - 1 {
                    currentRepIndex += 1
                    currentMovementIndex = 0
                    roundSplits.append(elapsedTime)
                    playSound("round")
                } else {
                    // Workout complete
                    stopTimer()
                }
            }
        }
    }
    
    private func completeRound() {
        completedRounds += 1
        currentMovementIndex = 0
        roundSplits.append(elapsedTime)
        playSound("round")
        HapticManager.shared.notification(.success)
    }
    
    private func saveResult() {
        showingResultEntry = true
    }
    
    private func saveWODResult(_ result: WODResult) {
        modelContext.insert(result)
        result.wod = wod
        result.user = currentUser
        wod.results.append(result)
        
        // Save splits as JSON
        if !roundSplits.isEmpty {
            let splitsData = roundSplits.map { formatTime($0) }
            if let jsonData = try? JSONEncoder().encode(splitsData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                result.splits = jsonString
            }
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.notification(.success)
            dismiss()
        } catch {
            print("Error saving WOD result: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateCompletedReps() -> Int {
        guard wod.wodType == .forTime else { return 0 }
        
        var totalReps = 0
        
        // Calculate completed full rounds
        if currentRepIndex > 0 {
            for i in 0..<currentRepIndex {
                totalReps += wod.repScheme[i] * movements.count
            }
        }
        
        // Add current round progress
        if currentRepIndex < wod.repScheme.count {
            totalReps += wod.repScheme[currentRepIndex] * currentMovementIndex
        }
        
        return totalReps
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Audio
    
    private func setupAudio() {
        // Pre-load sound effects
        _ = try? AVAudioSession.sharedInstance().setCategory(.ambient)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func playSound(_ type: String) {
        // Simple system sounds for now
        switch type {
        case "countdown":
            AudioServicesPlaySystemSound(1057) // Tick
        case "start":
            AudioServicesPlaySystemSound(1054) // Start
        case "round":
            AudioServicesPlaySystemSound(1055) // Round complete
        case "finish":
            AudioServicesPlaySystemSound(1053) // Finish
        default:
            break
        }
    }
}

// MARK: - Movement Timer Card
private struct MovementTimerCard: View {
    let movement: WODMovement
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let repScheme: [Int]
    let currentRepIndex: Int
    
    @Environment(\.theme) private var theme
    
    private var repsToDisplay: String {
        if let specificReps = movement.reps {
            return "\(specificReps)"
        } else if !repScheme.isEmpty && currentRepIndex < repScheme.count {
            return "\(repScheme[currentRepIndex])"
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? theme.colors.success : 
                          isCurrent ? theme.colors.accent : 
                          theme.colors.backgroundSecondary)
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Text("\(index + 1)")
                        .foregroundColor(isCurrent ? .white : theme.colors.textSecondary)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if !repsToDisplay.isEmpty {
                        Text(repsToDisplay)
                            .font(theme.typography.headline)
                            .foregroundColor(isCurrent ? theme.colors.accent : theme.colors.textPrimary)
                    }
                    
                    Text(movement.name)
                        .font(theme.typography.body)
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundColor(isCurrent ? theme.colors.textPrimary : 
                                       isCompleted ? theme.colors.textSecondary : 
                                       theme.colors.textPrimary)
                }
                
                if let userWeight = movement.userWeight {
                    Text("\(Int(userWeight))kg")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "arrow.right")
                    .foregroundColor(theme.colors.accent)
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(isCurrent ? theme.colors.accent.opacity(0.1) : 
                      isCompleted ? theme.colors.success.opacity(0.05) : 
                      theme.colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(isCurrent ? theme.colors.accent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Countdown Overlay
private struct CountdownOverlay: View {
    @Binding var isShowing: Bool
    @Binding var value: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(value > 0 ? "\(value)" : "GO!")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(value > 0 ? 1.0 : 1.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
                    
                    Text("Get Ready!")
                        .font(theme.typography.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Enhanced Result Entry
private struct EnhancedResultEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    let wod: WOD
    let isRX: Bool
    let elapsedTime: TimeInterval
    let rounds: Int
    let splits: [TimeInterval]
    let onSave: (WODResult) -> Void
    
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Result Summary
                    VStack(spacing: theme.spacing.m) {
                        Text("Workout Complete!")
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                        
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.accent)
                        
                        if wod.wodType == .amrap {
                            Text("\(rounds) rounds completed")
                                .font(theme.typography.headline)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        if isRX {
                            Label("Completed RX", systemImage: "checkmark.seal.fill")
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.success)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
                    
                    // Split Times
                    if !splits.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            Text("Split Times")
                                .font(theme.typography.headline)
                            
                            ForEach(Array(splits.enumerated()), id: \.offset) { index, split in
                                HStack {
                                    Text("Round \(index + 1)")
                                        .foregroundColor(theme.colors.textSecondary)
                                    Spacer()
                                    Text(formatTime(split))
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(theme.colors.backgroundSecondary)
                                .cornerRadius(theme.radius.s)
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text("Notes (optional)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(theme.spacing.s)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                }
                .padding()
            }
            .navigationTitle("Save Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let result = WODResult()
                        
                        if wod.wodType == .forTime {
                            result.totalTime = Int(elapsedTime)
                        } else if wod.wodType == .amrap {
                            result.rounds = rounds
                        }
                        
                        result.notes = notes.isEmpty ? nil : notes
                        result.isRX = isRX
                        
                        onSave(result)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}