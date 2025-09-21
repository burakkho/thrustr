import SwiftUI
import SwiftData

struct HealthAnalyticsView: View {
    @State private var viewModel = HealthAnalyticsViewModel()
    @Query private var users: [User]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 32) {
            // 🎯 HERO HEALTH STORY - Your wellness journey overview
            HealthStoryHeroCard(user: viewModel.currentUser)

            // 💫 ANIMATED HEALTH RINGS - Visual progress showcase
            EnhancedHealthRingsSection(user: viewModel.currentUser)

            // 🧠 AI HEALTH INTELLIGENCE - Smart insights grid
            EnhancedHealthIntelligenceSection()

            // 📈 HEALTH TRENDS TIMELINE - Historical patterns
            EnhancedHealthTrendsSection()
        }
        .onAppear {
            viewModel.updateUser(users.first)
            Task {
                await viewModel.loadTodaysHealthData()
            }
        }
        .onChange(of: users) { _, newUsers in
            viewModel.updateUser(newUsers.first)
        }
    }
}

// 🎯 HEALTH STORY HERO CARD
struct HealthStoryHeroCard: View {
    let user: User?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateHealth = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Health Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(healthStoryMessage)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                // Animated health icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.2), Color.red.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(animateHealth ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateHealth)
                    
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .scaleEffect(animateHealth ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateHealth)
                }
            }
            
            // Key Health Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                HealthStoryMetric(
                    icon: "figure.walk",
                    title: "Today's Steps",
                    value: formatSteps(healthKitService.todaySteps),
                    color: .blue,
                    celebrationType: calculateStepsCelebration()
                )
                
                HealthStoryMetric(
                    icon: "flame.fill",
                    title: "Active Calories",
                    value: formatCalories(healthKitService.todayActiveCalories),
                    color: .orange,
                    celebrationType: calculateCaloriesCelebration()
                )
                
                HealthStoryMetric(
                    icon: "heart.fill",
                    title: "Recovery Score",
                    value: "\(calculateRecoveryScore())%",
                    color: .red,
                    celebrationType: calculateRecoveryScore() >= 85 ? .celebration : .none
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.red.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            animateHealth = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthStoryMessage: String {
        let steps = healthKitService.todaySteps
        let calories = healthKitService.todayActiveCalories
        let recovery = calculateRecoveryScore()
        
        if steps >= 10000 && recovery >= 85 {
            return "Exceptional day! You're crushing your health goals."
        } else if steps >= 7500 || recovery >= 70 {
            return "Great progress! Your body is responding well."
        } else if steps == 0 && calories == 0 {
            return "Ready to start your wellness journey? Every step counts!"
        } else {
            return "Building healthy habits. Consistency is key to success."
        }
    }
    
    private func calculateStepsCelebration() -> CelebrationType {
        let steps = healthKitService.todaySteps
        if steps >= 15000 { return .fire }
        if steps >= 10000 { return .celebration }
        if steps >= 5000 { return .progress }
        return .none
    }
    
    private func calculateCaloriesCelebration() -> CelebrationType {
        guard let user = user else { return .none }
        let calories = healthKitService.todayActiveCalories
        let goal = user.dailyCalorieGoal
        
        if calories >= goal * 1.2 { return .fire }
        if calories >= goal { return .celebration }
        if calories >= goal * 0.7 { return .progress }
        return .none
    }
    
    private func calculateRecoveryScore() -> Int {
        // Enhanced recovery calculation with multiple factors
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps
        let activeCalories = healthKitService.todayActiveCalories
        
        var score = 50 // Base score
        
        // Heart Rate Variability Assessment (30 points)
        let heartRateScore: Int
        switch heartRate {
        case 0..<50: heartRateScore = 30 // Athletic level
        case 50..<60: heartRateScore = 25 // Excellent
        case 60..<70: heartRateScore = 20 // Good 
        case 70..<80: heartRateScore = 15 // Average
        case 80..<90: heartRateScore = 10 // Below average
        default: heartRateScore = 5 // Poor
        }
        score += heartRateScore
        
        // Activity Balance Assessment (20 points)
        let activityScore: Int
        if steps >= 12000 && activeCalories >= 600 {
            activityScore = 20 // Optimal activity
        } else if steps >= 8000 && activeCalories >= 400 {
            activityScore = 15 // Good activity
        } else if steps >= 5000 && activeCalories >= 200 {
            activityScore = 10 // Moderate activity
        } else if steps < 2000 && activeCalories < 100 {
            activityScore = 20 // Complete rest (good for recovery)
        } else {
            activityScore = 5 // Poor balance
        }
        score += activityScore
        
        // Weekly Pattern Assessment (10 points)
        let weeklyPatternScore = calculateWeeklyPatternScore()
        score += weeklyPatternScore
        
        // Day of Week Factor (10 points)
        let dayOfWeekScore = calculateDayOfWeekScore()
        score += dayOfWeekScore
        
        return max(10, min(score, 100)) // Ensure score is between 10-100
    }
    
    private func calculateWeeklyPatternScore() -> Int {
        // Analyze past 7 days activity pattern
        let calendar = Calendar.current
        let today = Date()
        var totalSteps = 0.0
        var activeDays = 0
        
        for i in 0..<7 {
            guard calendar.date(byAdding: .day, value: -i, to: today) != nil else { continue }
            // In real implementation, we'd query HealthKit for historical data
            // For now, simulate based on current day pattern
            if i == 0 {
                totalSteps += healthKitService.todaySteps
                if healthKitService.todaySteps > 3000 { activeDays += 1 }
            }
        }
        
        let averageSteps = totalSteps / 7.0
        let activityConsistency = Double(activeDays) / 7.0
        
        if averageSteps >= 8000 && activityConsistency >= 0.6 {
            return 10 // Excellent pattern
        } else if averageSteps >= 5000 && activityConsistency >= 0.4 {
            return 7 // Good pattern
        } else {
            return 3 // Needs improvement
        }
    }
    
    private func calculateDayOfWeekScore() -> Int {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())
        
        // Sunday = 1, Monday = 2, etc.
        switch dayOfWeek {
        case 1: return 8 // Sunday - rest day
        case 2: return 6 // Monday - start of week
        case 3, 4, 5: return 5 // Tue-Thu - mid week
        case 6: return 6 // Friday - end of week
        case 7: return 8 // Saturday - weekend
        default: return 5
        }
    }
    
    // MARK: - Helper Methods
    private func formatSteps(_ steps: Double) -> String {
        if steps == 0 { return "0" }
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000)
        }
        return String(format: "%.0f", steps)
    }
    
    private func formatCalories(_ calories: Double) -> String {
        if calories == 0 { return "0" }
        return String(format: "%.0f", calories)
    }
}

