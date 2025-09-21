import SwiftUI
import Charts
import SwiftData

struct StrengthProgressionDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Query private var users: [User]
    @State private var viewModel = StrengthProgressionDetailViewModel()
    
    private var currentUser: User? {
        users.first
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
        .onAppear {
            viewModel.setup(modelContext: modelContext, user: currentUser)
        }
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
            ForEach(viewModel.availableExercises, id: \.self) { exercise in
                Button(exercise) {
                    viewModel.updateSelectedExercise(exercise)
                }
            }
        } label: {
            HStack {
                Text(viewModel.selectedExercise)
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
                    viewModel.updateTimeRange(range)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(viewModel.selectedTimeRange == range ? .white : theme.colors.textSecondary)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(viewModel.selectedTimeRange == range ? theme.colors.accent : theme.colors.backgroundSecondary)
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
            
            if viewModel.progressData.isEmpty {
                EmptyStateView(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: "analytics.no_progress_data_title".localized,
                    message: "analytics.no_progress_data_message".localized,
                    primaryTitle: "training.start_workout".localized,
                    primaryAction: { }
                )
                .frame(height: 200)
            } else {
                Chart(viewModel.progressData) { dataPoint in
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
                                Text(viewModel.formatDate(date, short: true))
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
                value: formatWeight(viewModel.currentMax),
                icon: "dumbbell.fill",
                color: .orange
            )

            StatCard(
                title: "analytics.total_improvement".localized,
                value: "+\(String(format: "%.1f", viewModel.totalImprovement))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )

            StatCard(
                title: "analytics.last_pr".localized,
                value: viewModel.lastPRDate,
                icon: "calendar",
                color: .blue
            )

            StatCard(
                title: "analytics.training_frequency".localized,
                value: "\(viewModel.trainingFrequency)x/week",
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
                ForEach(viewModel.exerciseComparison, id: \.exercise) { comparison in
                    ExerciseComparisonRow(comparison: comparison)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
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