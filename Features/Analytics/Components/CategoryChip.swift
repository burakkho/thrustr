import SwiftUI

struct CategoryChipRow: View {
    @Binding var selectedCategory: AnalyticsCategory
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(AnalyticsCategory.allCases, id: \.self) { category in
                CategoryChip(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                }
            }
            Spacer()
        }
    }
}

struct CategoryChip: View {
    let category: AnalyticsCategory
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xs) {
                if let icon = category.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(category.displayName)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(
                isSelected ? theme.colors.accent : theme.colors.backgroundSecondary
            )
            .foregroundColor(
                isSelected ? .white : theme.colors.textSecondary
            )
            .cornerRadius(theme.radius.l)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var selectedCategory: AnalyticsCategory = .health
    
    return CategoryChipRow(selectedCategory: $selectedCategory)
        .environment(ThemeManager())
        .padding()
}