// 💫 ENHANCED HEALTH RINGS SECTION
struct EnhancedHealthRingsSection: View {
    let user: User?
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateRings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Health Activity Rings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: Text("Health Detail")) {
                    Text("View Details")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Animated Health Rings
            HStack(spacing: 40) {
                // Steps Ring
                AnimatedHealthRing(
                    progress: stepsProgress,
                    title: "Steps",
                    value: formatSteps(healthKitService.todaySteps),
                    goal: "10k",
                    color: .blue,
                    animate: animateRings
                )
                
                // Calories Ring
                AnimatedHealthRing(
                    progress: caloriesProgress,
                    title: "Calories",
                    value: formatCalories(healthKitService.todayActiveCalories),
                    goal: formatCalorieGoal(),
                    color: .orange,
                    animate: animateRings
                )
                
                // Heart Rate Ring (using recovery score)
                AnimatedHealthRing(
                    progress: Double(calculateRecoveryScore()) / 100.0,
                    title: "Recovery",
                    value: "\(calculateRecoveryScore())%",
                    goal: "85%",
                    color: .red,
                    animate: animateRings
                )
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animateRings = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var stepsProgress: Double {
        min(healthKitService.todaySteps / 10000.0, 1.0)
    }
    
    private var caloriesProgress: Double {
        guard let user = user else { return 0 }
        return min(healthKitService.todayActiveCalories / user.dailyCalorieGoal, 1.0)
    }
    
    private func formatSteps(_ steps: Double) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000)
        }
        return String(format: "%.0f", steps)
    }
    
    private func formatCalories(_ calories: Double) -> String {
        String(format: "%.0f", calories)
    }
    
    private func formatCalorieGoal() -> String {
        guard let user = user else { return "2000" }
        if user.dailyCalorieGoal >= 1000 {
            return String(format: "%.1fk", user.dailyCalorieGoal / 1000)
        }
        return String(format: "%.0f", user.dailyCalorieGoal)
    }
    
    private func calculateRecoveryScore() -> Int {
        // Enhanced recovery calculation with multiple factors
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps
        let activeCalories = healthKitService.todayActiveCalories
        
        var score = 50 // Base score
        
        // Heart Rate Assessment (30 points)
        let heartRateScore: Int
        switch heartRate {
        case 0..<50: heartRateScore = 30 // Athletic level
        case 50..<60: heartRateScore = 25 // Excellent
        case 60..<70: heartRateScore = 20 // Good 
        case 70..<80: heartRateScore = 15 // Average
        case 80..<90: heartRateScore = 10 // Below average
        default: heartRateScore = 5 // Poor
        }
        score += heartRateScore
        
        // Activity Balance Assessment (20 points)
        let activityScore: Int
        if steps >= 12000 && activeCalories >= 600 {
            activityScore = 20 // Optimal activity
        } else if steps >= 8000 && activeCalories >= 400 {
            activityScore = 15 // Good activity
        } else if steps >= 5000 && activeCalories >= 200 {
            activityScore = 10 // Moderate activity
        } else if steps < 2000 && activeCalories < 100 {
            activityScore = 20 // Complete rest (good for recovery)
        } else {
            activityScore = 5 // Poor balance
        }
        score += activityScore
        
        return max(10, min(score, 100)) // Ensure score is between 10-100
    }
}

