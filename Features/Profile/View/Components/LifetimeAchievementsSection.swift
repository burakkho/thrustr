import SwiftUI
import SwiftData

/**
 * Lifetime Achievements Section - Displays major lifetime statistics
 * 
 * Shows motivational lifetime stats like total weight lifted, distance covered,
 * total workouts, and active days. Designed to provide user motivation and
 * sense of accomplishment.
 */
struct LifetimeAchievementsSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    
    // MARK: - Properties
    let user: User?
    
    @Query(sort: \LiftSession.startDate, order: .reverse)
    private var allLiftSessions: [LiftSession]
    
    @Query(sort: \CardioSession.startDate, order: .reverse) 
    private var allCardioSessions: [CardioSession]
    
    // MARK: - Computed Stats
    
    private var totalWeightLifted: Double {
        guard let user = user else { return 0 }
        return user.calculateTotalWeightLifted(from: allLiftSessions)
    }
    
    private var totalDistanceCovered: Double {
        guard let user = user else { return 0 }
        return user.calculateTotalDistanceCovered(from: allCardioSessions)
    }
    
    private var totalWorkouts: Int {
        guard let user = user else { return 0 }
        return user.calculateTotalWorkouts(
            liftSessions: allLiftSessions, 
            cardioSessions: allCardioSessions
        )
    }
    
    private var activeDays: Int {
        guard let user = user else { return 0 }
        return user.calculateActiveDays(
            liftSessions: allLiftSessions,
            cardioSessions: allCardioSessions
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ProfileKeys.LifetimeAchievements.title.localized)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(ProfileKeys.LifetimeAchievements.subtitle.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, theme.spacing.m)
            
            // Achievement Cards
            VStack(spacing: theme.spacing.s) {
                HStack(spacing: theme.spacing.s) {
                    // Total Weight Lifted
                    LifetimeStatCard(
                        icon: "dumbbell.fill",
                        title: ProfileKeys.LifetimeAchievements.totalWeight.localized,
                        value: formatWeight(totalWeightLifted),
                        color: .blue
                    )
                    
                    // Total Distance Covered
                    LifetimeStatCard(
                        icon: "figure.run",
                        title: ProfileKeys.LifetimeAchievements.totalDistance.localized,
                        value: formatDistance(totalDistanceCovered),
                        color: .green
                    )
                }
                
                HStack(spacing: theme.spacing.s) {
                    // Total Workouts
                    LifetimeStatCard(
                        icon: "calendar.badge.plus",
                        title: ProfileKeys.LifetimeAchievements.totalWorkouts.localized,
                        value: "\(totalWorkouts)",
                        color: .purple
                    )
                    
                    // Active Days
                    LifetimeStatCard(
                        icon: "flame.fill",
                        title: ProfileKeys.LifetimeAchievements.activeDays.localized,
                        value: "\(activeDays)",
                        color: .orange
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ProfileKeys.LifetimeAchievements.title.localized)
    }
    
    // MARK: - Formatting Methods
    
    private func formatWeight(_ weight: Double) -> String {
        let tonsUnit = ProfileKeys.Units.tons.localized
        let kgUnit = ProfileKeys.Units.kg.localized
        let lbUnit = ProfileKeys.Units.lb.localized
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if unitSettings.unitSystem == .metric {
            if weight >= 1000 {
                let value = weight / 1000
                return (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)) + tonsUnit
            } else {
                formatter.maximumFractionDigits = 0
                return (formatter.string(from: NSNumber(value: weight)) ?? String(format: "%.0f", weight)) + kgUnit
            }
        } else {
            let pounds = weight * 2.20462
            if pounds >= 2000 {
                let value = pounds / 2000
                return (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)) + tonsUnit
            } else {
                formatter.maximumFractionDigits = 0
                return (formatter.string(from: NSNumber(value: pounds)) ?? String(format: "%.0f", pounds)) + lbUnit
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        return UnitsFormatter.formatDistance(meters: distance, system: unitSettings.unitSystem)
    }
}

// MARK: - Supporting Views

/**
 * Individual lifetime stat card with icon, value, and title.
 */
private struct LifetimeStatCard: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            // Icon with colored background
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            // Value with large text
            Text(value)
                .font(.title3.bold())
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Title with smaller text
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(theme.spacing.s)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    let sampleUser = User(
        name: "Test User",
        age: 25,
        gender: .male,
        height: 175,
        currentWeight: 80
    )
    
    LifetimeAchievementsSection(user: sampleUser)
        .padding()
        .modelContainer(for: [User.self, LiftSession.self, CardioSession.self], inMemory: true)
        .environmentObject(UnitSettings.shared)
}