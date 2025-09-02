import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct EnhancedWODTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var user: [User]
    
    let wod: WOD
    let movements: [WODMovement]
    let isRX: Bool
    let onCompletion: (() -> Void)?
    
    @State private var viewModel: WODTimerViewModel
    @State private var showingCountdown = false
    @State private var countdownValue = 3
    
    init(wod: WOD, movements: [WODMovement], isRX: Bool, onCompletion: (() -> Void)? = nil) {
        self.wod = wod
        self.movements = movements
        self.isRX = isRX
        self.onCompletion = onCompletion
        self._viewModel = State(initialValue: WODTimerViewModel(wod: wod, movements: movements, isRX: isRX))
    }
    
    private var currentUser: User? {
        user.first
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
                        Button(TrainingKeys.TimerControls.cancel.localized) {
                            viewModel.timerViewModel.stopTimer()
                            UIApplication.shared.isIdleTimerDisabled = false
                            onCompletion?()
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
                                    .trim(from: 0, to: viewModel.progressPercentage)
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
                                    .animation(.linear(duration: 0.5), value: viewModel.progressPercentage)
                                
                                VStack(spacing: 8) {
                                    TimerDisplay(
                                        formattedTime: viewModel.timerViewModel.formattedTime,
                                        isRunning: viewModel.timerViewModel.isRunning,
                                        size: .large,
                                        showSplit: viewModel.splitMode && viewModel.timerViewModel.isRunning,
                                        splitTime: viewModel.formattedSplitTime
                                    )
                                }
                            }
                        } else {
                            // Standard timer display for AMRAP/EMOM
                            VStack(spacing: 8) {
                                TimerDisplay(
                                    formattedTime: viewModel.timerViewModel.formattedTime,
                                    isRunning: viewModel.timerViewModel.isRunning,
                                    size: .huge
                                )
                                
                                if wod.wodType == .amrap {
                                    HStack(spacing: theme.spacing.xl) {
                                        VStack {
                                            Text("Rounds")
                                                .font(theme.typography.caption)
                                                .foregroundColor(theme.colors.textSecondary)
                                            Text("\(viewModel.completedRounds)")
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(theme.colors.success)
                                        }
                                        
                                        VStack {
                                            Text("Movement")
                                                .font(theme.typography.caption)
                                                .foregroundColor(theme.colors.textSecondary)
                                            Text("\(viewModel.currentMovementIndex + 1)/\(movements.count)")
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
                                        isCurrent: viewModel.currentMovementIndex == index,
                                        isCompleted: index < viewModel.currentMovementIndex || (wod.wodType == .amrap && viewModel.completedRounds > 0),
                                        repScheme: wod.repScheme,
                                        currentRepIndex: viewModel.currentRepIndex
                                    )
                                    .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.currentMovementIndex) { _, newValue in
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    
                    // Control Panel
                    VStack(spacing: theme.spacing.m) {
                        // Split/Round buttons for active timer
                        if viewModel.timerViewModel.isRunning && !viewModel.timerViewModel.isPaused {
                            HStack(spacing: theme.spacing.m) {
                                if wod.wodType == .forTime {
                                    Button(action: viewModel.recordSplit) {
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
                                    
                                    Button(action: viewModel.nextMovement) {
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
                                    Button(action: viewModel.completeRound) {
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
                        TimerControls(
                            timerState: TimerControls.TimerState(rawValue: viewModel.timerViewModel.timerState.rawValue) ?? .stopped,
                            onStart: viewModel.startWOD,
                            onPause: viewModel.pauseWOD,
                            onResume: viewModel.resumeWOD,
                            onStop: viewModel.stopWOD,
                            onReset: {
                                viewModel.timerViewModel.resetTimer()
                                viewModel.completedRounds = 0
                                viewModel.currentMovementIndex = 0
                                viewModel.currentRepIndex = 0
                                viewModel.movementSplits.removeAll()
                                viewModel.roundSplits.removeAll()
                            }
                        )
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                viewModel.timerViewModel.stopTimer()
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .sheet(isPresented: $viewModel.showingResultEntry) {
                EnhancedResultEntryView(
                    wod: wod,
                    isRX: isRX,
                    elapsedTime: viewModel.timerViewModel.elapsedTime,
                    rounds: viewModel.completedRounds,
                    splits: viewModel.roundSplits,
                    onSave: { result in
                        viewModel.saveWODResult(result, modelContext: modelContext, currentUser: currentUser)
                        dismiss()
                    }
                )
            }
        }
        .overlay {
            CountdownOverlay(
                isShowing: $showingCountdown,
                value: $countdownValue
            )
        }
        .onChange(of: viewModel.timerViewModel.showingCountdown) { _, newValue in
            showingCountdown = newValue
        }
        .onChange(of: viewModel.timerViewModel.countdownValue) { _, newValue in
            countdownValue = newValue
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
    @EnvironmentObject private var unitSettings: UnitSettings
    
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
                    Text(UnitsFormatter.formatWeight(kg: userWeight, system: unitSettings.unitSystem))
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
                        
                        TimerDisplay(
                            formattedTime: formatTime(elapsedTime),
                            size: .large
                        )
                        
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
                            .font(theme.typography.headline)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                }
                .padding()
            }
            .navigationTitle(CommonKeys.Navigation.saveResult.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(CommonKeys.Onboarding.Common.cancel.localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let result = WODResult()
                        result.totalTime = Int(elapsedTime)
                        result.rounds = rounds
                        result.notes = notes.isEmpty ? nil : notes
                        result.isRX = isRX
                        onSave(result)
                    }
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