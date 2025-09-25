import SwiftUI
import SwiftData
import Charts

struct ProgressChartsView: View {
    @State private var viewModel = ProgressChartsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Environment(UnitSettings.self) var unitSettings

    // SwiftData queries
    @Query private var allWeightEntries: [WeightEntry]
    @Query private var allLiftSessions: [LiftSession]
    @Query private var allCardioSessions: [CardioSession]
    @Query private var allBodyMeasurements: [BodyMeasurement]
    
    // PERFORMANCE: Removed redundant filtering - now handled by computed properties
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                ProgressChartsHeaderSection()
                
                // Time Range Selector
                TimeRangeSelector(selectedRange: $viewModel.selectedTimeRange)

                // Chart Type Selector
                ChartTypeSelector(selectedType: $viewModel.selectedChartType)

                // Main Chart Section
                if viewModel.isLoading {
                    ChartSkeletonView()
                } else {
                    MainChartSection(
                        chartType: viewModel.selectedChartType,
                        timeRange: viewModel.selectedTimeRange,
                        weightEntries: viewModel.filteredWeightEntries,
                        liftSessions: viewModel.filteredLiftSessions,
                        cardioSessions: allCardioSessions,
                        bodyMeasurements: viewModel.filteredBodyMeasurements,
                        user: viewModel.currentUser
                    )
                }

                // Summary Statistics
                SummaryStatisticsSection(
                    chartType: viewModel.selectedChartType,
                    weightEntries: viewModel.filteredWeightEntries,
                    liftSessions: viewModel.filteredLiftSessions,
                    cardioSessions: allCardioSessions,
                    timeRange: viewModel.selectedTimeRange
                )

                // Insights Section
                InsightsSection(
                    weightEntries: viewModel.filteredWeightEntries,
                    liftSessions: viewModel.filteredLiftSessions,
                    timeRange: viewModel.selectedTimeRange
                )
            }
            .padding()
        }
        .navigationTitle(ProfileKeys.progressCharts.localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.loadProgressData(
                allWeightEntries: allWeightEntries,
                allLiftSessions: allLiftSessions,
                allCardioSessions: allCardioSessions,
                allBodyMeasurements: allBodyMeasurements,
                user: users.first
            )
        }
        .onChange(of: viewModel.selectedTimeRange) { _, newRange in
            viewModel.changeTimeRange(
                to: newRange,
                allWeightEntries: allWeightEntries,
                allLiftSessions: allLiftSessions,
                allCardioSessions: allCardioSessions,
                allBodyMeasurements: allBodyMeasurements,
                user: users.first
            )
        }
        .onChange(of: viewModel.selectedChartType) { _, newType in
            viewModel.changeChartType(
                to: newType,
                allWeightEntries: allWeightEntries,
                allLiftSessions: allLiftSessions,
                allCardioSessions: allCardioSessions,
                allBodyMeasurements: allBodyMeasurements,
                user: users.first
            )
        }
    }
}

