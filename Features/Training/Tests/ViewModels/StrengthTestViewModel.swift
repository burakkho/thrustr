import SwiftUI
import SwiftData
import Combine

/**
 * Main view model for strength test coordination and management.
 * 
 * Handles test progression, input validation, scoring, and results calculation
 * while providing reactive UI state management.
 */
@MainActor
final class StrengthTestViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentTest: StrengthTest?
    @Published var testInputs: [StrengthExerciseType: TestInput] = [:]
    @Published var isTestInProgress: Bool = false
    @Published var isTestCompleted: Bool = false
    @Published var showingInstructions: StrengthExerciseType?
    @Published var showingResults: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let scoringService = TestScoringService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupInputValidation()
    }
    
    // MARK: - Static Factory
    
    static func createTemporary() -> StrengthTestViewModel {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: StrengthTest.self, StrengthTestResult.self, configurations: config)
            return StrengthTestViewModel(modelContext: container.mainContext)
        } catch {
            // Fallback to in-memory container
            fatalError("Could not create temporary StrengthTestViewModel: \(error)")
        }
    }
    
    // MARK: - Test Management
    
    /**
     * Starts a new strength test session.
     */
    func startNewTest(with user: User) {
        guard !isTestInProgress else { return }
        
        // Create new test
        let newTest = StrengthTest(
            userAge: user.age,
            userGender: user.genderEnum,
            userWeight: user.currentWeight
        )
        
        // Initialize test inputs with previous bests
        initializeTestInputs(for: user)
        
        // Set state
        currentTest = newTest
        isTestInProgress = true
        isTestCompleted = false
        showingResults = false
        errorMessage = nil
        
        // Add to model context
        modelContext.insert(newTest)
    }
    
    /**
     * Submits a result for a specific exercise.
     */
    func submitExerciseResult(for exerciseType: StrengthExerciseType, with user: User) {
        guard let currentTest = currentTest,
              let input = testInputs[exerciseType],
              input.isValid else {
            errorMessage = "strength.error.invalidInput".localized
            return
        }
        
        // Validate input
        let validation = scoringService.validateTestInput(
            exerciseType: exerciseType,
            value: input.value,
            userWeight: user.currentWeight,
            additionalWeight: input.additionalWeight
        )
        
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            return
        }
        
        // Score the exercise
        let result = scoringService.scoreExercise(
            exerciseType: exerciseType,
            value: input.value,
            userGender: user.genderEnum,
            userAge: user.age,
            userWeight: user.currentWeight,
            isWeighted: input.isWeighted,
            additionalWeight: input.additionalWeight,
            previousBest: user.getCurrentOneRM(for: exerciseType)
        )
        
        // Add result to test
        currentTest.addResult(result)
        
        // Mark input as completed
        testInputs[exerciseType]?.isCompleted = true
        
        // Check if all exercises are completed
        checkTestCompletion()
        
        // Clear any previous errors
        errorMessage = nil
        
        // Save changes
        saveChanges()
    }
    
    /**
     * Completes the current test and shows results.
     */
    func completeTest() {
        guard let currentTest = currentTest,
              currentTest.isCompleted else { return }
        
        isTestCompleted = true
        showingResults = true
        
        // Calculate final metrics
        let (overallScore, strengthProfile) = scoringService.calculateOverallScore(from: currentTest.results)
        currentTest.overallScore = overallScore
        currentTest.strengthProfile = strengthProfile
        currentTest.testDuration = Date().timeIntervalSince(currentTest.testDate)
        
        saveChanges()
    }
    
    /**
     * Saves test results and updates user profile.
     */
    func saveTestResults(for user: User) {
        guard let currentTest = currentTest else { return }
        
        isLoading = true
        
        // Update user with test results
        user.updateWithStrengthTest(currentTest)
        
        // Reset test state
        resetTestState()
        
        isLoading = false
    }
    
    /**
     * Cancels the current test without saving.
     */
    func cancelTest() {
        guard let currentTest = currentTest else { return }
        
        // Remove from context
        modelContext.delete(currentTest)
        
        // Reset state
        resetTestState()
    }
    
    // MARK: - Input Management
    
    /**
     * Updates input value for specific exercise.
     */
    func updateInput(for exerciseType: StrengthExerciseType, value: Double) {
        if testInputs[exerciseType] == nil {
            testInputs[exerciseType] = TestInput()
        }
        
        testInputs[exerciseType]?.value = value
        testInputs[exerciseType]?.validate()
    }
    
    /**
     * Updates weighted pull-up settings.
     */
    func updatePullUpInput(isWeighted: Bool, additionalWeight: Double) {
        if testInputs[.pullUp] == nil {
            testInputs[.pullUp] = TestInput()
        }
        
        testInputs[.pullUp]?.isWeighted = isWeighted
        testInputs[.pullUp]?.additionalWeight = additionalWeight
        testInputs[.pullUp]?.validate()
    }
    
    /**
     * Shows exercise instructions.
     */
    func showInstructions(for exerciseType: StrengthExerciseType) {
        showingInstructions = exerciseType
    }
    
    /**
     * Hides exercise instructions.
     */
    func hideInstructions() {
        showingInstructions = nil
    }
    
    // MARK: - Computed Properties
    
    var completedExercisesCount: Int {
        testInputs.values.filter { $0.isCompleted }.count
    }
    
    var progressPercentage: Double {
        Double(completedExercisesCount) / Double(StrengthExerciseType.allCases.count)
    }
    
    var canCompleteTest: Bool {
        completedExercisesCount == StrengthExerciseType.allCases.count
    }
    
    var currentExercise: StrengthExerciseType? {
        return StrengthExerciseType.allCases.first { exerciseType in
            !(testInputs[exerciseType]?.isCompleted ?? false)
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeTestInputs(for user: User) {
        testInputs.removeAll()
        
        for exerciseType in StrengthExerciseType.allCases {
            let input = TestInput()
            
            // Pre-populate with previous best if available
            if let previousBest = user.getCurrentOneRM(for: exerciseType) {
                input.value = previousBest
                input.previousBest = previousBest
            }
            
            testInputs[exerciseType] = input
        }
    }
    
    private func checkTestCompletion() {
        if completedExercisesCount == StrengthExerciseType.allCases.count {
            completeTest()
        }
    }
    
    private func resetTestState() {
        currentTest = nil
        testInputs.removeAll()
        isTestInProgress = false
        isTestCompleted = false
        showingResults = false
        errorMessage = nil
        isLoading = false
    }
    
    private func setupInputValidation() {
        // Observe input changes for real-time validation
        $testInputs
            .sink { [weak self] inputs in
                self?.validateAllInputs()
            }
            .store(in: &cancellables)
    }
    
    private func validateAllInputs() {
        // Validate each input and update error states
        for (exerciseType, input) in testInputs {
            let validation = scoringService.validateTestInput(
                exerciseType: exerciseType,
                value: input.value,
                userWeight: currentTest?.userWeight ?? 80.0,
                additionalWeight: input.additionalWeight
            )
            
            testInputs[exerciseType]?.isValid = validation.isValid
            testInputs[exerciseType]?.errorMessage = validation.errorMessage
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("❌ StrengthTestViewModel: Save failed - \(error.localizedDescription)")
            errorMessage = "strength.error.saveFailure".localized
        }
    }
    
    // MARK: - Safe Access Helpers
    
    /**
     * Safely gets exercise name with fallback.
     */
    func safeExerciseName(for exerciseType: StrengthExerciseType) -> String {
        return exerciseType.name
    }
    
    /**
     * Safely validates exercise type exists.
     */
    func isValidExerciseType(_ rawValue: String) -> Bool {
        return StrengthExerciseType(rawValue: rawValue) != nil
    }
    
    /**
     * Safely gets strength level with fallback.
     */
    func safeStrengthLevel(for rawValue: Int) -> StrengthLevel {
        return StrengthLevel(rawValue: rawValue) ?? .beginner
    }
}

// MARK: - Supporting Types

/**
 * Input state for individual exercises within the test.
 */
class TestInput: ObservableObject {
    @Published var value: Double = 0.0
    @Published var isWeighted: Bool = false
    @Published var additionalWeight: Double = 0.0
    @Published var isCompleted: Bool = false
    @Published var isValid: Bool = true
    @Published var errorMessage: String?
    
    var previousBest: Double?
    
    func validate() {
        // Enhanced validation with safety checks
        guard value.isFinite && !value.isNaN else {
            isValid = false
            errorMessage = "strength.validation.positiveValue".localized
            return
        }
        
        isValid = value > 0
        if !isValid {
            errorMessage = "strength.validation.positiveValue".localized
        } else {
            errorMessage = nil
        }
    }
    
    /**
     * Safe validation with comprehensive checks.
     */
    func validateSafely(for exerciseType: StrengthExerciseType) {
        // Check for NaN and infinite values
        guard value.isFinite && !value.isNaN else {
            isValid = false
            errorMessage = "strength.validation.positiveValue".localized
            return
        }
        
        // Check for additional weight issues
        if isWeighted {
            guard additionalWeight.isFinite && !additionalWeight.isNaN else {
                isValid = false
                errorMessage = "strength.validation.positiveValue".localized
                return
            }
        }
        
        // Standard validation
        validate()
    }
    
    var isPersonalRecord: Bool {
        guard let previousBest = previousBest else { return value > 0 }
        return value > previousBest
    }
}

// MARK: - Test State Extensions

extension StrengthTestViewModel {
    
    /**
     * Gets formatted progress text for UI display.
     */
    var progressText: String {
        return "strength.progress.exercisesCompleted".localized
            .replacingOccurrences(of: "{completed}", with: "\(completedExercisesCount)")
            .replacingOccurrences(of: "{total}", with: "\(StrengthExerciseType.allCases.count)")
    }
    
    /**
     * Gets the next recommended exercise to complete.
     */
    var nextExerciseRecommendation: String? {
        guard let nextExercise = currentExercise else { return nil }
        
        return "strength.recommendation.nextExercise".localized
            .replacingOccurrences(of: "{exercise}", with: nextExercise.name)
    }
    
    /**
     * Generates a shareable summary of test results.
     */
    func generateShareableSummary() -> String? {
        guard let currentTest = currentTest,
              currentTest.isCompleted else { return nil }
        
        return scoringService.formatTestSummary(currentTest, includeRecommendations: false)
    }
    
    /**
     * Gets estimated time remaining for test completion.
     */
    var estimatedTimeRemaining: String {
        let remainingExercises = StrengthExerciseType.allCases.count - completedExercisesCount
        let minutesPerExercise = 2 // Average time per exercise
        let totalMinutes = remainingExercises * minutesPerExercise
        
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)h \(minutes)m"
        }
    }
}
