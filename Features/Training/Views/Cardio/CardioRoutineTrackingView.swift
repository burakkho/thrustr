import SwiftUI
import SwiftData

struct CardioRoutineTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let routine: CardioRoutine
    let session: CardioSession
    
    @State private var isActive = true
    @State private var elapsedTime = 0
    @State private var distance: Double = 0.0 // km
    @State private var heartRate = 0
    @State private var notes = ""
    @State private var timer: Timer?
    @State private var showingComplete = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with routine info
            headerSection
            
            // Main tracking area
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Timer/Progress
                    progressSection
                    
                    // Stats Input
                    statsSection
                    
                    // Notes
                    notesSection
                    
                    // Complete button
                    completeButton
                }
                .padding(theme.spacing.l)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("Complete Session", isPresented: $showingComplete) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") { 
                completeSession()
            }
        } message: {
            Text("Are you sure you want to complete this session?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: theme.spacing.s) {
            // Navigation
            HStack {
                Button("Cancel") { 
                    stopTimer()
                    dismiss() 
                }
                .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text(routine.localizedName)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button(isActive ? "Pause" : "Resume") {
                    if isActive {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                    isActive.toggle()
                }
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            // Target info
            if routine.distance != nil || routine.duration != nil {
                HStack(spacing: theme.spacing.l) {
                    if routine.distance != nil {
                        Label("Target: \(routine.formattedDistance)", systemImage: "ruler")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if routine.duration != nil {
                        Label("Target: \(routine.formattedDuration)", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, theme.spacing.s)
        .background(theme.colors.cardBackground)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Elapsed Time (Big)
            Text(formatTime(elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(Color.cardioColor)
            
            Text("Elapsed Time")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.l)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: theme.spacing.m) {
            Text("Session Stats")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: theme.spacing.s) {
                // Distance (if applicable)
                if routine.distance != nil {
                    HStack(spacing: theme.spacing.m) {
                        Image(systemName: "ruler")
                            .font(.body)
                            .foregroundColor(Color.cardioColor)
                            .frame(width: 20)
                        
                        Text("Distance (km)")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Spacer()
                        
                        TextField("0.0", text: Binding(
                            get: { String(format: "%.1f", distance) },
                            set: { distance = Double($0) ?? 0.0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    }
                }
                
                // Heart Rate (optional)
                HStack(spacing: theme.spacing.m) {
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundColor(Color.cardioColor)
                        .frame(width: 20)
                    
                    Text("Heart Rate (bpm)")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    TextField("0", text: Binding(
                        get: { String(heartRate) },
                        set: { heartRate = Int($0) ?? 0 }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: theme.spacing.s) {
            Text("Session Notes")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("How did it go? Any observations...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: { showingComplete = true }) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                
                Text("Complete Session")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.cardioColor)
            .cornerRadius(theme.radius.m)
        }
        .padding(.top, theme.spacing.l)
    }
    
    // MARK: - Helper Views
    
    // MARK: - Timer Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func completeSession() {
        stopTimer()
        
        // Update session with final stats
        session.totalDuration = elapsedTime
        session.totalDistance = distance * 1000 // Convert km to meters
        session.averageHeartRate = heartRate > 0 ? heartRate : nil
        session.completedAt = Date()
        session.isCompleted = true
        session.sessionNotes = notes.isEmpty ? session.sessionNotes : notes
        
        // Save to context
        try? modelContext.save()
        
        // Dismiss
        dismiss()
    }
}

#Preview {
    let routine = CardioRoutine(
        id: "5k-run",
        name: "5K Run",
        exercise: "Running",
        distance: 5000,
        category: "endurance",
        icon: "figure.run"
    )
    
    let session = CardioSession(
        workout: nil,
        user: nil,
        wasFromTemplate: false
    )
    
    CardioRoutineTrackingView(routine: routine, session: session)
}