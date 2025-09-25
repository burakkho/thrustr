import SwiftUI
import SwiftData

struct NutritionAnalyticsDashboardView: View {
    @State private var viewModel = NutritionAnalyticsViewModel()
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        LazyVStack(spacing: 32) {
            // 🍎 NUTRITION STORY HERO - Your dietary journey overview
            NutritionStoryHeroCard(nutritionEntries: filteredNutritionEntries)

            // 🔥 VISUAL MACRO TIMELINE - Interactive daily breakdown
            EnhancedMacroTimelineSection(weeklyData: viewModel.weeklyData)

            // 🎯 NUTRITION GOALS TRACKING - Progress towards targets
            EnhancedNutritionGoalsSection(nutritionEntries: filteredNutritionEntries)

            // 📈 NUTRITION INSIGHTS GRID - Smart dietary analysis
            EnhancedNutritionInsightsSection(weeklyData: viewModel.weeklyData, nutritionEntries: filteredNutritionEntries)
        }
        .onAppear {
            // Set ModelContext and load data when view appears
            viewModel.setModelContext(modelContext)
        }
    }

    // MARK: - Helper Properties

    private var filteredNutritionEntries: [NutritionEntry] {
        viewModel.filteredEntries
    }
    
// 🍎 NUTRITION STORY HERO CARD
struct NutritionStoryHeroCard: View {
    let nutritionEntries: [NutritionEntry]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateNutrition = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CommonKeys.Analytics.nutritionJourney.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(nutritionStoryMessage)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                // Animated nutrition icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(animateNutrition ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateNutrition)
                    
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .scaleEffect(animateNutrition ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateNutrition)
                }
            }
            
            // Key Nutrition Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                NutritionStoryMetric(
                    icon: "flame.fill",
                    title: CommonKeys.Analytics.avgCalories.localized,
                    value: "\(calculateAvgCalories())kcal",
                    color: .orange,
                    celebrationType: calculateCaloriesCelebration()
                )
                
                NutritionStoryMetric(
                    icon: "chart.bar.fill",
                    title: CommonKeys.Analytics.loggedDays.localized,
                    value: "\(calculateLoggedDays())/7",
                    color: .blue,
                    celebrationType: calculateLoggedDays() >= 6 ? .celebration : .none
                )
                
                NutritionStoryMetric(
                    icon: "target",
                    title: CommonKeys.Analytics.consistency.localized,
                    value: "\(calculateConsistency())%",
                    color: .green,
                    celebrationType: calculateConsistency() >= 80 ? .fire : .none
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.green.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            animateNutrition = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var nutritionStoryMessage: String {
        let loggedDays = calculateLoggedDays()
        let consistency = calculateConsistency()
        let _ = calculateAvgCalories()
        
        if loggedDays >= 6 && consistency >= 80 {
            return "🌟 Excellent tracking! Your nutrition habits are on point."
        } else if loggedDays >= 4 || consistency >= 60 {
            return "💪 Good progress! Consistency is building strong habits."
        } else if nutritionEntries.isEmpty {
            return "Ready to start tracking your nutrition? Every meal matters!"
        } else {
            return "🎯 Building awareness. Small steps lead to big changes."
        }
    }
    
    private func calculateAvgCalories() -> Int {
        guard !nutritionEntries.isEmpty else { return 0 }
        let totalCalories = nutritionEntries.reduce(0) { $0 + $1.calories }
        return Int(totalCalories / Double(max(calculateLoggedDays(), 1)))
    }
    
    private func calculateLoggedDays() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        let uniqueDays = Set(nutritionEntries.compactMap { entry in
            let dayStart = calendar.startOfDay(for: entry.date)
            return (dayStart >= calendar.startOfDay(for: weekAgo) && dayStart <= calendar.startOfDay(for: today)) ? dayStart : nil
        })
        
        return uniqueDays.count
    }
    
    private func calculateConsistency() -> Int {
        let loggedDays = calculateLoggedDays()
        return Int((Double(loggedDays) / 7.0) * 100)
    }
    
    private func calculateCaloriesCelebration() -> CelebrationType {
        let avgCalories = calculateAvgCalories()
        if avgCalories >= 2500 { return .fire }
        if avgCalories >= 2000 { return .celebration }
        if avgCalories >= 1500 { return .progress }
        return .none
    }
}
    
