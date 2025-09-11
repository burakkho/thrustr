import SwiftUI

/**
 * ActivityRow - Single activity row component
 * 
 * Displays individual activity entries with icon, title, subtitle,
 * and timestamp. Handles tap navigation and consistent styling.
 */
struct ActivityRow: View {
    @Environment(\.theme) private var theme
    @Environment(TabRouter.self) var tabRouter
    @State private var isPressed = false
    @State private var isExpanded = false
    
    let activity: ActivityEntry
    
    private var isGroupedNutrition: Bool {
        activity.metadata?.customData?["is_grouped"] == "true"
    }
    
    private var groupedCount: Int {
        Int(activity.metadata?.customData?["grouped_count"] ?? "1") ?? 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main activity row
            HStack(spacing: theme.spacing.m) {
                // Activity Icon
                activityIcon
                
                // Content
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        Text(activity.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(1)
                        
                        if isGroupedNutrition {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                                .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        }
                        
                        Spacer()
                        
                        Text(activity.timeAgo)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if let subtitle = activity.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, theme.spacing.s)
            .padding(.horizontal, theme.spacing.m)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.s)
                    .fill(theme.colors.backgroundSecondary.opacity(isPressed ? 0.8 : 0.0))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .contentShape(Rectangle())
            .onTapGesture {
                if isGroupedNutrition {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } else {
                    handleActivityTap()
                }
            }
            .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
                isPressed = pressing
            })
            
            // Expanded details for grouped nutrition
            if isGroupedNutrition && isExpanded {
                expandedNutritionDetails
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isGroupedNutrition ? "Detayları görmek için dokunun" : DashboardKeys.General.tapForDetails.localized)
    }
    
    // MARK: - Subviews
    
    private var expandedNutritionDetails: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Rectangle()
                .fill(theme.colors.textSecondary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, theme.spacing.m)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack {
                    Text("Besin Değerleri")
                        .font(.caption.weight(.medium))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, theme.spacing.l)
                
                // Macro breakdown
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: theme.spacing.s) {
                    NutritionDetailItem(
                        label: "Protein",
                        value: "\(Int(activity.metadata?.protein ?? 0))g",
                        color: .red
                    )
                    
                    NutritionDetailItem(
                        label: "Karb",
                        value: "\(Int(activity.metadata?.carbs ?? 0))g",
                        color: .blue
                    )
                    
                    NutritionDetailItem(
                        label: "Yağ",
                        value: "\(Int(activity.metadata?.fat ?? 0))g",
                        color: .yellow
                    )
                }
                .padding(.horizontal, theme.spacing.l)
            }
        }
        .padding(.bottom, theme.spacing.s)
        .background(theme.colors.backgroundSecondary.opacity(0.3))
    }
    
    private var activityIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Image(systemName: activity.displayIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        switch activity.typeEnum {
        case .workoutCompleted, .personalRecord:
            return .blue
        case .cardioCompleted:
            return .green
        case .wodCompleted:
            return .orange
        case .nutritionLogged, .mealCompleted:
            return mealIconColor
        case .measurementUpdated, .weightUpdated, .bodyFatUpdated:
            return .purple
        case .goalCompleted, .streakMilestone, .weeklyGoalReached:
            return .yellow
        case .stepsGoalReached, .healthDataSynced, .sleepLogged:
            return .red
        case .programStarted, .programCompleted, .planUpdated:
            return .indigo
        case .strengthTestCompleted:
            return .blue
        default:
            return .gray
        }
    }
    
    private var iconBackgroundColor: Color {
        return iconColor
    }
    
    private var mealIconColor: Color {
        guard let subtitle = activity.subtitle else { return .orange }
        
        if subtitle.contains(DashboardKeys.Meals.breakfast.localized) || subtitle.contains("Breakfast") {
            return .yellow
        } else if subtitle.contains(DashboardKeys.Meals.lunch.localized) || subtitle.contains("Lunch") {
            return .orange
        } else if subtitle.contains(DashboardKeys.Meals.dinner.localized) || subtitle.contains("Dinner") {
            return .purple
        } else if subtitle.contains(DashboardKeys.Meals.snack.localized) || subtitle.contains("Snack") {
            return .green
        }
        return .orange
    }
    
    private var accessibilityLabel: String {
        var label = activity.title
        
        if let subtitle = activity.subtitle, !subtitle.isEmpty {
            label += ", \(subtitle)"
        }
        
        label += ", \(activity.timeAgo)"
        
        return label
    }
    
    // MARK: - Actions
    
    private func handleActivityTap() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Navigate based on activity type
        navigateToRelevantSection()
    }
    
    private func navigateToRelevantSection() {
        switch activity.typeEnum {
        case .wodCompleted:
            // Navigate to Training tab with WOD History
            tabRouter.selected = 1
            // Use notification to deep navigate to WOD History
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .navigateToWODHistory, object: nil)
            }
            
        case .personalRecord where activity.title.contains("WOD") || activity.title.contains("METCON"):
            // Navigate to Training tab with WOD History
            tabRouter.selected = 1
            // Use notification to deep navigate to WOD History
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .navigateToWODHistory, object: nil)
            }
            
        case .workoutCompleted, .cardioCompleted, .strengthTestCompleted:
            // Navigate to Training tab
            tabRouter.selected = 1
            
        case .personalRecord:
            // Navigate to Training tab for other PRs
            tabRouter.selected = 1
            
        case .nutritionLogged, .mealCompleted, .calorieGoalReached:
            // Navigate to Nutrition tab
            tabRouter.selected = 2
            
        case .measurementUpdated, .weightUpdated, .bodyFatUpdated:
            // Navigate to Profile tab
            tabRouter.selected = 3
            
        case .goalCompleted, .streakMilestone, .weeklyGoalReached:
            // Navigate to Training tab (goals section)
            tabRouter.selected = 1
            
        case .stepsGoalReached, .healthDataSynced, .sleepLogged:
            // Navigate to Profile tab (health section)
            tabRouter.selected = 3
            
        case .programStarted, .programCompleted, .planUpdated:
            // Navigate to Training tab
            tabRouter.selected = 1
            
        case .settingsUpdated, .profileUpdated, .unitSystemChanged:
            // Navigate to Profile tab
            tabRouter.selected = 3
        }
    }
}

