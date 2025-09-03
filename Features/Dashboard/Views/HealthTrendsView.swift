import SwiftUI
import Charts

struct HealthTrendsView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @StateObject private var unitSettings = UnitSettings.shared
    @State private var isLoading = true
    @State private var selectedMetric: HealthMetric = .steps
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Metric Selector
                    MetricSelector(selectedMetric: $selectedMetric)
                    
                    // MARK: - Main Chart
                    if isLoading {
                        LoadingChartView()
                    } else {
                        HealthMetricChart(
                            metric: selectedMetric,
                            dataPoints: getDataPointsForMetric(selectedMetric)
                        )
                    }
                    
                    // MARK: - Workout Trends Section
                    if !isLoading {
                        WorkoutTrendsSection(trends: healthKitService.workoutTrends)
                    }
                    
                    // MARK: - Quick Stats Grid
                    if !isLoading {
                        HealthQuickStatsGrid()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle(CommonKeys.HealthKit.trendsTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadHealthTrendsData()
            }
        }
        .onAppear {
            Task {
                await loadHealthTrendsData()
            }
        }
    }
    
    private func loadHealthTrendsData() async {
        isLoading = true
        defer { isLoading = false }
        
        await healthKitService.loadAllHistoricalData()
    }
    
    private func getDataPointsForMetric(_ metric: HealthMetric) -> [HealthDataPoint] {
        switch metric {
        case .steps:
            return healthKitService.stepsHistory
        case .weight:
            return healthKitService.weightHistory
        case .heartRate:
            return healthKitService.heartRateHistory
        }
    }
}

// MARK: - Health Metric Enum
enum HealthMetric: String, CaseIterable {
    case steps
    case weight
    case heartRate
    
    var displayName: String {
        switch self {
        case .steps: return CommonKeys.HealthKit.stepsMetric.localized
        case .weight: return CommonKeys.HealthKit.weightMetric.localized
        case .heartRate: return CommonKeys.HealthKit.heartRateMetric.localized
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .weight: return "scalemass.fill"
        case .heartRate: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .steps: return .blue
        case .weight: return .green
        case .heartRate: return .red
        }
    }
    
    func unit(for unitSystem: UnitSystem) -> String {
        switch self {
        case .steps: return CommonKeys.HealthKit.stepsUnit.localized
        case .weight: 
            switch unitSystem {
            case .metric: return "kg"
            case .imperial: return "lb"
            }
        case .heartRate: return CommonKeys.HealthKit.heartRateUnit.localized
        }
    }
}

// MARK: - Metric Selector
struct MetricSelector: View {
    @Binding var selectedMetric: HealthMetric
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(HealthMetric.allCases, id: \.self) { metric in
                Button(action: {
                    selectedMetric = metric
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.caption)
                        
                        Text(metric.displayName)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedMetric == metric ? metric.color : theme.colors.backgroundSecondary)
                    .foregroundColor(selectedMetric == metric ? .white : theme.colors.textPrimary)
                    .cornerRadius(16)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Health Metric Chart
struct HealthMetricChart: View {
    let metric: HealthMetric
    let dataPoints: [HealthDataPoint]
    @Environment(\.theme) private var theme
    @StateObject private var unitSettings = UnitSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.displayName)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if let trend = calculateTrend() {
                        HStack(spacing: 6) {
                            Image(systemName: trend.trend.icon)
                                .font(.caption)
                                .foregroundColor(getTrendColor(trend.trend))
                            
                            Text("\(trend.trend.displayText) %\(String(format: "%.1f", abs(trend.percentChange)))")
                                .font(theme.typography.caption)
                                .foregroundColor(getTrendColor(trend.trend))
                        }
                    }
                }
                
                Spacer()
                
                if let latestValue = dataPoints.last?.value {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatValue(latestValue, for: metric))
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(metric.color)
                        
