import SwiftUI

struct AnalyticsEnhancedTrendCard: View {
    let icon: String
    let title: String
    let currentValue: Int
    let unit: String
    let trendData: [Double]
    let color: Color
    let trend: TrendDirection
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            // Icon and trend indicator
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.swiftUIColor)
            }

            // Title and value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(currentValue) \(unit)")
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            // Mini trend chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(trendData.suffix(7).enumerated()), id: \.offset) { index, value in
                    let maxValue = trendData.max() ?? 1
                    let height = max(4, (value / maxValue) * 30)

                    Rectangle()
                        .fill(index == 6 ? color : color.opacity(0.5))
                        .frame(width: 4, height: height)
                        .cornerRadius(2)
                }
            }
            .frame(width: 40, height: 35)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Alternative Trend Card Styles

struct AnalyticsEnhancedTrendCardCompact: View {
    let icon: String
    let title: String
    let currentValue: Int
    let unit: String
    let trend: TrendDirection
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // Icon with trend overlay
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 45, height: 45)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                // Trend indicator overlay
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: trend.icon)
                            .font(.caption2)
                            .foregroundColor(trend.swiftUIColor)
                            .background(
                                Circle()
                                    .fill(theme.colors.cardBackground)
                                    .frame(width: 16, height: 16)
                            )
                    }
                    Spacer()
                }
                .frame(width: 45, height: 45)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(currentValue) \(unit)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Spacer()

            // Trend text
            Text(trend.displayText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(trend.swiftUIColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(trend.swiftUIColor.opacity(0.1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AnalyticsEnhancedTrendCardDetailed: View {
    let icon: String
    let title: String
    let currentValue: Int
    let unit: String
    let trendData: [Double]
    let color: Color
    let trend: TrendDirection
    let changePercentage: Double?
    let goalValue: Int?
    @Environment(\.theme) private var theme

    init(
        icon: String,
        title: String,
        currentValue: Int,
        unit: String,
        trendData: [Double],
        color: Color,
        trend: TrendDirection,
        changePercentage: Double? = nil,
        goalValue: Int? = nil
    ) {
        self.icon = icon
        self.title = title
        self.currentValue = currentValue
        self.unit = unit
        self.trendData = trendData
        self.color = color
        self.trend = trend
        self.changePercentage = changePercentage
        self.goalValue = goalValue
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)

                        Text("Current Value")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentValue) \(unit)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)

                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundColor(trend.swiftUIColor)

                        if let changePercentage = changePercentage {
                            Text("\(changePercentage > 0 ? "+" : "")\(String(format: "%.1f", changePercentage))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(trend.swiftUIColor)
                        } else {
                            Text(trend.displayText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(trend.swiftUIColor)
                        }
                    }
                }
            }

            // Goal progress (if provided)
            if let goalValue = goalValue {
                VStack(spacing: 8) {
                    HStack {
                        Text("Goal: \(goalValue) \(unit)")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)

                        Spacer()

                        let progress = min(Double(currentValue) / Double(goalValue), 1.0)
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(color.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)

                            Rectangle()
                                .fill(color)
                                .frame(
                                    width: geometry.size.width * min(Double(currentValue) / Double(goalValue), 1.0),
                                    height: 6
                                )
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }

            // Enhanced trend chart
            VStack(spacing: 8) {
                HStack {
                    Text("7-Day Trend")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Spacer()
                }

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(trendData.suffix(7).enumerated()), id: \.offset) { index, value in
                        let maxValue = trendData.max() ?? 1
                        let minValue = trendData.min() ?? 0
                        let normalizedValue = (value - minValue) / (maxValue - minValue)
                        let height = max(8, normalizedValue * 50)

                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: index == 6 ? [color, color.opacity(0.7)] : [color.opacity(0.5), color.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 8, height: height)
                                .cornerRadius(4)

                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                    }
                }
                .frame(height: 60)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Standard trend cards
        VStack(spacing: 12) {
            AnalyticsEnhancedTrendCard(
                icon: "figure.walk",
                title: "Steps Trend",
                currentValue: 8500,
                unit: "steps",
                trendData: [6000, 7200, 8100, 7800, 8300, 8600, 8500],
                color: Color.blue,
                trend: TrendDirection.increasing
            )

            AnalyticsEnhancedTrendCard(
                icon: "scalemass.fill",
                title: "Weight Trend",
                currentValue: 75,
                unit: "kg",
                trendData: [76.2, 76.0, 75.8, 75.5, 75.3, 75.1, 75.0],
                color: .green,
                trend: .decreasing
            )

            AnalyticsEnhancedTrendCard(
                icon: "heart.fill",
                title: "Heart Rate Trend",
                currentValue: 65,
                unit: "bpm",
                trendData: [68, 67, 66, 66, 65, 65, 65],
                color: .red,
                trend: .stable
            )
        }

        // Compact trend cards
        VStack(spacing: 8) {
            AnalyticsEnhancedTrendCardCompact(
                icon: "figure.walk",
                title: "Daily Steps",
                currentValue: 8500,
                unit: "steps",
                trend: .increasing,
                color: .blue
            )

            AnalyticsEnhancedTrendCardCompact(
                icon: "flame.fill",
                title: "Active Calories",
                currentValue: 450,
                unit: "kcal",
                trend: .stable,
                color: .orange
            )
        }

        // Detailed trend card
        AnalyticsEnhancedTrendCardDetailed(
            icon: "figure.walk",
            title: "Daily Steps",
            currentValue: 8500,
            unit: "steps",
            trendData: [6000, 7200, 8100, 7800, 8300, 8600, 8500],
            color: .blue,
            trend: .increasing,
            changePercentage: 12.5,
            goalValue: 10000
        )
    }
    .environment(ThemeManager())
    .padding()
}