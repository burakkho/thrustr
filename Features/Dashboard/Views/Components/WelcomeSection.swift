import SwiftUI

struct WelcomeSection: View {
    @Environment(\.theme) private var theme
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // Time-based greeting with user name
                    Text(timeBasedGreeting)
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
        .accessibilityLabel("\(timeBasedGreeting) \(user.streakDisplayText.isEmpty ? "" : "\(DashboardKeys.General.streakLabel.localized): \(user.streakDisplayText)")")
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    
    // MARK: - Private Properties
    private var displayName: String {
        user.name.isEmpty ? "User" : user.name
    }
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 6..<12:
            greeting = DashboardKeys.Greeting.goodMorning.localized
        case 12..<18:
            greeting = DashboardKeys.Greeting.goodAfternoon.localized
        case 18..<22:
            greeting = DashboardKeys.Greeting.goodEvening.localized
        default:
            greeting = DashboardKeys.Greeting.goodNight.localized
        }
        
        return "\(greeting), \(displayName)!"
    }
}


#Preview {
    let user = User()
    user.name = "Burak"
    
    return WelcomeSection(user: user)
        .padding()
}
