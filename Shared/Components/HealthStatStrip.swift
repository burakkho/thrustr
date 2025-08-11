import SwiftUI

struct DashboardHealthStatStripItem: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

// Placeholder kaldırıldı: HealthKit izni yoksa 0 değerler gösterilecek.


