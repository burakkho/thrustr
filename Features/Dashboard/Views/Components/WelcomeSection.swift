import SwiftUI

struct WelcomeSection: View {
    @Environment(\.theme) private var theme
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // Welcome message with user name fallback
                    Text(LocalizationKeys.Dashboard.welcome.localized(with: displayName))
                        .font(.title2.bold())
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(LocalizationKeys.Dashboard.howFeeling.localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Profile Picture or Initials
                ProfileInitials(name: displayName)
            }
        }
        .padding()
        .dashboardWelcomeCardStyle()
    }
    
    // MARK: - Private Properties
    private var displayName: String {
        user.name.isEmpty ? LocalizationKeys.Common.user.localized : user.name
    }
}

// MARK: - Profile Initials Component
private struct ProfileInitials: View {
    let name: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            Circle()
                .fill(theme.colors.accent.opacity(0.10))
                .frame(width: 50, height: 50)
            
            Text(String(name.prefix(1)).uppercased())
                .font(.title2.bold())
                .foregroundColor(theme.colors.accent)
        }
    }
}

#Preview {
    let user = User()
    user.name = "Burak"
    
    return WelcomeSection(user: user)
        .padding()
}