import SwiftUI

struct EmptyStateCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let message: String
    let primaryAction: ActionConfig?
    let secondaryAction: ActionConfig?
    
    struct ActionConfig {
        let title: String
        let icon: String?
        let action: () -> Void
        
        init(title: String, icon: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
    
    init(
        icon: String,
        title: String,
        message: String,
        primaryAction: ActionConfig? = nil,
        secondaryAction: ActionConfig? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(theme.colors.accent)
            }
            
            // Text Content
            VStack(spacing: theme.spacing.s) {
                Text(title)
                    .font(theme.typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Actions
            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: theme.spacing.m) {
                    if let primary = primaryAction {
                        QuickActionButton(
                            title: primary.title,
                            icon: primary.icon,
                            style: .primary,
                            size: .large,
                            action: primary.action
                        )
                    }
                    
                    if let secondary = secondaryAction {
                        QuickActionButton(
                            title: secondary.title,
                            icon: secondary.icon,
                            style: .ghost,
                            size: .medium,
                            action: secondary.action
                        )
                    }
                }
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(theme.colors.cardBackground)
                .shadow(color: theme.shadows.card.opacity(0.05), radius: 4)
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 30) {
        EmptyStateCard(
            icon: "dumbbell",
            title: "No Workouts Yet",
            message: "Start your fitness journey by creating your first workout routine",
            primaryAction: .init(
                title: "Create Workout",
                icon: "plus.circle.fill",
                action: { print("Create workout") }
            ),
            secondaryAction: .init(
                title: "Browse Templates",
                action: { print("Browse templates") }
            )
        )
        
        EmptyStateCard(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms or filters",
            primaryAction: .init(
                title: "Clear Filters",
                action: { print("Clear filters") }
            )
        )
    }
    .padding()
}