import SwiftUI

/**
 * Interactive stat card with cycling temporal data display.
 * 
 * Shows different time periods (daily/weekly/monthly) on tap.
 * Used in the dashboard's quick status section for Lift/Cardio/Nutrition metrics.
 */

enum TimeDisplayMode: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly" 
    case monthly = "monthly"
    
    var next: TimeDisplayMode {
        switch self {
        case .daily: return .weekly
        case .weekly: return .monthly
        case .monthly: return .daily
        }
    }
}

struct ActionableStatCard: View {
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var displayMode: TimeDisplayMode = .daily
    
    // MARK: - Properties
    let icon: String
    let title: String
    let dailyValue: String
    let weeklyValue: String
    let monthlyValue: String
    let dailySubtitle: String
    let weeklySubtitle: String
    let monthlySubtitle: String
    let progress: Double?
    let color: Color
    let onNavigate: (() -> Void)?
    
    // MARK: - Initializer
    init(
        icon: String,
        title: String,
        dailyValue: String,
        weeklyValue: String,
        monthlyValue: String,
        dailySubtitle: String,
        weeklySubtitle: String,
        monthlySubtitle: String,
        progress: Double? = nil,
        color: Color,
        onNavigate: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.dailyValue = dailyValue
        self.weeklyValue = weeklyValue
        self.monthlyValue = monthlyValue
        self.dailySubtitle = dailySubtitle
        self.weeklySubtitle = weeklySubtitle
        self.monthlySubtitle = monthlySubtitle
        self.progress = progress
        self.color = color
        self.onNavigate = onNavigate
    }
    
    // MARK: - Computed Properties
    private var currentValue: String {
        switch displayMode {
        case .daily: return dailyValue
        case .weekly: return weeklyValue
        case .monthly: return monthlyValue
        }
    }
    
    private var currentSubtitle: String {
        switch displayMode {
        case .daily: return dailySubtitle
        case .weekly: return weeklySubtitle
        case .monthly: return monthlySubtitle
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(currentValue)
                .font(.title3.bold())
                .foregroundColor(theme.colors.textPrimary)
                .contentTransition(.numericText(countsDown: false))
                .animation(.easeInOut(duration: 0.5), value: currentValue)
            
            if let progress = progress, progress > 0 {
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill with animation
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: max(progress, 0.05), y: 1.0, anchor: .leading)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progress)
                }
                .frame(height: 8)
            }
            
            Text(currentSubtitle)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, idealHeight: progress != nil ? 120 : 100)
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(
                    color: isPressed ? color.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isPressed ? 6 : 2,
                    y: isPressed ? 3 : 1
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            cycleThroughModes()
        }
        .onLongPressGesture(minimumDuration: 0.8, maximumDistance: .infinity, perform: {
            // Long press triggers navigation if available
            if let navigate = onNavigate {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                navigate()
            }
        }, onPressingChanged: { pressing in
            isPressed = pressing
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentSubtitle): \(currentValue)")
        .accessibilityHint(onNavigate != nil ? "Dokunarak zaman aralığı, basılı tutarak navigasyon" : "Dokunarak farklı zaman aralığını gör")
        .accessibilityAddTraits(.isButton)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    
    // MARK: - Actions
    private func cycleThroughModes() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            displayMode = displayMode.next
        }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 16) {
        ActionableStatCard(
            icon: "dumbbell.fill",
            title: "",
            dailyValue: "75 kg",
            weeklyValue: "65 kg",
            monthlyValue: "58 kg",
            dailySubtitle: "Today's Volume",
            weeklySubtitle: "Weekly Average",
            monthlySubtitle: "Monthly Average",
            color: .blue
        )
        
        ActionableStatCard(
            icon: "figure.run",
            title: "",
            dailyValue: "5.2 km",
            weeklyValue: "3.6 km",
            monthlyValue: "4.1 km",
            dailySubtitle: "Today's Distance",
            weeklySubtitle: "Weekly Average", 
            monthlySubtitle: "Monthly Average",
            color: .green
        )
    }
    .padding()
}
