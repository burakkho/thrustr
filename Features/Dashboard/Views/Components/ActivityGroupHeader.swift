import SwiftUI

/**
 * ActivityGroupHeader - Date section headers for activity feed
 * 
 * Simple header component for grouping activities by date
 * (Bugün, Dün, Bu Hafta) with consistent styling.
 */
struct ActivityGroupHeader: View {
    @Environment(\.theme) private var theme
    
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.colors.textSecondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal, theme.spacing.m)
        .padding(.vertical, theme.spacing.s)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(DashboardKeys.General.sectionLabel.localized): \(title)")
    }
}

#Preview {
    VStack(spacing: 16) {
        ActivityGroupHeader(title: "Bugün")
        ActivityGroupHeader(title: "Dün")
        ActivityGroupHeader(title: "Bu Hafta")
    }
    .padding()
}