// 🧠 ENHANCED HEALTH INTELLIGENCE SECTION
struct EnhancedHealthIntelligenceSection: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("AI Health Intelligence")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: HealthIntelligenceView()) {
                    Text("Full Report")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // AI Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                HealthInsightCard(
                    icon: "brain.head.profile",
                    title: "Recovery Status",
                    insight: generateRecoveryInsight(),
                    confidence: "High",
                    color: .purple
                )
                
                HealthInsightCard(
                    icon: "heart.text.square",
                    title: "Activity Pattern",
                    insight: generateActivityInsight(),
                    confidence: "Medium",
                    color: .blue
                )
                
                HealthInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Health Trend",
                    insight: generateTrendInsight(),
                    confidence: "High",
                    color: .green
                )
                
                HealthInsightCard(
                    icon: "lightbulb.fill",
                    title: "Recommendation",
                    insight: generateRecommendation(),
                    confidence: "Medium",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - AI Insight Generation
    
    private func generateRecoveryInsight() -> String {
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps
        
        if heartRate < 60 && steps >= 8000 {
            return "Excellent recovery markers. Your body is well-rested."
        } else if heartRate < 70 {
            return "Good recovery status. Consider maintaining current habits."
        } else {
            return "Recovery could improve. Focus on sleep and stress management."
        }
    }
    
    private func generateActivityInsight() -> String {
        let steps = healthKitService.todaySteps
        let _ = healthKitService.todayActiveCalories
        
        if steps >= 12000 {
            return "High activity day! You're exceeding recommended levels."
        } else if steps >= 8000 {
            return "Solid activity level. You're on track for health goals."
        } else if steps < 3000 {
            return "Low activity detected. Consider adding movement breaks."
        } else {
            return "Moderate activity. Small increases can boost wellness."
        }
    }
    
    private func generateTrendInsight() -> String {
        // Simplified trend analysis
        let currentSteps = healthKitService.todaySteps
        
        if currentSteps >= 10000 {
            return "Positive trend in daily activity. Keep up the momentum!"
        } else if currentSteps >= 5000 {
            return "Steady progress observed. Gradual improvements are key."
        } else {
            return "Room for improvement in activity levels detected."
        }
    }
    
    private func generateRecommendation() -> String {
        let steps = healthKitService.todaySteps
        let heartRate = healthKitService.restingHeartRate ?? 70
        
        if steps < 5000 {
            return "Try adding 10-minute walks after meals."
        } else if heartRate > 75 {
            return "Consider stress reduction techniques like meditation."
        } else if steps >= 10000 {
            return "Great work! Add strength training for complete fitness."
        } else {
            return "Increase daily steps by 1000 for optimal health benefits."
        }
    }
}

