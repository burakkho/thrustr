import SwiftUI
import Charts

/**
 * Dedicated chart view for strength progress visualization.
 *
 * Displays strength progression over time using lift session data,
 * highlighting personal records and 1RM improvements.
 */
struct StrengthChartView: View {
    let liftSessions: [LiftSession]

    @State private var selectedPoint: Date? = nil

    private var strengthData: [StrengthProgressData] {
        return liftSessions.compactMap { session in
            // Get the strongest exercise result from the session
            guard let results = session.exerciseResults,
                  let strongestResult = results.max(by: { $0.estimatedOneRM < $1.estimatedOneRM }) else {
                return nil
            }

            let bestSet = strongestResult.sets.filter { $0.isCompleted && $0.weight != nil }
                .max { ($0.weight ?? 0) < ($1.weight ?? 0) }

            return StrengthProgressData(
                date: session.startDate,
                exercise: strongestResult.exercise?.exerciseName ?? "Unknown",
                weight: bestSet?.weight ?? 0,
                reps: bestSet?.reps ?? 0,
                oneRM: strongestResult.estimatedOneRM,
                isPersonalRecord: strongestResult.isPersonalRecord
            )
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            if strengthData.isEmpty {
                EmptyChartView(message: ProfileKeys.Analytics.noStrengthData.localized)
            } else {
                if #available(iOS 16.0, *) {
                    Chart(strengthData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("1RM", data.oneRM)
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("1RM", data.oneRM)
                        )
                        .foregroundStyle(data.isPersonalRecord ? .yellow : .red)
                        .symbolSize(data.isPersonalRecord ? 120 : 60)

                        // Highlight personal records
                        if data.isPersonalRecord {
                            PointMark(
                                x: .value("Date", data.date),
                                y: .value("1RM", data.oneRM)
                            )
                            .foregroundStyle(.yellow.opacity(0.3))
                            .symbolSize(150)
                        }

                        // Highlight selected point
                        if let selectedPoint = selectedPoint, selectedPoint == data.date {
                            RuleMark(x: .value("Selected", selectedPoint))
                                .foregroundStyle(.red.opacity(0.3))
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

                    // Legend
                    HStack(spacing: 16) {
                        LegendItem(color: .red, text: "1RM Progress")
                        LegendItem(color: .yellow, text: "Personal Record")
                    }
                    .font(.caption)
                } else {
                    FallbackChartView(color: .red, message: "Strength Progress")
                }
            }
        }
    }

    private func findNearestDataPoint(to date: Date) -> Date? {
        return strengthData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })?.date
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}