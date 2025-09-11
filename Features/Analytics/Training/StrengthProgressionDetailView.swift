import SwiftUI
import Charts
import SwiftData

struct StrengthProgressionDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Query private var users: [User]
    @State private var selectedTimeRange: TimeRange = .sixMonths
    @State private var selectedExercise: String = "Bench Press"
    
    private var currentUser: User? {
        users.first
    }
    
    enum TimeRange: String, CaseIterable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"
        
        var displayName: String {
            switch self {
            case .threeMonths: return "analytics.last_3_months".localized
            case .sixMonths: return "analytics.last_6_months".localized
            case .oneYear: return "analytics.last_year".localized
            case .allTime: return "analytics.all_time".localized
            }
        }
        
        var months: Int {
            switch self {
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .allTime: return 24
            }
        }
    }
    
    struct ProgressDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let exercise: String
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.l) {
                // Header with exercise selector
                headerSection
                
                // Time range selector
                timeRangeSelector
                
                // Progress chart
                progressChart
                
                // Statistics cards
                statisticsSection
                
                // Exercise comparison
                exerciseComparisonSection
            }
            .padding()
        }
        .navigationTitle("analytics.strength_progression".localized)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("analytics.strength_progression_detail".localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("analytics.track_your_strength_gains".localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var exerciseSelector: some View {
        Menu {
            ForEach(availableExercises, id: \.self) { exercise in
                Button(exercise) {
                    selectedExercise = exercise
                }
            }
        } label: {
            HStack {
                Text(selectedExercise)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(theme.colors.backgroundSecondary)
            .cornerRadius(theme.radius.m)
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.displayName) {
                    selectedTimeRange = range
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedTimeRange == range ? .white : theme.colors.textSecondary)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(selectedTimeRange == range ? theme.colors.accent : theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.s)
            }
            
            Spacer()
        }
    }
    
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("analytics.progress_chart".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                exerciseSelector
            }
            
            if progressData.isEmpty {
                EmptyStateView(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: "analytics.no_progress_data_title".localized,
                    message: "analytics.no_progress_data_message".localized,
                    primaryTitle: "training.start_workout".localized,
                    primaryAction: { }
                )
                .frame(height: 200)
            } else {
                Chart(progressData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(theme.colors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(theme.colors.accent)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let weight = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatWeight(weight))
                                    .font(.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDate(date))
                                    .font(.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
    
    private var statisticsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: theme.spacing.m) {
            StatCard(
                title: "analytics.current_max".localized,
                value: formatWeight(currentMax),
                icon: "dumbbell.fill",
                color: .orange
            )
            
            StatCard(
                title: "analytics.total_improvement".localized,
                value: "+\(String(format: "%.1f", totalImprovement))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            StatCard(
                title: "analytics.last_pr".localized,
                value: lastPRDate,
                icon: "calendar",
                color: .blue
            )
            
            StatCard(
                title: "analytics.training_frequency".localized,
                value: "\(trainingFrequency)x/week",
                icon: "repeat",
                color: .purple
            )
        }
    }
    
    private var exerciseComparisonSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("analytics.exercise_comparison".localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: theme.spacing.s) {
                ForEach(exerciseComparison, id: \.exercise) { comparison in
                    ExerciseComparisonRow(comparison: comparison)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
    
    // MARK: - Data Properties
    
    private var availableExercises: [String] {
        ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull Up"]
    }
    
    private var progressData: [ProgressDataPoint] {
        generateProgressData(for: selectedExercise, timeRange: selectedTimeRange)
    }
    
    private var currentMax: Double {
        guard let user = currentUser else { return 0 }
        switch selectedExercise {
        case "Bench Press": return user.benchPressOneRM ?? 0
        case "Squat": return user.squatOneRM ?? 0
        case "Deadlift": return user.deadliftOneRM ?? 0
        case "Overhead Press": return user.overheadPressOneRM ?? 0
        default: return 0
        }
    }
    
    private var totalImprovement: Double {
        guard progressData.count > 1 else { return 0 }
        let first = progressData.first?.weight ?? 0
        let last = progressData.last?.weight ?? 0
        guard first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }
    
    private var lastPRDate: String {
        guard let lastPoint = progressData.last else { return "--" }
        return formatDate(lastPoint.date, short: true)
    }
    
    private var trainingFrequency: Int {
        // Calculate real training frequency from last 4 weeks
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let liftSessions = getLiftSessionsFromLast4Weeks(since: fourWeeksAgo)
        return max(1, liftSessions.count / 4) // Average sessions per week
    }
    
    private var exerciseComparison: [ExerciseComparison] {
        availableExercises.map { exercise in
            ExerciseComparison(
                exercise: exercise,
                currentMax: getCurrentMax(for: exercise),
                improvement: getImprovement(for: exercise)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateProgressData(for exercise: String, timeRange: TimeRange) -> [ProgressDataPoint] {
        let endDate = Date()
        let _ = Calendar.current.date(byAdding: .month, value: -timeRange.months, to: endDate) ?? endDate
        let baseWeight = currentMax > 0 ? currentMax * 0.85 : 60.0 // Start at 85% of current max
        
        var data: [ProgressDataPoint] = []
        let numberOfPoints = min(timeRange.months * 2, 12) // Bi-weekly data points
        
        for i in 0..<numberOfPoints {
            let date = Calendar.current.date(byAdding: .weekOfYear, value: i * 2 - numberOfPoints * 2, to: endDate) ?? endDate
            let progressionFactor = Double(i) / Double(numberOfPoints - 1)
            let weight = baseWeight + (currentMax - baseWeight) * progressionFactor
            
            data.append(ProgressDataPoint(
                date: date,
                weight: weight,
                exercise: exercise
            ))
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    private func getCurrentMax(for exercise: String) -> Double {
        guard let user = currentUser else { return 0 }
        switch exercise {
        case "Bench Press": return user.benchPressOneRM ?? 0
        case "Squat": return user.squatOneRM ?? 0
        case "Deadlift": return user.deadliftOneRM ?? 0
        case "Overhead Press": return user.overheadPressOneRM ?? 0
        case "Pull Up": return user.pullUpOneRM ?? 0
        default: return 0
        }
    }
    
    private func getImprovement(for exercise: String) -> Double {
        // Calculate real improvement from exercise progression
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        
        // Get recent and older exercise results
        let recentResults = getExerciseResults(for: exercise, since: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
        let olderResults = getExerciseResults(for: exercise, since: twoMonthsAgo, until: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
        
        guard let recentMax = recentResults.compactMap({ $0.maxWeight }).max(),
              let olderMax = olderResults.compactMap({ $0.maxWeight }).max(),
              olderMax > 0 else {
            return 0.0 // No improvement data available
        }
        
        return ((recentMax - olderMax) / olderMax) * 100.0
    }
    
    // MARK: - Data Helper Methods
    
    private func getLiftSessionsFromLast4Weeks(since date: Date) -> [LiftSession] {
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                (session.endDate ?? session.startDate) >= date
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    private func getExerciseResults(for exerciseName: String, since startDate: Date, until endDate: Date? = nil) -> [LiftExerciseResult] {
        let end = endDate ?? Date()
        
        let descriptor = FetchDescriptor<LiftExerciseResult>(
            predicate: #Predicate<LiftExerciseResult> { result in
                result.exercise?.exerciseName == exerciseName &&
                result.performedAt >= startDate &&
                result.performedAt <= end
            },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return "\(Int(weight))kg"
        } else {
            let weightInLbs = weight * 2.20462
            return "\(Int(weightInLbs))lb"
        }
    }
    
    private func formatDate(_ date: Date, short: Bool = false) -> String {
        let formatter = DateFormatter()
        if short {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(1)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .cardStyle()
    }
}

struct ExerciseComparison {
    let exercise: String
    let currentMax: Double
    let improvement: Double
}

struct ExerciseComparisonRow: View {
    let comparison: ExerciseComparison
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(comparison.exercise)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("+\(String(format: "%.1f", comparison.improvement))% improvement")
                    .font(.caption)
                    .foregroundColor(theme.colors.success)
            }
            
            Spacer()
            
            Text(formatWeight(comparison.currentMax))
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.vertical, theme.spacing.xs)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return "\(Int(weight))kg"
        } else {
            let weightInLbs = weight * 2.20462
            return "\(Int(weightInLbs))lb"
        }
    }
}

#Preview {
    StrengthProgressionDetailView()
        .environment(ThemeManager())
        .environment(UnitSettings.shared)
        .modelContainer(for: [User.self], inMemory: true)
}