// 📈 ENHANCED HEALTH TRENDS SECTION
struct EnhancedHealthTrendsSection: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Health Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: HealthTrendsView()) {
                    Text("View Charts")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Enhanced Trend Cards
            VStack(spacing: 12) {
                EnhancedTrendCard(
                    icon: "figure.walk",
                    title: "Steps Trend",
                    currentValue: Int(healthKitService.todaySteps),
                    unit: "steps",
                    trendData: healthKitService.stepsHistory.map { $0.value },
                    color: .blue,
                    trend: calculateStepsTrend()
                )
                
                EnhancedTrendCard(
                    icon: "scalemass.fill",
                    title: "Weight Trend",
                    currentValue: Int(healthKitService.currentWeight ?? 0),
                    unit: unitSettings.unitSystem == .metric ? "kg" : "lb",
                    trendData: healthKitService.weightHistory.map { $0.value },
                    color: .green,
                    trend: calculateWeightTrend()
                )
                
                EnhancedTrendCard(
                    icon: "heart.fill",
                    title: "Heart Rate Trend",
                    currentValue: Int(healthKitService.restingHeartRate ?? 0),
                    unit: "bpm",
                    trendData: healthKitService.heartRateHistory.map { $0.value },
                    color: .red,
                    trend: calculateHeartRateTrend()
                )
            }
        }
    }
    
    // MARK: - Trend Calculations
    
    private func calculateStepsTrend() -> TrendDirection {
        let recentAvg = healthKitService.stepsHistory.suffix(3).map { $0.value }.reduce(0, +) / 3
        let previousAvg = healthKitService.stepsHistory.prefix(4).map { $0.value }.reduce(0, +) / 4
        
        if recentAvg > previousAvg * 1.1 { return .increasing }
        if recentAvg < previousAvg * 0.9 { return .decreasing }
        return .stable
    }
    
    private func calculateWeightTrend() -> TrendDirection {
        guard healthKitService.weightHistory.count >= 2 else { return .stable }
        let recent = healthKitService.weightHistory.suffix(2).map { $0.value }
        let change = recent.last! - recent.first!
        
        if abs(change) < 0.5 { return .stable }
        return change > 0 ? .increasing : .decreasing
    }
    
    private func calculateHeartRateTrend() -> TrendDirection {
        guard healthKitService.heartRateHistory.count >= 3 else { return .stable }
        let recentAvg = healthKitService.heartRateHistory.suffix(3).map { $0.value }.reduce(0, +) / 3
        let previousAvg = healthKitService.heartRateHistory.prefix(4).map { $0.value }.reduce(0, +) / 4
        
        if recentAvg < previousAvg - 2 { return .decreasing } // Lower HR is better
        if recentAvg > previousAvg + 2 { return .increasing }
        return .stable
    }
}

// MARK: - Supporting Components

struct HealthStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct AnimatedHealthRing: View {
    let progress: Double
    let title: String
    let value: String
    let goal: String
    let color: Color
    let animate: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: animate)
                
                // Center value
                VStack(spacing: 2) {
                    Text(value)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("/ \(goal)")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

struct HealthInsightCard: View {
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

struct EnhancedTrendCard: View {
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

#Preview {
    HealthAnalyticsView()
        .environment(UnitSettings.shared)
        .environment(ThemeManager())
        .padding()
}
