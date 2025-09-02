import SwiftUI

/**
 * EmptyActivityView - Smart empty state for activity feed
 * 
 * Shows contextual messaging based on time of day and user state,
 * with motivational content and quick action buttons.
 */
struct EmptyActivityView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var tabRouter: TabRouter
    
    var user: User? = nil
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Dynamic Icon based on time
            Image(systemName: contextualIcon)
                .font(.system(size: 50, weight: .light))
                .foregroundColor(theme.colors.accent.opacity(0.6))
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            
            // Smart Content
            VStack(spacing: theme.spacing.s) {
                Text(contextualTitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(contextualDescription)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Motivational message
                Text(motivationalMessage)
                    .font(.callout.weight(.medium))
                    .foregroundColor(theme.colors.accent)
                    .multilineTextAlignment(.center)
                    .padding(.top, theme.spacing.s)
            }
            
            // Quick Actions
            VStack(spacing: theme.spacing.m) {
                quickActionButton(
                    title: DashboardKeys.Activities.startWorkout.localized,
                    icon: "dumbbell.fill",
                    color: .blue
                ) {
                    tabRouter.selected = 1 // Navigate to Training
                }
                
                quickActionButton(
                    title: DashboardKeys.Activities.logNutrition.localized,
                    icon: "fork.knife",
                    color: .orange
                ) {
                    tabRouter.selected = 2 // Navigate to Nutrition
                }
                
                quickActionButton(
                    title: DashboardKeys.Activities.logWeight.localized,
                    icon: "scalemass",
                    color: .green
                ) {
                    tabRouter.selected = 3 // Navigate to Profile
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xl)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(contextualTitle)
        .accessibilityHint(contextualDescription)
    }
    
    // MARK: - Smart Content Properties
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
    
    private var contextualIcon: String {
        switch currentHour {
        case 6..<12: return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.fill"
        }
    }
    
    private var contextualTitle: String {
        if isWeekend {
            return DashboardKeys.Activities.weekendTitle.localized
        }
        
        switch currentHour {
        case 6..<12: return DashboardKeys.Activities.morningTitle.localized
        case 12..<17: return DashboardKeys.Activities.afternoonTitle.localized
        case 17..<21: return DashboardKeys.Activities.eveningTitle.localized
        default: return DashboardKeys.Activities.nightTitle.localized
        }
    }
    
    private var contextualDescription: String {
        if user?.onboardingCompleted == false {
            return DashboardKeys.Activities.emptyDesc.localized
        }
        
        if isWeekend {
            return DashboardKeys.Activities.weekendDesc.localized
        }
        
        switch currentHour {
        case 6..<12: return DashboardKeys.Activities.morningDesc.localized
        case 12..<17: return DashboardKeys.Activities.afternoonDesc.localized
        case 17..<21: return DashboardKeys.Activities.eveningDesc.localized
        default: return DashboardKeys.Activities.nightDesc.localized
        }
    }
    
    private var motivationalMessage: String {
        if isWeekend {
            return DashboardKeys.Activities.weekendMotivation.localized
        }
        
        switch currentHour {
        case 6..<12: return DashboardKeys.Activities.morningMotivation.localized
        case 12..<17: return DashboardKeys.Activities.afternoonMotivation.localized
        case 17..<21: return DashboardKeys.Activities.eveningMotivation.localized
        default: return DashboardKeys.Activities.nightMotivation.localized
        }
    }
    
    // MARK: - Quick Action Button
    
    @ViewBuilder
    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(theme.colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    EmptyActivityView(user: nil)
        .environmentObject(TabRouter())
        .environment(\.theme, DefaultLightTheme())
        .padding()
}
