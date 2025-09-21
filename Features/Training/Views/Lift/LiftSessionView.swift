import SwiftUI
import SwiftData


struct SimpleExerciseCardRow: View {
    @Binding var exerciseData: ExerciseResultData
    let iExpanded: Bool
    let isEditMode: Bool

    let onToggle: () -> Void
    let onAddSet: () -> Void
    let onCompleteSet: (Int) -> Void

    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) private var unitSettings

    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header - Always Visible
            exerciseHeader

            // Expanded Content - Sets Details
            if iExpanded {
                setsContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.3), value: iExpanded)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                onToggle()
            }
        }
    }

    // MARK: - Exercise Header
    private var exerciseHeader: some View {
        HStack(spacing: 12) {
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseData.exerciseName)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)

                Text("\(exerciseData.completedSets)/\(exerciseData.totalSets) sets")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            // Progress Indicator
            VStack(alignment: .trailing, spacing: 4) {
                if exerciseData.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else {
                    let progress = exerciseData.totalSets > 0 ? Double(exerciseData.completedSets) / Double(exerciseData.totalSets) : 0

                    ZStack {
                        Circle()
                            .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 3)
                            .frame(width: 24, height: 24)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(theme.colors.accent, lineWidth: 3)
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                    }
                }

                // Expand/Collapse Indicator
                Image(systemName: iExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .rotationEffect(.degrees(iExpanded ? 0 : 0))
                    .animation(.easeInOut(duration: 0.3), value: iExpanded)
            }
        }
        .padding(theme.spacing.m)
        .background(iExpanded ? theme.colors.cardBackground : Color.clear)
    }

    // MARK: - Sets Content
    private var setsContent: some View {
        VStack(spacing: theme.spacing.s) {
            // Sets List
            ForEach(Array(exerciseData.sets.enumerated()), id: \.offset) { index, set in
                SetRow(
                    set: set,
                    setNumber: index + 1,
                    unitSettings: unitSettings,
                    onComplete: { onCompleteSet(index) }
                )
            }

            // Add Set Button
            Button(action: onAddSet) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.body)
                    Text("Add Set")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.s)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(theme.radius.s)
            }
        }
        .padding(.horizontal, theme.spacing.m)
        .padding(.bottom, theme.spacing.m)
    }
}

// MARK: - Set Row Component
struct SetRow: View {
    let set: SetData
    let setNumber: Int
    let unitSettings: UnitSettings
    let onComplete: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(setNumber)")
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(set.isCompleted ? .green : theme.colors.textSecondary)
                .frame(width: 20, alignment: .center)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textSecondary)

                if let weight = set.weight {
                    Text(UnitsFormatter.formatWeight(kg: weight, system: unitSettings.unitSystem))
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                } else {
                    Text("--")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Reps
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textSecondary)

                Text("\(set.reps)")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Complete Button
            Button(action: onComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(set.isCompleted ? .green : theme.colors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.xs)
        .background(set.isCompleted ? Color.green.opacity(0.1) : theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.s)
    }
}

