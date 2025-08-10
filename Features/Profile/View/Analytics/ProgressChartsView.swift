import SwiftUI
import SwiftData
import Charts

struct ProgressChartsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var workouts: [Workout]
    @Query private var weightEntries: [WeightEntry]
    @Query private var bodyMeasurements: [BodyMeasurement]
    
    @State private var selectedTimeRange: TimeRange = .month3
    @State private var selectedChartType: ChartType = .weight
    
    private var currentUser: User? {
        users.first
    }
    
    private var filteredWeightEntries: [WeightEntry] {
        let cutoffDate = selectedTimeRange.cutoffDate
        return weightEntries.filter { $0.date >= cutoffDate }
    }
    
    private var filteredWorkouts: [Workout] {
        let cutoffDate = selectedTimeRange.cutoffDate
        return workouts.filter { $0.date >= cutoffDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                ProgressChartsHeaderSection()
                
                // Time Range Selector
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                
                // Chart Type Selector
                ChartTypeSelector(selectedType: $selectedChartType)
                
                // Main Chart Section
                MainChartSection(
                    chartType: selectedChartType,
                    timeRange: selectedTimeRange,
                    weightEntries: filteredWeightEntries,
                    workouts: filteredWorkouts,
                    bodyMeasurements: bodyMeasurements,
                    user: currentUser
                )
                
                // Summary Statistics
                SummaryStatisticsSection(
                    chartType: selectedChartType,
                    weightEntries: filteredWeightEntries,
                    workouts: filteredWorkouts,
                    timeRange: selectedTimeRange
                )
                
                // Insights Section
                InsightsSection(
                    weightEntries: filteredWeightEntries,
                    workouts: filteredWorkouts,
                    timeRange: selectedTimeRange
                )
            }
            .padding()
        }
        .navigationTitle("İlerleme Grafikleri")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
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
                Text("İlerleme Grafikleri")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Performansınızı ve gelişiminizi görsel olarak takip edin")
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
            Text("Zaman Aralığı")
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
            Text("Grafik Türü")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(selectedType == type ? .white : type.color)
                            
                            Text(type.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedType == type ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedType == type ? type.color : Color(.secondarySystemBackground))
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
    let workouts: [Workout]
    let bodyMeasurements: [BodyMeasurement]
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartType.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Group {
                switch chartType {
                case .weight:
                    WeightChartView(entries: weightEntries)
                case .workoutVolume:
                    WorkoutVolumeChartView(workouts: workouts)
                case .workoutFrequency:
                    WorkoutFrequencyChartView(workouts: workouts, timeRange: timeRange)
                case .bodyMeasurements:
                    BodyMeasurementsChartView(measurements: bodyMeasurements)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Weight Chart View
struct WeightChartView: View {
    let entries: [WeightEntry]
    
    private var chartData: [WeightChartData] {
        entries.map { WeightChartData(date: $0.date, weight: $0.weight) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if chartData.isEmpty {
                EmptyChartView(message: "Henüz kilo kaydı bulunmuyor")
            } else {
                if #available(iOS 16.0, *) {
                    Chart(chartData) { data in
                        LineMark(
                            x: .value("Tarih", data.date),
                            y: .value("Kilo", data.weight)
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Tarih", data.date),
                            y: .value("Kilo", data.weight)
                        )
                        .foregroundStyle(.orange)
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
                    FallbackChartView(color: .orange, message: "Kilo Değişimi")
                }
            }
        }
    }
}

// MARK: - Workout Volume Chart View
struct WorkoutVolumeChartView: View {
    let workouts: [Workout]
    
    private var weeklyData: [WeeklyVolumeData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.dateInterval(of: .weekOfYear, for: workout.date)?.start ?? workout.date
        }
        
        return grouped.map { (week, workouts) in
            let totalVolume = workouts.reduce(0.0) { total, workout in
                total + workout.totalVolume
            }
            return WeeklyVolumeData(week: week, volume: totalVolume)
        }.sorted { $0.week < $1.week }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if weeklyData.isEmpty {
                EmptyChartView(message: "Henüz antrenman verisi bulunmuyor")
            } else {
                if #available(iOS 16.0, *) {
                    Chart(weeklyData) { data in
                        BarMark(
                            x: .value("Hafta", data.week),
                            y: .value("Hacim", data.volume)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                } else {
                    FallbackChartView(color: .blue, message: "Haftalık Antrenman Hacmi")
                }
            }
        }
    }
}

// MARK: - Workout Frequency Chart View
struct WorkoutFrequencyChartView: View {
    let workouts: [Workout]
    let timeRange: TimeRange
    
    private var frequencyData: [FrequencyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.dateInterval(of: .weekOfYear, for: workout.date)?.start ?? workout.date
        }
        
        return grouped.map { (week, workouts) in
            FrequencyData(period: week, count: workouts.count)
        }.sorted { $0.period < $1.period }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if frequencyData.isEmpty {
                EmptyChartView(message: "Henüz antrenman verisi bulunmuyor")
            } else {
                if #available(iOS 16.0, *) {
                    Chart(frequencyData) { data in
                        BarMark(
                            x: .value("Hafta", data.period),
                            y: .value("Sıklık", data.count)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 200)
                } else {
                    FallbackChartView(color: .green, message: "Antrenman Sıklığı")
                }
            }
        }
    }
}

