import SwiftUI

struct TimerDisplay: View {
    @Environment(\.theme) private var theme
    let formattedTime: String
    let isRunning: Bool
    let size: TimerDisplaySize
    let showSplit: Bool
    let splitTime: String?
    
    enum TimerDisplaySize {
        case small, medium, large, huge
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 56
            case .huge: return 72
            }
        }
    }
    
    init(
        formattedTime: String,
        isRunning: Bool = false,
        size: TimerDisplaySize = .large,
        showSplit: Bool = false,
        splitTime: String? = nil
    ) {
        self.formattedTime = formattedTime
        self.isRunning = isRunning
        self.size = size
        self.showSplit = showSplit
        self.splitTime = splitTime
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            Text(formattedTime)
                .font(.system(size: size.fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(isRunning ? theme.colors.accent : theme.colors.textPrimary)
                .animation(.easeInOut(duration: 0.1), value: formattedTime)
            
            if showSplit, let splitTime = splitTime {
                Text("Split: \(splitTime)")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerDisplay(
            formattedTime: "12:34.5",
            isRunning: true,
            size: .huge
        )
        
        TimerDisplay(
            formattedTime: "05:23.1",
            isRunning: false,
            size: .large,
            showSplit: true,
            splitTime: "01:45"
        )
        
        TimerDisplay(
            formattedTime: "00:45.2",
            size: .medium
        )
    }
    .padding()
}
