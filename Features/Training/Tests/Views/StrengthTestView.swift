import SwiftUI
import SwiftData

/**
 * Minimalist strength test interface with clean input form design.
 * 
 * Features a single-page form layout with underlined inputs and
 * a prominent analyze button, matching modern UI patterns.
 */
struct StrengthTestView: View {
    // MARK: - Properties
    let user: User
    
    @StateObject private var viewModel: StrengthTestViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    // Input state - simple dictionary approach
    @State private var exerciseWeights: [StrengthExerciseType: Double] = [:]
    @State private var exerciseReps: [StrengthExerciseType: Double] = [:]
    @State private var isValidated = false
    
    // Progress tracking
    @State private var completedExercises: Set<StrengthExerciseType> = []
    
    // Validation state
    @State private var inputErrors: [StrengthExerciseType: String] = [:]
    @State private var fieldFocusStates: [StrengthExerciseType: Bool] = [:]
    
    // Real-time feedback
    @State private var currentEstimates: [StrengthExerciseType: Double] = [:]
    @State private var showPreview = false
    
    // MARK: - Initialization
    
    init(user: User, modelContext: ModelContext) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: StrengthTestViewModel(modelContext: modelContext))
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.showingResults {
                    resultView
                } else {
                    minimalistTestView
                }
            }
            .navigationTitle(CommonKeys.Navigation.enterBestSets.localized)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            initializeInputs()
            // Initialize validation for all exercises
            for exerciseType in StrengthExerciseType.allCases {
                validateInput(for: exerciseType)
            }
        }
        .sheet(item: Binding(
            get: { viewModel.showingInstructions },
            set: { _ in viewModel.hideInstructions() }
        )) { exerciseType in
            TestInstructionsSheet(exerciseType: exerciseType)
        }
        .alert("strength.error.title".localized, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("common.ok".localized) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Minimalist Test View
    
    private var minimalistTestView: some View {
        VStack(spacing: 0) {
            // Progress Header
            progressHeader
            
            // Subtitle
            HStack {
                Text("Enter your heaviest recent sets (10 reps or fewer)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                Spacer()
            }
            .padding(.horizontal, theme.spacing.l)
            .padding(.top, theme.spacing.m)
            
            // Exercise input form
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    ForEach(StrengthExerciseType.allCases) { exerciseType in
                        enhancedInputRow(for: exerciseType)
                    }
                    
                    Spacer(minLength: theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.l)
                .padding(.vertical, theme.spacing.l)
            }
            
            // Analyze button
            analyzeButton
        }
        .background(theme.colors.backgroundPrimary)
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Strength Assessment")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("\(completedExercises.count)/5 Complete")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Progress dots
                HStack(spacing: theme.spacing.xs) {
                    ForEach(Array(StrengthExerciseType.allCases.enumerated()), id: \.offset) { index, exerciseType in
                        Circle()
                            .fill(completedExercises.contains(exerciseType) ? theme.colors.accent : theme.colors.accent.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .scaleEffect(completedExercises.contains(exerciseType) ? 1.2 : 1.0)
                            .animation(.spring(duration: 0.3), value: completedExercises)
                    }
                }
            }
            
            // Progress bar
            ProgressView(value: Double(completedExercises.count), total: 5.0)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.accent))
                .scaleEffect(y: 2)
                .animation(.easeInOut(duration: 0.3), value: completedExercises.count)
        }
        .cardStyle(.default)
        .padding(.horizontal, theme.spacing.l)
    }
    
    // MARK: - Analyze Button
    
    private var analyzeButton: some View {
        VStack(spacing: 0) {
            Button {
                analyzeStrength()
            } label: {
                HStack {
                    if !isValidated {
                        Image(systemName: "checkmark.circle")
                            .font(.headline)
                    }
                    
                    Text(dynamicButtonText)
                        .font(ButtonTokens.primary.font)
                    
                    if isValidated {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(.primary))
            .disabled(!isValidated)
            .padding(.horizontal, theme.spacing.l)
            .padding(.bottom, theme.spacing.l)
        }
        .background(theme.colors.backgroundPrimary)
    }
    
    
    // MARK: - Result View
    
    @ViewBuilder
    private var resultView: some View {
        if let currentTest = viewModel.currentTest {
            TestResultSummary(
                strengthTest: currentTest,
                onShareTapped: {
                    shareResults()
                },
                onSaveTapped: {
                    saveAndExit()
                }
            )
        } else {
            EmptyStateView(
                systemImage: "exclamationmark.triangle",
                title: "strength.error.noResults".localized,
                message: "strength.error.noResultsSubtitle".localized,
                primaryTitle: "common.ok".localized,
                primaryAction: { }
            )
        }
    }
    
    // MARK: - Helper Properties
    
    private var dynamicButtonText: String {
        if isValidated {
            return "🎯 Kuvvet Analizini Başlat"
        } else if completedExercises.count > 0 {
            return "Devam Et (\(completedExercises.count)/5)"
        } else {
            return "Değerleri Girip Devam Edin"
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isValidated {
            return Color.green
        } else if completedExercises.count > 0 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    // MARK: - Helper Methods
    
    private func enhancedInputRow(for exerciseType: StrengthExerciseType) -> some View {
        let weightBinding = Binding(
            get: { exerciseWeights[exerciseType] ?? 0 },
            set: { newValue in
                exerciseWeights[exerciseType] = newValue
                validateInput(for: exerciseType)
            }
        )
        
        let repsBinding = Binding(
            get: { exerciseReps[exerciseType] ?? 1 },
            set: { newValue in
                exerciseReps[exerciseType] = newValue
                validateInput(for: exerciseType)
            }
        )
        
        return EnhancedStrengthTestInputRow(
            exerciseType: exerciseType,
            weight: weightBinding,
            reps: repsBinding,
            previousBest: user.getCurrentOneRM(for: exerciseType),
            isCompleted: completedExercises.contains(exerciseType),
            errorMessage: inputErrors[exerciseType],
            estimatedOneRM: currentEstimates[exerciseType],
            isFocused: fieldFocusStates[exerciseType] ?? false,
            onInstructionsTap: {
                viewModel.showInstructions(for: exerciseType)
            },
            onFocusChange: { isFocused in
                fieldFocusStates[exerciseType] = isFocused
            }
        )
    }
    
    private func initializeInputs() {
        for exerciseType in StrengthExerciseType.allCases {
            // Pre-populate with previous best if available
            if let previousBest = user.getCurrentOneRM(for: exerciseType) {
                if exerciseType == .pullUp {
                    exerciseReps[exerciseType] = previousBest
                } else {
                    exerciseWeights[exerciseType] = previousBest
                    exerciseReps[exerciseType] = 1
                }
            } else {
                exerciseWeights[exerciseType] = 0
                // Set reps to 0 for pull-up to start in pending state
                exerciseReps[exerciseType] = exerciseType == .pullUp ? 0 : 1
            }
        }
        // Initialize validation for all exercises\n        for exerciseType in StrengthExerciseType.allCases {\n            validateInput(for: exerciseType)\n        }
    }
    
    private func validateInput(for exerciseType: StrengthExerciseType) {
        let weight = exerciseWeights[exerciseType] ?? 0
        let reps = exerciseReps[exerciseType] ?? 0
        
        // Clear previous error
        inputErrors[exerciseType] = nil
        currentEstimates[exerciseType] = nil
        
        // Validate based on exercise type
        let isValid: Bool
        var errorMessage: String?
        
        if exerciseType == .pullUp {
            isValid = reps > 0
            if !isValid && reps == 0 {
                errorMessage = "Tekrar sayısı girin"
            }
        } else {
            isValid = weight > 0 && reps > 0
            if weight <= 0 && reps <= 0 {
                errorMessage = "Ağırlık ve tekrar sayısı girin"
            } else if weight <= 0 {
                errorMessage = "Ağırlık girin"
            } else if reps <= 0 {
                errorMessage = "Tekrar sayısı girin"
            }
        }
        
        // Update error state
        inputErrors[exerciseType] = errorMessage
        
        // Calculate estimated 1RM if valid
        if isValid {
            let estimated1RM = exerciseType.calculateOneRM(weight: weight, reps: Int(reps))
            currentEstimates[exerciseType] = estimated1RM
            
            // Update completed state
            completedExercises.insert(exerciseType)
        } else {
            // Remove from completed if invalid
            completedExercises.remove(exerciseType)
        }
        
        // Update overall validation state
        isValidated = completedExercises.count == StrengthExerciseType.allCases.count
    }
    
    private func validateInputs() {
        print("🔍 Validating inputs...")
        
        var newCompletedExercises: Set<StrengthExerciseType> = []
        
        for exerciseType in StrengthExerciseType.allCases {
            let weight = exerciseWeights[exerciseType] ?? 0
            let reps = exerciseReps[exerciseType] ?? 0
            
            let isValid: Bool
            if exerciseType == .pullUp {
                isValid = reps > 0
                print("📊 \(exerciseType.rawValue): reps=\(reps), valid=\(isValid)")
            } else {
                isValid = weight > 0 && reps > 0
                print("📊 \(exerciseType.rawValue): weight=\(weight), reps=\(reps), valid=\(isValid)")
            }
            
            if isValid {
                newCompletedExercises.insert(exerciseType)
            }
        }
        
        // Update completed exercises with animation
        withAnimation(.spring(duration: 0.3)) {
            completedExercises = newCompletedExercises
        }
        
        // Check if all exercises are completed
        isValidated = completedExercises.count == StrengthExerciseType.allCases.count
        
        print("✅ Completed exercises: \(completedExercises.count)/5")
    }
    
    private func analyzeStrength() {
        print("🎯 Analyze Strength button tapped!")
        
        viewModel.startNewTest(with: user)
        
        for exerciseType in StrengthExerciseType.allCases {
            let weight = exerciseWeights[exerciseType] ?? 0
            let reps = exerciseReps[exerciseType] ?? 1
            
            let value: Double
            
            // Use exercise-specific 1RM calculation
            value = exerciseType.calculateOneRM(weight: weight, reps: Int(reps))
            
            // Update the view model's test inputs
            viewModel.updateInput(for: exerciseType, value: value)
            
            // Submit the result
            viewModel.submitExerciseResult(for: exerciseType, with: user)
        }
        
        // Complete the test
        viewModel.completeTest()
    }
    
    private func shareResults() {
        // Implementation would show share sheet
        if let _ = viewModel.generateShareableSummary() {
            // Show system share sheet
        }
    }
    
    private func saveAndExit() {
        viewModel.saveTestResults(for: user)
        
        // Log activity to dashboard
        if let currentTest = viewModel.currentTest {
            let averageStrengthLevel = currentTest.averageStrengthLevel
            let levelName = averageStrengthLevel.name
            
            ActivityLoggerService.shared.logStrengthTestCompleted(
                exerciseCount: currentTest.results.count,
                averageStrengthLevel: levelName,
                totalScore: currentTest.overallScore,
                user: user
            )
        }
        
        dismiss()
    }
}

// MARK: - Supporting Types

// MARK: - Supporting Views

private struct StatPreview: View {
    let title: String
    let value: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(theme.colors.accent)
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview("Strength Test View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, StrengthTest.self, configurations: config)
    
    let sampleUser = User(
        name: "Test User",
        age: 25,
        gender: .male,
        height: 175,
        currentWeight: 80
    )
    
    StrengthTestView(user: sampleUser, modelContext: container.mainContext)
        .modelContainer(for: [User.self, StrengthTest.self], inMemory: true)
}
