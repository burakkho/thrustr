import SwiftUI
import Charts

/**
 * Dedicated chart view for cardio progress visualization.
 *
 * Displays cardio performance over time including distance, duration,
 * calories burned, and heart rate trends.
 */
struct CardioChartView: View {
    let cardioSessions: [CardioSession]

    @State private var selectedMetric: CardioMetric = .distance
    @State private var selectedPoint: Date? = nil

    private var cardioData: [CardioProgressData] {
        return cardioSessions.map { session in
            CardioProgressData(
                date: session.startDate,
                duration: TimeInterval(session.totalDuration),
                distance: session.totalDistance,
                calories: session.totalCaloriesBurned ?? 0,
                heartRate: session.averageHeartRate.map { Double($0) },
                type: session.workoutName
            )
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            if cardioData.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noCardioData.localized)
            } else {
                // Metric Selector
                metricSelector

                // Chart
                if #available(iOS 16.0, *) {
                    Chart(cardioData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Value", metricValue(for: data))
                        )
                        .foregroundStyle(selectedMetric.color)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Value", metricValue(for: data))
                        )
                        .foregroundStyle(selectedMetric.color)
                        .symbolSize(selectedPoint == data.date ? 80 : 50)

                        // Highlight selected point
                        if let selectedPoint = selectedPoint, selectedPoint == data.date {
                            RuleMark(x: .value("Selected", selectedPoint))
                                .foregroundStyle(selectedMetric.color.opacity(0.3))
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
                    FallbackChartView(color: selectedMetric.color, message: selectedMetric.displayName)
                }
            }
        }
    }

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CardioMetric.allCases, id: \.self) { metric in
                    Button {
                        selectedMetric = metric
                    } label: {
                        Text(metric.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMetric == metric ? metric.color : Color(.secondarySystemBackground))
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func metricValue(for data: CardioProgressData) -> Double {
        switch selectedMetric {
        case .distance:
            return data.distance
        case .duration:
            return data.duration / 60.0 // Convert to minutes
        case .calories:
            return Double(data.calories)
        case .heartRate:
            return data.heartRate ?? 0
        }
    }

    private func findNearestDataPoint(to date: Date) -> Date? {
        return cardioData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })?.date
    }
}

enum CardioMetric: String, CaseIterable {
    case distance = "distance"
    case duration = "duration"
    case calories = "calories"
    case heartRate = "heartRate"

    var displayName: String {
        switch self {
        case .distance:
            return "Distance"
        case .duration:
            return "Duration"
        case .calories:
            return "Calories"
        case .heartRate:
            return "Heart Rate"
        }
    }

    var color: Color {
        switch self {
        case .distance:
            return .blue
        case .duration:
            return .green
        case .calories:
            return .orange
        case .heartRate:
            return .red
        }
    }
}