// MARK: - Lift Session View
struct LiftSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    let workout: LiftWorkout
    let programExecution: ProgramExecution?
    @State private var viewModel = LiftSessionViewModel()
    @State private var showingCompletion = false
    @State private var showingCancelAlert = false
    @State private var showingExerciseSelection = false
    @State private var sessionNotes = ""
    @State private var showingProgramCelebration = false

    
    var body: some View {
        NavigationStack {
            if viewModel.currentSession != nil {
                mainContentView
            } else {
                ProgressView("Starting workout...")
                    .onAppear {
                        startSession()
                    }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message = message {
                // Handle error display if needed
                print("Error: \(message)")
            }
        }
        .onChange(of: viewModel.successMessage) { _, message in
            if let message = message {
                // Handle success display if needed
                print("Success: \(message)")
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: theme.spacing.l) {
                sessionHeaderView
                progressOverview
                exerciseListView
                actionButtons
            }
            .padding(.bottom, 100)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(CommonKeys.Onboarding.Common.cancel.localized) {
                    showingCancelAlert = true
                }
            }
            
            ToolbarItem(placement: .principal) {
                HStack(spacing: theme.spacing.s) {
                    Text(workout.localizedName)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                    
                    if (viewModel.currentSession?.exerciseResults?.count ?? 0) > 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.toggleEditingOrder()
                            }
                        }) {
                            Image(systemName: viewModel.isEditingOrder ? "checkmark" : "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(CommonKeys.Onboarding.Common.finish.localized) {
                    completeSession()
                }
                .fontWeight(.semibold)
                .disabled(!viewModel.canCompleteSession)
            }
        }
        .alert(TrainingKeys.Alerts.cancelWorkout.localized, isPresented: $showingCancelAlert) {
            Button(TrainingKeys.Alerts.keepTraining.localized, role: .cancel) { }
            Button(TrainingKeys.Alerts.cancelWorkoutAction.localized, role: .destructive) {
                cancelSession()
            }
        } message: {
            Text(TrainingKeys.Alerts.cancelWorkoutMessage.localized)
        }
        .sheet(isPresented: $showingCompletion) {
            if viewModel.isSessionReady, let currentSession = viewModel.currentSession, let user = viewModel.currentUser {
                Components.LiftSessionSummaryView(
                    session: currentSession,
                    user: user,
                    onDismiss: {
                        handleWorkoutCompletion()
                    }
                )
            } else {
                // Fallback view if session or user is nil
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Session Error")
                        .font(.headline)
                    Text("Workout session not found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Close") {
                        showingCompletion = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelectionView { exercise in
                addExerciseToSession(exercise)
                showingExerciseSelection = false
            }
        }
        .sheet(isPresented: $showingProgramCelebration) {
            ProgramCompletionCelebrationView(
                programName: workout.program?.localizedName ?? "Program",
                onDismiss: { showingProgramCelebration = false }
            )
        }
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearMessages() } }
        )) {
            Button("OK") { viewModel.clearMessages() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var exerciseListView: some View {
        VStack(spacing: theme.spacing.m) {
            exerciseListContent
        }
    }
    
    @ViewBuilder
    private var exerciseListContent: some View {
        if viewModel.hasExercises {
            List {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exerciseData in
                    SimpleExerciseCardRow(
                        exerciseData: Binding(
                            get: { viewModel.exercises[index] },
                            set: { viewModel.updateExercise($0) }
                        ),
                        iExpanded: viewModel.expandedExerciseId == exerciseData.id,
                        isEditMode: viewModel.isEditingOrder,
                        onToggle: {
                            viewModel.toggleExpansion(for: exerciseData.id)
                        },
                        onAddSet: {
                            viewModel.addSet(to: exerciseData.id)
                        },
                        onCompleteSet: { setIndex in
                            viewModel.completeSet(exerciseId: exerciseData.id, setIndex: setIndex)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .deleteDisabled(!viewModel.isEditingOrder)
                }
                .onMove(perform: viewModel.isEditingOrder ? { indices, destination in viewModel.moveExercises(from: indices, to: destination) } : nil)
            }
            .listStyle(PlainListStyle())
        } else {
            EmptyView()
        }
    }
    
    
    // MARK: - Session Header
    private var sessionHeaderView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Session \((workout.sessions?.count ?? 0) + 1)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    if let program = workout.program {
                        Text(program.localizedName)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                
                Spacer()
                
                if let lastPerformed = workout.lastPerformed {
                    VStack(alignment: .trailing) {
                        Text("Last workout")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text(lastPerformed, formatter: RelativeDateTimeFormatter())
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
    
    // MARK: - Progress Overview
    private var progressOverview: some View {
        HStack(spacing: theme.spacing.m) {
            LiftStatCard(
                icon: "scalemass.fill",
                title: "Volume",
                value: UnitsFormatter.formatVolume(kg: viewModel.sessionTotals.volume, system: unitSettings.unitSystem),
                color: theme.colors.accent
            )

            LiftStatCard(
                icon: "number",
                title: "Sets",
                value: "\(viewModel.sessionTotals.sets)",
                color: theme.colors.success
            )

            LiftStatCard(
                icon: "repeat",
                title: "Reps",
                value: "\(viewModel.sessionTotals.reps)",
                color: theme.colors.warning
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            // Add Exercise Button
            Button(action: {
                showingExerciseSelection = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Exercise")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }
            
            // Notes Button
            Button(action: {
                sessionNotes = viewModel.currentSession?.notes ?? ""
                // showingNotes = true // Notes functionality can be implemented later
            }) {
                HStack {
                    Image(systemName: "note.text")
                    Text("Workout Notes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods

    private func setupViewModel() {
        viewModel.configure(modelContext: modelContext)
    }

    private func startSession() {
        Task {
            await viewModel.startWorkoutSession(
                workout: workout,
                programExecution: programExecution
            )
        }
    }
    
    
    
    private func completeSession() {
        Task {
            await viewModel.completeSession()

            await MainActor.run {
                showingCompletion = true
            }
        }
    }

    private func cancelSession() {
        dismiss()
    }

    private func handleWorkoutCompletion() {
        dismiss()
    }

    private func addExerciseToSession(_ exercise: Exercise) {
        viewModel.addExercise(exercise)
    }
}

// MARK: - Workout Notes Sheet
struct WorkoutNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Binding var notes: String
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.m) {
                // Header
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text("Workout Notes")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Add notes about your workout, form cues, or how you're feeling")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Text Editor
                TextEditor(text: $notes)
                    .font(theme.typography.body)
                    .padding(theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
                    .frame(minHeight: 200)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(CommonKeys.Navigation.notes.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(notes)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}


// MARK: - Lift Main Stat Card
struct LiftMainStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    let color: Color
    let onEdit: (() -> Void)?
    
    init(icon: String, value: String, label: String, color: Color, onEdit: (() -> Void)? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if let onEdit = onEdit {
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Exercise Result Row
struct ExerciseResultRow: View {
    @Environment(\.theme) private var theme
    let result: LiftExerciseResult
    let unitSettings: UnitSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.exercise?.exerciseName ?? "Unknown Exercise")
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("\(result.completedSets) sets • \(result.totalReps) reps")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(UnitsFormatter.formatVolume(kg: result.totalVolume, system: unitSettings.unitSystem))
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let maxWeight = result.maxWeight {
                    Text("Max: \(UnitsFormatter.formatWeight(kg: maxWeight, system: unitSettings.unitSystem))")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Duration Edit Sheet
struct LiftDurationEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "timer")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Edit Duration")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Adjust your workout duration")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.l)
                
                // Time Picker
                VStack(spacing: theme.spacing.m) {
                    Text("Duration")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.m) {
                        // Hours
                        VStack(spacing: theme.spacing.xs) {
                            Text("Hour")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)")
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Minutes
                        VStack(spacing: theme.spacing.xs) {
                            Text("Min")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Seconds
                        VStack(spacing: theme.spacing.xs) {
                            Text("Sec")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60, id: \.self) { second in
                                    Text(String(format: "%02d", second))
                                        .tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                    }
                }
                .cardStyle()
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Save")
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle("Edit Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct LiftShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Lift Stat Row
struct LiftStatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.s)
    }
}

