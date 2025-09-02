import SwiftUI
import SwiftData
import Combine

/**
 * View model for managing test results display and historical data.
 * 
 * Handles test result visualization, comparison with previous tests,
 * and provides insights for user progress tracking.
 */
@MainActor
final class TestResultsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentResults: StrengthTest?
    @Published var historicalTests: [StrengthTest] = []
    @Published var showingComparison: Bool = false
    @Published var selectedHistoricalTest: StrengthTest?
    @Published var isLoadingHistory: Bool = false
    @Published var shareText: String?
    @Published var showingShareSheet: Bool = false
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let scoringService = TestScoringService.shared
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Data Loading
    
    /**
     * Loads user's strength test history.
     */
    func loadTestHistory() {
        isLoadingHistory = true
        
        do {
            let descriptor = FetchDescriptor<StrengthTest>(
                predicate: #Predicate { $0.isCompleted },
                sortBy: [SortDescriptor(\.testDate, order: .reverse)]
            )
            
            historicalTests = try modelContext.fetch(descriptor)
            isLoadingHistory = false
        } catch {
            print("Failed to load test history: \(error)")
            isLoadingHistory = false
        }
    }
    
    /**
     * Sets the current test results for display.
     */
    func setCurrentResults(_ strengthTest: StrengthTest) {
        currentResults = strengthTest
        loadTestHistory()
    }
    
    // MARK: - Comparison Methods
    
    /**
     * Compares current test with previous test.
     */
    func compareWithPrevious() -> TestComparison? {
        guard let current = currentResults,
              let previous = previousTest else { return nil }
        
        return TestComparison(current: current, previous: previous)
    }
    
    /**
     * Shows comparison view with selected historical test.
     */
    func showComparison(with historicalTest: StrengthTest) {
        selectedHistoricalTest = historicalTest
        showingComparison = true
    }
    
    /**
     * Hides comparison view.
     */
    func hideComparison() {
        showingComparison = false
        selectedHistoricalTest = nil
    }
    
    // MARK: - Sharing Methods
    
    /**
     * Prepares test results for sharing.
     */
    func prepareForSharing(includeRecommendations: Bool = true) {
        guard let currentResults = currentResults else { return }
        
        shareText = scoringService.formatTestSummary(
            currentResults,
            includeRecommendations: includeRecommendations
        )
        
        showingShareSheet = true
    }
    
    /**
     * Dismisses share sheet.
     */
    func dismissShareSheet() {
        showingShareSheet = false
        shareText = nil
    }
    
    // MARK: - Progress Analysis
    
    /**
     * Analyzes progress over time for specific exercise.
     */
    func progressAnalysis(for exerciseType: StrengthExerciseType) -> ExerciseProgress? {
        let exerciseResults = historicalTests.compactMap { test in
            test.result(for: exerciseType)
        }.sorted { $0.testDate < $1.testDate }
        
        guard exerciseResults.count >= 2 else { return nil }
        
        return ExerciseProgress(
            exerciseType: exerciseType,
            results: exerciseResults
        )
    }
    
    /**
     * Gets overall strength trend over time.
     */
    var overallStrengthTrend: StrengthTrend {
        guard historicalTests.count >= 2 else { return .stable }
        
        let recentTests = Array(historicalTests.prefix(3))
        let scores = recentTests.map { $0.overallScore }
        
        let averageImprovement = zip(scores.dropFirst(), scores).map { current, previous in
            current - previous
        }.reduce(0, +) / Double(scores.count - 1)
        
        if averageImprovement > 0.05 { // 5% improvement threshold
            return .improving
        } else if averageImprovement < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Computed Properties
    
    var previousTest: StrengthTest? {
        return historicalTests.first { $0 != currentResults }
    }
    
    var hasHistoricalData: Bool {
        return !historicalTests.isEmpty
    }
    
    var timeSincePreviousTest: String? {
        guard let previous = previousTest else { return nil }
        
        let days = Calendar.current.dateComponents([.day], from: previous.testDate, to: Date()).day ?? 0
        
        if days < 7 {
            return "strength.results.daysAgo".localized.replacingOccurrences(of: "{days}", with: "\(days)")
        } else {
            let weeks = days / 7
            return "strength.results.weeksAgo".localized.replacingOccurrences(of: "{weeks}", with: "\(weeks)")
        }
    }
    
    var personalRecordsCount: Int {
        currentResults?.results.filter { $0.isPersonalRecord }.count ?? 0
    }
    
    var recommendationsCount: Int {
        guard let currentResults = currentResults else { return 0 }
        return scoringService.generateRecommendations(for: currentResults).count
    }
    
    // MARK: - Insights Generation
    
    /**
     * Generates key insights from test results.
     */
    func generateInsights() -> [TestInsight] {
        guard currentResults != nil else { return [] }
        
        var insights: [TestInsight] = []
        
        // Personal records insight
        if personalRecordsCount > 0 {
            insights.append(TestInsight(
                type: .personalRecords,
                title: "strength.insights.personalRecords".localized,
                description: "strength.insights.personalRecordsDescription".localized
                    .replacingOccurrences(of: "{count}", with: "\(personalRecordsCount)"),
                icon: "star.fill",
                color: .orange
            ))
        }
        
        // Strength profile insight
        insights.append(TestInsight(
            type: .strengthProfile,
            title: "strength.insights.profile".localized,
            description: getProfileInsightDescription(),
            icon: "figure.strengthtraining.traditional",
            color: getProfileInsightColor()
        ))
        
        // Progress trend insight
        if let comparison = compareWithPrevious() {
            insights.append(TestInsight(
                type: .progressTrend,
                title: "strength.insights.progress".localized,
                description: comparison.improvementDescription,
                icon: comparison.trendIcon,
                color: comparison.trendColor
            ))
        }
        
        return insights
    }
    
    private func getProfileInsightDescription() -> String {
        guard let profile = currentResults?.strengthProfile else { return "" }
        
        switch profile {
        case "balanced":
            return "strength.insights.balancedDescription".localized
        case "upper_dominant":
            return "strength.insights.upperDominantDescription".localized
        case "lower_dominant":
            return "strength.insights.lowerDominantDescription".localized
        default:
            return ""
        }
    }
    
    private func getProfileInsightColor() -> Color {
        guard let profile = currentResults?.strengthProfile else { return .gray }
        
        switch profile {
        case "balanced": return .green
        case "upper_dominant": return .blue
        case "lower_dominant": return .orange
        default: return .gray
        }
    }
}

