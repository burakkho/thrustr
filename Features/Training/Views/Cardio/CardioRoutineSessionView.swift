import SwiftUI
import SwiftData

struct CardioRoutineSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let routine: CardioRoutine
    let user: User
    
    @State private var notes: String = ""
    @State private var showingSession = false
    @State private var session: CardioSession?
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text("Start Routine")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                // Balance the cancel button
                Button("Cancel") { }
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.vertical, theme.spacing.s)
            .background(theme.colors.cardBackground)
            
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header
                    routineHeader
                    
                    // Target Info
                    targetInfoSection
                    
                    // Notes Section  
                    notesSection
                    
                    // Start Button
                    startButtonSection
                }
                .padding(theme.spacing.l)
            }
        }
        .fullScreenCover(isPresented: $showingSession) {
            if let session = session {
                CardioRoutineTrackingView(routine: routine, session: session)
            }
        }
    }
    
    // MARK: - Routine Header
    private var routineHeader: some View {
        VStack(spacing: theme.spacing.m) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cardioColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: routine.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color.cardioColor)
            }
            
            // Title and Description
            VStack(spacing: theme.spacing.s) {
                Text(routine.localizedName)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(routine.localizedDescription)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Difficulty Badge
            Text(routine.difficulty.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(routine.difficultyColor).opacity(0.2))
                .foregroundColor(Color(routine.difficultyColor))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Target Info Section
    private var targetInfoSection: some View {
        VStack(spacing: theme.spacing.m) {
            Text("Routine Details")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: theme.spacing.s) {
                // Primary Target
                targetInfoRow(
                    icon: routine.distance != nil ? "ruler" : "clock",
                    label: routine.distance != nil ? "Target Distance" : "Target Duration",
                    value: routine.primaryTarget,
                    color: Color.cardioColor
                )
                
                // Estimated Time
                if !routine.formattedEstimatedTime.isEmpty {
                    targetInfoRow(
                        icon: "stopwatch",
                        label: "Estimated Time",
                        value: "~\(routine.formattedEstimatedTime)",
                        color: theme.colors.textSecondary
                    )
                }
                
                // Exercise Type
                targetInfoRow(
                    icon: "figure.run",
                    label: "Exercise",
                    value: routine.exercise,
                    color: theme.colors.textSecondary
                )
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: theme.spacing.s) {
            Text("Notes (Optional)")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Add any notes for this session...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Start Button Section
    private var startButtonSection: some View {
        Button(action: startSession) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: "play.fill")
                    .font(.title3)
                
                Text("Start \(routine.localizedName)")
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
    private func targetInfoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: theme.spacing.m) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    // MARK: - Actions
    private func startSession() {
        // Create session
        let newSession = CardioSession(
            workout: nil,
            user: user,
            wasFromTemplate: false
        )
        
        // Set target values from routine
        if routine.distance != nil {
            newSession.totalDistance = 0 // Will be tracked during session
            // Store target in notes for reference
            if notes.isEmpty {
                newSession.sessionNotes = "Target: \(routine.formattedDistance)"
            } else {
                newSession.sessionNotes = "\(notes)\nTarget: \(routine.formattedDistance)"
            }
        }
        
        if routine.duration != nil {
            newSession.totalDuration = 0 // Will be tracked during session
            // Store target in notes for reference
            if notes.isEmpty {
                newSession.sessionNotes = "Target: \(routine.formattedDuration)"
            } else {
                newSession.sessionNotes = "\(notes)\nTarget: \(routine.formattedDuration)"
            }
        }
        
        if !notes.isEmpty && newSession.sessionNotes == nil {
            newSession.sessionNotes = notes
        }
        
        // Save to context
        modelContext.insert(newSession)
        
        // Assign and show session
        self.session = newSession
        self.showingSession = true
        
        // Dismiss this view
        dismiss()
    }
}

#Preview {
    let routine = CardioRoutine(
        id: "5k-run",
        name: "5K Run",
        nameEN: "5K Run",
        nameTR: "5K Koşu",
        description: "Classic 5 kilometer running distance",
        exercise: "Running",
        distance: 5000,
        estimatedTime: 1500,
        category: "endurance",
        difficulty: "intermediate",
        icon: "figure.run"
    )
    
    let user = User(name: "Test User")
    
    CardioRoutineSessionView(routine: routine, user: user)
}