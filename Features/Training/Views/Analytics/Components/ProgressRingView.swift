import SwiftUI

struct ProgressRingView: View {
    @Environment(\.theme) private var theme
    let progress: Double // 0.0 to 1.0
    let title: String
    let current: String
    let target: String
    let color: Color
    let lineWidth: CGFloat
    
    init(
        progress: Double,
        title: String,
        current: String,
        target: String,
        color: Color,
        lineWidth: CGFloat = 8
    ) {
        self.progress = min(max(progress, 0.0), 1.0) // Clamp between 0-1
        self.title = title
        self.current = current
        self.target = target
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: 80, height: 80)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
                
                // Progress percentage text
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Current/Target values
            VStack(spacing: 2) {
                Text(current)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("of \(target)")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRingView(
            progress: 0.85,
            title: TrainingKeys.Analytics.weekly.localized,
            current: "17",
            target: "20",
            color: .orange
        )
        
        ProgressRingView(
            progress: 0.6,
            title: TrainingKeys.Analytics.monthly.localized,
            current: "30km",
            target: "50km",
            color: .green
        )
    }
    .padding()
}