// MARK: - Header Section
struct ProgressChartsHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text(ProfileKeys.progressCharts.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(ProfileKeys.chartsSubtitle.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ProfileKeys.Analytics.timeRange.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            selectedRange = range
                        } label: {
                            Text(range.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedRange == range ? Color.blue : Color(.secondarySystemBackground))
                                .foregroundColor(selectedRange == range ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Chart Type Selector
struct ChartTypeSelector: View {
    @Binding var selectedType: ChartType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ProfileKeys.Analytics.chartType.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        let isSelected = selectedType == type
                        let iconColor: Color = isSelected ? .white : type.color
                        let textColor: Color = isSelected ? .white : .primary
                        let bgColor: Color = isSelected ? type.color : Color(.secondarySystemBackground)

                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(iconColor)

                            Text(type.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(textColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bgColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Main Chart Section
struct MainChartSection: View {
    let chartType: ChartType
    let timeRange: TimeRange
    let weightEntries: [WeightEntry]
    let liftSessions: [LiftSession]
    let cardioSessions: [CardioSession]
    let bodyMeasurements: [BodyMeasurement]
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartType.displayName)
                .font(.headline)
                .fontWeight(.semibold)

            chartContentView
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private var chartContentView: some View {
        switch chartType {
        case .weight:
            WeightChartView(entries: weightEntries)
        case .workoutVolume:
            WorkoutVolumeChartView(liftSessions: liftSessions)
        case .workoutFrequency:
            WorkoutFrequencyChartView(liftSessions: liftSessions, timeRange: timeRange)
        case .bodyMeasurements:
            BodyMeasurementsChartView(measurements: bodyMeasurements)
        case .strength:
            StrengthChartView(liftSessions: liftSessions)
        case .cardio:
            CardioChartView(cardioSessions: cardioSessions.filter { $0.isCompleted && $0.startDate >= timeRange.cutoffDate })
        }
    }
}

// MARK: - Weight Chart View
struct WeightChartView: View {
    let entries: [WeightEntry]
    @Environment(UnitSettings.self) var unitSettings
    
    @State private var selectedPoint: Date? = nil
    
    private var chartData: [WeightChartData] {
        entries.map { WeightChartData(date: $0.date, weight: $0.weight) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if chartData.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noDataAvailable.localized)
            } else {
                if #available(iOS 16.0, *) {
                    Chart(chartData) { data in
                        LineMark(
                             x: .value("Date", data.date),
                             y: .value("Weight", data.weight)
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                             x: .value("Date", data.date),
                             y: .value("Weight", data.weight)
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(selectedPoint == data.date ? 80 : 50)
                        
                        // Highlight selected point
                        if let selectedPoint = selectedPoint, selectedPoint == data.date {
                            RuleMark(x: .value("Selected", selectedPoint))
                                .foregroundStyle(.orange.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    if let date = chartProxy.value(atX: location.x, as: Date.self) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedPoint = findNearestDataPoint(to: date)
                                        }
                                    }
                                }
                        }
                    }
                } else {
                    FallbackChartView(color: .orange, message: "Weight Change")
                }
            }
        }
    }
    
    private func findNearestDataPoint(to date: Date) -> Date? {
        return chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })?.date
    }
}

// MARK: - Workout Volume Chart View
struct WorkoutVolumeChartView: View {
    let liftSessions: [LiftSession]
    
    private var weeklyData: [WeeklyVolumeData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: liftSessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
        }
        
        return grouped.map { (week, sessions) in
            let totalVolume = sessions.reduce(0.0) { total, session in
                total + session.totalVolume
            }
            let workoutCount = sessions.count
            let averageVolume = workoutCount > 0 ? totalVolume / Double(workoutCount) : 0.0
            return WeeklyVolumeData(week: week, volume: totalVolume, workoutCount: workoutCount, averageVolume: averageVolume)
        }.sorted { $0.week < $1.week }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if weeklyData.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noDataAvailable.localized)
            } else {
                if #available(iOS 16.0, *) {
                    Chart(weeklyData) { data in
                        BarMark(
                            x: .value("Week", data.week),
                            y: .value("Volume", data.volume)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                } else {
                    FallbackChartView(color: .blue, message: "Workout Volume")
                }
            }
        }
    }
}

// MARK: - Workout Frequency Chart View
struct WorkoutFrequencyChartView: View {
    let liftSessions: [LiftSession]
    let timeRange: TimeRange
    
    private var frequencyData: [FrequencyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: liftSessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
        }
        
        return grouped.map { (week, sessions) in
            let frequency = sessions.count
            let target = 3 // Default weekly workout target
            let completionRate = Double(frequency) / Double(target)
            return FrequencyData(period: week, frequency: frequency, target: target, completionRate: completionRate)
        }.sorted { $0.period < $1.period }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if frequencyData.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noDataAvailable.localized)
            } else {
                if #available(iOS 16.0, *) {
                    Chart(frequencyData) { data in
                        BarMark(
                            x: .value("Week", data.period),
                            y: .value("Frequency", data.frequency)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 200)
                } else {
                    FallbackChartView(color: .green, message: "Workout Frequency")
                }
            }
        }
    }
}

// MARK: - Body Measurements Chart View
struct BodyMeasurementsChartView: View {
    let measurements: [BodyMeasurement]
    @Environment(UnitSettings.self) var unitSettings
    
    @State private var selectedMeasurementType: MeasurementType = .waist
    
    private var filteredMeasurements: [BodyMeasurement] {
        measurements.filter { $0.typeEnum == selectedMeasurementType }
            .sorted { $0.date < $1.date }
    }
    
