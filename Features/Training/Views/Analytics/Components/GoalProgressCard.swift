import SwiftUI

struct GoalProgressCard: View {
    @Environment(\.theme) private var theme
    
    let title: String
    let progress: Double // 0.0 - 1.0
    let current: String
    let target: String
    let color: Color
    let onTap: () -> Void
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.m) {
                // Progress Ring
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                        .animation(.easeInOut(duration: 0.8), value: progress)
                    
                    // Percentage text
                    Text("\(progressPercentage)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                // Title
                Text(title)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Current / Target
                VStack(spacing: 2) {
                    Text(current)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("/ \(target)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack(spacing: 16) {
        GoalProgressCard(
            title: TrainingKeys.Analytics.sessions.localized,
            progress: 0.75,
            current: "12",
            target: "16",
            color: .blue,
            onTap: { }
        )
        
        GoalProgressCard(
            title: TrainingKeys.Analytics.distance.localized,
            progress: 0.45,
            current: "22km",
            target: "50km",
            color: .red,
            onTap: { }
        )
    }
    .padding()
}