// MARK: - Body Measurements Chart View
struct BodyMeasurementsChartView: View {
    let measurements: [BodyMeasurement]
    
    var body: some View {
        VStack(spacing: 12) {
            if measurements.isEmpty {
                EmptyChartView(message: "Henüz vücut ölçümü bulunmuyor")
            } else {
                Text("Vücut ölçümleri grafiği için BodyMeasurementsView'daki grafik bölümünü kullanın")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.flattrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
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
            
            Text("Grafik iOS 16+ gerektirir")
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
    let workouts: [Workout]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Özet İstatistikler")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                switch chartType {
                case .weight:
                    WeightStatisticsCards(entries: weightEntries)
                case .workoutVolume, .workoutFrequency:
                    WorkoutStatisticsCards(workouts: workouts, timeRange: timeRange)
                case .bodyMeasurements:
                    BodyMeasurementStatisticsCards()
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
            title: "Toplam Değişim",
            value: String(format: "%.1f kg", weightChange),
            color: weightChange >= 0 ? .green : .red
        )
        
        StatCard(
            title: "Ortalama Kilo",
            value: String(format: "%.1f kg", averageWeight),
            color: .blue
        )
        
        StatCard(
            title: "Kayıt Sayısı",
            value: "\(entries.count)",
            color: .orange
        )
        
        StatCard(
            title: "En Son",
            value: String(format: "%.1f kg", entries.first?.weight ?? 0),
            color: .purple
        )
    }
}

// MARK: - Workout Statistics Cards
struct WorkoutStatisticsCards: View {
    let workouts: [Workout]
    let timeRange: TimeRange
    
    private var totalWorkouts: Int {
        workouts.count
    }
    
    private var averageWorkoutsPerWeek: Double {
        let weeks = timeRange.weekCount
        return weeks > 0 ? Double(totalWorkouts) / Double(weeks) : 0
    }
    
