import SwiftUI

enum QuickActionStyle {
    case primary
    case secondary
    case outlined
    case ghost
}

enum QuickActionSize {
    case small
    case medium
    case large
    case fullWidth
}

struct QuickActionButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String?
    let subtitle: String?
    let style: QuickActionStyle
    let size: QuickActionSize
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        subtitle: String? = nil,
        style: QuickActionStyle = .primary,
        size: QuickActionSize = .medium,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.style = style
        self.size = size
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            if size == .fullWidth {
                fullWidthContent
            } else {
                standardContent
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var standardContent: some View {
        HStack(spacing: spacing) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(titleFont)
                    .fontWeight(fontWeight)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .opacity(0.8)
                }
            }
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
        .overlay(borderOverlay)
        .cornerRadius(cornerRadius)
    }
    
    private var fullWidthContent: some View {
        HStack(spacing: spacing) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(titleFont)
                    .fontWeight(fontWeight)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .opacity(0.8)
                }
            }
            
            Spacer()
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .overlay(borderOverlay)
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - Computed Properties (View context içinde)
    
    private var foregroundColor: Color {
        if isDestructive {
            return style == .primary ? .white : theme.colors.error
        }
        
        switch style {
        case .primary:
            return .white
        case .secondary:
            return theme.colors.textPrimary
        case .outlined, .ghost:
            return theme.colors.accent
        }
    }
    
    private var backgroundColor: Color {
        if isDestructive && style == .primary {
            return theme.colors.error
        }
        
        switch style {
        case .primary:
            return theme.colors.accent
        case .secondary:
            return theme.colors.backgroundSecondary
        case .outlined, .ghost:
            return Color.clear
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isDestructive ? theme.colors.error : theme.colors.accent,
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Size Properties
    
    private var spacing: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 8
        case .large, .fullWidth: return 10
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        case .fullWidth: return 16
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .fullWidth: return 14
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large, .fullWidth: return 12
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 14, weight: .medium)
        case .medium: return .system(size: 16, weight: .medium)
        case .large, .fullWidth: return .system(size: 18, weight: .medium)
        }
    }
    
    private var titleFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .body
        case .large, .fullWidth: return .headline
        }
    }
    
    private var subtitleFont: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large, .fullWidth: return .footnote
        }
    }
    
    private var fontWeight: Font.Weight {
        switch style {
        case .primary: return .semibold
        case .secondary, .outlined: return .medium
        case .ghost: return .regular
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Primary styles
        QuickActionButton(
            title: "Start Workout",
            icon: "play.fill",
            style: .primary,
            action: {}
        )
        
        QuickActionButton(
            title: "Browse Programs",
            icon: "rectangle.3.group",
            subtitle: "Find structured plans",
            style: .secondary,
            action: {}
        )
        
        QuickActionButton(
            title: "Delete",
            icon: "trash",
            style: .outlined,
            isDestructive: true,
            action: {}
        )
        
        QuickActionButton(
            title: "Full Width Button",
            icon: "arrow.right",
            subtitle: "This spans the entire width",
            style: .primary,
            size: .fullWidth,
            action: {}
        )
    }
    .padding()
}