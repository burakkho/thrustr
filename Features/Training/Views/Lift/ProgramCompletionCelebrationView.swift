import SwiftUI

struct ProgramCompletionCelebrationView: View {
    @Environment(\.theme) private var theme
    let programName: String
    let onDismiss: () -> Void
    
    @State private var showingConfetti = false
    @State private var scale = 0.8
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            // Trophy Icon with Animation
            ZStack {
                Circle()
                    .fill(theme.colors.success.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showingConfetti ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showingConfetti)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.colors.warning)
                    .scaleEffect(scale)
            }
            
            VStack(spacing: theme.spacing.m) {
                Text(TrainingKeys.Celebration.congratulations.localized)
                    .font(theme.typography.heading1)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("\(programName) " + TrainingKeys.Celebration.programCompleted.localized)
                    .font(theme.typography.title3)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(TrainingKeys.Celebration.achievementMessage.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacing.l)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: theme.spacing.m) {
                Button {
                    onDismiss()
                } label: {
                    Text(TrainingKeys.Celebration.continueTraining.localized)
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.m)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                }
                
                Button {
                    // Share achievement
                    shareAchievement()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(TrainingKeys.Celebration.share.localized)
                    }
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, theme.spacing.xl)
        }
        .padding(.vertical, theme.spacing.xl)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                scale = 1.0
                showingConfetti = true
            }
        }
    }
    
    private func shareAchievement() {
        let shareText = "\(TrainingKeys.Celebration.shareText.localized) \(programName)! 💪 #Thrustr #Fitness"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        rootViewController.present(activityVC, animated: true)
    }
}

#Preview {
    ProgramCompletionCelebrationView(
        programName: "StrongLifts 5x5",
        onDismiss: {}
    )
}