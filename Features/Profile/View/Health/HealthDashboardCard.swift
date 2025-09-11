import SwiftUI
import HealthKit

struct HealthDashboardCard: View {
    let user: User
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) private var unitSettings
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced Header with better spacing
            HStack {
                Text("health.daily_overview".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: HealthTrendsView()) {
                    Text("common.view_all".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Enhanced Health Stats with larger progress displays
            VStack(spacing: 16) {
                // Primary metrics with large progress bars
                VStack(spacing: 12) {
                    EnhancedHealthStatRow(
                        icon: "figure.walk",
                        value: formatSteps(healthKitService.todaySteps),
                        label: "health.steps".localized,
                        color: .blue,
                        progress: stepsProgress,
                        goal: "10,000"
                    )
                    
                    EnhancedHealthStatRow(
                        icon: "flame.fill",
                        value: formatCalories(healthKitService.todayActiveCalories),
                        label: "health.calories".localized,
                        color: .orange,
                        progress: caloriesProgress,
                        goal: String(format: "%.0f", user.dailyCalorieGoal)
                    )
                }
                
                // Secondary metrics in compact grid
                HStack(spacing: 12) {
                    CompactHealthMetric(
                        icon: "scalemass.fill",
                        value: formatWeight(healthKitService.currentWeight),
                        label: "health.weight".localized,
                        color: .green
                    )
                    
                    CompactHealthMetric(
                        icon: "heart.fill",
                        value: formatHeartRate(healthKitService.restingHeartRate),
                        label: "health.resting_hr".localized,
                        color: .red
                    )
                }
            }
            .padding(.horizontal, 4)
            
            // Prominent AI Health Intelligence
            if healthKitService.isAuthorized {
                ProminentHealthIntelligence()
            } else {
                // Enhanced authorization prompt
                HealthKitAuthPrompt()
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.xl)
        .shadow(color: theme.shadows.card, radius: 6, x: 0, y: 3)
        .onAppear {
            Task {
                await healthKitService.readTodaysData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var stepsProgress: Double {
        let goal = 10000.0 // Default step goal
        return min(healthKitService.todaySteps / goal, 1.0)
    }
    
    private var caloriesProgress: Double {
        let goal = user.dailyCalorieGoal
        return min(healthKitService.todayActiveCalories / goal, 1.0)
    }
    
    // MARK: - Formatting Methods
    
    private func formatSteps(_ steps: Double) -> String {
        if steps == 0 { return "--" }
        return NumberFormatter.localizedString(from: NSNumber(value: steps), number: .decimal)
    }
    
    private func formatCalories(_ calories: Double) -> String {
        if calories == 0 { return "--" }
        return String(format: "%.0f", calories)
    }
    
    private func formatWeight(_ weight: Double?) -> String {
        guard let weight = weight else { return "--" }
        
        if unitSettings.unitSystem == .metric {
            return String(format: "%.1f kg", weight)
        } else {
            let weightInPounds = weight * 2.20462
            return String(format: "%.1f lb", weightInPounds)
        }
    }
    
    private func formatHeartRate(_ heartRate: Double?) -> String {
        guard let heartRate = heartRate else { return "--" }
        return String(format: "%.0f bpm", heartRate)
    }
}

// MARK: - Enhanced Health Components

// Large progress row for primary metrics
struct EnhancedHealthStatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let progress: Double
    let goal: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with icon and value
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(label)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Goal display
                Text("/ \(goal)")
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textTertiary)
            }
            
            // Large progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                        .animation(.easeInOut(duration: 1.0), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.05))
        .cornerRadius(theme.radius.m)
    }
}

// Compact metric for secondary data
struct CompactHealthMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(theme.radius.s)
    }
}

// Prominent AI Intelligence Section  
struct ProminentHealthIntelligence: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @State private var insight: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // AI Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    Text("health.ai_insight".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                Spacer()
                
                NavigationLink(destination: HealthIntelligenceView()) {
                    Image(systemName: "arrow.up.right.circle")
                        .font(.title3)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            // Insight content with larger text
            Text(insight.isEmpty ? "health.analyzing".localized : insight)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.1), .blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(theme.radius.l)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            generateEnhancedInsight()
        }
    }
    
    private func generateEnhancedInsight() {
        Task {
            let steps = healthKitService.todaySteps
            let calories = healthKitService.todayActiveCalories
            
            await MainActor.run {
                if steps > 10000 && calories > 400 {
                    insight = "health.insight.excellent_day".localized
                } else if steps > 8000 {
                    insight = "health.insight.active_day".localized
                } else if steps > 5000 {
                    insight = "health.insight.moderate_day".localized
                } else if steps > 0 {
                    insight = "health.insight.light_day".localized
                } else {
                    insight = "health.insight.get_moving".localized
                }
            }
        }
    }
}

// Enhanced HealthKit authorization prompt
struct HealthKitAuthPrompt: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("health.authorization_needed".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("health.connect_description".localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            
            NavigationLink(destination: HealthKitAuthorizationView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("health.setup".localized)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.red)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.05))
        .cornerRadius(theme.radius.l)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Health Stat Cell
struct HealthStatCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var progress: Double?
    var showProgress: Bool = true
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Icon and Value
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            // Label and Progress
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack {
                    Text(label)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                }
                
                // Progress bar if enabled and progress available
                if showProgress, let progress = progress, progress > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(theme.colors.backgroundSecondary)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                            
                            Rectangle()
                                .fill(color.opacity(0.8))
                                .frame(width: geometry.size.width * progress, height: 3)
                                .cornerRadius(1.5)
                                .animation(.easeInOut(duration: 0.6), value: progress)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Health Intelligence Summary
struct HealthIntelligenceSummary: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @State private var insight: String = ""
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // AI Icon
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(theme.colors.accent)
                .padding(8)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(8)
            
            // Insight
            VStack(alignment: .leading, spacing: 2) {
                Text("health.ai_insight".localized)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text(insight.isEmpty ? "health.analyzing".localized : insight)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            NavigationLink(destination: HealthIntelligenceView()) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary.opacity(0.3))
        .cornerRadius(theme.radius.s)
        .onAppear {
            generateQuickInsight()
        }
    }
    
    private func generateQuickInsight() {
        Task {
            // Generate a quick health insight based on available data
            let steps = healthKitService.todaySteps
            let _ = healthKitService.todayActiveCalories
            
            await MainActor.run {
                if steps > 8000 {
                    insight = "health.insight.active_day".localized
                } else if steps > 5000 {
                    insight = "health.insight.moderate_day".localized
                } else if steps > 0 {
                    insight = "health.insight.light_day".localized
                } else {
                    insight = "health.insight.get_moving".localized
                }
            }
        }
    }
}

#Preview {
    let user = User(name: "Test User", age: 30, gender: .male, height: 175, currentWeight: 75)
    
    HealthDashboardCard(user: user)
        .environment(UnitSettings.shared)
        .environment(ThemeManager())
        .padding()
}