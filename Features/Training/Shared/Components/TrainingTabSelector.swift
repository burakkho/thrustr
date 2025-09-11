import SwiftUI

struct TrainingTabSelector: View {
    @Environment(\.theme) private var theme
    @Binding var selection: Int
    let tabs: [TrainingTab]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.s) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    TrainingTabButton(
                        tab: tab,
                        isSelected: selection == index,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = index
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, theme.spacing.s)
    }
}

struct TrainingTab {
    let title: String
    let icon: String?
    let badge: Int?
    
    init(title: String, icon: String? = nil, badge: Int? = nil) {
        self.title = title
        self.icon = icon
        self.badge = badge
    }
}

// MARK: - TabSelectorItem Conformance
extension TrainingTab: TabSelectorItem {
    var id: String { title }
    var displayName: String { title }
}

private struct TrainingTabButton: View {
    @Environment(\.theme) private var theme
    let tab: TrainingTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xs) {
                if let icon = tab.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(tab.title)
                    .font(theme.typography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if let badge = tab.badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.colors.accent)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var selection = 0
    
    VStack {
        TrainingTabSelector(
            selection: $selection,
            tabs: [
                TrainingTab(title: "Workouts", icon: "dumbbell"),
                TrainingTab(title: "Programs", badge: 2),
                TrainingTab(title: "History", icon: "clock.arrow.circlepath"),
                TrainingTab(title: "Routines")
            ]
        )
    }
}