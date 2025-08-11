//
//  QuickStatCard.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI

struct QuickStatCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let borderlessLight: Bool
    
    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        borderlessLight: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.borderlessLight = borderlessLight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .modifier(QuickStatCardSurfaceModifier(useBorderlessLight: borderlessLight))
    }
}

#Preview {
    VStack {
        QuickStatCard(
            icon: "figure.walk",
            title: "Bugün",
            value: "8,432",
            subtitle: "adım",
            color: .blue,
            borderlessLight: true
        )
        
        QuickStatCard(
            icon: "flame.fill",
            title: "Kalori",
            value: "2,150",
            subtitle: "kcal",
            color: .orange,
            borderlessLight: true
        )
    }
    .padding()
}

// MARK: - Surface modifier (local to component to avoid global changes)
private struct QuickStatCardSurfaceModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let useBorderlessLight: Bool
    func body(content: Content) -> some View {
        if useBorderlessLight && colorScheme == .light {
            content
                .padding(theme.spacing.m)
                .background(theme.colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.shadowLight, radius: 4, y: 1)
        } else {
            content
                .cardStyle()
        }
    }
}