// MARK: - Supporting Components

struct NutritionDetailItem: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.xs)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        // Workout activity
        ActivityRow(activity: sampleWorkoutActivity())
        
        // Nutrition activity
        ActivityRow(activity: sampleNutritionActivity())
        
        // Measurement activity
        ActivityRow(activity: sampleMeasurementActivity())
        
        // Goal activity
        ActivityRow(activity: sampleGoalActivity())
    }
    .padding()
    .environment(TabRouter())
}

// MARK: - Preview Helpers

private func sampleWorkoutActivity() -> ActivityEntry {
    let activity = ActivityEntry(
        type: ActivityType.workoutCompleted,
        title: "Bench Press",
        subtitle: "3 set | 24 reps | 80kg | 45dk",
        icon: "dumbbell.fill"
    )
    activity.timestamp = Date().addingTimeInterval(-3600) // 1 hour ago
    return activity
}

private func sampleNutritionActivity() -> ActivityEntry {
    let activity = ActivityEntry(
        type: ActivityType.nutritionLogged,
        title: "Kahvaltı kaydedildi",
        subtitle: "420 cal | 25g P | 45g C | 18g F",
        icon: "sunrise.fill"
    )
    activity.timestamp = Date().addingTimeInterval(-10800) // 3 hours ago
    return activity
}

private func sampleMeasurementActivity() -> ActivityEntry {
    let activity = ActivityEntry(
        type: ActivityType.weightUpdated,
        title: "Kilo güncellendi",
        subtitle: "75.2kg → 75.0kg (-0.2kg)",
        icon: "scalemass"
    )
    activity.timestamp = Date().addingTimeInterval(-86400) // 1 day ago
    return activity
}

private func sampleGoalActivity() -> ActivityEntry {
    let activity = ActivityEntry(
        type: ActivityType.goalCompleted,
        title: "Haftalık lift hedefi tamamlandı",
        subtitle: "3/3 session ✅",
        icon: "checkmark.circle.fill"
    )
    activity.timestamp = Date().addingTimeInterval(-1800) // 30 minutes ago
    return activity
}