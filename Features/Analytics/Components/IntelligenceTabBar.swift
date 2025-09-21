import SwiftUI

struct IntelligenceTabBar: View {
    @Binding var selectedTab: IntelligenceTab
    @Environment(\.theme) private var theme

    var body: some View {
        // Modern iOS 17 style segmented control
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(IntelligenceTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .medium))

                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(selectedTab == tab ? .semibold : .medium)
                        }
                        .foregroundColor(selectedTab == tab ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? theme.colors.accent : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.colors.backgroundSecondary)
                    .shadow(color: theme.shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: IntelligenceTab = .overview

        var body: some View {
            IntelligenceTabBar(selectedTab: $selectedTab)
                .environment(\.theme, DefaultLightTheme())
        }
    }

    return PreviewWrapper()
}