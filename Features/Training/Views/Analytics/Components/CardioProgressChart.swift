import SwiftUI
import SwiftData
import Charts

struct CardioProgressChart: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Environment(HealthKitService.self) var healthKitService
    
    let user: User
    @State private var selectedTimeRange: TimeRange = .sixMonths
    @State private var selectedMetric: CardioMetric? = nil
    @State private var cardioSessions: [CardioSession] = []
    @State private var isLoading = false
    
    enum TimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"
        
        var months: Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .allTime: return 24
            }
        }
        
        var displayTitle: String {
            switch self {
            case .oneMonth: return TrainingKeys.CardioAnalytics.oneMonth.localized
            case .threeMonths: return TrainingKeys.CardioAnalytics.threeMonths.localized
            case .sixMonths: return TrainingKeys.CardioAnalytics.sixMonths.localized
            case .oneYear: return TrainingKeys.CardioAnalytics.lastYear.localized
            case .allTime: return TrainingKeys.CardioAnalytics.allTime.localized
            }
        }
    }
    
    enum CardioMetric: String, CaseIterable {
        case distance = "distance"
        case pace = "pace"
        case heartRate = "heartRate"
        
        var displayName: String {
            switch self {
            case .distance: return TrainingKeys.Cardio.distance.localized
            case .pace: return TrainingKeys.Cardio.pace.localized
            case .heartRate: return TrainingKeys.CardioAnalytics.heartRate.localized
            }
        }
        
        var icon: String {
            switch self {
            case .distance: return "location"
            case .pace: return "speedometer"
            case .heartRate: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .distance: return .blue
            case .pace: return .green
            case .heartRate: return .red
            }
        }
        
        var unit: String {
            switch self {
            case .distance: return "km/week"
            case .pace: return "min/km"
            case .heartRate: return "bpm"
            }
        }
    }
    
    struct CardioDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let distance: Double // km per week
        let averagePace: Double // min per km
        let averageHeartRate: Double // bpm
        let sessionCount: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            headerSection
            timeRangeSelector
            
            if isLoading {
                loadingState
            } else {
                metricsOverview
                cardioChart
                metricsLegend
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .shadow(color: theme.shadows.card, radius: 4, y: 2)
        .onAppear {
            loadCardioData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            loadCardioData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.CardioAnalytics.cardioTitle.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.CardioAnalytics.subtitle.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            if !cardioSessions.isEmpty {
                Button(action: {
                    selectedMetric = selectedMetric == nil ? .distance : nil
                }) {
                    Image(systemName: selectedMetric == nil ? "eye" : "eye.fill")
                        .font(.title3)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTimeRange = range
                    }
                }
                .font(.caption)
                .fontWeight(selectedTimeRange == range ? .semibold : .medium)
                .foregroundColor(selectedTimeRange == range ? .white : theme.colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedTimeRange == range ? 
                    theme.colors.accent : 
                    theme.colors.backgroundSecondary
                )
                .cornerRadius(theme.radius.s)
            }
            
            Spacer()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(TrainingKeys.CardioAnalytics.dataLoading.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
    
    private var metricsOverview: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(CardioMetric.allCases, id: \.self) { metric in
                metricCard(for: metric)
            }
        }
    }
    
    private func metricCard(for metric: CardioMetric) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.caption)
                    .foregroundColor(metric.color)
                
                Text(metric.displayName)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Text(currentMetricValue(for: metric))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(metricTrend(for: metric))
                .font(.caption2)
                .foregroundColor(trendColor(for: metric))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.s)
        .background(
            selectedMetric == metric ? 
            metric.color.opacity(0.1) : 
            theme.colors.backgroundSecondary.opacity(0.5)
        )
        .cornerRadius(theme.radius.s)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMetric = selectedMetric == metric ? nil : metric
            }
        }
    }
    
    private var cardioChart: some View {
        Group {
            if !cardioSessions.isEmpty {
                Chart(cardioProgressData) { dataPoint in
                    if shouldShowMetric(.distance) {
                        LineMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.Cardio.distance.localized, dataPoint.distance)
                        )
                        .foregroundStyle(CardioMetric.distance.color)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.Cardio.distance.localized, dataPoint.distance)
                        )
                        .foregroundStyle(CardioMetric.distance.color)
                        .symbolSize(selectedMetric == .distance ? 80 : 50)
                    }
                    
                    if shouldShowMetric(.pace) && dataPoint.averagePace > 0 {
                        LineMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.Cardio.pace.localized, dataPoint.averagePace)
                        )
                        .foregroundStyle(CardioMetric.pace.color)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [5, 3]))
                        
                        PointMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.Cardio.pace.localized, dataPoint.averagePace)
                        )
                        .foregroundStyle(CardioMetric.pace.color)
                        .symbolSize(selectedMetric == .pace ? 80 : 50)
                    }
                    
                    if shouldShowMetric(.heartRate) && dataPoint.averageHeartRate > 0 {
                        LineMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.CardioAnalytics.heartRate.localized, dataPoint.averageHeartRate)
                        )
                        .foregroundStyle(CardioMetric.heartRate.color)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [3, 2]))
                        
                        PointMark(
                            x: .value(TrainingKeys.StrengthAnalytics.dateLabel.localized, dataPoint.date),
                            y: .value(TrainingKeys.CardioAnalytics.heartRate.localized, dataPoint.averageHeartRate)
                        )
                        .foregroundStyle(CardioMetric.heartRate.color)
                        .symbolSize(selectedMetric == .heartRate ? 80 : 50)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: selectedTimeRange.months <= 3 ? 1 : 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(theme.colors.border.opacity(0.3))
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(formatAxisValue(val))
                                    .font(.caption2)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                .chartBackground { _ in
                    Rectangle()
                        .fill(theme.colors.backgroundSecondary.opacity(0.3))
                        .cornerRadius(theme.radius.s)
                }
                .animation(.easeInOut(duration: 0.5), value: selectedTimeRange)
                .animation(.easeInOut(duration: 0.3), value: selectedMetric)
            } else {
                emptyCardioState
            }
        }
    }
    
    private var metricsLegend: some View {
        HStack(spacing: theme.spacing.m) {
            ForEach(CardioMetric.allCases, id: \.self) { metric in
                HStack(spacing: 6) {
                    Circle()
                        .fill(metric.color)
                        .frame(width: 8, height: 8)
                    
                    Text(metric.displayName)
                        .font(.caption)
                        .foregroundColor(
                            selectedMetric == metric ? 
                            theme.colors.textPrimary : 
                            theme.colors.textSecondary
                        )
                        .fontWeight(selectedMetric == metric ? .semibold : .regular)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMetric = selectedMetric == metric ? nil : metric
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var emptyCardioState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.5))
            
            Text(TrainingKeys.CardioAnalytics.noDataTitle.localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(TrainingKeys.CardioAnalytics.noDataDescription.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(TrainingKeys.Analytics.startFirstCardio.localized) {
                // Navigate to cardio section
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Processing & HealthKit Integration
    
    private var cardioProgressData: [CardioDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -selectedTimeRange.months, to: endDate) ?? endDate
        
        // Combine SwiftData sessions with HealthKit workouts
        let weeklyData = combineCardioDataSources(startDate: startDate, endDate: endDate)
        
        return weeklyData.map { weekData in
            let totalDistance = weekData.totalDistance / 1000.0 // Convert to km
            let totalDuration = weekData.totalDuration / 60.0 // Convert to minutes
            let averagePace = totalDistance > 0 ? totalDuration / totalDistance : 0 // min/km
            
            return CardioDataPoint(
                date: weekData.weekStart,
                distance: totalDistance,
                averagePace: averagePace,
                averageHeartRate: weekData.averageHeartRate,
                sessionCount: weekData.sessionCount
            )
        }
    }
    
    private struct WeeklyCardioData {
        let weekStart: Date
        let totalDistance: Double // meters
        let totalDuration: TimeInterval // seconds
        let averageHeartRate: Double // bpm
        let sessionCount: Int
    }
    
    private func combineCardioDataSources(startDate: Date, endDate: Date) -> [WeeklyCardioData] {
        let calendar = Calendar.current
        var weeklyGroups: [Date: WeeklyCardioData] = [:]
        
        // Process SwiftData CardioSessions
        let filteredSessions = cardioSessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate && session.isCompleted
        }
        
        for session in filteredSessions {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
            
            if let existing = weeklyGroups[weekStart] {
                weeklyGroups[weekStart] = WeeklyCardioData(
                    weekStart: weekStart,
                    totalDistance: existing.totalDistance + session.totalDistance,
                    totalDuration: existing.totalDuration + TimeInterval(session.totalDuration),
                    averageHeartRate: calculateWeightedAverage(
                        existing.averageHeartRate, existing.sessionCount,
                        Double(session.averageHeartRate ?? 0), 1
                    ),
                    sessionCount: existing.sessionCount + 1
                )
            } else {
                weeklyGroups[weekStart] = WeeklyCardioData(
                    weekStart: weekStart,
                    totalDistance: session.totalDistance,
                    totalDuration: TimeInterval(session.totalDuration),
                    averageHeartRate: Double(session.averageHeartRate ?? 0),
                    sessionCount: 1
                )
            }
        }
        
        // Enhance with HealthKit data if available
        enhanceWithHealthKitData(weeklyGroups: &weeklyGroups, startDate: startDate, endDate: endDate)
        
        return weeklyGroups.values.sorted { $0.weekStart < $1.weekStart }
    }
    
    private func enhanceWithHealthKitData(weeklyGroups: inout [Date: WeeklyCardioData], startDate: Date, endDate: Date) {
        // Use HealthKit historical data to fill gaps
        for healthPoint in healthKitService.heartRateHistory {
            guard healthPoint.date >= startDate && healthPoint.date <= endDate else { continue }
            
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: healthPoint.date)?.start ?? healthPoint.date
            
            // Only enhance existing weeks, don't create new ones from heart rate alone
            if let existing = weeklyGroups[weekStart] {
                if existing.averageHeartRate == 0 {
                    weeklyGroups[weekStart] = WeeklyCardioData(
                        weekStart: weekStart,
                        totalDistance: existing.totalDistance,
                        totalDuration: existing.totalDuration,
                        averageHeartRate: healthPoint.value,
                        sessionCount: existing.sessionCount
                    )
                }
            }
        }
    }
    
    private func calculateWeightedAverage(_ value1: Double, _ count1: Int, _ value2: Double, _ count2: Int) -> Double {
        guard value1 > 0 || value2 > 0 else { return 0 }
        let totalCount = count1 + count2
        guard totalCount > 0 else { return 0 }
        return ((value1 * Double(count1)) + (value2 * Double(count2))) / Double(totalCount)
    }
    
    private func loadCardioData() {
        isLoading = true
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -selectedTimeRange.months, to: endDate) ?? endDate
        
        let descriptor = FetchDescriptor<CardioSession>(
            predicate: #Predicate { session in
                session.startDate >= startDate && session.startDate <= endDate && session.isCompleted
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            cardioSessions = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            print("Error loading cardio sessions: \(error)")
            cardioSessions = []
            isLoading = false
        }
    }
    
    private func shouldShowMetric(_ metric: CardioMetric) -> Bool {
        return selectedMetric == nil || selectedMetric == metric
    }
    
    private func currentMetricValue(for metric: CardioMetric) -> String {
        guard !cardioSessions.isEmpty else { return "--" }
        
        let recentWeekData = Array(cardioProgressData.suffix(4)) // Last 4 weeks
        guard !recentWeekData.isEmpty else { return "--" }
        
        switch metric {
        case .distance:
            let avgDistance = recentWeekData.map(\.distance).reduce(0, +) / Double(recentWeekData.count)
            return String(format: "%.1f", avgDistance)
            
        case .pace:
            let validPaces = recentWeekData.map(\.averagePace).filter { $0 > 0 }
            guard !validPaces.isEmpty else { return "--" }
            let avgPace = validPaces.reduce(0, +) / Double(validPaces.count)
            return formatPace(avgPace)
            
        case .heartRate:
            let validHRs = recentWeekData.map(\.averageHeartRate).filter { $0 > 0 }
            guard !validHRs.isEmpty else { return "--" }
            let avgHR = validHRs.reduce(0, +) / Double(validHRs.count)
            return "\(Int(avgHR))"
        }
    }
    
    private func metricTrend(for metric: CardioMetric) -> String {
        guard cardioProgressData.count >= 2 else { return "" }
        
        let recent = Array(cardioProgressData.suffix(2))
        guard let first = recent.first, let last = recent.last else { return "" }
        
        switch metric {
        case .distance:
            let change = last.distance - first.distance
            return change > 0 ? "↗️ +\(String(format: "%.1f", change))km" : 
                   change < 0 ? "↘️ \(String(format: "%.1f", change))km" : "→"
            
        case .pace:
            guard first.averagePace > 0 && last.averagePace > 0 else { return "" }
            let changeSeconds = (last.averagePace - first.averagePace) * 60
            return changeSeconds < 0 ? "↗️ \(Int(-changeSeconds))s" : 
                   changeSeconds > 0 ? "↘️ +\(Int(changeSeconds))s" : "→"
            
        case .heartRate:
            guard first.averageHeartRate > 0 && last.averageHeartRate > 0 else { return "" }
            let change = last.averageHeartRate - first.averageHeartRate
            return change < 0 ? "↗️ \(Int(-change))" : 
                   change > 0 ? "↘️ +\(Int(change))" : "→"
        }
    }
    
    private func trendColor(for metric: CardioMetric) -> Color {
        guard cardioProgressData.count >= 2 else { return theme.colors.textSecondary }
        
        let recent = Array(cardioProgressData.suffix(2))
        guard let first = recent.first, let last = recent.last else { return theme.colors.textSecondary }
        
        switch metric {
        case .distance:
            return last.distance > first.distance ? theme.colors.success : 
                   last.distance < first.distance ? theme.colors.error : theme.colors.textSecondary
        case .pace:
            guard first.averagePace > 0 && last.averagePace > 0 else { return theme.colors.textSecondary }
            return last.averagePace < first.averagePace ? theme.colors.success : 
                   last.averagePace > first.averagePace ? theme.colors.error : theme.colors.textSecondary
        case .heartRate:
            guard first.averageHeartRate > 0 && last.averageHeartRate > 0 else { return theme.colors.textSecondary }
            // Lower resting HR is better for endurance
            return last.averageHeartRate < first.averageHeartRate ? theme.colors.success : 
                   last.averageHeartRate > first.averageHeartRate ? theme.colors.error : theme.colors.textSecondary
        }
    }
    
    private func formatPace(_ paceMinPerKm: Double) -> String {
        guard paceMinPerKm > 0 else { return "--" }
        let minutes = Int(paceMinPerKm)
        let seconds = Int((paceMinPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        if selectedMetric == .pace || (selectedMetric == nil && value < 10) {
            return formatPace(value)
        } else if selectedMetric == .heartRate || (selectedMetric == nil && value > 50) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CardioSession.self, User.self, configurations: config)
    
    let user = User(name: "Test Athlete")
    user.totalCardioSessions = 12
    user.totalCardioDistance = 75000 // 75km
    user.totalCardioTime = 18000 // 5 hours
    
    // Create realistic test cardio sessions
    for i in 0..<12 {
        let session = CardioSession()
        session.startDate = Calendar.current.date(byAdding: .weekOfYear, value: -i, to: Date()) ?? Date()
        session.totalDistance = Double.random(in: 3000...10000) // 3-10km per session
        session.totalDuration = Int.random(in: 1200...3600) // 20-60 min
        session.averageHeartRate = Int.random(in: 140...175) // Athletic HR range
        session.isCompleted = true
        container.mainContext.insert(session)
    }
    
    return CardioProgressChart(user: user)
        .environment(UnitSettings.shared)
        .environment(HealthKitService())
        .modelContainer(container)
        .padding()
}