    private var totalVolume: Double {
        workouts.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var averageVolume: Double {
        totalWorkouts > 0 ? totalVolume / Double(totalWorkouts) : 0
    }
    
    var body: some View {
        StatCard(
            title: "Toplam Antrenman",
            value: "\(totalWorkouts)",
            color: .blue
        )
        
        StatCard(
            title: "Haftalık Ortalama",
            value: String(format: "%.1f", averageWorkoutsPerWeek),
            color: .green
        )
        
        StatCard(
            title: "Toplam Hacim",
            value: String(format: "%.0f kg", totalVolume),
            color: .orange
        )
        
        StatCard(
            title: "Ortalama Hacim",
            value: String(format: "%.0f kg", averageVolume),
            color: .purple
        )
    }
}

// MARK: - Body Measurement Statistics Cards
struct BodyMeasurementStatisticsCards: View {
    var body: some View {
        StatCard(
            title: "Değişim",
            value: "Hesaplanıyor",
            color: .blue
        )
        
        StatCard(
            title: "Ortalama",
            value: "Hesaplanıyor",
            color: .green
        )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Insights Section
struct InsightsSection: View {
    let weightEntries: [WeightEntry]
    let workouts: [Workout]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Öngörüler")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if !weightEntries.isEmpty && weightEntries.count >= 2 {
                    WeightInsightCard(entries: weightEntries)
                }
                
                if !workouts.isEmpty {
                    WorkoutInsightCard(workouts: workouts, timeRange: timeRange)
                }
                
                if workouts.isEmpty && weightEntries.isEmpty {
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
        guard entries.count >= 2 else { return "Yetersiz veri" }
        
        let latest = entries.first?.weight ?? 0
        let previous = entries.dropFirst().first?.weight ?? 0
        
        if latest > previous {
            return "Kilo artış trendinde"
        } else if latest < previous {
            return "Kilo azalış trendinde"
        } else {
            return "Kilo stabil"
        }
    }
    
    var body: some View {
        InsightCard(
            icon: "scalemass.fill",
            title: "Kilo Trendi",
            insight: trend,
            color: .orange
        )
    }
}

struct WorkoutInsightCard: View {
    let workouts: [Workout]
    let timeRange: TimeRange
    
    private var consistency: String {
        let weeks = timeRange.weekCount
        let averagePerWeek = weeks > 0 ? Double(workouts.count) / Double(weeks) : 0
        
        if averagePerWeek >= 4 {
            return "Mükemmel tutarlılık!"
        } else if averagePerWeek >= 3 {
            return "İyi tutarlılık"
        } else if averagePerWeek >= 2 {
            return "Orta tutarlılık"
        } else {
            return "Daha tutarlı olabilirsin"
        }
    }
    
    var body: some View {
        InsightCard(
            icon: "dumbbell.fill",
            title: "Antrenman Tutarlılığı",
            insight: consistency,
            color: .blue
        )
    }
}

struct EmptyInsightCard: View {
    var body: some View {
        InsightCard(
            icon: "lightbulb.fill",
            title: "Öngörüler",
            insight: "Veri girmeye başladığında burada öngörüler görebileceksin",
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

// MARK: - Data Models
struct WeightChartData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct WeeklyVolumeData: Identifiable {
    let id = UUID()
    let week: Date
    let volume: Double
}

struct FrequencyData: Identifiable {
    let id = UUID()
    let period: Date
    let count: Int
}

// MARK: - Enums
enum TimeRange: CaseIterable {
    case week1, month1, month3, month6, year1
    
    var displayName: String {
        switch self {
        case .week1: return "1 Hafta"
        case .month1: return "1 Ay"
        case .month3: return "3 Ay"
        case .month6: return "6 Ay"
        case .year1: return "1 Yıl"
        }
    }
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week1: return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month1: return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .month3: return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .month6: return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year1: return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    var weekCount: Int {
        switch self {
        case .week1: return 1
        case .month1: return 4
        case .month3: return 12
        case .month6: return 24
        case .year1: return 52
        }
    }
}

enum ChartType: CaseIterable {
    case weight, workoutVolume, workoutFrequency, bodyMeasurements
    
    var displayName: String {
        switch self {
        case .weight: return "Kilo Değişimi"
        case .workoutVolume: return "Antrenman Hacmi"
        case .workoutFrequency: return "Antrenman Sıklığı"
        case .bodyMeasurements: return "Vücut Ölçüleri"
        }
    }
    
    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .workoutVolume: return "chart.bar.fill"
        case .workoutFrequency: return "calendar"
        case .bodyMeasurements: return "ruler.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weight: return .orange
        case .workoutVolume: return .blue
        case .workoutFrequency: return .green
        case .bodyMeasurements: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        ProgressChartsView()
    }
}
