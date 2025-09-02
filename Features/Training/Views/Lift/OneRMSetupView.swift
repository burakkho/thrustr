import SwiftUI
import SwiftData
import Foundation

// MARK: - One RM Setup View
struct OneRMSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    
    let program: LiftProgram
    let onComplete: (User) -> Void
    
    @Query private var users: [User]
    @State private var squatRM = ""
    @State private var benchRM = ""
    @State private var deadliftRM = ""
    @State private var ohpRM = ""
    @State private var currentStep = 0
    @State private var showingStartingWeights = false
    @State private var calculatedWeights: [String: Double] = [:]
    @State private var showingCalculator = false
    
    private var currentUser: User? {
        users.first
    }
    
    private let exercises = [
        ("squat", "Squat", "figure.strengthtraining.traditional"),
        ("bench", "Bench Press", "figure.strengthtraining.traditional"),
        ("deadlift", "Deadlift", "figure.strengthtraining.functional"),
        ("ohp", "Overhead Press", "figure.arms.open")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                progressIndicator
                
                // Content
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Header
                        headerSection
                        
                        // Current Exercise Input
                        if currentStep < exercises.count {
                            exerciseInputSection
                        }
                        
                        // Navigation Buttons
                        navigationButtons
                    }
                    .padding(.horizontal)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .navigationTitle(CommonKeys.Navigation.programSetup.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartingWeights) {
            StartingWeightsPreviewView(
                program: program,
                startingWeights: calculatedWeights,
                onConfirm: {
                    saveAndStartProgram()
                }
            )
        }
        .sheet(isPresented: $showingCalculator) {
            OneRMCalculatorView { calculatedValue in
                // Auto-fill current exercise's 1RM field
                let roundedValue = String(format: "%.1f", calculatedValue)
                currentRMBinding.wrappedValue = roundedValue
                showingCalculator = false
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(0..<exercises.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .frame(height: 4)
                    .foregroundColor(
                        index <= currentStep ? theme.colors.accent : theme.colors.backgroundSecondary
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.m)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: theme.spacing.m) {
            if currentStep < exercises.count {
                let exercise = exercises[currentStep]
                
                Image(systemName: exercise.2)
                    .font(.system(size: 48))
                    .foregroundColor(theme.colors.accent)
                
                Text(exercise.1)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.OneRM.enterWeight.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.colors.success)
                
                Text("Setup Complete!")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
    }
    
    // MARK: - Exercise Input Section
    private var exerciseInputSection: some View {
        VStack(spacing: theme.spacing.l) {
            // 1RM Input
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text("1 Rep Max (\(unitSettings.unitSystem == .metric ? "kg" : "lb"))")
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack {
                    TextField(TrainingKeys.OneRM.enterWeight.localized, text: currentRMBinding)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(theme.typography.headline)
                    
                    Text(unitSettings.unitSystem == .metric ? "kg" : "lb")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            
            // Help Section
            helpSection
        }
    }
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.OneRM.estimateHelp.localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Calculator Button
                Button(action: { showingCalculator = true }) {
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: "function")
                            .font(.body)
                            .foregroundColor(theme.colors.accent)
                            .frame(width: 20)
                        
                        Text(TrainingKeys.OneRM.calculateWeights.localized)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.accent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                helpTip(icon: "lightbulb", text: "Estimate: If you can do 5 reps with 60kg, your 1RM is ~67kg")
                helpTip(icon: "exclamationmark.circle", text: TrainingKeys.OneRM.underestimateWarning.localized)
            }
        }
        .padding()
        .background(theme.colors.warning.opacity(0.05))
        .cornerRadius(theme.radius.m)
    }
    
    private func helpTip(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(theme.colors.warning)
                .frame(width: 20)
            
            Text(text)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: theme.spacing.m) {
            if currentStep > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(TrainingKeys.OneRM.previous.localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.radius.m)
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep < exercises.count - 1 ? TrainingKeys.OneRM.next.localized : TrainingKeys.OneRM.calculateWeights.localized)
                    if currentStep < exercises.count - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCurrentStepValid ? theme.colors.accent : theme.colors.backgroundSecondary)
                .foregroundColor(isCurrentStepValid ? .white : theme.colors.textSecondary)
                .cornerRadius(theme.radius.m)
            }
            .disabled(!isCurrentStepValid)
        }
    }
    
    // MARK: - Computed Properties
    private var currentRMBinding: Binding<String> {
        switch currentStep {
        case 0: return $squatRM
        case 1: return $benchRM
        case 2: return $deadliftRM
        case 3: return $ohpRM
        default: return .constant("")
        }
    }
    
    private var isCurrentStepValid: Bool {
        let currentValue = currentRMBinding.wrappedValue
        return !currentValue.isEmpty && Double(currentValue) != nil && (Double(currentValue) ?? 0) > 0
    }
    
    // MARK: - Actions
    private func nextStep() {
        if currentStep < exercises.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Calculate starting weights and show preview
            calculateStartingWeights()
            showingStartingWeights = true
        }
    }
    
    private func previousStep() {
        withAnimation {
            currentStep = max(0, currentStep - 1)
        }
    }
    
    private func calculateStartingWeights() {
        guard let squat = Double(squatRM),
              let bench = Double(benchRM),
              let deadlift = Double(deadliftRM),
              let ohp = Double(ohpRM) else { return }
        
        calculatedWeights = [
            "squat": squat * 0.65,
            "bench": bench * 0.65,
            "row": bench * 0.80, // Row starts at 80% of bench
            "deadlift": deadlift * 0.65,
            "ohp": ohp * 0.65
        ]
    }
    
    private func saveAndStartProgram() {
        guard let user = currentUser,
              let squat = Double(squatRM),
              let bench = Double(benchRM),
              let deadlift = Double(deadliftRM),
              let ohp = Double(ohpRM) else { return }
        
        // Save 1RMs to user
        user.squatOneRM = squat
        user.benchPressOneRM = bench
        user.deadliftOneRM = deadlift
        user.overheadPressOneRM = ohp
        user.oneRMLastUpdated = Date()
        
        // Save to context
        do {
            try modelContext.save()
            Logger.success("1RM data saved successfully")
            
            // Complete setup
            onComplete(user)
            dismiss()
            
        } catch {
            Logger.error("Failed to save 1RM data: \(error)")
        }
    }
}

