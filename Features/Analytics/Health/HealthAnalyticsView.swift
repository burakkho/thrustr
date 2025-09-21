import SwiftUI
import SwiftData

struct HealthAnalyticsView: View {
    @State private var viewModel = HealthAnalyticsViewModel()
    @Query private var users: [User]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 32) {
            // 🎯 HERO HEALTH STORY - Your wellness journey overview
            AnalyticsHealthStoryHeroCard(user: viewModel.currentUser)

            // 💫 ANIMATED HEALTH RINGS - Visual progress showcase
            AnalyticsEnhancedHealthRingsSection(user: viewModel.currentUser)

            // 🧠 AI HEALTH INTELLIGENCE - Smart insights grid
            AnalyticsEnhancedHealthIntelligenceSection()

            // 📈 HEALTH TRENDS TIMELINE - Historical patterns
            AnalyticsEnhancedHealthTrendsSection()
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


// 💫 ENHANCED HEALTH RINGS SECTION
struct EnhancedHealthRingsSection: View {
    let user: User?
    @State private var viewModel = HealthAnalyticsViewModel()
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
                    progress: viewModel.stepsProgress,
                    title: "Steps",
                    value: viewModel.formatSteps(Double(viewModel.todaySteps)),
                    goal: "10k",
                    color: .blue,
                    animate: animateRings
                )

                // Calories Ring
                AnimatedHealthRing(
                    progress: viewModel.caloriesProgress,
                    title: "Calories",
                    value: viewModel.formatCalories(viewModel.todayActiveCalories),
                    goal: viewModel.formatCalorieGoal(),
                    color: .orange,
                    animate: animateRings
                )

                // Heart Rate Ring (using recovery score)
                AnimatedHealthRing(
                    progress: Double(viewModel.calculateRecoveryScore()) / 100.0,
                    title: "Recovery",
                    value: "\(viewModel.calculateRecoveryScore())%",
                    goal: "85%",
                    color: .red,
                    animate: animateRings
                )
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            viewModel.updateUser(user)
            Task {
                await viewModel.loadTodaysHealthData()
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                animateRings = true
            }
        }
    }
}

// 🧠 ENHANCED HEALTH INTELLIGENCE SECTION
struct EnhancedHealthIntelligenceSection: View {
    @State private var viewModel = HealthAnalyticsViewModel()
    @State private var healthReport: HealthReport?
    @State private var isLoading = false
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
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let report = healthReport {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(Array(viewModel.getPriorityInsights(from: report.insights).prefix(4)), id: \.id) { insight in
                        HealthInsightCard(
                            icon: insight.type.icon,
                            title: insight.title,
                            insight: insight.message,
                            confidence: insight.confidence.displayName,
                            color: insight.type.color
                        )
                    }
                }
            } else {
                Text("Loading health insights...")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .onAppear {
            loadHealthIntelligence()
        }
    }

    // MARK: - ViewModel Integration

    private func loadHealthIntelligence() {
        isLoading = true

        Task {
            let report = await viewModel.generateHealthIntelligence()

            await MainActor.run {
                self.healthReport = report
                self.isLoading = false
            }
        }
    }
}

// 📈 ENHANCED HEALTH TRENDS SECTION
struct EnhancedHealthTrendsSection: View {
    @State private var viewModel = HealthAnalyticsViewModel()
    @State private var healthReport: HealthReport?
    @State private var isLoading = false
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
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                VStack(spacing: 12) {
                    EnhancedTrendCard(
                        icon: "figure.walk",
                        title: "Steps Trend",
                        currentValue: viewModel.todaySteps,
                        unit: "steps",
                        trendData: viewModel.stepsHistory,
                        color: Color.blue,
                        trend: getTrendDirection(for: .steps)
                    )

                    EnhancedTrendCard(
                        icon: "scalemass.fill",
                        title: "Weight Trend",
                        currentValue: Int(viewModel.currentUser?.weight ?? 0),
                        unit: unitSettings.unitSystem == .metric ? "kg" : "lb",
                        trendData: viewModel.weightHistory,
                        color: .green,
                        trend: getTrendDirection(for: .weight)
                    )

                    EnhancedTrendCard(
                        icon: "heart.fill",
                        title: "Heart Rate Trend",
                        currentValue: Int(viewModel.currentHeartRate ?? 0),
                        unit: "bpm",
                        trendData: [],
                        color: .red,
                        trend: getTrendDirection(for: .heartHealth)
                    )
                }
            }
        }
        .onAppear {
            loadHealthData()
        }
    }

    // MARK: - ViewModel Integration

    private func loadHealthData() {
        isLoading = true

        Task {
            let report = await viewModel.generateHealthIntelligence()
            await viewModel.loadTodaysHealthData()

            await MainActor.run {
                self.healthReport = report
                self.isLoading = false
            }
        }
    }

    private func getTrendDirection(for insightType: HealthInsightType) -> TrendDirection {
        guard let report = healthReport else { return .stable }

        let trendInsights = viewModel.getTrendInsights(from: report.insights)
        let relevantInsight = trendInsights.first { $0.type == insightType }

        // Map confidence to trend direction as fallback
        switch relevantInsight?.confidence {
        case .high:
            return .increasing
        case .medium:
            return .stable
        case .low:
            return .decreasing
        case .none:
            return .stable
        }
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
