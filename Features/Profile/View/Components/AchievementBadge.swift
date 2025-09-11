import SwiftUI
import SwiftData

// MARK: - Achievement Badge Component
// Compact badge for displaying achievements in profile card
struct AchievementBadge: View {
    let achievement: Achievement
    let size: AchievementBadgeSize
    
    init(achievement: Achievement, size: AchievementBadgeSize = .small) {
        self.achievement = achievement
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Badge background with enhanced gradients
            Circle()
                .fill(
                    achievement.isCompleted ?
                    getCompletedGradient() :
                    getIncompleteGradient()
                )
                .frame(width: size.diameter, height: size.diameter)
            
            // Achievement icon with glow effect for showcase
            Image(systemName: achievement.icon)
                .font(size.iconFont)
                .fontWeight(size == .showcase ? .semibold : .regular)
                .foregroundColor(achievement.isCompleted ? .white : .secondary)
                .shadow(
                    color: size == .showcase && achievement.isCompleted ? .white.opacity(0.3) : .clear,
                    radius: 2
                )
            
            // Completion indicator with enhanced stroke
            if achievement.isCompleted {
                Circle()
                    .stroke(Color.white, lineWidth: size.strokeWidth)
                    .frame(width: size.diameter, height: size.diameter)
                    .shadow(
                        color: size == .showcase ? .black.opacity(0.1) : .clear,
                        radius: 2
                    )
            }
        }
        .scaleEffect(size == .showcase ? 1.0 : 1.0)
        .shadow(
            color: size == .showcase && achievement.isCompleted ? .orange.opacity(0.3) : .clear,
            radius: size == .showcase ? 4 : 0,
            x: 0,
            y: size == .showcase ? 2 : 0
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(achievement.title)
        .accessibilityValue(achievement.isCompleted ? "Completed" : "In progress")
    }
    
    // MARK: - Helper Methods
    private func getCompletedGradient() -> LinearGradient {
        // Enhanced gradients based on achievement category
        let colors: [Color]
        
        switch achievement.category {
        case .workout:
            colors = [.orange, .red]
        case .nutrition:
            colors = [.green, .blue]
        case .weight:
            colors = [.blue, .purple]
        case .streak:
            colors = [.yellow, .orange]
        case .social:
            colors = [.purple, .pink]
        default:
            colors = [.yellow, .orange]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func getIncompleteGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Achievement Badge Row
// Horizontal row of achievement badges for profile card
struct AchievementBadgeRow: View {
    let achievements: [Achievement]
    let maxDisplay: Int = 3
    @Environment(\.theme) private var theme
    
    private var displayAchievements: [Achievement] {
        Array(achievements.prefix(maxDisplay))
    }
    
    private var remainingCount: Int {
        max(0, achievements.count - maxDisplay)
    }
    
    var body: some View {
        if !achievements.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("profile.recent_achievements".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if remainingCount > 0 {
                        NavigationLink(destination: AchievementsView()) {
                            Text("+\(remainingCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(theme.colors.accent))
                        }
                        .accessibilityLabel("View all achievements")
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(displayAchievements, id: \.id) { achievement in
                        NavigationLink(destination: AchievementsView()) {
                            AchievementBadge(achievement: achievement, size: .small)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Achievement Badge Size Configuration
enum AchievementBadgeSize {
    case small, medium, large, showcase
    
    var diameter: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 44
        case .showcase: return 60  // New larger size for prominent display
        }
    }
    
    var iconFont: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .body
        case .showcase: return .title2  // Larger icon for showcase
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 1
        case .medium: return 1.5
        case .large: return 2
        case .showcase: return 3  // Thicker stroke for showcase
        }
    }
}

// MARK: - HealthKit-Driven Achievement Helper
// Computes achievements based on HealthKit and app data
struct AchievementComputer {
    @MainActor
    static func computeRecentAchievements(
        user: User?,
        healthKitService: HealthKitService,
        liftSessions: [LiftSession] = [],
        nutritionEntries: [NutritionEntry] = [],
        weightEntries: [WeightEntry] = []
    ) -> [Achievement] {
        
        let achievements = Achievement.allAchievements.map { achievement in
            var updatedAchievement = achievement
            updatedAchievement.updateProgress(
                liftSessions: liftSessions,
                weightEntries: weightEntries, 
                nutritionEntries: nutritionEntries,
                user: user
            )
            
            // Add HealthKit-specific progress updates
            updateHealthKitProgress(&updatedAchievement, healthKitService: healthKitService)
            
            return updatedAchievement
        }
        
        // Return recently completed achievements first, then highest progress
        return achievements
            .filter { $0.isCompleted || $0.progressPercentage > 0.1 }
            .sorted { lhs, rhs in
                if lhs.isCompleted && !rhs.isCompleted { return true }
                if !lhs.isCompleted && rhs.isCompleted { return false }
                return lhs.progressPercentage > rhs.progressPercentage
            }
    }
    
    @MainActor
    private static func updateHealthKitProgress(_ achievement: inout Achievement, healthKitService: HealthKitService) {
        // Update achievements based on HealthKit data
        switch achievement.title {
        case let title where title.contains("Steps") || title.contains("Adım"):
            if healthKitService.isAuthorized {
                achievement.currentProgress = healthKitService.todaySteps
            }
            
        case let title where title.contains("Calories") || title.contains("Kalori"):
            if healthKitService.isAuthorized {
                achievement.currentProgress = healthKitService.todayActiveCalories
            }
            
        case let title where title.contains("Active") || title.contains("Aktif"):
            if healthKitService.isAuthorized {
                // Weekly active days based on calories > 200
                achievement.currentProgress = healthKitService.todayActiveCalories > 200 ? 1 : 0
            }
            
        default:
            break
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single badges
        HStack(spacing: 12) {
            AchievementBadge(
                achievement: Achievement(
                    title: "First Workout",
                    description: "Complete your first workout",
                    icon: "dumbbell.fill",
                    category: .workout,
                    targetValue: 1
                ),
                size: .small
            )
            
            AchievementBadge(
                achievement: {
                    var achievement = Achievement(
                        title: "Step Master",
                        description: "Walk 10,000 steps",
                        icon: "figure.walk",
                        category: .workout,
                        targetValue: 10000
                    )
                    achievement.currentProgress = 10000
                    return achievement
                }(),
                size: .medium
            )
            
            AchievementBadge(
                achievement: {
                    var achievement = Achievement(
                        title: "Streak Champion",
                        description: "7 day workout streak",
                        icon: "flame.fill",
                        category: .streak,
                        targetValue: 7
                    )
                    achievement.currentProgress = 7
                    return achievement
                }(),
                size: .large
            )
        }
        
        // Badge row
        AchievementBadgeRow(achievements: [
            {
                var achievement = Achievement(
                    title: "First Workout",
                    description: "Complete your first workout",
                    icon: "dumbbell.fill",
                    category: .workout,
                    targetValue: 1
                )
                achievement.currentProgress = 1
                return achievement
            }(),
            {
                var achievement = Achievement(
                    title: "Step Master",
                    description: "Walk 10,000 steps",
                    icon: "figure.walk",
                    category: .workout,
                    targetValue: 10000
                )
                achievement.currentProgress = 8500
                return achievement
            }(),
            Achievement(
                title: "Future Goal",
                description: "Future achievement",
                icon: "star.fill",
                category: .workout,
                targetValue: 100
            )
        ])
    }
    .padding()
}