// 🔥 ENHANCED MACRO TIMELINE SECTION
struct EnhancedMacroTimelineSection: View {
    let weeklyData: [DayData]
    @Environment(\.theme) private var theme
    @State private var selectedDay: DayData?
    @State private var animateBars = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.macroTimeline.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: Text(CommonKeys.Analytics.detailedCharts.localized)) {
                    Text(CommonKeys.Analytics.viewDetails.localized)
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
    
// 🎯 ENHANCED NUTRITION GOALS SECTION
struct EnhancedNutritionGoalsSection: View {
    let nutritionEntries: [NutritionEntry]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.nutritionGoals.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: Text(CommonKeys.Analytics.goalSettings.localized)) {
                    Text(CommonKeys.Analytics.editGoals.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Goals Progress Cards
            VStack(spacing: 12) {
                NutritionGoalCard(
                    icon: "flame.fill",
                    title: CommonKeys.Analytics.dailyCalories.localized,
                    current: calculateAvgCalories(),
                    target: 2000,
                    unit: "kcal",
                    color: .orange
                )
                
                NutritionGoalCard(
                    icon: "figure.strengthtraining.traditional",
                    title: CommonKeys.Analytics.proteinIntake.localized,
                    current: Int(calculateAvgProtein()),
                    target: 150,
                    unit: "g",
                    color: .red
                )
                
                NutritionGoalCard(
                    icon: "chart.bar.fill",
                    title: CommonKeys.Analytics.loggingStreak.localized,
                    current: calculateCurrentStreak(),
                    target: 7,
                    unit: "days",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateAvgCalories() -> Int {
        guard !nutritionEntries.isEmpty else { return 0 }
        let weekEntries = getThisWeekEntries()
        guard !weekEntries.isEmpty else { return 0 }
        
        let totalCalories = weekEntries.reduce(0) { $0 + $1.calories }
        return Int(totalCalories / Double(getLoggedDaysCount()))
    }
    
    private func calculateAvgProtein() -> Double {
        guard !nutritionEntries.isEmpty else { return 0 }
        let weekEntries = getThisWeekEntries()
        guard !weekEntries.isEmpty else { return 0 }
        
        let totalProtein = weekEntries.reduce(0) { $0 + $1.protein }
        return totalProtein / Double(getLoggedDaysCount())
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        for _ in 0..<30 { // Check last 30 days
            let hasEntry = nutritionEntries.contains { entry in
                calendar.startOfDay(for: entry.date) == currentDate
            }
            
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getThisWeekEntries() -> [NutritionEntry] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        return nutritionEntries.filter { entry in
            entry.date >= calendar.startOfDay(for: weekAgo) && entry.date <= today
        }
    }
    
    private func getLoggedDaysCount() -> Int {
        let calendar = Calendar.current
        let weekEntries = getThisWeekEntries()
        
        let uniqueDays = Set(weekEntries.map { entry in
            calendar.startOfDay(for: entry.date)
        })
        
        return max(uniqueDays.count, 1)
    }
}

// 📈 ENHANCED NUTRITION INSIGHTS SECTION
struct EnhancedNutritionInsightsSection: View {
    let weeklyData: [DayData]
    let nutritionEntries: [NutritionEntry]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.nutritionIntelligence.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // AI Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                NutritionInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: CommonKeys.Analytics.eatingPattern.localized,
                    insight: generateEatingPatternInsight(),
                    confidence: CommonKeys.Analytics.highConfidence.localized,
                    color: .blue
                )
                
                NutritionInsightCard(
                    icon: "leaf.fill",
                    title: CommonKeys.Analytics.macroBalance.localized,
                    insight: generateMacroBalanceInsight(),
                    confidence: CommonKeys.Analytics.mediumConfidence.localized,
                    color: .green
                )
                
                NutritionInsightCard(
                    icon: "target",
                    title: CommonKeys.Analytics.goalProgress.localized,
                    insight: generateGoalProgressInsight(),
                    confidence: CommonKeys.Analytics.highConfidence.localized,
                    color: .purple
                )
                
                NutritionInsightCard(
                    icon: "lightbulb.fill",
                    title: CommonKeys.Analytics.recommendation.localized,
                    insight: generateRecommendation(),
                    confidence: CommonKeys.Analytics.mediumConfidence.localized,
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - AI Insight Generation
    
    private func generateEatingPatternInsight() -> String {
        let activeDays = weeklyData.filter { $0.calories > 0 }.count
        let consistency = Double(activeDays) / 7.0
        
        if consistency >= 0.85 {
            return "Excellent consistency! You're tracking \(activeDays)/7 days."
        } else if consistency >= 0.6 {
            return "Good tracking pattern. Consider logging \(7 - activeDays) more days."
        } else {
            return "Inconsistent tracking detected. Focus on daily logging."
        }
    }
    
    private func generateMacroBalanceInsight() -> String {
        let totalProtein = weeklyData.map { $0.protein * 4 }.reduce(0, +)
        let totalCarbs = weeklyData.map { $0.carbs * 4 }.reduce(0, +) 
        let totalFat = weeklyData.map { $0.fat * 9 }.reduce(0, +)
        let totalCalories = totalProtein + totalCarbs + totalFat
        
        guard totalCalories > 0 else {
            return "Start tracking to analyze your macro balance."
        }
        
        let proteinPercent = (totalProtein / totalCalories) * 100
        
        if proteinPercent >= 25 {
            return "High protein diet detected. Great for muscle building!"
        } else if proteinPercent >= 15 {
            return "Balanced protein intake. Consider increasing for fitness goals."
        } else {
            return "Low protein detected. Focus on protein-rich foods."
        }
    }
    
    private func generateGoalProgressInsight() -> String {
        let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / 7
        let targetCalories = 2000.0
        
        let progress = (avgCalories / targetCalories) * 100
        
        if progress >= 90 && progress <= 110 {
            return "Perfect! You're hitting your calorie targets consistently."
        } else if progress < 90 {
            return "Below target. Consider adding \(Int(targetCalories - avgCalories)) more calories."
        } else {
            return "Above target. Consider reducing by \(Int(avgCalories - targetCalories)) calories."
        }
    }
    
    private func generateRecommendation() -> String {
        let activeDays = weeklyData.filter { $0.calories > 0 }.count
        let avgProtein = weeklyData.map { $0.protein }.reduce(0, +) / 7
        
        if activeDays < 4 {
            return "Set daily reminders to improve tracking consistency."
        } else if avgProtein < 100 {
            return "Add protein-rich snacks like Greek yogurt or nuts."
        } else {
            return "Great work! Consider tracking micronutrients next."
        }
    }
}
    
// MARK: - Supporting Components

struct NutritionStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if celebrationType != .none {
                    Image(systemName: celebrationIcon)
                        .font(.caption)
                        .foregroundColor(celebrationColor)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var celebrationIcon: String {
        switch celebrationType {
        case .celebration: return "party.popper.fill"
        case .progress: return "arrow.up.circle.fill"
        case .fire: return "flame.fill"
        case .none: return ""
        }
    }
    
    private var celebrationColor: Color {
        switch celebrationType {
        case .celebration: return .yellow
        case .progress: return .green
        case .fire: return .red
        case .none: return .clear
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
                MacroDetail(label: CommonKeys.Analytics.calories.localized, value: "\(Int(day.calories))", color: .orange)
                MacroDetail(label: CommonKeys.Analytics.protein.localized, value: "\(Int(day.protein))g", color: .red)
                MacroDetail(label: CommonKeys.Analytics.carbs.localized, value: "\(Int(day.carbs))g", color: .blue)
                MacroDetail(label: CommonKeys.Analytics.fat.localized, value: "\(Int(day.fat))g", color: .purple)
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

struct NutritionGoalCard: View {
    let icon: String
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Title and progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(current)/\(target) \(unit)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.backgroundSecondary)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * min(Double(current) / Double(target), 1.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct NutritionInsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let confidence: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(confidence)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(insight)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
}

#Preview {
    NutritionAnalyticsDashboardView()
        .environment(ThemeManager())
        .environment(UnitSettings.shared)
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}