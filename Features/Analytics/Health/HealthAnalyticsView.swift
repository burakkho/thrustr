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
