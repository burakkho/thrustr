import SwiftUI

struct LoadingView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 24) {
            // App Logo/Icon
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.accent)
                .scaleEffect(1.2)
            
            // Loading Spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.accent))
                .scaleEffect(1.5)
            
            // Loading Text
            VStack(spacing: 8) {
                Text("loading.title")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("loading.subtitle")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.backgroundPrimary)
    }
}

#Preview {
    LoadingView()
        .environment(\.theme, DefaultLightTheme())
}