// MARK: - Starting Weights Preview
struct StartingWeightsPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    
    let program: LiftProgram
    let startingWeights: [String: Double]
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    headerSection
                    weightsListSection
                    proTipsSection
                    confirmButton
                }
                .padding()
            }
            .navigationTitle(CommonKeys.Navigation.startingWeights.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Starting Weights Calculated")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Based on your 1RMs, here are your starting weights for \(program.localizedName.isEmpty ? "your program" : program.localizedName)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var weightsListSection: some View {
        VStack(spacing: theme.spacing.m) {
            ForEach(Array(startingWeights.keys.sorted()), id: \.self) { exercise in
                if let weight = startingWeights[exercise] {
                    StartingWeightRow(
                        exercise: exercise.capitalized,
                        weight: weight
                    )
                }
            }
        }
    }
    
    private var proTipsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("💡 Pro Tips")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("• Starting conservative ensures proper form")
                Text("• You'll add \(unitSettings.unitSystem == .metric ? "2.5kg" : "5lb") every successful workout")
                Text("• You can adjust weights during workouts")
            }
            .font(theme.typography.body)
            .foregroundColor(theme.colors.textSecondary)
        }
        .padding()
        .background(theme.colors.warning.opacity(0.05))
        .cornerRadius(theme.radius.m)
    }
    
    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text(TrainingKeys.Common.startProgram.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
        }
    }
}

// MARK: - Starting Weight Row
struct StartingWeightRow: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    let exercise: String
    let weight: Double
    
    var body: some View {
        HStack {
            Text(exercise)
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            Text(UnitsFormatter.formatWeight(kg: weight, system: unitSettings.unitSystem))
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.accent)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Preview
#Preview {
    OneRMSetupView(
        program: LiftProgram(
            name: "Test Program",
            nameEN: "Test Program",
            nameTR: "Test Programı",
            weeks: 4,
            daysPerWeek: 3,
            level: "beginner",
            category: "strength",
        ),
        onComplete: { _ in }
    )
}