// MARK: - Supporting Types

/**
 * Comparison between two strength tests.
 */
struct TestComparison {
    let current: StrengthTest
    let previous: StrengthTest
    
    var overallImprovement: Double {
        return current.overallScore - previous.overallScore
    }
    
    var improvementPercentage: Double {
        guard previous.overallScore > 0 else { return 0 }
        return (overallImprovement / previous.overallScore) * 100
    }
    
    var improvementDescription: String {
        if overallImprovement > 0.05 {
            return "strength.comparison.significantImprovement".localized
                .replacingOccurrences(of: "{percentage}", with: String(format: "%.1f%%", improvementPercentage))
        } else if overallImprovement > 0 {
            return "strength.comparison.slightImprovement".localized
        } else if overallImprovement < -0.05 {
            return "strength.comparison.decline".localized
        } else {
            return "strength.comparison.stable".localized
        }
    }
    
    var trendIcon: String {
        if overallImprovement > 0.05 {
            return "arrow.up.circle.fill"
        } else if overallImprovement > 0 {
            return "arrow.up.circle"
        } else if overallImprovement < -0.05 {
            return "arrow.down.circle.fill"
        } else {
            return "minus.circle"
        }
    }
    
    var trendColor: Color {
        if overallImprovement > 0.05 {
            return .green
        } else if overallImprovement > 0 {
            return .blue
        } else if overallImprovement < -0.05 {
            return .red
        } else {
            return .gray
        }
    }
    
    /**
     * Gets exercise-specific comparisons.
     */
    func exerciseComparison(for exerciseType: StrengthExerciseType) -> ExerciseComparison? {
        guard let currentResult = current.result(for: exerciseType),
              let previousResult = previous.result(for: exerciseType) else {
            return nil
        }
        
        return ExerciseComparison(
            current: currentResult,
            previous: previousResult,
            exerciseType: exerciseType
        )
    }
}

/**
 * Progress analysis for a specific exercise over time.
 */
struct ExerciseProgress {
    let exerciseType: StrengthExerciseType
    let results: [StrengthTestResult]
    
    var trend: StrengthTrend {
        guard results.count >= 2 else { return .stable }
        
        let recentValues = results.suffix(3).map { $0.value }
        let averageImprovement = zip(recentValues.dropFirst(), recentValues).map { current, previous in
            (current - previous) / previous
        }.reduce(0, +) / Double(recentValues.count - 1)
        
        if averageImprovement > 0.1 { // 10% improvement
            return .improving
        } else if averageImprovement < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    var bestResult: StrengthTestResult? {
        return results.max { $0.value < $1.value }
    }
    
    var totalImprovement: Double {
        guard let first = results.first, let last = results.last else { return 0 }
        return last.value - first.value
    }
    
    var improvementPercentage: Double {
        guard let first = results.first, let last = results.last, first.value > 0 else { return 0 }
        return ((last.value - first.value) / first.value) * 100
    }
}

/**
 * Comparison between two exercise results.
 */
struct ExerciseComparison {
    let current: StrengthTestResult
    let previous: StrengthTestResult
    let exerciseType: StrengthExerciseType
    
    var improvement: Double {
        return current.value - previous.value
    }
    
    var improvementPercentage: Double {
        guard previous.value > 0 else { return 0 }
        return (improvement / previous.value) * 100
    }
    
    var levelImprovement: Int {
        return current.strengthLevel - previous.strengthLevel
    }
}

/**
 * Test insight for results analysis.
 */
struct TestInsight {
    let type: InsightType
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    enum InsightType {
        case personalRecords
        case strengthProfile
        case progressTrend
        case recommendation
    }
}

/**
 * Overall strength trend classification.
 */
enum StrengthTrend {
    case improving
    case stable
    case declining
    
    var description: String {
        switch self {
        case .improving:
            return "strength.trend.improving".localized
        case .stable:
            return "strength.trend.stable".localized
        case .declining:
            return "strength.trend.declining".localized
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle"
        case .declining: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        }
    }
}
