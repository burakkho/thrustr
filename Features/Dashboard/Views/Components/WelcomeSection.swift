import SwiftUI

struct WelcomeSection: View {
    @Environment(\.theme) private var theme
    let user: User
    let greeting: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // Time-based greeting with user name (from ViewModel)
                    Text(greeting)
                        .font(.title2.bold())
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(DashboardKeys.howFeeling.localized)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Enhanced streak counter with icon
                if !user.streakDisplayText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(user.streakDisplayText)
                            .font(.subheadline.bold())
                            .foregroundColor(theme.colors.accent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.colors.accent.opacity(0.1))
                    )
                }
                
                // App Logo
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greeting) \(user.streakDisplayText.isEmpty ? "" : "\(DashboardKeys.General.streakLabel.localized): \(user.streakDisplayText)")")
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}


#Preview {
    let user = User()
    user.name = "Burak"

    return WelcomeSection(user: user, greeting: "Good Morning, Burak!")
        .padding()
}
