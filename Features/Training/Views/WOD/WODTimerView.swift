import SwiftUI
import SwiftData

struct WODTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    let wod: WOD
    let movements: [WODMovement]
    let isRX: Bool
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var isCompleted = false
    
    // AMRAP tracking
    @State private var completedRounds = 0
    @State private var currentMovementIndex = 0
    @State private var currentReps = 0
    
    // Result entry
    @State private var showingResultEntry = false
    @State private var resultTime = ""
    @State private var resultRounds = ""
    @State private var resultExtraReps = ""
    @State private var resultNotes = ""
    
    private var currentUser: User? {
        user.first
    }
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
    
    private var currentMovement: WODMovement? {
        guard currentMovementIndex < movements.count else { return nil }
        return movements[currentMovementIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Display
                VStack(spacing: theme.spacing.m) {
                    Text(formattedTime)
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(isRunning ? theme.colors.accent : theme.colors.textPrimary)
                    
                    Text(wod.name)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    if isRX {
                        Text("RX")
                            .font(theme.typography.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, theme.spacing.m)
                            .padding(.vertical, 4)
                            .background(theme.colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(theme.radius.s)
                    }
                }
                .padding(.vertical, theme.spacing.xl)
                
                // WOD Info
                ScrollView {
                    VStack(spacing: theme.spacing.l) {
                        // Type and rep scheme
                        HStack(spacing: theme.spacing.xl) {
                            VStack {
                                Text(wod.wodType.displayName)
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                Text(wod.wodType.rawValue.uppercased())
                                    .font(theme.typography.headline)
                                    .fontWeight(.bold)
                            }
                            
                            if !wod.repScheme.isEmpty {
                                VStack {
                                    Text("Rep Scheme")
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                    Text(wod.formattedRepScheme)
                                        .font(theme.typography.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            if let timeCap = wod.formattedTimeCap {
                                VStack {
                                    Text("Time Cap")
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                    Text(timeCap)
                                        .font(theme.typography.headline)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.m)
                        
                        // AMRAP Progress (if applicable)
                        if wod.wodType == .amrap {
                            VStack(spacing: theme.spacing.m) {
                                Text("Progress")
                                    .font(theme.typography.headline)
                                
                                HStack(spacing: theme.spacing.xl) {
                                    VStack {
                                        Text("Rounds")
                                            .font(theme.typography.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                        Text("\(completedRounds)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(theme.colors.accent)
                                    }
                                    
                                    VStack {
                                        Text("Current")
                                            .font(theme.typography.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                        Text(currentMovement?.name ?? "-")
                                            .font(theme.typography.body)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                    }
                                }
                                
                                // Round buttons for AMRAP
                                Button(action: completeRound) {
                                    Text("Complete Round")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(theme.colors.success)
                                        .foregroundColor(.white)
                                        .cornerRadius(theme.radius.m)
                                }
                                .disabled(!isRunning)
                            }
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                        }
                        
                        // Movements List
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            Text("Movements")
                                .font(theme.typography.headline)
                            
                            ForEach(Array(movements.enumerated()), id: \.element.id) { index, movement in
                                HStack {
                                    Image(systemName: currentMovementIndex == index ? "chevron.right.circle.fill" : "circle")
                                        .foregroundColor(currentMovementIndex == index ? theme.colors.accent : theme.colors.textSecondary)
                                    
                                    VStack(alignment: .leading) {
                                        Text(movement.fullDisplayText)
                                            .font(theme.typography.body)
                                            .foregroundColor(currentMovementIndex == index ? theme.colors.textPrimary : theme.colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(theme.spacing.s)
                                .background(currentMovementIndex == index ? theme.colors.accent.opacity(0.1) : Color.clear)
                                .cornerRadius(theme.radius.s)
                            }
                        }
                        .padding()
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.m)
                    }
                    .padding()
                }
                
                // Control Buttons
                HStack(spacing: theme.spacing.m) {
                    if !isRunning && !isCompleted {
                        Button(action: startTimer) {
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
                        Button(action: pauseTimer) {
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
                .padding()
            }
            .navigationTitle("WOD Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        timer?.invalidate()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
            .sheet(isPresented: $showingResultEntry) {
                ResultEntryView(
                    wod: wod,
                    isRX: isRX,
                    elapsedTime: elapsedTime,
                    rounds: completedRounds,
                    onSave: { result in
                        modelContext.insert(result)
                        result.wod = wod
                        result.user = currentUser
                        wod.results.append(result)
                        
                        try? modelContext.save()
                        HapticManager.shared.notification(.success)
                        dismiss()
                    }
                )
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
            }
        }
    }
    
    private func pauseTimer() {
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
        showingResultEntry = true
    }
    
    private func completeRound() {
        completedRounds += 1
        currentMovementIndex = 0
        HapticManager.shared.impact(.medium)
    }
    
    private func saveResult() {
        showingResultEntry = true
    }
}

// MARK: - Result Entry View
private struct ResultEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    let wod: WOD
    let isRX: Bool
    let elapsedTime: TimeInterval
    let rounds: Int
    let onSave: (WODResult) -> Void
    
    @State private var timeMinutes = ""
    @State private var timeSeconds = ""
    @State private var amrapRounds = ""
    @State private var amrapExtraReps = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("WOD Result") {
                    if wod.wodType == .forTime {
                        HStack {
                            TextField("MM", text: $timeMinutes)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                            Text(":")
                            TextField("SS", text: $timeSeconds)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                        }
                    } else if wod.wodType == .amrap {
                        HStack {
                            TextField("Rounds", text: $amrapRounds)
                                .keyboardType(.numberPad)
                            TextField("Extra Reps", text: $amrapExtraReps)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    if isRX {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.colors.success)
                            Text("This was completed RX")
                                .foregroundColor(theme.colors.success)
                        }
                    }
                }
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
                            let minutes = Int(timeMinutes) ?? 0
                            let seconds = Int(timeSeconds) ?? 0
                            result.totalTime = minutes * 60 + seconds
                        } else if wod.wodType == .amrap {
                            result.rounds = Int(amrapRounds)
                            result.extraReps = Int(amrapExtraReps)
                        }
                        
                        result.notes = notes.isEmpty ? nil : notes
                        result.isRX = isRX
                        
                        onSave(result)
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill with timer values
                if wod.wodType == .forTime {
                    let minutes = Int(elapsedTime) / 60
                    let seconds = Int(elapsedTime) % 60
                    timeMinutes = String(minutes)
                    timeSeconds = String(seconds)
                } else if wod.wodType == .amrap {
                    amrapRounds = String(rounds)
                }
            }
        }
    }
}