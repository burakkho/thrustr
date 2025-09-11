import SwiftUI

// MARK: - TabSelectorItem Protocol
protocol TabSelectorItem: Hashable, Identifiable {
    var displayName: String { get }
    var icon: String? { get }
    var badge: Int? { get }
}

// MARK: - Generic TabSelector Component
struct TabSelector<T: TabSelectorItem>: View {
    @Environment(\.theme) private var theme
    @Binding var selection: T
    let items: [T]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.s) {
                ForEach(items, id: \.id) { item in
                    TabButton(
                        item: item,
                        isSelected: selection.id == item.id,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = item
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

// MARK: - Tab Button Component
private struct TabButton<T: TabSelectorItem>: View {
    @Environment(\.theme) private var theme
    let item: T
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xs) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(item.displayName)
                    .font(theme.typography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if let badge = item.badge, badge > 0 {
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

