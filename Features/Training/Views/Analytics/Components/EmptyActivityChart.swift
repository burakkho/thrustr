import SwiftUI

struct EmptyActivityChart: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Chart Icon
            ZStack {
                Circle()
                    .fill(theme.colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.colors.accent.opacity(0.6))
            }
            
            // Text Content
            VStack(spacing: theme.spacing.s) {
                Text("No Activity Data")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Complete some workouts to see your weekly activity chart")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 1)
    }
}

#Preview {
    EmptyActivityChart()
}