                        Text(metric.unit(for: unitSettings.unitSystem))
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            
            if dataPoints.isEmpty {
                HealthEmptyChartView(message: "\(metric.displayName) \(CommonKeys.HealthKit.dataNotFoundMessage.localized)")
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value(CommonKeys.HealthKit.dateLabel.localized, point.date),
                        y: .value(CommonKeys.HealthKit.valueLabel.localized, point.value)
                    )
                    .foregroundStyle(metric.color)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value(CommonKeys.HealthKit.dateLabel.localized, point.date),
                        y: .value(CommonKeys.HealthKit.valueLabel.localized, point.value)
                    )
                    .foregroundStyle(metric.color.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func calculateTrend() -> HealthDataTrend? {
        guard !dataPoints.isEmpty else { return nil }
        return HealthDataTrend(dataPoints: dataPoints)
    }
    
    private func getTrendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
    
    private func formatValue(_ value: Double, for metric: HealthMetric) -> String {
        switch metric {
        case .steps:
            return String(format: "%.0f", value)
        case .weight:
            switch unitSettings.unitSystem {
            case .metric:
                return String(format: "%.1f", value)
            case .imperial:
                let lbs = UnitsConverter.kgToLbs(value)
                return String(format: "%.1f", lbs)
            }
        case .heartRate:
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Workout Trends Section
struct WorkoutTrendsSection: View {
    let trends: WorkoutTrends
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.HealthKit.workoutTrendsTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            // Weekly workout chart
            if !trends.weeklyWorkouts.isEmpty {
                Chart(trends.weeklyWorkouts) { weekData in
                    BarMark(
                        x: .value(CommonKeys.HealthKit.weekLabel.localized, weekData.weekString),
                        y: .value(CommonKeys.HealthKit.workoutLabel.localized, weekData.workoutCount)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
            
            // Activity type breakdown
            if !trends.activityTypeBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CommonKeys.HealthKit.activityBreakdownTitle.localized)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    ForEach(trends.activityTypeBreakdown.prefix(4)) { activity in
                        HStack {
                            Text(activity.activityType)
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(activity.count) (\(String(format: "%.1f", activity.percentage))%)")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        ProgressView(value: activity.percentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

// MARK: - Quick Stats Grid
struct HealthQuickStatsGrid: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @StateObject private var unitSettings = UnitSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.HealthKit.currentHealthDataTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                HealthStatCard(
                    title: CommonKeys.HealthKit.todayStepsTitle.localized,
                    value: String(format: "%.0f", healthKitService.todaySteps),
                    unit: CommonKeys.HealthKit.stepsUnit.localized,
                    icon: "figure.walk",
                    color: .blue
                )
                
                HealthStatCard(
                    title: CommonKeys.HealthKit.activeCaloriesTitle.localized,
                    value: String(format: "%.0f", healthKitService.todayActiveCalories),
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                if let weight = healthKitService.currentWeight {
                    HealthStatCard(
                        title: CommonKeys.HealthKit.currentWeightTitle.localized,
                        value: formatWeight(weight),
                        unit: weightUnit,
                        icon: "scalemass.fill",
                        color: .green
                    )
                }
                
                if let hr = healthKitService.restingHeartRate {
                    HealthStatCard(
                        title: CommonKeys.HealthKit.restingHeartRateTitle.localized,
                        value: String(format: "%.0f", hr),
                        unit: CommonKeys.HealthKit.heartRateUnit.localized,
                        icon: "heart.fill",
                        color: .red
                    )
                }
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func formatWeight(_ kg: Double) -> String {
        switch unitSettings.unitSystem {
        case .metric:
            return String(format: "%.1f", kg)
        case .imperial:
            let lbs = UnitsConverter.kgToLbs(kg)
            return String(format: "%.1f", lbs)
        }
    }
    
    private var weightUnit: String {
        switch unitSettings.unitSystem {
        case .metric: return "kg"
        case .imperial: return "lb"
        }
    }
}

// MARK: - Health Stat Card
struct HealthStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(unit)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(16)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(10)
    }
}

// MARK: - Loading and Empty States
struct LoadingChartView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(CommonKeys.HealthKit.loadingDataMessage.localized)
                .frame(height: 200)
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct HealthEmptyChartView: View {
    let message: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            
            Text(message)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

#Preview {
    HealthTrendsView()
}