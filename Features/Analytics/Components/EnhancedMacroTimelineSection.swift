import SwiftUI

struct EnhancedMacroTimelineSection: View {
    let weeklyData: [DayData]
    @Environment(\.theme) private var theme
    @State private var selectedDay: DayData?
    @State private var animateBars = false

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Macro Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: Text("Detailed Charts")) {
                    Text("View Details")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)

            // Interactive Macro Chart
            VStack(spacing: 16) {
                // Enhanced Bar Chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData, id: \.date) { day in
                        MacroBarView(
                            day: day,
                            maxCalories: weeklyData.map { $0.calories }.max() ?? 1,
                            isSelected: selectedDay?.date == day.date,
                            animate: animateBars
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDay = selectedDay?.date == day.date ? nil : day
                            }
                        }
                    }
                }
                .frame(height: 120)

                // Selected Day Details
                if let selected = selectedDay {
                    MacroDetailCard(day: selected)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animateBars = true
            }
        }
    }
}

struct MacroBarView: View {
    let day: DayData
    let maxCalories: Double
    let isSelected: Bool
    let animate: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            // Stacked macro bar
            VStack(spacing: 2) {
                let totalCalories = day.calories
                let height = animate ? (totalCalories / max(maxCalories, 1)) * 80 : 0

                ZStack(alignment: .bottom) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.colors.backgroundSecondary)
                        .frame(width: 24, height: 80)

                    // Calories bar with macro sections
                    if totalCalories > 0 {
                        VStack(spacing: 0) {
                            // Fat (top)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.purple)
                                .frame(width: 20, height: max(2, height * (day.fat * 9) / totalCalories))

                            // Carbs (middle)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 20, height: max(2, height * (day.carbs * 4) / totalCalories))

                            // Protein (bottom)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 20, height: max(2, height * (day.protein * 4) / totalCalories))
                        }
                        .frame(height: height)
                        .animation(.easeInOut(duration: 0.8).delay(Double.random(in: 0...0.4)), value: animate)
                    }
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }

            // Day label
            Text(String(day.dayName.prefix(3)))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)
        }
    }
}

struct MacroDetailCard: View {
    let day: DayData
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            Text(day.dayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)

            HStack(spacing: 16) {
                MacroDetail(label: "Calories", value: "\(Int(day.calories))", color: .orange)
                MacroDetail(label: "Protein", value: "\(Int(day.protein))g", color: .red)
                MacroDetail(label: "Carbs", value: "\(Int(day.carbs))g", color: .blue)
                MacroDetail(label: "Fat", value: "\(Int(day.fat))g", color: .purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.backgroundSecondary.opacity(0.5))
        )
    }
}

struct MacroDetail: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
    }
}

#Preview {
    EnhancedMacroTimelineSection(weeklyData: [
        DayData(date: Date(), dayName: "Mon", calories: 1800, protein: 120, carbs: 200, fat: 60),
        DayData(date: Date(), dayName: "Tue", calories: 2100, protein: 140, carbs: 220, fat: 70),
        DayData(date: Date(), dayName: "Wed", calories: 1950, protein: 130, carbs: 210, fat: 65)
    ])
    .environment(\.theme, DefaultLightTheme())
}