    private var chartData: [MeasurementChartData] {
        filteredMeasurements.map { measurement in
            let convertedValue = unitSettings.unitSystem == .metric ? measurement.value : measurement.value * 0.393701
            return MeasurementChartData(
                date: measurement.date,
                measurement: convertedValue,
                measurementType: selectedMeasurementType.rawValue,
                change: 0.0
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if measurements.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noDataAvailable.localized)
            } else {
                // Measurement Type Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MeasurementType.allCases, id: \.self) { type in
                            Button {
                                selectedMeasurementType = type
                            } label: {
                                Text(type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedMeasurementType == type ? type.color : Color(.secondarySystemBackground))
                                    .foregroundColor(selectedMeasurementType == type ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Chart
                if chartData.isEmpty {
                    EmptyChartView(message: "No data for selected measurement")
                } else {
                    if #available(iOS 16.0, *) {
                        Chart(chartData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Measurement", data.measurement)
                            )
                            .foregroundStyle(selectedMeasurementType.color)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            PointMark(
                                x: .value("Date", data.date),
                                y: .value("Measurement", data.measurement)
                            )
                            .foregroundStyle(selectedMeasurementType.color)
                            .symbolSize(50)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } else {
                        FallbackChartView(
                            color: selectedMeasurementType.color, 
                            message: selectedMeasurementType.displayName
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Chart Skeleton View
struct ChartSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonView(height: 20, width: 150)
            
            VStack(spacing: 12) {
                // Chart area skeleton
                SkeletonView(height: 200, cornerRadius: 12)
                
                // Legend skeleton
                HStack(spacing: 12) {
                    SkeletonView(height: 12, width: 60)
                    SkeletonView(height: 12, width: 80)
                    SkeletonView(height: 12, width: 70)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.flattrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Data Available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("Start tracking to see your progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Fallback Chart View
struct FallbackChartView: View {
    let color: Color
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Charts require iOS 16+")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
}

// MARK: - Summary Statistics Section
struct SummaryStatisticsSection: View {
    let chartType: ChartType
    let weightEntries: [WeightEntry]
    let liftSessions: [LiftSession]
    let cardioSessions: [CardioSession]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ProfileKeys.Analytics.statistics.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                switch chartType {
                case .weight:
                    WeightStatisticsCards(entries: weightEntries)
                case .workoutVolume, .workoutFrequency:
                    WorkoutStatisticsCards(liftSessions: liftSessions, timeRange: timeRange)
                case .bodyMeasurements:
                    BodyMeasurementStatisticsCards()
                case .strength:
                    StrengthStatisticsCards(liftSessions: liftSessions, timeRange: timeRange)
                case .cardio:
                    CardioStatisticsCards(cardioSessions: cardioSessions.filter { $0.isCompleted && $0.startDate >= timeRange.cutoffDate }, timeRange: timeRange)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Weight Statistics Cards
struct WeightStatisticsCards: View {
    let entries: [WeightEntry]
    @Environment(UnitSettings.self) var unitSettings
    
    private var weightChange: Double {
        guard entries.count >= 2 else { return 0 }
        let latest = entries.first?.weight ?? 0
        let earliest = entries.last?.weight ?? 0
        return latest - earliest
    }
    
    private var averageWeight: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map { $0.weight }.reduce(0, +) / Double(entries.count)
    }
    
    var body: some View {
        StatCard(
            title: ProfileKeys.Analytics.weightChange.localized,
            value: UnitsFormatter.formatWeight(kg: weightChange, system: unitSettings.unitSystem),
            icon: weightChange >= 0 ? "arrow.up" : "arrow.down",
            color: weightChange >= 0 ? .green : .red
        )
        
        StatCard(
            title: ProfileKeys.Analytics.averageWeight.localized,
            value: UnitsFormatter.formatWeight(kg: averageWeight, system: unitSettings.unitSystem),
            icon: "scalemass.fill",
            color: .blue
        )
        
        StatCard(
            title: ProfileKeys.Analytics.entries.localized,
            value: "\(entries.count)",
            icon: "list.number",
            color: .orange
        )
        
        StatCard(
            title: ProfileKeys.Analytics.latest.localized,
            value: UnitsFormatter.formatWeight(kg: entries.first?.weight ?? 0, system: unitSettings.unitSystem),
            icon: "clock.badge.checkmark",
            color: .purple
        )
    }
}

// MARK: - Workout Statistics Cards
struct WorkoutStatisticsCards: View {
    let liftSessions: [LiftSession]
    let timeRange: TimeRange
    @Environment(UnitSettings.self) var unitSettings
    
    private var totalWorkouts: Int {
        liftSessions.count
    }
    
    private var averageWorkoutsPerWeek: Double {
        let weeks = timeRange.weekCount
        return weeks > 0 ? Double(totalWorkouts) / Double(weeks) : 0
    }
    
    private var totalVolume: Double {
        liftSessions.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var averageVolume: Double {
        totalWorkouts > 0 ? totalVolume / Double(totalWorkouts) : 0
    }
    
    var body: some View {
        StatCard(
            title: ProfileKeys.Analytics.totalWorkouts.localized,
            value: "\(totalWorkouts)",
            icon: "figure.strengthtraining.traditional",
            color: .blue
        )
        
        StatCard(
            title: ProfileKeys.Analytics.weeklyAverage.localized,
            value: String(format: "%.1f", averageWorkoutsPerWeek),
            icon: "calendar.badge.plus",
            color: .green
        )
        
        StatCard(
            title: ProfileKeys.Analytics.totalVolume.localized,
            value: UnitsFormatter.formatWeight(kg: totalVolume, system: unitSettings.unitSystem),
            icon: "chart.bar.fill",
            color: .orange
        )
        
        StatCard(
            title: ProfileKeys.Analytics.averageVolume.localized,
            value: UnitsFormatter.formatWeight(kg: averageVolume, system: unitSettings.unitSystem),
            icon: "chart.line.uptrend.xyaxis",
            color: .purple
        )
    }
}

// MARK: - Body Measurement Statistics Cards
struct BodyMeasurementStatisticsCards: View {
    var body: some View {
        StatCard(
            title: ProfileKeys.Analytics.change.localized,
            value: ProfileKeys.Analytics.calculating.localized,
            icon: "arrow.up.arrow.down",
            color: .blue
        )
        
        StatCard(
            title: ProfileKeys.Analytics.average.localized,
            value: ProfileKeys.Analytics.calculating.localized,
            icon: "chart.line.flattrend.xyaxis",
            color: .green
        )
    }
}

// StatCard now imported from StrengthProgressionDetailView

// MARK: - Insights Section
struct InsightsSection: View {
    let weightEntries: [WeightEntry]
    let liftSessions: [LiftSession]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ProfileKeys.Analytics.insights.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if !weightEntries.isEmpty && weightEntries.count >= 2 {
                    WeightInsightCard(entries: weightEntries)
                }
                
                if !liftSessions.isEmpty {
                    WorkoutInsightCard(liftSessions: liftSessions, timeRange: timeRange)
                }
                
                if liftSessions.isEmpty && weightEntries.isEmpty {
                    EmptyInsightCard()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct WeightInsightCard: View {
    let entries: [WeightEntry]
    
    private var trend: String {
        guard entries.count >= 2 else { return ProfileKeys.Analytics.insufficientData.localized }
        
        let latest = entries.first?.weight ?? 0
        let previous = entries.dropFirst().first?.weight ?? 0
        
        if latest > previous {
            return ProfileKeys.Analytics.trendingUpward.localized
        } else if latest < previous {
            return ProfileKeys.Analytics.trendingDownward.localized
        } else {
            return ProfileKeys.Analytics.stableTrend.localized
        }
    }
    
    var body: some View {
        InsightCard(
            icon: "scalemass.fill",
            title: ProfileKeys.Analytics.weightTrend.localized,
            insight: trend,
            color: .orange
        )
    }
}

struct WorkoutInsightCard: View {
    let liftSessions: [LiftSession]
    let timeRange: TimeRange
    
    private var consistency: String {
        let weeks = timeRange.weekCount
        let averagePerWeek = weeks > 0 ? Double(liftSessions.count) / Double(weeks) : 0
        
        if averagePerWeek >= 4 {
            return ProfileKeys.Analytics.excellentConsistency.localized
        } else if averagePerWeek >= 3 {
            return ProfileKeys.Analytics.goodConsistency.localized
        } else if averagePerWeek >= 2 {
            return ProfileKeys.Analytics.averageConsistency.localized
        } else {
            return ProfileKeys.Analytics.lowConsistency.localized
        }
    }
    
    var body: some View {
        InsightCard(
            icon: "dumbbell.fill",
            title: ProfileKeys.Analytics.workoutConsistency.localized,
            insight: consistency,
            color: .blue
        )
    }
}

struct EmptyInsightCard: View {
    var body: some View {
        InsightCard(
            icon: "lightbulb.fill",
            title: ProfileKeys.Analytics.insights.localized,
            insight: ProfileKeys.Analytics.noDataAvailable.localized,
            color: .gray
        )
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


#Preview {
    NavigationStack {
        ProgressChartsView()
    }
}
